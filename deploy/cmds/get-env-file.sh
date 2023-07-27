#! /bin/bash

###
# download the env file from the secret manager
# first arg is for the directory to download to relative to deploy directory
# You will want to review the env file before using it, since it has values for both dev and prod
###

set -e
CMDS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $CMDS_DIR/..
path=$1
if [ -z "$path" ]; then
  path=""
elif [[ ! $path == */ ]]; then
  path="${path}/"
fi

gcloud secrets versions access latest --secret=itis-wp-rt-forms-env > $path.env
