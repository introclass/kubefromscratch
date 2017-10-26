#!/bin/bash

WORKPATH=`pwd`
source ${WORKPATH}/../../LinuxShell/library.sh

CADIR=${WORKPATH}/ca
CA=${CADIR}/ca.pem
CAKEY=${CADIR}/ca-key.pem

OUTPUT=${WORKPATH}/output

#$1: output dir
#$2: ca key file
#$3: ca file
gen_ca(){
	local OUTPUT=$1
	local CAKEY=$2
	local CA=$3

	func_self_signed_ca_interactive ${CAKEY} ${CA} 365
	func_green_str "ca is OK."
	func_green_str "key file: ${CAKEY}"
	func_green_str "ca  file: ${CA}"
}

if [[ ! -e ${CA} || ! -e ${CAKEY} ]];then
	func_red_str "$CA or $CAKEY doesn't exist, generate a new ca?[Y|N]: "
	read GENCA
	case $GENCA in
		(Y) gen_ca $OUTPUT $CAKEY $CA;;
		(N) exit;;
		(*) func_red_str "Your select is wrong!"; exit;;
	esac
fi
