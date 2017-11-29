#!/bin/bash
. ../LinuxShell/library.sh

ORI_OSTYPE=$OSTYPE
export OSTYPE=notdetected 
BASEDIR=`pwd`
PROJECT_NAME=kube-router
PROJECT_VERSION="v0.0.17"

BUILD_IMAGE_DIR=${BASEDIR}/dockerfiles/build-image
BUILD_IMAGE=${PROJECT_NAME}:build
DATA_CONTAINER="${PROJECT_NAME}-data"
RSYNC_CONTAINER="${PROJECT_NAME}-rsync"
BUILD_CONTAINER="${PROJECT_NAME}-build"

REMOTE_ROOT=/go/src/github.com/cloudnativelabs/kube-router

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
		git clone --depth 1 --single-branch --branch $PROJECT_VERSION https://www.github.com/cloudnativelabs/kube-router.git
	fi
}

prepare_build_image(){
	cd $BASEDIR
	func_docker_image_exist $BUILD_IMAGE
	if [[ $? == "0" ]];then
		docker build -t $BUILD_IMAGE $BUILD_IMAGE_DIR
		return
	fi
	dd if=/dev/urandom bs=512 count=1 2>/dev/null | LC_ALL=C tr -dc 'A-Za-z0-9' | dd bs=32 count=1 2>/dev/null >${BUILD_IMAGE_DIR}/rsyncd.password
	chmod go= "${BUILD_IMAGE_DIR}/rsyncd.password"
	docker build -t $BUILD_IMAGE $BUILD_IMAGE_DIR
}

prepare_modify_scripts(){
	cd $BASEDIR
	if [[ "$ORI_OSTYPE" == "darwin"* ]];then
		sed -i "" -e "s@\$(DOCKER) run -v \$(PWD):/pwd golang:alpine @\$(DOCKER) run --rm -v \$(PWD):/pwd $BUILD_IMAGE @" ${BASEDIR}/${PROJECT_NAME}/Makefile
		sed -i "" -e "s@container: kube-router gobgp@container: @" ${BASEDIR}/${PROJECT_NAME}/Makefile
	else
		sed -i"" -e "s@\$(DOCKER) run -v \$(PWD):/pwd golang:alpine @\$(DOCKER) run --rm -v \$(PWD):/pwd $BUILD_IMAGE @" ${BASEDIR}/${PROJECT_NAME}/Makefile
		sed -i"" -e "s@container: kube-router gobgp@container: @" ${BASEDIR}/${PROJECT_NAME}/Makefile
	fi

	if [[ "$ORI_OSTYPE" == "darwin"* ]];then
		sed -i "" -e 's@sudo docker@docker@' ${BASEDIR}/${PROJECT_NAME}/Makefile
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
		--filter='- /kube-router' \
		--filter='- /gobgp' \
		--filter='- /_output/' \
		--filter='- /_cache/' \
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
	"${docker_cmd[@]}" /bin/sh -c "make kube-router"
}

build_on_host(){
	cd $BASEDIR
	pushd $BASEDIR/$PROJECT_NAME
		make gobgp
	popd
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
		--filter='+ /kube-router' \
		--filter='+ /gobgp' \
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
	pushd $BASEDIR/$PROJECT_NAME
		make container
		docker rmi ${PROJECT_NAME}:${PROJECT_VERSION}
		docker tag cloudnativelabs/kube-router-git:HEAD ${PROJECT_NAME}:${PROJECT_VERSION}
		docker rmi cloudnativelabs/kube-router-git:HEAD
	popd
}

reset(){
	func_docker_destroy_container ${DATA_CONTAINER}
	func_docker_destroy_container $RSYNC_CONTAINER
	func_docker_destroy_container $BUILD_CONTAINER
	func_docker_destroy_image $BUILD_IMAGE
}

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
	(reset) reset;;
	(*) build;copy_output;build_on_host;release;;
esac
