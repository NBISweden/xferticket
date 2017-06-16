require 'net/ldap'

class DirectoryUser
  def self.authenticate(settings, params)
    #return false if params[:username].empty? || params[:password].empty?
    # connect anonymously & lookup user to do authenticated bind_as() next
    ldap = Net::LDAP.new(:host => settings.ldap_server,
                         :port => settings.ldap_port,
                         :base => settings.ldap_base,
                         :encryption => settings.ldap_enc ? :simple_tls : nil,
                         :auth => { :method => :anonymous })
    ldap.bind_as(:base => settings.ldap_base,
                 :filter => "(uid=#{Net::LDAP::Filter.escape(params.first)})",
    :password => params.last)
  rescue Errno::ECONNREFUSED
    raise 
    'Unable to connect to LDAP server'
  rescue NoMethodError => ex
    if [:ldap_server, :ldap_port, :ldap_base].include? ex.name
      raise 
      "Missing '#{ex.name}' attribute in configuration."
    else
      raise
    end
  end
end
