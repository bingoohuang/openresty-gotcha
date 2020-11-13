# SCRIPTPATH is from https://stackoverflow.com/a/4774063/14077979
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo SCRIPTPATHPath:$SCRIPTPATH
cd $SCRIPTPATH

# 导出 hash
HASHKEY=__gateway_redis__
REDISCLI_AUTH="xaaU123~" redis-cli -h 192.168.126.5  -p 36794 --raw hgetall  $HASHKEY >  $HASHKEY.out

# 导入hash
HASHKEY=__gateway_redis__
while read line1; do read line2; echo $line2 | redis-cli -x -h 127.0.0.1 -p 6379 HSET $HASHKEY $line1; done < $HASHKEY.out
