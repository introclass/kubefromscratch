#!/bin/bash
source ../library.sh

CMD=`basename $0 .sh`
$CMD /tmp/req.config  no 2048 /tmp/keyfile hello@mail.com www.domain.com IP:192.168.1.1
