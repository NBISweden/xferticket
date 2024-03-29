require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
require 'ostruct'
require 'sanitize'
require 'bcrypt'

module XferTickets
  # Tickets 
  class Ticket
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :expire_days, Integer
    property :userid, String
    property :title, String
    property :uuid, String, :unique => true, :required => true
    property :salt, String
    property :pwd, Text
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
      self.expire_days = [
          Integer(params[:expire_days], 10),
          XferTickets::Application.settings.maximum_expiration_time
      ].min
      self.uuid = SecureRandom.urlsafe_base64(n=32)
      self.pwd = nil
      Dir.mkdir(self.directory, 0777)
      File.chmod(0777, self.directory)
    end

    def expirydate
      return self.created_at + self.expire_days
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

    def set_password(str)
      if(str.empty?)
        self.pwd = nil
      else
        self.pwd = BCrypt::Password.create(str).to_s
      end
    end

    def check_password(str)
      !self.pwd || BCrypt::Password.new(self.pwd).is_password?(str)
    end
  end
end
