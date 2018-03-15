#!/bin/bash
ORI_OSTYPE=$OSTYPE
export OSTYPE=notdetected 
BASEDIR=`pwd`
K8SVERSION="v1.8.0"

if [ ! -d $BASEDIR ];then
	mkdir $BASEDIR
fi

prepare_codes(){
	cd $BASEDIR
	if [ -d $BASEDIR/kubernetes ];then
		cd $BASEDIR/kubernetes
		local tag=`git tag|grep "^$K8SVERSION$"`
		if [ "$tag" != "$K8SVERSION" ];then
			echo "$BASEDIR/kubernetes exists, may be a wrong version"
			exit 1
		fi
	else
		git clone --depth 1 --single-branch --branch $K8SVERSION https://www.github.com/kubernetes/kubernetes.git
	fi
}

prepare_build_base_image(){
	cd $BASEDIR
	# if I have kube-cross's origin dockerfile, i can build the image by myself.
	# I want it.
	local KUBE_BUILD_IMAGE_CROSS_TAG=`cat ${BASEDIR}/kubernetes/build/build-image/cross/VERSION`

	local BUILD_BASE_IMAGE="lijiaocn/kube-cross:${KUBE_BUILD_IMAGE_CROSS_TAG}"
	docker build -t  ${BUILD_BASE_IMAGE} -f ./dockerfiles/kube-cross-glibc.dockerfile  ./dockerfiles
	docker tag ${BUILD_BASE_IMAGE} gcr.io/google_containers/kube-cross:${KUBE_BUILD_IMAGE_CROSS_TAG}
}

prepare_release_base_image(){
	cd $BASEDIR
	# if I have origin dockerfiles, i can build the image by myself.
	# I want it.
	local RELEASE_BASE_VERSION=`cat ${BASEDIR}/kubernetes/build/common.sh |grep debian_iptables_version=|sed -e "s/.*=//g"`
	
	docker pull googlecontainer/debian-iptables-amd64:v7
	docker tag googlecontainer/debian-iptables-amd64:v7    gcr.io/google-containers/debian-iptables-amd64:${RELEASE_BASE_VERSION}
	
#	docker pull googlecontainer/debian-iptables-arm:v7
#	docker tag googlecontainer/debian-iptables-arm:v7      gcr.io/google-containers/debian-iptables-arm:${RELEASE_BASE_VERSION}
#	
#	docker pull googlecontainer/debian-iptables-arm64:v7
#	docker tag googlecontainer/debian-iptables-arm64:v7    gcr.io/google-containers/debian-iptables-arm64:${RELEASE_BASE_VERSION}
#	
#	docker pull googlecontainer/debian-iptables-ppc64le:v7
#	docker tag googlecontainer/debian-iptables-ppc64le:v7  gcr.io/google-containers/debian-iptables-ppc64le:${RELEASE_BASE_VERSION}
#	
#	docker pull googlecontainer/debian-iptables-s390x:v7
#	docker tag googlecontainer/debian-iptables-s390x:v7    gcr.io/google-containers/debian-iptables-s390x:${RELEASE_BASE_VERSION}
}

prepare_modify_scripts(){
	cd $BASEDIR
	if [[ "$ORI_OSTYPE" == "darwin"* ]];then
		sed -i "" -e "s/build --pull/build /" ${BASEDIR}/kubernetes/build/lib/release.sh
		sed -i "" -e "s/--delete \\\/--delete --no-perms \\\/" ${BASEDIR}/kubernetes/build/common.sh
		sed -i "" -e "s/\(^make.*KUBE_TEST_\)/#\1/" ${BASEDIR}/kubernetes/hack/make-rules/cross.sh
	else
		sed -i"" -e "s/build --pull/build /" ${BASEDIR}/kubernetes/build/lib/release.sh
		sed -i"" -e "s/--delete \\\/--delete --no-perms \\\/" ${BASEDIR}/kubernetes/build/common.sh
		sed -i"" -e "s/\(^make.*KUBE_TEST_\)/#\1/" ${BASEDIR}/kubernetes/hack/make-rules/cross.sh
	fi
	cd $BASEDIR/kubernetes; git add . ;git commit -m "modify build script"
}

build(){
	cd ${BASEDIR}/kubernetes
	# don't run test，and just build for linux/amd64
	# reference kubernetes/Makefile
	# if OSTYPE is darwin*, will build for darwin
	make quick-release KUBE_RELEASE_RUN_TESTS=n KUBE_FASTBUILD=true
}

prepare_codes
prepare_build_base_image
prepare_release_base_image
prepare_modify_scripts
build
