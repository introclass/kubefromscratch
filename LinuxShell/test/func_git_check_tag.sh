#!/bin/bash

. ../library.sh

func_git_check_tag  https://github.com/coreos/etcd.git  origin/release-0.4  "" etcd
echo $?
