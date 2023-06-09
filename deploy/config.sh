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
THEME_TAG='v3.4.0'
WP_CORE_VERSION='6.2.2'
FORMINATOR_VERSION='1.24.1'
OPENID_CONNECT_GENERIC_VERSION='3.9.1'
WPMU_DEV_DASHBOARD_VERSION='4.11.18'
MYSQL_TAG=5.7
ADMINER_TAG=4

# Auth
OIDC_PROVIDER_URL='https://sandbox.auth.library.ucdavis.edu/realms/internal'
OIDC_CLIENT_ID='rt-forms-client'
#OIDC_CLIENT_SECRET='set this in your .env file'
OIDC_PROTOCOL_URL=$OIDC_PROVIDER_URL/protocol/openid-connect
OIDC_ENDPOINT_LOGIN_URL=$OIDC_PROTOCOL_URL/auth
OIDC_ENDPOINT_USERINFO_URL=$OIDC_PROTOCOL_URL/userinfo
OIDC_ENDPOINT_TOKEN_URL=$OIDC_PROTOCOL_URL/token
OIDC_ENDPOINT_LOGOUT_URL=$OIDC_PROTOCOL_URL/logout
OIDC_CLIENT_SCOPE='openid profile email roles'
OIDC_LOGIN_TYPE='auto'
OIDC_CREATE_IF_DOES_NOT_EXIST='true'
OIDC_LINK_EXISTING_USERS='true'
OIDC_REDIRECT_USER_BACK='true'
OIDC_ENFORCE_PRIVACY='true'

# Directories
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
UCD_THEME_ENV=prod

# forminator rt addon plugin
FORMINATOR_RT_ADDON_REPO_NAME=forminator-addon-rt
FORMINATOR_RT_ADDON_REPO_URL=$GITHUB_ORG_URL/$FORMINATOR_RT_ADDON_REPO_NAME

##
# Git
##
GIT=git
GIT_CLONE="$GIT clone"

ALL_GIT_REPOSITORIES=( $FORMINATOR_RT_ADDON_REPO_NAME )
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
NPM_PRIVATE_PACKAGES=()
JS_BUNDLES=()

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

# Theme development
# To be able to edit the theme as you develop this app, uncomment the following, run init-local-dev:
# and then uncomment the corresponding volume section in your local-dev docker-compose file

# ALL_GIT_REPOSITORIES=( $THEME_REPO_NAME $FORMINATOR_RT_ADDON_REPO_NAME )
# NPM_PRIVATE_PACKAGES=(
#   $REPOSITORY_DIR/$THEME_REPO_NAME/src/public
#   $REPOSITORY_DIR/$THEME_REPO_NAME/src/editor
# )
# JS_BUNDLES=(
#   $REPOSITORY_DIR/$THEME_REPO_NAME/src/public
#   $REPOSITORY_DIR/$THEME_REPO_NAME/src/editor
# )
# UCD_THEME_ENV=dev
