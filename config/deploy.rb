set :application, 'offside_rails'
set :deploy_user, 'offside24'

set :repo_url, 'git@github.com:ykostov/offside_rails.git'
set :pty, false
set :use_sudo, false
set :init_system, :systemd
# setup rbenv.
set :rbenv_type, :system
set :rbenv_ruby, '2.5.0'
set :rbenv_path, '~/.rbenv'
set :default_env, path: '~/.rbenv/shims:~/.rbenv/bin:$PATH'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w( rake gem bundle ruby rails )
set :puma_init_active_record, true

# Sidekiq
# SSHKit.config.command_map[:sidekiq] = "bundle exec sidekiq"
# SSHKit.config.command_map[:sidekiqctl] = "bundle exec sidekiqctl"
# set :service_unit_name, "sidekiq-#{fetch(:application)}-#{fetch(:stage)}.service"
# how many old releases do we want to keep, not much
set :keep_releases, 5
# files we want symlinking to specific entries in shared
set :linked_files, %w(config/database.yml config/application.yml config/master.key)

# dirs we want symlinking to shared
set :linked_dirs, %w(log tmp/pids tmp/cache tmp/sockets vendor/bundle
                      public/system uploads
                      tmp/uploads/store tmp/uploads/cache)

# append :linked_files, "config/master.key"
# what specs should be run before deployment is allowed to
# continue, see lib/capistrano/tasks/run_tests.cap
set :tests, []

# which config files should be copied by deploy:setup_config
# see documentation in lib/capistrano/tasks/setup_config.cap
# for details of operations
set(:config_files, %w(
  nginx.conf
  database.example.yml
  application.example.yml
))

# log_rotation
# monit

# which config files should be made executable after copying
# by deploy:setup_config
# set(:executable_config_files, %w(
#   unicorn_init.sh
# ))

# files which need to be symlinked to other parts of the
# filesystem. For example nginx virtualhosts, log rotation
# init scripts etc. The full_app_name variable isn't
# available at this point so we use a custom template {{}}
# tag and then add it at run time.
set(:symlinks, [
  {
    source: 'nginx.conf',
    link: '/etc/nginx/sites-enabled/{{full_app_name}}'
  },
  # {
  #   source: 'unicorn_init.sh',
  #   link: '/etc/init.d/unicorn_{{full_app_name}}'
  # }
])

# ,
# {
#   source: "log_rotation",
#  link: "/etc/logrotate.d/{{full_app_name}}"
# },
# {
#   source: "monit",
#   link: "/etc/monit/conf.d/{{full_app_name}}.conf"
# }
# this:
# http://www.capistranorb.com/documentation/getting-started/flow/
# is worth reading for a quick overview of what tasks are called
# and when for `cap stage deploy`

namespace :deploy do
  # make sure we're deploying what we think we're deploying
  before :deploy, 'deploy:check_revision'
  # only allow a deploy with passing tests to deployed
  # before :deploy, "deploy:run_tests"
  # compile assets locally then rsync
  after 'deploy:symlink:shared', 'deploy:compile_assets_locally'
  after :finishing, 'deploy:cleanup'

  # remove the default nginx configuration as it will tend
  # to conflict with our configs.
  before 'deploy:setup_config', 'nginx:remove_default_vhost'

  # reload nginx to it will pick up any modified vhosts from
  # setup_config
  after 'deploy:setup_config', 'nginx:reload'

  desc 'Restart puma'
  task :restart_puma do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:start'
    end
  end
  # Restart monit so it will pick up any monit configurations
  # we've added
  # after 'deploy:setup_config', 'monit:restart'

  # As of Capistrano 3.1, the `deploy:restart` task is not called
  # automatically.
  after 'deploy:publishing', 'deploy:restart'
  after 'deploy:publishing', 'deploy:restart_puma'
end
append :linked_files, "config/master.key"

namespace :deploy do
  namespace :check do
    before :linked_files, :set_master_key do
      on roles(:app), in: :sequence, wait: 10 do
        unless test("[ -f #{shared_path}/config/master.key ]")
          upload! 'config/master.key', "#{shared_path}/config/master.key"
        end
      end
    end
  end
end
