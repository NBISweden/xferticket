# Tickets 
class Ticket
  include DataMapper::Resource

  property :id, Serial
  property :created_at, DateTime
  property :userid, String
  property :title, String
  property :uuid, String, :unique => true, :required => true

  before :destroy do
          # replace w/ delete dir
    begin
          puts "Deleting: #{self.uuid}"
          FileUtils.remove_entry_secure(self.directory)
    rescue
          puts "Hmmmm... could not find data dir #{self.directory}."
    end
  end

  def initialize(params, user)
          self.userid = user
          self.title = params[:title]
          self.uuid = SecureRandom.urlsafe_base64(n=32)
          Dir.mkdir(self.directory, 0777)
          File.chmod(0777, self.directory)
  end

  def expirydate
          return self.created_at + Sinatra::Application::settings.expiration_time
  end

  def directory
          return File.join(Sinatra::Application::settings.datadir, self.uuid)
  end

  def files
          return Dir.glob(File.join(self.directory, "*"))
  end
end
