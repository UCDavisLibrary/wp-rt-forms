ARG APP_IMAGE_NAME_TAG
FROM ${APP_IMAGE_NAME_TAG}

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg curl cron procps

# Update Key
RUN curl -O https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    && apt-key add apt-key.gpg

# Prep work for gsutils
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Install gcloud/gsutils
RUN apt-get update && apt-get install -y mariadb-client \
  wait-for-it google-cloud-sdk

RUN mkdir -p /deploy-utils/data
WORKDIR /deploy-utils
COPY wp-scripts wp-scripts
COPY tail.sh .

# Backup
RUN mkdir data/backup
COPY backup backup
COPY backup/cron /etc/cron.d/backup
RUN chmod 0644 /etc/cron.d/backup

# Init
RUN mkdir data/init
COPY init init

ENTRYPOINT [ "bash", "-c" ]
CMD ["echo 'Use command arg to specify a script to run.'"]
