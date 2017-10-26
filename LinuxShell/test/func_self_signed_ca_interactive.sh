#!/bin/bash
. ../library.sh
CMD=`basename $0 .sh`
$CMD /tmp/b/key.pem /tmp/a/ca.pem 356
