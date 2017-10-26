#!/bin/bash
ETCDCTL_API=3 ./bin/etcdctl --cacert=./cert/ca/server/ca.pem --key=./cert/client/key.pem --cert=./cert/client/cert.pem $*
