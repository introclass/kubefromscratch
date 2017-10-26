#!/bin/bash

. ../library.sh

x=("add" "ddd" "ddd" "ee")

func_in_array "add"  x
echo $?

func_in_array "addddd" x
echo $?
