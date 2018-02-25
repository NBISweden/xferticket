$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "xferticket"

#set :run, false
#set :environment, :production

run XferTickets::Application
