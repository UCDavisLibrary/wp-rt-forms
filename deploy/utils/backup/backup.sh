#! /bin/bash

source /etc/profile

GOOGLE_CLOUD_PROJECT=digital-ucdavis-edu
GOOGLE_APPLICATION_CREDENTIALS=/etc/service-account.json
DATA_DIR=/deploy-utils/data/backup
UPLOAD_DIR=/uploads

if [[ -z $BACKUP_DATA_ENV ]]; then
  echo "BACKUP_DATA_ENV variable is required."
  exit 1
fi

if [[ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
  echo "Google cloud credential key file doesn't exist"
  exit 1
fi

# connect to wp db
if [[ $WORDPRESS_DB_HOST =~ ":" ]]; then
  WORDPRESS_DB_JUST_HOST=$(echo $WORDPRESS_DB_HOST | cut -d ":" -f1)
  WORDPRESS_DB_JUST_PORT=$(echo $WORDPRESS_DB_HOST | cut -d ":" -f2)
else
  WORDPRESS_DB_JUST_HOST=$WORDPRESS_DB_HOST
  WORDPRESS_DB_JUST_PORT=3306
fi
alias mysql="mysql --user=$WORDPRESS_DB_USER --host=$WORDPRESS_DB_JUST_HOST --port=$WORDPRESS_DB_JUST_PORT --password=$WORDPRESS_DB_PASSWORD $WORDPRESS_DB_DATABASE"

echo "Generating sqldump file"
mysqldump --password="$MYSQL_ROOT_PASSWORD" --host=$WORDPRESS_DB_JUST_HOST --port=$WORDPRESS_DB_JUST_PORT "$WORDPRESS_DB_DATABASE" | gzip > $DATA_DIR/$BACKUP_FILE_NAME

echo "Compressing wp media uploads directory"
tar -czvf $DATA_DIR/$UPLOADS_FILE_NAME $UPLOAD_DIR

echo "uploading files to cloud bucket ${GC_BUCKET_BACKUPS}/${BACKUP_DATA_ENV}"
gcloud auth login --quiet --cred-file=${GOOGLE_APPLICATION_CREDENTIALS}
# gcloud config set project $GOOGLE_CLOUD_PROJECT
gsutil cp $DATA_DIR/$BACKUP_FILE_NAME "gs://${GC_BUCKET_BACKUPS}/${BACKUP_DATA_ENV}/${BACKUP_FILE_NAME}"
gsutil cp $DATA_DIR/$UPLOADS_FILE_NAME "gs://${GC_BUCKET_BACKUPS}/${BACKUP_DATA_ENV}/${UPLOADS_FILE_NAME}"

echo "backup complete"
