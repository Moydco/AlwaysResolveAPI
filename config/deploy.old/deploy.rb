# --------------------------------------------------------------------------- #
# Copyright 2013-2015, AlwaysResolve Project (alwaysresolve.org), MOYD.CO LTD #
#                                                                             #
# Licensed under the Apache License, Version 2.0 (the "License"); you may     #
# not use this file except in compliance with the License. You may obtain     #
# a copy of the License at                                                    #
#                                                                             #
# http://www.apache.org/licenses/LICENSE-2.0                                  #
#                                                                             #
# Unless required by applicable law or agreed to in writing, software         #
# distributed under the License is distributed on an "AS IS" BASIS,           #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    #
# See the License for the specific language governing permissions and         #
# limitations under the License.                                              #
# --------------------------------------------------------------------------- #


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

set :linked_files, %w{config/settings.local.yml config/mongoid.yml config/sidekiq.yml config/newrelic.yml config/initializers/sidekiq.rb}
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