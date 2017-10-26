#!/bin/bash
ETCDCTL_API=2 ./bin/etcdctl --ca-file=./cert/ca/server/ca.pem --key-file=./cert/client/key.pem --cert-file=./cert/client/cert.pem $*
