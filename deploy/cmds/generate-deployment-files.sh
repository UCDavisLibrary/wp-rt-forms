#! /bin/bash

##
# Generate docker-compose deployment and local development files based on
# config.sh parameters
##

set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR/../templates

source ../config.sh

# generate main dc file
content=$(cat deployment.yaml)
for key in $(compgen -v); do
  if [[ $key == "COMP_WORDBREAKS" || $key == "content" || $key == "GC_READ_KEY_FILE_CONTENT" ]]; then
    continue;
  fi
  escaped=$(printf '%s\n' "${!key}" | sed -e 's/[\/&]/\\&/g')
  content=$(echo "$content" | sed "s/{{$key}}/${escaped}/g")
done
echo "$content" > ../docker-compose.yaml

# generate local development dc file
content=$(cat local-dev.yaml)
LOCAL_BUILD=true source ../config.sh
for key in $(compgen -v); do
  if [[ $key == "COMP_WORDBREAKS" || $key == "content" || $key == "GC_READ_KEY_FILE_CONTENT" ]]; then
    continue;
  fi
  escaped=$(printf '%s\n' "${!key}" | sed -e 's/[\/&]/\\&/g')
  content=$(echo "$content" | sed "s/{{$key}}/${escaped}/g")
done
if [ ! -d "../wp-rt-forms-local-dev" ]; then
  mkdir ../wp-rt-forms-local-dev
fi

echo "$content" > ../wp-rt-forms-local-dev/docker-compose.yaml
