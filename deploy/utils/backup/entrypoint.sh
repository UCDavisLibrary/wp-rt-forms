#! /bin/bash

BACKUP_PROFILE=/etc/profile.d/backup.sh

if [[ $RUN_BACKUP != "true" ]]; then
  echo "RUN_BACKUP flag not set to 'true', backup container will not run."
  exit 0;
fi

# Apply cron job
if [[ ! -f /var/log/cron.log ]]; then
  crontab /etc/cron.d/backup
  touch /var/log/cron.log
fi

if [[ -f $BACKUP_PROFILE ]]; then
  rm $BACKUP_PROFILE
fi

# cron tab runs in a blank enviornment, create a backup profile cron can load
echo "export NIGHTLY_BACKUPS=$RUN_BACKUP" >> $RUN_BACKUP
echo "export GC_BUCKET_BACKUPS=$GC_BUCKET_BACKUPS" >> $BACKUP_PROFILE
echo "export GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT" >> $BACKUP_PROFILE
echo "export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS" >> $BACKUP_PROFILE
echo "export BACKUP_DATA_ENV=$BACKUP_DATA_ENV" >> $BACKUP_PROFILE
echo "export BACKUP_FILE_NAME=$BACKUP_FILE_NAME" >> $BACKUP_PROFILE
echo "export UPLOADS_FILE_NAME=$UPLOADS_FILE_NAME" >> $BACKUP_PROFILE
echo "export WORDPRESS_DB_HOST=$WORDPRESS_DB_HOST" >> $BACKUP_PROFILE
echo "export WORDPRESS_DB_USER=$WORDPRESS_DB_USER" >> $BACKUP_PROFILE
echo "export WORDPRESS_DB_DATABASE=$WORDPRESS_DB_DATABASE" >> $BACKUP_PROFILE
echo "export WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD" >> $BACKUP_PROFILE
echo "export MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" >> $BACKUP_PROFILE

cron && tail -f /var/log/cron.log
