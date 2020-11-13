#!/usr/bin/env bash

set -x

gobench -method POST -u http://127.0.0.1:2000/echo1 -d 10s
sleep 10
gobench -method POST -u http://127.0.0.1:2000/echo2 -d 10s
sleep 10
gobench -method POST -u http://127.0.0.1:2000/ngx/print -d 10s
sleep 10
gobench -method POST -u http://127.0.0.1:2000/file/print -d 10s
sleep 10
gobench -method POST -u http://127.0.0.1:2000/require/print -d 10s
sleep 10
gobench -method POST -u http://127.0.0.1:2000/module/print -d 10s

# 🕙[ 22:15:51 ] ❯ sh gobench.sh
# + gobench -method POST -u http://127.0.0.1:2000/echo1 -d 10s
# Dispatching 100 goroutines
# Waiting for results...
#
# Total Requests:                 735265 hits
# Successful requests:            735265 hits
# Network failed:                 0 hits
# Bad requests(!2xx):             0 hits
# Successful requests rate:       73506 hits/sec
# Read throughput:                12 MiB/sec
# Write throughput:               11 MiB/sec
# Test time:                      10.002707792s
# + sleep 10
# + gobench -method POST -u http://127.0.0.1:2000/echo2 -d 10s
# Dispatching 100 goroutines
# Waiting for results...
#
# Total Requests:                 683073 hits
# Successful requests:            683073 hits
# Network failed:                 0 hits
# Bad requests(!2xx):             0 hits
# Successful requests rate:       68290 hits/sec
# Read throughput:                12 MiB/sec
# Write throughput:               10 MiB/sec
# Test time:                      10.002528317s
# + sleep 10
# + gobench -method POST -u http://127.0.0.1:2000/ngx/print -d 10s
# Dispatching 100 goroutines
# Waiting for results...
#
# Total Requests:                 579692 hits
# Successful requests:            579692 hits
# Network failed:                 0 hits
# Bad requests(!2xx):             0 hits
# Successful requests rate:       57939 hits/sec
# Read throughput:                11 MiB/sec
# Write throughput:               9.1 MiB/sec
# Test time:                      10.005072167s
# + sleep 10
# + gobench -method POST -u http://127.0.0.1:2000/file/print -d 10s
# Dispatching 100 goroutines
# Waiting for results...
#
# Total Requests:                 601560 hits
# Successful requests:            601560 hits
# Network failed:                 0 hits
# Bad requests(!2xx):             0 hits
# Successful requests rate:       60135 hits/sec
# Read throughput:                11 MiB/sec
# Write throughput:               9.5 MiB/sec
# Test time:                      10.003351803s
# + sleep 10
# + gobench -method POST -u http://127.0.0.1:2000/require/print -d 10s
# Dispatching 100 goroutines
# Waiting for results...
#
# Total Requests:                 629692 hits
# Successful requests:            629692 hits
# Network failed:                 0 hits
# Bad requests(!2xx):             0 hits
# Successful requests rate:       62948 hits/sec
# Read throughput:                12 MiB/sec
# Write throughput:               10 MiB/sec
# Test time:                      10.003318031s
# + sleep 10
# + gobench -method POST -u http://127.0.0.1:2000/module/print -d 10s
# Dispatching 100 goroutines
# Waiting for results...
#
# Total Requests:                 633415 hits
# Successful requests:            633415 hits
# Network failed:                 0 hits
# Bad requests(!2xx):             0 hits
# Successful requests rate:       63322 hits/sec
# Read throughput:                12 MiB/sec
# Write throughput:               10 MiB/sec
# Test time:                      10.002972318s
#
# openresty-gotcha/bench on  main [?] took 1m50s