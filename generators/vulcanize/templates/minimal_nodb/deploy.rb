# This is a sample Capistrano config file for rubber

set :rails_env, (ENV["RAILS_ENV"] ||= 'production')
set :application, "your_app_name"

set :deploy_via, :checkout
set :repository, 'http://src.foo.com/svn/yourapp/trunk'

set :user, 'root'
set :password, nil

# Use sudo with user rails for cap deploy:[stop|start|restart]
set :use_sudo,      true
set :runner,        'rails'

set :deploy_to,     "/mnt/#{application}-#{rails_env}"
# How many old releases should be kept around when running "cleanup" task
set :keep_releases, 3

# =============================================================================
# TASKS
# =============================================================================

before "deploy:restart", "rubber:config", "setup_perms"
before "deploy:start", "rubber:config", "setup_perms"
after "deploy", "deploy:cleanup"

# Fix perms because we start server as rails user
# Server needs to be able to write logs, etc.
task :setup_perms do
  run "find #{shared_path} -name cached-copy -prune -o -print | xargs chown #{runner}:#{runner}"
  run "chown -R #{runner}:#{runner} #{current_path}/tmp"
end

deploy.task :restart, :roles => :app do
    run "cd #{current_path} && mongrel_rails cluster::stop --force --clean"
    run "cd #{current_path} && mongrel_rails cluster::start --clean"
end

deploy.task :stop, :roles => :app do
    run "cd #{current_path} && mongrel_rails cluster::stop --force --clean"
end

deploy.task :start, :roles => :app do
    run "cd #{current_path} && mongrel_rails cluster::start --clean"
end

# Override rubber's bootstrap_db since there is no db role for minimal_nodb
rubber.task :bootstrap_db do
end

after "rubber:install_packages", "custom_install"
after "rubber:install_gems", "custom_install_app"

task :custom_install do
  # add the rails user for running app server with
  run "adduser --system --group rails"
end

task :custom_install_app, :roles => :app do
  # Setup system to restart mongrel_cluster on reboot
  rubber.run_script 'install_app', <<-ENDSCRIPT
    mkdir -p /etc/mongrel_cluster
    rm -f /etc/mongrel_cluster/#{application}-#{rails_env}.yml && ln -s /mnt/#{application}-#{rails_env}/current/config/mongrel_cluster.yml /etc/mongrel_cluster/#{application}-#{rails_env}.yml
    find /usr/lib/ruby/gems -path "*/resources/mongrel_cluster" -exec cp {} /etc/init.d/ \\;
    chmod +x /etc/init.d/mongrel_cluster
    update-rc.d -f mongrel_cluster remove
    update-rc.d mongrel_cluster defaults 99 00
  ENDSCRIPT
end
