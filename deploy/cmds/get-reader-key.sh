#! /bin/bash

###
# download the reader key from the secret manager
###

set -e
CMDS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $CMDS_DIR/..

gcloud --project=digital-ucdavis-edu secrets versions access latest --secret=itis-backup-reader-key > ./secrets/reader-key.json
