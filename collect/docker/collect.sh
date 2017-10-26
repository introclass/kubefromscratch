#!/bin/bash
RUNPATH=`pwd`
source ${RUNPATH}/../../LinuxShell/library.sh

ITERMS_DIR=iterms
ITERM=

TEMPLATES_DIR=./TEMPLATE
TEMPLATE=

OUTPUT_DIR=${RUNPATH}/output

#$1: dest dir
#$2: template file
#$3: name
gen_daemon_conf(){
	local dest=$1
	local template=$2
	local name=$3
	sed -e "s/{NAME}/${name}/g" $template >$dest/daemon.json
	for i in `ls $ITERMS_DIR/$name`;do
		if [[ "$OSTYPE" == "darwin"* ]];then
			sed -i "" -e "s@{$i}@`cat $ITERMS_DIR/$name/$i`@" $dest/daemon.json
		else
			sed -i"" -e "s@{$i}@`cat $ITERMS_DIR/$name/$i`@" $dest/daemon.json
		fi
	done
}

# $1: iterm name
collect_iterm(){
	local iterm=$1
	local dest=${OUTPUT_DIR}/${iterm}
	func_fatal_cmd func_create_dirs $dest

	local build_docker=../../build-docker-ce

	local script_install=$build_docker/docker/install.sh
	func_fatal_cmd func_force_copy $dest $script_install

	gen_daemon_conf $dest $TEMPLATE $iterm

	local dir_scripts=./scripts
	local script_start=${dir_scripts}/start.sh
	local script_stop=${dir_scripts}/stop.sh
	func_fatal_cmd func_force_copy $dest $script_start $script_stop

	pushd ${OUTPUT_DIR}; tar -czvf ${iterm}.tar.gz ${iterm}; popd
	rm -rf ${OUTPUT_DIR}/${iterm}

	func_green_str "${iterm} is ok"
	func_green_str "output to: ${OUTPUT_DIR}/${iterm}.tar.gz"
}

select_one(){
	for i in `ls ${ITERMS_DIR}`;do
		func_yellow_str $i
	done
	echo -n "select the iterm: "
	read ITERM
	if [ ! -e ${ITERMS_DIR}/${ITERM} ];then
		func_red_str "${ITERMS_DIR}/${ITERM} doesn't exist!" 
		exit
	fi
	collect_iterm $ITERM
}

select_all(){
	for i in `ls ${ITERMS_DIR}`;do
		collect_iterm $i
	done
}

select_template(){
	for i in `ls ${TEMPLATES_DIR}`
	do
		func_yellow_str $i
	done
	echo -n "Select the template: "
	read TEMPLATE
	TEMPLATE="`pwd`/${TEMPLATES_DIR}/${TEMPLATE}"
	if [ ! -e ${TEMPLATE} ];then
		func_red_str "${TEMPLATE} doesn't exist!" 
		exit
	fi
}

echo -n "Select all iterms?[Y|N]: "
read ALL
select_template  # will set var `TEMPLATE`
case $ALL in
	(Y)select_all;;
	(N)select_one;;
	(*)func_red_str "Your choose is wrong!"; exit;;
esac
