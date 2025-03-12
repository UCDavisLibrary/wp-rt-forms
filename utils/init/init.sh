#! /bin/bash

GOOGLE_CLOUD_PROJECT=digital-ucdavis-edu
UPLOADS_DIR=/uploads
WP_SCRIPTS_DIR=/deploy-utils/wp-scripts
GOOGLE_APPLICATION_CREDENTIALS=/etc/service-account.json
DATA_DIR=/deploy-utils/data/init
WP_SRC_ROOT=/usr/src/wordpress

shopt -s expand_aliases

if [[ $RUN_INIT != "true" ]]; then
  echo "RUN_INIT flag not set to 'true', init container will not run."
  exit 0;
fi

if [[ -z $UPLOADS_FILE_NAME ]]; then
  echo "UPLOADS_FILE_NAME variable is required."
  exit 1
fi

if [[ -z $BACKUP_FILE_NAME ]]; then
  echo "BACKUP_FILE_NAME variable is required."
  exit 1
fi

if [[ -z $GC_BUCKET_BACKUPS ]]; then
  echo "GC_BUCKET_BACKUPS variable is required."
  exit 1
fi

if [[ -z $SERVER_URL ]]; then
  echo "SERVER_URL variable is required."
  exit 1
fi

if [[ -z $INIT_DATA_ENV ]]; then
  echo "INIT_DATA_ENV variable is required."
  exit 1
fi

# separate db host from port. wp conflates them in its host config variable.
if [[ $WORDPRESS_DB_HOST =~ ":" ]]; then
  WORDPRESS_DB_JUST_HOST=$(echo $WORDPRESS_DB_HOST | cut -d ":" -f1)
  WORDPRESS_DB_JUST_PORT=$(echo $WORDPRESS_DB_HOST | cut -d ":" -f2)
else
  WORDPRESS_DB_JUST_HOST=$WORDPRESS_DB_HOST
  WORDPRESS_DB_JUST_PORT=3306
fi
alias mysql="mysql --user=$WORDPRESS_DB_USER --host=$WORDPRESS_DB_JUST_HOST --port=$WORDPRESS_DB_JUST_PORT --password=$WORDPRESS_DB_PASSWORD $WORDPRESS_DB_DATABASE"

# wait for db to start up
wait-for-it $WORDPRESS_DB_JUST_HOST:$WORDPRESS_DB_JUST_PORT -t 0

function updateDbHost {
  DATA_ENV_URL=$(echo "SELECT option_value from wp_options WHERE option_name='siteurl' LIMIT 1" | mysql -s)
  echo "Updating links from ${DATA_ENV_URL} to ${SERVER_URL}"

  mysql -e "update wp_options set option_value='${SERVER_URL}' where option_name='siteurl';"
  mysql -e "update wp_options set option_value='${SERVER_URL}' where option_name='home';"
  mysql -e "UPDATE wp_posts SET post_content = REPLACE(post_content, '${DATA_ENV_URL}', '${SERVER_URL}');"
  mysql -e "UPDATE wp_posts SET guid = REPLACE(guid, '${DATA_ENV_URL}', '${SERVER_URL}');"
  wp eval-file ${WP_SCRIPTS_DIR}/update-host.php ${DATA_ENV_URL} ${SERVER_URL} --path=$WP_SRC_ROOT --allow-root

  if [[ ! -z $SITE_TAGLINE ]]; then
    mysql -e "update wp_options set option_value='${SITE_TAGLINE}' where option_name='blogdescription';"
  fi
}

# check database
DB_HAS_DATA=$(echo "SELECT count(*) FROM information_schema.TABLES WHERE (TABLE_SCHEMA = '${WORDPRESS_DB_DATABASE}') AND (TABLE_NAME = 'wp_options')" | mysql -s )
if [[ $DB_HAS_DATA = 0 ]]; then
  echo "No WP data found in db, attempting to pull content for google cloud bucket"

  gcloud auth login --quiet --cred-file=${GOOGLE_APPLICATION_CREDENTIALS}
  gcloud config set project $GOOGLE_CLOUD_PROJECT

  echo "Downloading: gs://${GC_BUCKET_BACKUPS}/${INIT_DATA_ENV}/${BACKUP_FILE_NAME}"
  gsutil cp "gs://${GC_BUCKET_BACKUPS}/${INIT_DATA_ENV}/${BACKUP_FILE_NAME}" $DATA_DIR/$BACKUP_FILE_NAME

  echo "Loading sql dump file"
  zcat $DATA_DIR/$BACKUP_FILE_NAME | mysql -f
  rm $DATA_DIR/$BACKUP_FILE_NAME

  updateDbHost

elif [[ $RUN_DB_HOST_UPDATE == 'true' ]]; then
  echo "RUN_DB_HOST_UPDATE set to true, running db host update only"
  updateDbHost
else
  echo "WP data found in ${WORDPRESS_DB_JUST_HOST}:${WORDPRESS_DB_JUST_PORT}. Skipping hydration."
fi


# check uploads folder
UPLOADS_FILE_COUNT=$(ls -1q $UPLOADS_DIR | wc -l)

if [[ $UPLOADS_FILE_COUNT == 0 ]]; then
  echo "Uploads folder is empty, attempting to pull content for google cloud bucket"

  gcloud auth login --quiet --cred-file=${GOOGLE_APPLICATION_CREDENTIALS}
  gcloud config set project $GOOGLE_CLOUD_PROJECT

  echo "Downloading: gs://${GC_BUCKET_BACKUPS}/${INIT_DATA_ENV}/${UPLOADS_FILE_NAME}"
  gsutil cp "gs://${GC_BUCKET_BACKUPS}/${INIT_DATA_ENV}/${UPLOADS_FILE_NAME}" $UPLOADS_DIR/$UPLOADS_FILE_NAME
  echo "Extracting: tar -zxvf $UPLOADS_DIR/$UPLOADS_FILE_NAME -C $UPLOADS_DIR"
  cd $UPLOADS_DIR
  tar -zxvf $UPLOADS_DIR/$UPLOADS_FILE_NAME -C .
  rm $UPLOADS_DIR/$UPLOADS_FILE_NAME

  # Check if zip file contained a 'uploads' folder, if so move up one directory
  UPLOADS_FILE_COUNT=$(ls -1q $UPLOADS_DIR | wc -l)
  FILE_NAME=$(ls -1q)
  if [[ $UPLOADS_FILE_COUNT == 1 && $FILE_NAME == 'uploads' ]]; then
    mv uploads/* .
    rm -r uploads
  fi
else
  echo "Uploads folder has data. Skipping hydration."
fi

echo "Init container is finished and exiting (this is supposed to happen)"
