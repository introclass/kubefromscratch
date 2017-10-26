#!/bin/bash
. ../library.sh

declare -a array
arrary[0]="hello"
#arrary[1]="world"
#arrary[2]="1"
#arrary[3]="2"


a=`func_join_array  "," "" arrary ""`
echo $a

a=`func_join_array  "," "http://" arrary ""`
echo $a

a=`func_join_array  "," "" arrary ":4001"`
echo $a

a=`func_join_array  "," "http://" arrary ":4001"`
echo $a

