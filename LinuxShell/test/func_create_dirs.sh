#/bin/bash

. ../library.sh

func_create_dirs "A/a/1 A/a/2  B/b/1"
tree A
tree B
rm -rf A B
