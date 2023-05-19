#! /bin/bash

######### DEPLOYMENT CONFIG ############
# Setup your application deployment here
########################################

# Grab build number is mounted in CI system
if [[ -f /config/.buildenv ]]; then
  source /config/.buildenv
else
  BUILD_NUM=-1
fi

# Main version number we are tagging the app with. Always update
# this when you cut a new version of the app!
APP_VERSION=v0.0.9.${BUILD_NUM}

# Repository tags/branchs
# Tags should always be used for production deployments
# Branches can be used for development deployments
REPO_TAG=main

# Dependency tags/branches
THEME_TAG='v3.3.0'
WP_CORE_VERSION='6.2.1'
FORMINATOR_VERSION='1.23.3'
WPMU_DEV_DASHBOARD_VERSION='4.11.18'
MYSQL_TAG=5.7
ADMINER_TAG=4

DEPLOY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$( cd $DEPLOY_DIR/.. && pwd )"
SRC_DIR=$ROOT_DIR/src


##
# Repositories
##

GITHUB_ORG_URL=https://github.com/UCDavisLibrary

# theme
THEME_REPO_NAME=ucdlib-theme-wp
THEME_REPO_URL=$GITHUB_ORG_URL/$WEBSITE_REPO_NAME

# forminator rt addon plugin
FORMINATOR_RT_ADDON_REPO_NAME=forminator-addon-rt
FORMINATOR_RT_ADDON_REPO_URL=$GITHUB_ORG_URL/$FORMINATOR_RT_ADDON_REPO_NAME

##
# Git
##
GIT=git
GIT_CLONE="$GIT clone"

ALL_GIT_REPOSITORIES=( $THEME_REPO_NAME $FORMINATOR_RT_ADDON_REPO_NAME )
REPOSITORY_DIR=repositories

##
# Container
##

# Container Registery
CONTAINER_REG_ORG=gcr.io/digital-ucdavis-edu

#if [[ -z $BRANCH_NAME ]]; then
#  CONTAINER_CACHE_TAG=$(git rev-parse --abbrev-ref HEAD)
#else
#  CONTAINER_CACHE_TAG=$BRANCH_NAME
#fi
CONTAINER_CACHE_TAG='sandbox'

# set localhost/local-dev used by
# local development docker-compose file
if [[ ! -z $LOCAL_BUILD ]]; then
  CONTAINER_REG_ORG='localhost/local-dev'
fi


# Container Images
APP_IMAGE_NAME=$CONTAINER_REG_ORG/itis-wp-rt-forms
MYSQL_IMAGE_NAME=mysql
ADMINER_IMAGE_NAME=adminer

APP_IMAGE_NAME_TAG=$APP_IMAGE_NAME:$REPO_TAG
MYSQL_IMAGE_NAME_TAG=$MYSQL_IMAGE_NAME:$MYSQL_TAG
ADMINER_IMAGE_NAME_TAG=$ADMINER_IMAGE_NAME:$ADMINER_TAG

ALL_DOCKER_BUILD_IMAGES=( $APP_IMAGE_NAME )

ALL_DOCKER_BUILD_IMAGE_TAGS=(
  $APP_IMAGE_NAME_TAG
)

# NPM
NPM=npm
NPM_PRIVATE_PACKAGES=(
  $REPOSITORY_DIR/$THEME_REPO_NAME/src/public
  $REPOSITORY_DIR/$THEME_REPO_NAME/src/editor
)
JS_BUNDLES=(
  $REPOSITORY_DIR/$THEME_REPO_NAME/src/public
  $REPOSITORY_DIR/$THEME_REPO_NAME/src/editor
)

# wp directories
WP_SRC_ROOT=/usr/src/wordpress
WP_LOG_ROOT=/var/log/wordpress
WP_THEME_DIR=$WP_SRC_ROOT/wp-content/themes
WP_UCD_THEME_DIR=$WP_THEME_DIR/$THEME_REPO_NAME
WP_PLUGIN_DIR=$WP_SRC_ROOT/wp-content/plugins

# google cloud
GC_PLUGIN_DIR=wordpress-general/plugins
CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [[ -f "$CONFIG_DIR/reader-key.json" ]]; then
  GOOGLE_KEY_FILE_CONTENT="$(cat $CONFIG_DIR/reader-key.json)"
else
  echo "Warning: no Google key file found. Run cmds/init-keys.sh to download the key file."
fi
