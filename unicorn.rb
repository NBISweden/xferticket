# set path to app that will be used to configure unicorn,
# note the trailing slash in this example
@dir = "/usr/local/src/xferticket/"

# ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"

worker_processes 2
working_directory @dir

# disable rewindable input in order to avoid temporary files
#rewindable_input false

timeout 120

# Specify path to socket unicorn listens to,
# we will use this in our nginx.conf later
listen "#{@dir}tmp/sockets/unicorn.sock", :backlog => 64

# Set process id path
pid "#{@dir}tmp/pids/unicorn.pid"

# Set log file paths
stderr_path "#{@dir}log/unicorn.stderr.log"
stdout_path "#{@dir}log/unicorn.stdout.log"
