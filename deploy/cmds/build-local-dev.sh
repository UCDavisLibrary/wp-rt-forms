#! /bin/bash

###
# Build images for local development.  They will be tagged with local-dev and are
# meant to be used with wp-rt-forms-local/docker-compose.yaml
# Note: these images should never be pushed to docker hub
###

set -e
DEPLOY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DEPLOY_DIR

LOCAL_BUILD=true ./build.sh
