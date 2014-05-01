#require "rvm/capistrano"

#set :rvm_ruby_string, :local              # use the same ruby as used locally for deployment
#set :rvm_autolibs_flag, "read-only"       # more info: rvm help autolibs

#before 'deploy:setup', 'rvm:install_rvm'  # install/update RVM
#before 'deploy:setup', 'rvm:install_ruby' # install Ruby and create gemset, OR:

# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'api.moyd.co'
set :repo_url, 'git@git.azcloud.it:alberto/api-moyd-co.git'

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }
# set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

set :linked_files, %w{config/settings.local.yml config/sidekiq.yml config/sidekiq.yml config/initializers/sidekiq.rb}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :keep_releases, 5

namespace :deploy do

#  desc "Prepare our symlinks" #7
#  task :post_symlink do
#      run "ln -nfs #{shared_path}/tmp #{release_path}/tmp"
#      run "ln -nfs #{shared_path}/settings.local.yml #{release_path}/config/settings.local.yml"
#      run "ln -nfs #{shared_path}/sidekiq.yml #{release_path}/config/sidekiq.yml"
#      run "ln -nfs #{shared_path}/mongoid.yml #{release_path}/config/sidekiq.yml"
#      run "ln -nfs #{shared_path}/sidekiq.rb #{release_path}/config/initializers/sidekiq.rb"
#  end

  after :finishing, 'deploy:cleanup'

end