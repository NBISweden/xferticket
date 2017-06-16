require "rubygems"
require "bundler/setup"
require "sinatra"
require "sinatra/config_file"
require "sinatra/flash"
require "rufus/scheduler"
require "minitar"
require "securerandom"
require "logger"
require File.join(File.dirname(__FILE__), "environment")

# This is to enable streaming tar:
class Sinatra::Helpers::Stream
  alias_method :write, :<<
end

configure :production, :development do
  set :logging, nil
  logger = Logger.new STDOUT
  logger.level = Logger::INFO
  logger.datetime_format = '%a %d-%m-%Y %H%M '
  set :logger, logger
end

# Load config file
unless File.exist?('config/config.yml')
  STDERR.puts 'Please provide a configuration file config/config.yml'
  exit 1
end

config_file 'config/config.yml'

# refuse to run as root
if Process.uid == 0
  STDERR.puts 'Please do not run this as root.' 
  exit 1
end

# check that data directory is writeable
unless(File.writable?(settings.datadir))
  STDERR.puts "Error: data directory not writeable."
  exit 1
end

# warning when using simple password authorization
if(settings.authentication == "simplepassword")
  settings.logger.warn "simplepassword authentication - not secure, only for testing purposes!"
end

# set up sessions
enable :sessions
register Sinatra::Flash

set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }


configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

# remove expired tickets every minute
scheduler = Rufus::Scheduler.new
scheduler.every '60s' do
          Ticket.all.each do |t|
                  if(t.created_at + Sinatra::Application::settings.expiration_time < DateTime.now)
                    settings.logger.info "Deleting expired ticket #{t.uuid}"
                    t.destroy
                  end
          end
end
helpers do
  def protected!
    redirect(to('/login')) unless session[:userid]
  end
end

# root page
get "/" do
  @tickets = Ticket.all(:userid => session[:userid]) if session[:userid]
  erb :root
end

# authorization
get "/login" do
  erb :login
end
post "/login" do
  if(settings.authentication == "simplepassword")
    if([params[:username], params[:password]] == [settings.simpleuser, settings.simplepassword])
      user = settings.simpleuser
      session[:userid] = user
    end
  elsif(settings.authentication == "ldap")
    user = DirectoryUser.authenticate(settings, [params[:username], params[:password]])
    session[:userid] = user.first.uid.first if user
    settings.logger.info "Log in by user #{session[:userid]}"
  end
  if session[:userid]
    redirect to('/')
  else
    flash.next[:error] = "Invalid credentials"
    redirect to('/login')
  end
end
get "/logout" do
  settings.logger.info "Log out by user #{session[:userid]}"
  session[:userid] = nil
  redirect to('/')
end

# create new ticket
post "/tickets" do
  protected!
  settings.logger.info "New ticket by #{session[:userid]}"
  t = Ticket.new(params, session[:userid] )
  t.save
  redirect to('/')
end

# delete ticket
delete "/tickets/:uuid/?" do |u|
  protected!
  @ticket = Ticket.first(:uuid => u)
  if @ticket.userid == session["userid"]
    @ticket.destroy 
    redirect to('/')
  else
    halt 401, "Not authorized\n"
  end
end


# view tickets
get "/tickets/?" do
  redirect to('/')
end
# view ticket
get "/tickets/:uuid/?" do |u|
  #not_found if u.nil?
  @ticket = Ticket.first(:uuid => u)
  halt 401, 'not found' unless @ticket
  erb :ticket
end

# upload file
post "/tickets/:uuid/upload" do |u|
        puts params
  @ticket = Ticket.first(:uuid => u)
  halt 401, 'not found' unless @ticket
  File.open(File.join(@ticket.directory, params['filename'][:filename]), "w") do |f|
    f.write(params['filename'][:tempfile].read)
  end
  redirect to('/tickets/'+u )
end

# download file
get "/tickets/:uuid/:f/download/?" do |u,f|
  @ticket = Ticket.first(:uuid => u)
  halt 401, 'not found' unless @ticket
  fn = File.join(@ticket.directory, f)
  halt 401, 'not found' unless File.exist?(fn)
  if(settings.accelredirect)
    response.headers['X-Accel-Redirect'] = fn
  end
  send_file fn
end

# download archive (not working)
get "/tickets/:uuid/downloadarchive/?" do |u|
  @ticket = Ticket.first(:uuid => u)
  halt 401, 'not found' unless @ticket
  attachment("archive.tar")
    stream do |out|
      Dir.chdir(@ticket.directory) do
        Archive::Tar::Minitar.pack(Dir.glob('*'), out)
      end
  end
end
