#!/bin/bash
WORKPATH=`pwd`

if [ ! -h ./gen.sh ];then
	echo "You can't run ./gen.sh at here, you must run gen.sh's symbol link at subdirs"
	exit 1
fi

source ${WORKPATH}/../../LinuxShell/library.sh

CADIR=${WORKPATH}/ca
CA=${CADIR}/ca.pem
CAKEY=${CADIR}/ca-key.pem

OUTPUT=${WORKPATH}/output

TEMPLATES_DIR=./TEMPLATE
TEMPLATE=

ITERMS_DIR=./iterms
ITERM=

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

#$1: template file
#$2: common name
#$3: dest dir
gen_req_config(){
	local template=$1
	local name=$2
	local DESTDIR=$3
	
	if [ ! -e $ITERM/COMMONNAME ];then
		sed -e "s/{COMMONNAME}/${name}/" $template >${DESTDIR}/req.config
	else
		cp $template ${DESTDIR}/req.config
	fi
	
	if [[ "$OSTYPE" == "darwin"* ]];then
		sed -i "" -e "s@{DESTDIR}@${DESTDIR}@" ${DESTDIR}/req.config
		if [ ! -e $ITERM/ORGNIZATION ];then
			sed -i "" -e "s@{ORGNIZATION}@kubefromscratch.org@" ${DESTDIR}/req.config
		fi
	else
		sed -i"" -e "s@{DESTDIR}@${DESTDIR}@" ${DESTDIR}/req.config
		if [ ! -e $ITERM/ORGNIZATION ];then
			sed -i"" -e "s@{ORGNIZATION}@kubefromscratch.org@" ${DESTDIR}/req.config
		fi
	fi
	
	for i in `ls $ITERM`;do
		if [[ "$OSTYPE" == "darwin"* ]];then
			sed -i "" -e "s@{$i}@`cat $ITERM/$i`@" ${DESTDIR}/req.config
		else
			sed -i"" -e "s@{$i}@`cat $ITERM/$i`@" ${DESTDIR}/req.config
		fi
	done
}

#$1: OUTPUT
#$2: iterm
#$3: CA
#$4: CAKEY
gen_iterm_cert(){
	local CUR=`pwd`
	local OUTPUT=$1
	local ITERM=$2
	local CA=$3
	local CAKEY=$4

	local DESTDIR=${OUTPUT}/`basename ${ITERM}`
	func_fatal_cmd func_create_dirs ${DESTDIR}

	gen_req_config ${TEMPLATE} `basename ${ITERM}` ${DESTDIR}
	openssl req  -new  -nodes -out ${DESTDIR}/ca.csr -config ${DESTDIR}/req.config
	openssl x509 -req -days 365 -in ${DESTDIR}/ca.csr -CA $CA -CAkey $CAKEY -CAcreateserial -out ${DESTDIR}/cert.pem  -extfile ${DESTDIR}/req.config -extensions v3_ca
	if [[ $? != 0 ]];then
		func_red_str "something is wrong."
		exit
	fi

	func_green_str "`basename ${ITERM}` is OK."
	func_green_str "output to: ${DESTDIR}"
}

gen_all(){
	for iterm in `ls ${ITERMS_DIR}`
	do
		ITERM=${ITERMS_DIR}/${iterm}
		func_yellow_str "Generate cert for ${ITERM}"
		gen_iterm_cert ${OUTPUT} ${ITERM} ${CA} ${CAKEY}
	done
}

gen_one(){
	func_yellow_str "`ls ${ITERMS_DIR}`"
	echo -n "Select the iterm: "
	read ITERM

	ITERM=${ITERMS_DIR}/${ITERM}

	if [ ! -d  ${ITERM} ];then
		func_red_str "Not found directory ${ITERM} in ${ITERMS_DIR}"
		exit
	fi

	gen_iterm_cert ${OUTPUT} ${ITERM} ${CA} ${CAKEY}
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

if [[ ! -e ${CA} || ! -e ${CAKEY} ]];then
	func_red_str "$CA or $CAKEY doesn't exist, generate a new ca?[Y|N]: "
	read GENCA
	case $GENCA in
		(Y) gen_ca $OUTPUT $CAKEY $CA;;
		(N) exit;;
		(*) func_red_str "Your select is wrong!"; exit;;
	esac
fi

echo -n "Generate certs for all iterms?[Y|N]: "
read GENALL
select_template   # will set var `TEMPLATE`
case $GENALL in
	(Y)gen_all;;
	(N)gen_one;;
	(*)func_red_str "Your select is wrong!"; exit;;
esac
