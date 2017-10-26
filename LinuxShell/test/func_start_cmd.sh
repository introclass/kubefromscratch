#!/bin/bash

. ../library.sh

pid="./pidfile"
log="./log"
name="ssh"
cmd="ssh root@192.168.13.87"

func_start_cmd $pid $log $name $cmd
