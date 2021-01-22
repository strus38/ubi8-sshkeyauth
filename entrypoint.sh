#!/usr/bin/env ash
if [ `whoami` == 'keys-sync' ]; then
  if [ ! -r /ska/config/config.ini ]; then
      echo "config.ini not found or incorrect permissions."
      echo "Permissions must be $(id -u keys-sync):$(id -g keys-sync) with at least 400"
      exit 1
  fi
  if [ ! -r /ska/config/keys-sync ]; then
      echo "private key not found or incorrect permissions."
      echo "Permissions must be $(id -u keys-sync):$(id -g keys-sync) with 400"
      exit 1
  fi
  if [ ! -r /ska/config/keys-sync.pub ]; then
      echo "public key not found or incorrect permissions."
      echo "Permissions must be $(id -u keys-sync):$(id -g keys-sync) with at least 400"
      exit 1
  fi
  if ! grep "^timeout_util = GNU coreutils$" /ska/config/config.ini > /dev/null; then
      echo "timeout_util must be set to GNU coreutils."
      echo "Change it to: timeout_util = GNU coreutils"
      exit 1
  fi
elif [ $(id -u) = 0 ]; then
  if ! sudo -u keys-sync /entrypoint.sh; then
    exit 1
  fi
  rsync -a --delete /ska/public_html/ /public_html/
  echo "Waiting for database..."
  for i in $(seq 1 10); do 
    if /ska/scripts/apply_migrations.php; then
      echo "Success"
      break
    fi
    echo "Trying again in 1 sec"
    sleep 1
  done
  
  /usr/sbin/crond
  /ska/scripts/syncd.php --user keys-sync
  /usr/sbin/php-fpm7 -F
else
  echo "Must be executed with root"
fi
