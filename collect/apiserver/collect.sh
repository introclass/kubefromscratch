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
gen_supervisord_conf(){
	local dest=$1
	local template=$2
	local name=$3

	if [ ! -d $ETCD_ITERMS_DIR ];then
		func_red_str "Not found: $ETCD_ITERMS_DIR"
		exit 1
	fi

	local etcd_servers
	for i in `ls $ETCD_ITERMS_DIR`;do
		etcd_servers="$etcd_servers,https://$i:2379"
	done
	etcd_servers=`echo $etcd_servers | sed -e "s/,//"`

	sed -e "s/{NAME}/${name}/g" $template >$dest/supervisord.conf
	if [[ "$OSTYPE" == "darwin"* ]];then
		sed -i "" -e "s@{BINDIP}@0.0.0.0@" $dest/supervisord.conf
		sed -i "" -e "s@{ETCD_SERVERS}@${etcd_servers}@" $dest/supervisord.conf
		sed -i "" -e "s@{ETCD_PREFIX}@/kubernetes@" $dest/supervisord.conf
		sed -i "" -e "s@{CLUSTER_SERVICEIP_RANGE}@172.16.0.0/17@" $dest/supervisord.conf
	else
		sed -i"" -e "s@{BINDIP}@0.0.0.0@" $dest/supervisord.conf
		sed -i"" -e "s@{ETCD_SERVERS}@${etcd_servers}@" $dest/supervisord.conf
		sed -i"" -e "s@{ETCD_PREFIX}@$/kubernetes@" $dest/supervisord.conf
		sed -i"" -e "s@{CLUSTER_SERVICEIP_RANGE}@172.16.0.0/17@" $dest/supervisord.conf
	fi
}

# $1: iterm name
collect_iterm(){
	local iterm=$1
	local dest=${OUTPUT_DIR}/${iterm}

	local dir_bin=$dest/bin
	local dir_data=$dest/data
	local dir_log=$dest/log
	func_fatal_cmd func_create_dirs $dir_bin $dir_data $dir_log

	local dir_ca_etcd=$dest/cert/ca/etcd
	local dir_ca_client=$dest/cert/ca/client
	local dir_ca_kubelet=$dest/cert/ca/kubelet
	local dir_cert_etcd=$dest/cert/etcd
	local dir_cert_apiserver=$dest/cert/apiserver
	local dir_cert_kubelet=$dest/cert/kubelet
	local dir_key_service_account=$dest/cert/service_account
	func_fatal_cmd func_create_dirs $dir_ca_etcd $dir_ca_client $dir_ca_kubelet $dir_cert_etcd $dir_cert_apiserver $dir_cert_kubelet $dir_key_service_account

	local build_kube=../../build-kubernetes
	local bin_kube_apiserver=${build_kube}/kubernetes/_output/dockerized/bin/linux/amd64/kube-apiserver
	func_fatal_cmd func_force_copy $dir_bin $bin_kube_apiserver

	local build_certs=../../build-certs
	local ca_etcd=${build_certs}/etcd-server/ca/ca.pem
	local ca_kubelet=${build_certs}/kubelet/ca/ca.pem
	local ca_client=${build_certs}/apiserver-client/ca/ca.pem
	local cert_etcd=${build_certs}/etcd-client/output/$iterm/cert.pem
	local key_etcd=${build_certs}/etcd-client/output/$iterm/key.pem
	local cert_apiserver=${build_certs}/apiserver/output/$iterm/cert.pem
	local key_apiserver=${build_certs}/apiserver/output/$iterm/key.pem
	local cert_kubelet=${build_certs}/kubelet-client/output/$iterm/cert.pem
	local key_kubelet=${build_certs}/kubelet-client/output/$iterm/key.pem
	local key_service_account=${build_certs}/serviceAccount/ca/ca.pem

	func_fatal_cmd func_force_copy $dir_ca_etcd $ca_etcd
	func_fatal_cmd func_force_copy $dir_cert_etcd $cert_etcd $key_etcd
	func_fatal_cmd func_force_copy $dir_cert_apiserver $cert_apiserver $key_apiserver
	func_fatal_cmd func_force_copy $dir_ca_kubelet $ca_kubelet
	func_fatal_cmd func_force_copy $dir_cert_kubelet $cert_kubelet $key_kubelet
	func_fatal_cmd func_force_copy $dir_ca_client $ca_client
	func_fatal_cmd func_force_copy $dir_key_service_account $key_service_account

	gen_supervisord_conf $dest $TEMPLATE $iterm

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
