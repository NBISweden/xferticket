require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
require 'ostruct'
require "sinatra/config_file"
require 'sys/filesystem'


module XferTickets
  class Application < Sinatra::Base

    register Sinatra::ConfigFile

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
      set :show_exceptions, true
      set :dump_errors, true
      set :views, "#{File.dirname(__FILE__)}/views"

      SiteConfig = OpenStruct.new(
        :title => 'xferticket',
        :author => 'Mikael Borg',
        :repo => 'https://github.com/NBISweden/xferticket',
      )

      DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/#{Sinatra::Base.environment}.db"))
      DataMapper.finalize
      DataMapper.auto_upgrade!

    end

    # Load config file
    unless File.exist?('config/config.yml')
      STDERR.puts 'Please provide a configuration file config/config.yml'
      exit 1
    end

    config_file '../../config/config.yml'

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
    #enable :sessions
    #set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
    session_secret = ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
    use Rack::Session::Cookie, :key => 'rack.session',
      :path => '/',
      :secret => session_secret



    register Sinatra::Flash


    # remove expired tickets every minute
    scheduler = Rufus::Scheduler.new(:lockfile => ".rufus-scheduler.lock")
    unless scheduler.down?
      scheduler.every '60s' do
        Ticket.all.each do |t|
          if(t.created_at + settings.expiration_time < DateTime.now)
            settings.logger.info "Deleting expired ticket #{t.uuid}"
            t.destroy
          end
        end
      end
    end

    helpers do
      def protected!
        redirect(to('/login')) unless session[:userid]
      end

      def ownerprotected!(t)
        protected!
        halt 404, "Not found\n" unless t
        halt 401, "Not authorized\n" unless session[:userid] == t.userid
      end

      def dirsize(path)
        return 0 unless File.directory?(path)
        Dir.glob(File.join(path, '**', '*')).map{ |f| File.exist?(f) ? File.size(f) : 0  }.inject(0, :+)
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
        user = XferTickets::DirectoryUser.authenticate(settings, [params[:username], params[:password]])
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

    # view status
    get "/status" do
      protected!
      @no_of_tickets = Ticket.all.size
      @bytes_free = Sys::Filesystem.stat(settings.datadir).bytes_free
      @bytes_used = dirsize(settings.datadir)
      erb :status
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
      @ticket = XferTickets::Ticket.first(:uuid => u)
      halt 404, 'not found' unless @ticket
      ownerprotected!(@ticket)
      @ticket.destroy 
      halt 200
    end


    # view tickets
    get "/tickets/?" do
      redirect to('/')
    end
    # view ticket
    get "/tickets/:uuid/?" do |u|
      #not_found if u.nil?
      @ticket = Ticket.first(:uuid => u)
      halt 404, 'not found' unless @ticket
      erb :ticket
    end

    # set allow_uploads
    patch "/tickets/:uuid/allow_uploads" do |u|
      @ticket = XferTickets::Ticket.first(:uuid => u)
      ownerprotected!(@ticket)
      @ticket.set_allow_uploads(params['allow_uploads'] == "true")
      @ticket.save
      200
    end

    # upload file
    post "/tickets/:uuid/upload/?" do |u|
      @ticket = XferTickets::Ticket.first(:uuid => u)
      halt 404, 'not found' unless @ticket
      halt 401, 'not allowed' unless @ticket.allow_uploads
      if (params["filename.uploadsmodule"])
        # upload already handled by fron httpd, just move file to correct location
        FileUtils.mv(params["filename.path"], File.join(@ticket.directory,params["filename.name"]))
      else
        File.open(File.join(@ticket.directory, params['filename'][:filename]), "w") do |f|
          f.write(params['filename'][:tempfile].read)
          #f.write(request.body.read) # does not work, boundaries included
        end
      end
      redirect back
    end

    put "/tickets/:uuid/upload/:fn" do |u,fn|
      @ticket = XferTickets::Ticket.first(:uuid => u)
      halt 404, 'not found' unless @ticket
      halt 401, 'not allowed' unless @ticket.allow_uploads
      File.open(File.join(@ticket.directory, fn), "w") do |f|
        f.write(request.body.read)
      end
      redirect to('/tickets/'+u )
    end

    # download file
    get "/tickets/:uuid/:f/download/?" do |u,f|
      @ticket = XferTickets::Ticket.first(:uuid => u)
      halt 404, 'not found' unless @ticket
      fn = File.join(@ticket.directory, f)
      halt 404, 'not found' unless File.exist?(fn)
      if(settings.accelredirect )
        redirectlink = fn.sub(File.dirname(settings.datadir), "")
        settings.logger.info "#{fn} -> X-Accel-Redirect: #{redirectlink}"
        response.headers['X-Accel-Redirect'] = redirectlink
      end
      send_file fn
    end

    # download archive
    get "/tickets/:uuid/downloadarchive/?" do |u|
      @ticket = XferTickets::Ticket.first(:uuid => u)
      halt 404, 'not found' unless @ticket
      attachment("archive.tar")
      stream do |out|
        Dir.chdir(@ticket.directory) do
          Archive::Tar::Minitar.pack(Dir.glob('*'), out)
        end
      end
    end

  end
end
