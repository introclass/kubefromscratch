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
gen_supervisord_conf(){
	local dest=$1
	local template=$2
	local name=$3

	local init_clusters
	for i in `ls $ITERMS_DIR`;do
		init_clusters="$init_clusters,$i=https://$i:2380"
	done
	init_clusters=`echo $init_clusters | sed -e "s/,//"`

	sed -e "s/{NAME}/${name}/g" $template >$dest/supervisord.conf
	if [[ "$OSTYPE" == "darwin"* ]];then
		sed -i "" -e "s@{INIT_CLUSTERS}@${init_clusters}@" $dest/supervisord.conf
		sed -i "" -e "s@{BINDIP}@0.0.0.0@" $dest/supervisord.conf
	else
		sed -i"" -e "s@{INIT_CLUSTERS}@${init_clusters}@" $dest/supervisord.conf
		sed -i"" -e "s@{BINDIP}@0.0.0.0@" $dest/supervisord.conf
	fi
}

# $1: iterm name
collect_iterm(){
	local iterm=$1
	local dest=${OUTPUT_DIR}/${iterm}

	local dir_bin=$dest/bin
	local dir_data=$dest/data
	local dir_backup=$dest/backup
	local dir_log=$dest/log
	func_fatal_cmd func_create_dirs $dir_bin $dir_data $dir_backup $dir_log

	local dir_ca_client=$dest/cert/ca/client
	local dir_ca_peer=$dest/cert/ca/peer
	local dir_ca_server=$dest/cert/ca/server
	local dir_cert_server=$dest/cert/server
	local dir_cert_peer=$dest/cert/peer
	local dir_cert_client=$dest/cert/client
	func_fatal_cmd func_create_dirs $dir_ca_client $dir_ca_peer $dir_ca_server $dir_cert_server $dir_cert_peer $dir_cert_client

	local build_etcd=../../build-etcd/
	local bin_etcd=${build_etcd}/etcd/bin/etcd
	local bin_etcdctl=${build_etcd}/etcd/bin/etcdctl
	func_fatal_cmd func_force_copy $dir_bin $bin_etcd $bin_etcdctl

	local build_certs=../../build-certs
	local ca_client=${build_certs}/etcd-client/ca/ca.pem
	local ca_peer=${build_certs}/etcd-peer/ca/ca.pem
	local ca_server=${build_certs}/etcd-server/ca/ca.pem
	local server_cert=${build_certs}/etcd-server/output/$iterm/cert.pem
	local server_key=${build_certs}/etcd-server/output/$iterm/key.pem
	local peer_cert=${build_certs}/etcd-peer/output/$iterm/cert.pem
	local peer_key=${build_certs}/etcd-peer/output/$iterm/key.pem
	local client_cert=${build_certs}/etcd-client/output/$iterm/cert.pem
	local client_key=${build_certs}/etcd-client/output/$iterm/key.pem

	func_fatal_cmd func_force_copy $dir_ca_client $ca_client
	func_fatal_cmd func_force_copy $dir_ca_peer $ca_peer
	func_fatal_cmd func_force_copy $dir_ca_server $ca_server
	func_fatal_cmd func_force_copy $dir_cert_server $server_cert $server_key
	func_fatal_cmd func_force_copy $dir_cert_peer $peer_cert $peer_key
	func_fatal_cmd func_force_copy $dir_cert_client $client_cert $client_key

	gen_supervisord_conf $dest $TEMPLATE $iterm

	local dir_scripts=./scripts
	local script_start=${dir_scripts}/start.sh
	local script_stop=${dir_scripts}/stop.sh
	local script_etcdctl2=${dir_scripts}/etcdctl2.sh
	local script_etcdctl3=${dir_scripts}/etcdctl3.sh
	func_fatal_cmd func_force_copy $dest $script_start $script_stop $script_etcdctl2 $script_etcdctl3

	pushd ${OUTPUT_DIR}; tar -czvf ${iterm}.tar.gz ${iterm}; popd
	rm -rf ${OUTPUT_DIR}/${iterm}
	func_green_str "${iterm} is ok"
	func_green_str "output to: ${OUTPUT_DIR}/${iterm}"
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
