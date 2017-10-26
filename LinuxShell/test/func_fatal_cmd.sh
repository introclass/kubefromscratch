#!/bin/bash

. ../library.sh

func_fatal_cmd "ls -l"
#func_fatal_cmd "xxx e"
#func_fatal_cmd "ls -l"
func_fatal_cmd func_force_copy /tmp ./a.sh
