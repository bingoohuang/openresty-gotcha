#!/usr/bin/env bash

set -x

# SCRIPTPATH is from https://stackoverflow.com/a/4774063/14077979
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo SCRIPTPATHPath:$SCRIPTPATH

OPENRESTY_HOME=~/openresty

[ -z "$OPENRESTY_HOME" ] && echo "env \$OPENRESTY_HOME is required" && exit 1
[ ! -f "$OPENRESTY_HOME/bin/resty" ] && echo "\$OPENRESTY_HOME=$OPENRESTY_HOME is invalid."  && exit 1

echo "Copy lua libraries and configurations files:"
cp -v $SCRIPTPATH/bench.conf $OPENRESTY_HOME/nginx/conf/
cp -v $SCRIPTPATH/*.lua $OPENRESTY_HOME/nginx/conf/

ps -ef|grep nginx
cd $OPENRESTY_HOME/nginx && sbin/nginx -c conf/bench.conf -s reload
sleep 3
ps -ef|grep nginx

echo "Complete!"
