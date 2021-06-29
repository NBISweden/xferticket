
shared_dir = "/tmp"

# Change to match your CPU core count
workers 2

# Min and Max threads per worker
threads 1, 6

# Default to production
environment "production"

# Logging
stdout_redirect "#{shared_dir}/puma.stdout.log", "#{shared_dir}/puma.stderr.log", true

# Set up socket location
bind "unix://#{shared_dir}/puma.sock"

# Set master PID and state locations
pidfile "#{shared_dir}/puma.pid"
state_path "#{shared_dir}/puma.state"

