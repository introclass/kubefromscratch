#!/bin/bash

. ../library.sh

#func_secret_input_on
#read VAR
#func_secret_input_off
#echo $VAR

PASSWORD=""

func_secret_input PASSWORD "PASSWORD:"
echo $PASSWORD
