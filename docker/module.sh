#!/bin/bash

# Requirements:
command -v curl >/dev/null 2>&1 || {
    echo "\033[0;31mCURL is required for this script, installing.\033[m";
    apt-get install curl -y
}

command -v git >/dev/null 2>&1 || {
    echo -e "\033[0;31mGit is required for this script to run, installing\033[m";
    apt-get install git -y
}

command -v jq >/dev/null 2>&1 || {
    echo -e "\033[0;31mjq is required for this script to run, installing\033[m";
    apt-get install jq -y
}

command -v php >/dev/null 2>&1 || { echo -e "\033[0;31mPHP is required for this script to run\033[m" >&2; exit 1; }

if [ -z "$1" ]; then
    echo -e "\033[0;31mYou need to choose module to install\033[m";
    exit 1;
fi;

if [[ ${GH_ACCESS_TOKEN} == "null" ]]; then
    echo "Could not find GH_ACCESS_TOKEN, aborting";
    exit 0;
fi;

# Start

echo "Installing ${OMEKA_MODULE}...";

OMEKA_MODULE="${1}"
T=(${OMEKA_MODULE//\// })
OMEKA_MODULE_USER=${T[0]}
OMEKA_FOLDER_NAME="${2}"

if [[ ${OMEKA_MODULE} == *"/"* ]]; then
  echo -e "\033[0;34mWe've detected you're wanting to install a Github repo...\033[m"

  # Checking repository exists and current user is authenticated.
  REPO_STATUS_CODE=$(curl -u ${GH_ACCESS_TOKEN} -I https://api.github.com/repos/${OMEKA_MODULE} 2>/dev/null | head -n 1 | cut -d$' ' -f2)
  if [ ${REPO_STATUS_CODE} != 200 ]; then
    echo -e "\033[0;31mRepository does not exist, make sure you are have set up your ENV variables for GITHUB_USER and GITHUB_TOKEN\033[m"
    exit 1;
  fi

  echo -e "\033[0;33m ==> Checking for existing modules\033[m"
  cd modules

  if [ "$(ls -A ./${OMEKA_MODULE})" ]; then
    echo -e "\033[0;33mWARNING: Repository already exists.\033[m"
    echo -e  "\033[0;33mRun 'rm -rf $(pwd)/${OMEKA_MODULE}' to remove this manually and try again\033[m"
    cd ${OMEKA_MODULE}
  else
    echo -e "\033[0;33m ==> Cloning repository\033[m"
    mkdir -p ./${OMEKA_MODULE}
    cd ${OMEKA_MODULE}
    REPOSITORY="https://${GH_ACCESS_TOKEN}@github.com/${OMEKA_MODULE}.git"
    git clone --single-branch --branch master ${REPOSITORY} .
  fi;


  MODULE_FOLDER_DESTINATION=$(cat ./composer.json | jq -r '.extra."install-name"');
  if [[ ${MODULE_FOLDER_DESTINATION} == "null" ]]; then
    MODULE_FOLDER_DESTINATION=$(cat ./composer.json | jq -r '.extra."omeka-module-name"');
  fi

  if [[ ${MODULE_FOLDER_DESTINATION} == "null" ]]; then
    MODULE_FOLDER_DESTINATION=${OMEKA_FOLDER_NAME}
    if [[ -z ${MODULE_FOLDER_DESTINATION} ]]; then
      echo -e "\033[0;31mCannot detect module name, please enter manually as second argument\033[m"
      exit 1;
    fi;
  fi;
  cd -

  echo -e "\033[0;33m ==> Moving module to destination: ${MODULE_FOLDER_DESTINATION}\033[m"
  mv ./${OMEKA_MODULE} ${MODULE_FOLDER_DESTINATION}
  rm -rf ./${OMEKA_MODULE_USER} # clean up

  # At this point we have a module!
  cd ${MODULE_FOLDER_DESTINATION};

  # Composer install
  HAS_COMPOSER_DEPENDENCIES=$(cat ./composer.json | jq -r '.require');
  if [[ ${HAS_COMPOSER_DEPENDENCIES} != "null" ]]; then
    if [ -x "$(command -v composer)" ]; then
        echo -e "\033[0;34mFound local composer, using for installation\033[m";
        composer install --no-dev --no-scripts --optimize-autoloader
    else
        echo -e "\033[0;33mDid not find local composer, downloading...\033[m";
        curl -o composer.phar https://getcomposer.org/composer.phar
        php composer.phar install --no-dev --no-scripts --optimize-autoloader
    fi;
  fi;

  cd -;
  echo -e "\n\033[0;32m 🎉   ${MODULE_FOLDER_DESTINATION} (${OMEKA_MODULE}) was installed into your modules folder!\033[m";
fi;