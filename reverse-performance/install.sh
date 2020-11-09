#!/usr/bin/env bash

[ -z "$OPENRESTY_HOME" ] && echo "env \$OPENRESTY_HOME is required" && exit 1
[ ! -f "$OPENRESTY_HOME/bin/resty" ] && echo "\$OPENRESTY_HOME=$OPENRESTY_HOME is invalid."  && exit 1

echo "Install to $OPENRESTY_HOME:"
cp -v openresty/lualib/resty/* $OPENRESTY_HOME/lualib/resty/

backupFile="$OPENRESTY_HOME/nginx/conf/nginx.conf.$(date +%Y%m%d%H%M%S)"

echo "Backup original nginx.conf to $backupFile:"
cp $OPENRESTY_HOME/nginx/conf/nginx.conf $backupFile

echo "Copy lua libraries and configurations files:"
cp -v openresty/nginx/conf/* $OPENRESTY_HOME/nginx/conf/
echo "Complete!"
