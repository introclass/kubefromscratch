#!/bin/bash
. ../LinuxShell/library.sh

ORI_OSTYPE=$OSTYPE
export OSTYPE=notdetected 
BASEDIR=`pwd`
PROJECT_NAME=coredns
PROJECT_VERSION="v0.9.9"

BUILD_IMAGE_DIR=${BASEDIR}/dockerfiles/build-image
BUILD_IMAGE=${PROJECT_NAME}:build
DATA_CONTAINER="${PROJECT_NAME}-data"
RSYNC_CONTAINER="${PROJECT_NAME}-rsync"
BUILD_CONTAINER="${PROJECT_NAME}-build"

REMOTE_ROOT=/go/src/github.com/coredns/coredns

USER_ID=$(id -u)
GROUP_ID=$(id -g)

RSYNC_PORT=8730
CONTAINER_RSYNC_PORT=8730

if [ ! -d $BASEDIR ];then
	mkdir $BASEDIR
fi

prepare_codes(){
	cd $BASEDIR
	if [ -d $BASEDIR/${PROJECT_NAME} ];then
		cd $BASEDIR/${PROJECT_NAME}
		local tag=`git tag|grep "^$PROJECT_VERSION$"`
		if [ "$tag" != "$PROJECT_VERSION" ];then
			echo "$BASEDIR/${PROJECT_NAME} exists, may be a wrong version"
			exit 1
		fi
	else
		git clone --depth 1 --single-branch --branch $PROJECT_VERSION https://github.com/coredns/coredns.git ${PROJECT_NAME}
	fi
}

prepare_build_image(){
	cd $BASEDIR
	func_docker_image_exist $BUILD_IMAGE
	if [[ $? == "0" ]];then
		return
	fi
	dd if=/dev/urandom bs=512 count=1 2>/dev/null | LC_ALL=C tr -dc 'A-Za-z0-9' | dd bs=32 count=1 2>/dev/null >${BUILD_IMAGE_DIR}/rsyncd.password
	chmod go= "${BUILD_IMAGE_DIR}/rsyncd.password"
	docker build -t $BUILD_IMAGE $BUILD_IMAGE_DIR
}

prepare_modify_scripts(){
	cd $BASEDIR

	if [ ! -d ${PROJECT_NAME}/vendor/github.com/mholt ];then
		git clone --depth 1 --single-branch --branch "v0.10.10" https://github.com/mholt/caddy.git ./relies/vendor/github.com/mholt/caddy
		cp  -r ./relies/vendor/github.com/mholt ${PROJECT_NAME}/vendor/github.com/
	fi
	
	if [ ! -d ${PROJECT_NAME}/vendor/github.com/miekg ];then
		git clone --depth 1 --single-branch --branch master https://github.com/miekg/dns.git ./relies/vendor/github.com/miekg/dns
		cp  -r ./relies/vendor/github.com/miekg ${PROJECT_NAME}/vendor/github.com/
	fi
	
	if [ ! -d ${PROJECT_NAME}/vendor/golang.org/x/net ];then
		cp  -r ./relies/vendor/golang.org/x/net ${PROJECT_NAME}/vendor/golang.org/x/
	fi
	
	if [ -d ${PROJECT_NAME}/vendor/golang.org/x/text ];then
		# files in repo's vendor path: golang.org/x/text is not enough, replace them
		rm -rf ${PROJECT_NAME}/vendor/golang.org/x/text   
	fi
	cp  -r ./relies/vendor/golang.org/x/text ${PROJECT_NAME}/vendor/golang.org/x/

	if [[ "$ORI_OSTYPE" == "darwin"* ]];then
		sed -i "" -e "s@^coredns: check godeps@coredns: @" ${BASEDIR}/${PROJECT_NAME}/Makefile
	else
		sed -i"" -e "s@^coredns: check godeps@coredns: @" ${BASEDIR}/${PROJECT_NAME}/Makefile
	fi

}

ensure_data_container(){
	local ret=0
	local code=$(docker inspect \
		-f '{{.State.ExitCode}}' \
		"${DATA_CONTAINER}" 2>/dev/null || ret=$?)
	if [[ "${ret}" == 0 && "${code}" != 0 ]]; then
		func_docker_destroy_container ${DATA_CONTAINER}
		ret=1
	fi
	if [[ "${ret}" != 0 ]]; then
		local -ra docker_cmd=(
			docker run
			--volume "${REMOTE_ROOT}"   # white-out the whole output dir
			--volume /usr/local/go/pkg/linux_386_cgo
			--volume /usr/local/go/pkg/linux_amd64_cgo
			--volume /usr/local/go/pkg/linux_arm_cgo
			--volume /usr/local/go/pkg/linux_arm64_cgo
			--volume /usr/local/go/pkg/linux_ppc64le_cgo
			--volume /usr/local/go/pkg/darwin_amd64_cgo
			--volume /usr/local/go/pkg/darwin_386_cgo
			--volume /usr/local/go/pkg/windows_amd64_cgo
			--volume /usr/local/go/pkg/windows_386_cgo
			--name "${DATA_CONTAINER}"
			--hostname "${HOSTNAME}"
			"${BUILD_IMAGE}"
			chown -R ${USER_ID}:${GROUP_ID} "${REMOTE_ROOT}" /usr/local/go/pkg/
		)
		"${docker_cmd[@]}"
	fi
}

start_rsyncd_container(){
	func_docker_destroy_container $RSYNC_CONTAINER
	local -ra docker_cmd=(
		docker run
		--volumes-from $DATA_CONTAINER
		--name "${RSYNC_CONTAINER}"
		--user=$USER_ID:$GROUP_ID
		--hostname "${HOSTNAME}"
		-p 127.0.0.1:${RSYNC_PORT}:${CONTAINER_RSYNC_PORT}
		-d 
		-e HOME="$REMOTE_ROOT"
		-e ALLOW_HOST="$(ifconfig|grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' |grep -Eo '([0-9]*\.){3}[0-9]*' |grep -v '127.0.0.1')"
		"${BUILD_IMAGE}"
	)
	"${docker_cmd[@]}" /rsyncd.sh >/dev/null
}

check_rsyncd(){
	local tries=20
	while (( ${tries} > 0 )) ; do
		if rsync "rsync://project@127.0.0.1:$RSYNC_PORT/" \
			--password-file="${BUILD_IMAGE_DIR}/rsyncd.password" &> /dev/null ; then
			return 0
		fi
		tries=$(( ${tries} - 1))
		sleep 0.1
	done
	
	echo "can't connect rysncd"
	exit 1
}

sync_to_container(){
	start_rsyncd_container
	check_rsyncd
	local -a rsync_opts=(
		--archive
		--password-file=${BUILD_IMAGE_DIR}/rsyncd.password
	)
	rsync ${rsync_opts[@]} \
		--delete --no-perms \
		--filter='H /.git/' \
		--filter='- /.make/' \
		--filter='- /bin/' \
		--filter='- /gopath' \
		--filter='- /_output/' \
		--filter='- /_cache/' \
		--filter='- /coredns' \
		--filter='- /' \
		${BASEDIR}/${PROJECT_NAME}/ rsync://project@127.0.0.1:${RSYNC_PORT}/project/
	stop_rsyncd_container
}

stop_rsyncd_container(){
	docker stop ${RSYNC_CONTAINER} >/dev/null
	docker rm ${RSYNC_CONTAINER} >/dev/null
}

build(){
	func_docker_destroy_container $BUILD_CONTAINER
	local -ra docker_cmd=(
		docker run
		--volumes-from $DATA_CONTAINER
		--name "${BUILD_CONTAINER}"
		--user=$USER_ID:$GROUP_ID
		--hostname "${HOSTNAME}"
		--workdir "${REMOTE_ROOT}"
		--rm
		"${BUILD_IMAGE}"
	)
	"${docker_cmd[@]}" /bin/sh -c "make coredns"
}

build_on_host(){
	echo "nothing to do"
}

copy_output(){
	start_rsyncd_container
	check_rsyncd
	local -a rsync_opts=(
		--archive
		--password-file=${BUILD_IMAGE_DIR}/rsyncd.password
	)
	rsync ${rsync_opts[@]} \
		--prune-empty-dirs \
		--filter='+ /vendor/' \
		--filter='+ /Godeps/' \
		--filter='+ /coredns' \
		--filter='+ /_output' \
		--filter='+ _cache' \
		--filter='+ */' \
		--filter='- /**' \
		rsync://project@127.0.0.1:${RSYNC_PORT}/project/ ${BASEDIR}/${PROJECT_NAME}
	stop_rsyncd_container
}

enter_container(){
	local -ra docker_cmd=(
		docker run
		--rm
		--volumes-from $DATA_CONTAINER
		--user=$USER_ID:$GROUP_ID
		--hostname "${HOSTNAME}"
		--workdir "${REMOTE_ROOT}"
		-it 
		"${BUILD_IMAGE}"
	)
	"${docker_cmd[@]}" /bin/sh
}

release(){
	cd $BASEDIR
	echo "nothing to do"
}

reset(){
	func_docker_destroy_container $DATA_CONTAINER
	func_docker_destroy_container $RSYNC_CONTAINER
	func_docker_destroy_container $BUILD_CONTAINER
	func_docker_destroy_image $BUILD_IMAGE
}

if [[ "$1" == "reset" ]];then
	reset
	exit 0
fi

prepare_codes
prepare_build_image
prepare_modify_scripts
ensure_data_container
sync_to_container

case $1 in
	(bash) enter_container;;
	(build) build; copy_output;;
	(copy) copy_output;;
	(host) build_on_host;;
	(release) release;;
	(*) build;copy_output;build_on_host;release;;
esac
