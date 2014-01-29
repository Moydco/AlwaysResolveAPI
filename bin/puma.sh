#!/usr/bin/env bash

# Simple move this file into your Rails `script` folder. Also make sure you `chmod +x puma.sh`.
# Please modify the CONSTANT variables to fit your configurations.

# The script will start with config set by $PUMA_CONFIG_FILE by default

PUMA_CONFIG_FILE=/var/www/api.moyd.co/web/current/config/puma.rb
PUMA_PID_FILE=/var/www/api.moyd.co/web/current/tmp/puma.pid
PUMA_SOCKET=/var/www/api.moyd.co/web/current/tmp/puma.sock

# check if puma process is running
puma_is_running() {
  if [ -S $PUMA_SOCKET ] ; then
    if [ -e $PUMA_PID_FILE ] ; then
      if cat $PUMA_PID_FILE | xargs pgrep -P > /dev/null ; then
        return 0
      else
        echo "No puma process found"
      fi
    else
      echo "No puma pid file found"
    fi
  else
    echo "No puma socket found"
  fi

  return 1
}

case "$1" in
  start)
    echo "Starting puma..."
    rm -f $PUMA_SOCKET
    if [ -e $PUMA_CONFIG_FILE ] ; then
      su  shapi_moyd <<'EOF'
cd /var/www/api.moyd.co/web/current && RAILS_ENV=production ~/.rvm/bin/rvm jruby-1.7.9@api.moyd.co do bundle exec puma --config /var/www/api.moyd.co/web/current/config/puma.rb
EOF
    else
      su  shapi_moyd <<'EOF'
cd /var/www/api.moyd.co/web/current && RAILS_ENV=production ~/.rvm/bin/rvm jruby-1.7.9@api.moyd.co do bundle exec puma --daemon --bind unix:///var/www/api.moyd.co/web/current/tmp/puma.sock --pidfile /var/www/api.moyd.co/web/current/tmp/puma.pid
EOF
    fi

    echo "done"
    ;;

  stop)
    echo "Stopping puma..."
      kill -s SIGTERM `cat $PUMA_PID_FILE`
      rm -f $PUMA_PID_FILE
      rm -f $PUMA_SOCKET

    echo "done"
    ;;

  restart)
    if puma_is_running ; then
      echo "Hot-restarting puma..."
      kill -s SIGUSR2 `cat $PUMA_PID_FILE`

      echo "Doublechecking the process restart..."
      sleep 5
      if puma_is_running ; then
        echo "done"
        exit 0
      else
        echo "Puma restart failed :/"
      fi
    fi

    echo "Trying cold reboot"
    script/puma.sh start
    ;;

  *)
    echo "Usage: script/puma.sh {start|stop|restart}" >&2
    ;;
esac