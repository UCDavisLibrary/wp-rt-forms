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
  --build-arg GOOGLE_KEY_FILE_CONTENT="${GOOGLE_KEY_FILE_CONTENT}" \
  --build-arg GC_PLUGIN_DIR=${GC_PLUGIN_DIR} \
  --build-arg FORMINATOR_VERSION=${FORMINATOR_VERSION} \
  --build-arg OPENID_CONNECT_GENERIC_VERSION=${OPENID_CONNECT_GENERIC_VERSION} \
  --build-arg THEME_TAG=${THEME_TAG} \
  --build-arg WPMU_DEV_DASHBOARD_VERSION=${WPMU_DEV_DASHBOARD_VERSION} \
  --build-arg FORMINATOR_RT_ADDON_REPO_URL=${FORMINATOR_RT_ADDON_REPO_URL} \
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
