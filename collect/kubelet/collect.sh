#!/bin/bash
RUNPATH=`pwd`
source ${RUNPATH}/../../LinuxShell/library.sh

ITERMS_DIR=iterms
ITERM=

TEMPLATES_DIR=./TEMPLATE
TEMPLATE=

OUTPUT_DIR=${RUNPATH}/output

ETCD_ITERMS_DIR=${RUNPATH}/../etcd/iterms

#$1: dest dir
#$2: template file
#$3: name
gen_kube_config(){
	local dest=$1
	local template=$2
	local name=$3

	sed -e "s/{NAME}/${name}/g" $template >$dest/kubeconfig.yml
	if [[ "$OSTYPE" == "darwin"* ]];then
		sed -i "" -e "s@{APISERVER}@https://apiserver1.local@" $dest/kubeconfig.yml
	else
		sed -i"" -e "s@{APISERVER}@https://apiserver1.local@" $dest/kubeconfig.yml
	fi
}

#$1: dest dir
#$2: template file
#$3: name
gen_supervisord_conf(){
	local dest=$1
	local template=$2
	local name=$3

	if [ ! -d $ETCD_ITERMS_DIR ];then
		func_red_str "Not found: $ETCD_ITERMS_DIR"
		exit 1
	fi

	sed -e "s/{NAME}/${name}/g" $template >$dest/supervisord.conf
	for i in `ls $ITERMS_DIR/$name`;do
		if [[ "$OSTYPE" == "darwin"* ]];then
			sed -i "" -e "s@{$i}@`cat $ITERMS_DIR/$name/$i`@" $dest/supervisord.conf
		else
			sed -i"" -e "s@{$i}@`cat $ITERMS_DIR/$name/$i`@" $dest/supervisord.conf
		fi
	done
}

# $1: iterm name
collect_iterm(){
	local iterm=$1
	local dest=${OUTPUT_DIR}/${iterm}

	local dir_bin=$dest/bin
	local dir_data=$dest/data
	local dir_log=$dest/log
	local dir_cni_bin=$dest/cni/bin
	local dir_cni_conf=$dest/cni/conf
	func_fatal_cmd func_create_dirs $dir_bin $dir_data $dir_log $dir_cni_bin $dir_cni_conf

	local dir_ca_apiserver=$dest/cert/ca/apiserver
	local dir_ca_kubelet_client=$dest/cert/ca/kubelet-client
	local dir_cert_apiserver_client=$dest/cert/apiserver-client
	local dir_cert_kubelet=$dest/cert/kubelet
	func_fatal_cmd func_create_dirs $dir_ca_apiserver $dir_ca_kubelet_client $dir_cert_apiserver_client $dir_cert_kubelet

	local build_kube=../../build-kubernetes
	local bin_kubelet=${build_kube}/kubernetes/_output/dockerized/bin/linux/amd64/kubelet
	func_fatal_cmd func_force_copy $dir_bin $bin_kubelet

	local build_certs=../../build-certs
	local ca_apiserver=${build_certs}/apiserver/ca/ca.pem
	local ca_kubelet_client=${build_certs}/kubelet-client/ca/ca.pem
	local cert_apiserver_client=${build_certs}/apiserver-client/output/$iterm/cert.pem
	local key_apiserver_client=${build_certs}/apiserver-client/output/$iterm/key.pem
	local cert_kubelet=${build_certs}/kubelet/output/$iterm/cert.pem
	local key_kubelet=${build_certs}/kubelet/output/$iterm/key.pem

	func_fatal_cmd func_force_copy $dir_ca_apiserver $ca_apiserver
	func_fatal_cmd func_force_copy $dir_ca_kubelet_client $ca_kubelet_client
	func_fatal_cmd func_force_copy $dir_cert_apiserver_client $cert_apiserver_client $key_apiserver_client
	func_fatal_cmd func_force_copy $dir_cert_kubelet $cert_kubelet $key_kubelet

	local build_cni_plugins=../../build-cni-plugins
	local bin_cni_plugins=${build_cni_plugins}/cni-plugins/bin/*
	func_fatal_cmd func_force_copy $dir_cni_bin $bin_cni_plugins

	local conf_cni=./conf/cni/*
	func_fatal_cmd func_force_copy $dir_cni_conf $conf_cni

	gen_supervisord_conf $dest $TEMPLATE $iterm
	gen_kube_config $dest kubeconfig.yml $iterm

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
