#! /bin/bash

###
# download the reader key from the secret manager
###

set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR/..

gcloud secrets versions access latest --secret=itis-backup-reader-key > reader-key.json
