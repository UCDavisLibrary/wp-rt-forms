#! /bin/bash

###
# Main build process to cutting production images
###

set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR/..
source config.sh

# Use buildkit to speedup local builds
# Not supported in google cloud build yet
if [[ -z $CLOUD_BUILD ]]; then
  export DOCKER_BUILDKIT=1
fi

# Application
docker build \
  -t $APP_IMAGE_NAME_TAG \
  --cache-from=$APP_IMAGE_NAME:$CONTAINER_CACHE_TAG \
  --build-arg WP_CORE_VERSION=${WP_CORE_VERSION} \
  --build-arg WP_SRC_ROOT=${WP_SRC_ROOT} \
  --build-arg WP_LOG_ROOT=${WP_LOG_ROOT} \
  --build-arg WP_THEME_DIR=${WP_THEME_DIR} \
  --build-arg WP_PLUGIN_DIR=${WP_PLUGIN_DIR} \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --build-arg BUILD_NUM=${BUILD_NUM} \
  --build-arg BUILD_TIME=${BUILD_TIME} \
  --build-arg APP_VERSION=${APP_VERSION} \
  $ROOT_DIR