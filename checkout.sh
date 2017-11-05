#!/bin/bash

echo "Checking for new modules"

MODULES_INSTALLED=0

function __install_pkg_from_dir() {
  if [ -z "$1" ]
  then
    echo "No package path given"
    return 0
  fi

  if [ -z "$2" ]
  then
    echo "No package ID given"
    return 0
  fi

  if [ -z "$3" ]
  then
    echo "No package branch given"
    return 0
  fi

  PKG_PATH="$1"
  ID="$2"
  BRANCH="$3"
  VERSION="$4"

  COMPOSER_FILE="$PKG_PATH/composer.json"
  PKG_NAME=$(jq -r '.name' < "$COMPOSER_FILE")

  composer config "repositories.$ID" path "$PKG_PATH"

  if [[ $(jq -r ".require[\"$PKG_NAME\"]" < "$(pwd)/composer.json") == "null" ]]; then
    if [ -z "$VERSION" ]; then
      composer require --prefer-source "$PKG_NAME:dev-$BRANCH"
    else
      composer require --prefer-source "$PKG_NAME:dev-$BRANCH as $VERSION"
    fi
  fi
}

while read -r REPO_ID TYPE VERSION
do
  if [[ "$REPO_ID" != *"/"* ]];
  then
    ID="$REPO_ID"
    REPO_URL="git@github.com:digirati-co-uk/$ID"
  else
    ID=$(echo "$REPO_ID" | cut -d '/' -f 2)
    REPO_URL="git@github.com:$REPO_ID"
  fi

  case "$TYPE" in
    "library") PKG_PATH="workspace/libraries/$ID" ;;
    "theme") PKG_PATH="workspace/themes/$ID" ;;
    "module") PKG_PATH="workspace/modules/$ID" ;;
    *) PKG_PATH="workspace/libraries/$ID" ;;
  esac

  if [ ! -d "$PKG_PATH" ]
  then
    git clone "$REPO_URL" "$PKG_PATH"
  fi

  BRANCH=$(git --git-dir="$PKG_PATH/.git" rev-parse --abbrev-ref HEAD)

  if [ "$TYPE" == "theme" ];
  then
    THEME_SRC_DIR=$(find "$PKG_PATH/src/omeka/" -maxdepth 1 -mindepth 1 -type d)
    __install_pkg_from_dir "$THEME_SRC_DIR/module" "$ID-module" "$BRANCH" "$VERSION"
    __install_pkg_from_dir "$THEME_SRC_DIR/theme/" "$ID-theme" "$BRANCH" "$VERSION"
  else
    __install_pkg_from_dir "$PKG_PATH" "$ID" "$BRANCH" "$VERSION"
  fi
done <<- "EOF"
    omeka-iiif-view-module module
    omeka-iiif-import-module module
    omeka-elucidate-module module
    omeka-i18n-module module
    omeka-annotation-studio-module module
    omeka-public-user-module module
    omeka-web-hooks-module module
    omeka-royal-society-db-module module
    omeka-elucidate-proxy-module module
    elucidate-php library 3.0.0
    iiif-php library 1.1
    nlw-frontend theme
    rs-frontend theme
    ida-frontend theme
    garyttierney/w3c-annotations-php library
EOF

if [ $MODULES_INSTALLED -gt 0 ]; then
    echo "Installed $MODULES_INSTALLED modules"
else
    echo "No modules to install"
fi