#!/bin/bash

. ../library.sh

pidf="ssh.pid"
logf="ssh"
cmd="ssh root@192.168.13.87"
func_daemon_cmd $pidf $logf $cmd
