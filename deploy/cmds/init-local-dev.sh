#! /bin/bash

###
# Init the /repositories folder with symbolic links to folders that exist in the same parent
# directory as this directory.
# Note: This script does not checkout any repository, it simply cleans the /repositories folders
# and makes the symbolic links
#
# also installs npm dependencies and generates dev bundles
###

set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR/..

source ./config.sh

if [ -d "./${REPOSITORY_DIR}" ]; then
  rm -rf ./$REPOSITORY_DIR
fi
mkdir ./$REPOSITORY_DIR

for repo in "${ALL_GIT_REPOSITORIES[@]}"; do
  ln -s ../../../$repo ./$REPOSITORY_DIR/$repo
done

ls -al $REPOSITORY_DIR

./cmds/install-private-packages.sh
./cmds/generate-dev-bundles.sh
