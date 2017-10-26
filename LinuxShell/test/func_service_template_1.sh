#!/bin/bash

. ../library.sh


declare -A Configs

TARGET=./loop.sh
Logs=./
Configs[-a]="-a aaa"
Configs[-b]="-b bbb"
Configs[-c]="-c ccc"

func_service_template_1 $TARGET $Logs Configs $1
