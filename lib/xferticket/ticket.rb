require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
require 'ostruct'
require 'sanitize'

module XferTickets
  # Tickets 
  class Ticket
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :userid, String
    property :title, String
    property :uuid, String, :unique => true, :required => true
    property :allow_uploads, Boolean, :default => true

    before :destroy do
    puts "Deleting: #{self.uuid}"
      # replace w/ delete dir
      begin
        self.set_allow_uploads(true)
        FileUtils.remove_entry_secure(self.directory, true)
      rescue
        puts "Hmmmm... could not find data dir #{self.directory}."
      end
    end

    def initialize(params, user)
      self.userid = user
      self.title = Sanitize.clean(params[:title])
      self.uuid = SecureRandom.urlsafe_base64(n=32)
      Dir.mkdir(self.directory, 0777)
      File.chmod(0777, self.directory)
    end

    def expirydate
      return self.created_at + XferTickets::Application.settings.expiration_time
    end

    def directory
      return File.join(XferTickets::Application.settings.datadir, self.uuid)
    end

    def files
      return Dir.glob(File.join(self.directory, "*"))
    end

    def set_allow_uploads(val)
      if val
        self.allow_uploads = true
        File.chmod(0777, self.directory)
      else
        self.allow_uploads = false
        File.chmod(0555, self.directory)
      end
    end
  end
end
