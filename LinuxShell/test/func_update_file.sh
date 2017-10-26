#!/bin/bash

. ../library.sh

lver_file=./testversion
rver_url=http://192.168.202.240/testversion
lfile=./testfile
rfile_url=http://192.168.202.240/testfile

func_update_file $lver_file $rver_url $lfile $rfile_url
