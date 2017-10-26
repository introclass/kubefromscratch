#!/bin/bash

conf_file=/etc/docker/daemon.json

if [ -e $conf_file ];then
	mv $conf_file $conf_file.backup
fi

if [ -h $conf_file ];then
	mv $conf_file $conf_file.backup
fi

if [ ! -d /etc/docker ];then
	mkdir -p /etc/docker
fi

ln -s `pwd`/daemon.json  $conf_file

systemctl start docker
