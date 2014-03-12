# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'api.moyd.co'
set :repo_url, 'git@git.azcloud.it:alberto/api-moyd-co.git'

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }
# set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

# set :linked_files, %w{config/database.yml}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      #execute "ln -nfs #{shared_path}/tmp #{release_path}/tmp"
      #execute "ln -nfs #{shared_path}/settings.local.yml #{release_path}/config/settings.local.yml"
      #execute "ln -nfs #{shared_path}/newrelic.yml #{release_path}/config/newrelic.yml"
      #execute :touch, "#{shared_path}/tmp/restart.txt"
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after :finishing, 'deploy:cleanup'

end