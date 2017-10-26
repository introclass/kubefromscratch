#!/bin/bash
. ../library.sh

lfile=./export.tar.gz
url=http://192.168.202.240/testfile
sha1=http://192.168.202.240/testversion

func_curl_file_sha1 $lfile $url $sha1
