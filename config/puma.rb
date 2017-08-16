app_dir = File.expand_path("../..", __FILE__)
shared_dir = "#{app_dir}/tmp"

# Change to match your CPU core count
workers 2

# Min and Max threads per worker
threads 1, 6

# Default to production
environment "production"

# Logging
stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

# Set up socket location
bind "unix://#{shared_dir}/sockets/puma.sock"

# Set master PID and state locations
pidfile "#{shared_dir}/puma.pid"
state_path "#{shared_dir}/puma.state"

daemonize false
