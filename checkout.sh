#!/bin/bash

echo "Checking for new modules"

MODULES_INSTALLED=0

while read -r ID PKG_NAME
do
    MODULE_PATH="workspace/modules/$ID"

    if [ ! -d "$MODULE_PATH" ]; then
        if [[ "$ID" != *"github.com"* ]]; then
            git clone "git@github.com:digirati-co-uk/$ID" "$MODULE_PATH"
        else
            git clone "$ID" "$MODULE_PATH"
        fi
    fi

    BRANCH=$(git --git-dir="$MODULE_PATH/.git" rev-parse --abbrev-ref HEAD)

    composer config "repositories.$ID" path "$MODULE_PATH"

    if ! composer show --no-interaction  2>&1  | grep -q "$PKG_NAME"; then
        composer require "$PKG_NAME" "dev-$BRANCH"
        MODULES_INSTALLED=$((MODULES_INSTALLED + 1))
    fi
done <<- "EOF"
    omeka-iiif-view-module digirati/omeka-iiif-view-module
    omeka-iiif-import-module digirati/omeka-iiif-import-module
    omeka-elucidate-module dlcs/omeka-elucidate-module
    omeka-i18n-module digirati/omeka-i18n-module
    omeka-annotation-studio-module digirati/omeka-annotation-studio-module
    omeka-public-user-module digirati/omeka-public-user-module
    omeka-web-hooks-module digirati/omeka-web-hooks-module
    omeka-royal-society-db-module digirati/omeka-royal-society-db-module
    omeka-elucidate-proxy-module digirati-co-uk/omeka-elucidate-proxy-module
EOF

if [ $MODULES_INSTALLED -gt 0 ]; then
    echo "Installed $MODULES_INSTALLED modules"
else
    echo "No modules to install"
fi