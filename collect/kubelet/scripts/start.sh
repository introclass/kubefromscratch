#!/bin/bash

if [ ! -e /opt/cni/bin ];then
	mkdir -p /opt/cni 2>/dev/null
	ln -s `pwd`/cni/bin /opt/cni/bin
fi

if [ ! -e /etc/cni/net.d ];then
	mkdir -p /etc/cni 2>/dev/null
	ln -s `pwd`/cni/conf /etc/cni/net.d
fi

supervisord -c supervisord.conf
