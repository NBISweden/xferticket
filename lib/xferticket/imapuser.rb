module XferTickets

  require 'net/imap'

  class IMAPUser
    def self.authenticate(settings, params)
      imap = Net::IMAP.new(settings.imap_server,
                           :port => settings.imap_port,
                           :ssl => settings.imap_tls)

      caps = imap.capability()

      if caps.include?('STARTTLS') then
        imap.starttls()
        # Refetch capabilities after connection upgrade
        caps = imap.capability()
      end

      if caps.include?('LOGIN')
        imap.login(params[0],
                   params[1])
      elsif caps.include?('AUTH=PLAIN')
        imap.authenticate('LOGIN',
                          params[0],
                          params[1])
      else
        raise 'No supported authentication method'
      end
      # return e-mail user as user id
      params[0]
    rescue Errno::ECONNREFUSED
      raise 
      'Unable to connect to IMAP server'
    rescue Net::IMAP::NoResponseError
      nil
    end
  end
end
