#!/bin/bash
export OSTYPE=notdetected 
BASEDIR=`pwd`
VERSION="v3.2.7"

if [ ! -d $BASEDIR ];then
	mkdir $BASEDIR
fi

prepare_codes(){
	cd $BASEDIR
	if [ -d $BASEDIR/etcd ];then
		cd $BASEDIR/etcd
		local tag=`git tag|grep "^$VERSION$"`
		if [ "$tag" != "$VERSION" ];then
			echo "$BASEDIR/etcd exists, may be a wrong version"
			exit 1
		fi
	else
		git clone --depth 1 --single-branch --branch $VERSION https://www.github.com/coreos/etcd.git
	fi
}

build(){
	cd ${BASEDIR}
	docker run --rm -v `pwd`/etcd:/go/src/etcd -w /go/src/etcd golang:1.8.1 /bin/sh -c "./build"
}
prepare_codes
build
