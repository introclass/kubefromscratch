---
layout: default
title: CHANGELOG
author: lijiaocn
createdate: 2017/11/23 10:16:10
changedate: 2017/11/23 10:17:27

---

* auto-gen TOC:
{:toc}

## first release： v1.8.0 

| name      | boot sequence | supervisord addr |   need by   |   version   |
|-----------|---------------|------------------|-------------|-------------|
|etcd       |       1       | 127.0.0.1:9001   |   master    |   v3.2.7    |
|apiserver  |       2       | 127.0.0.1:9002   |   master    |   v1.8.0    |
|controller-manager| 3      | 127.0.0.1:9003   |   master    |   v1.8.0    |
|scheduler  |       3       | 127.0.0.1:9004   |   master    |   v1.8.0    |
|coredns    |       4       | 127.0.0.1:9005   |   node      |   v0.9.9    |
|kubectl    |       no      | don't need       |   user      |   v1.8.0    |
|docker     |       4       | not use          |   node      |   17.03.2   |
|kubelet    |       5       | 127.0.0.1:9006   |   node      |   v1.8.0    |
|kube-router |      6       | 127.0.0.1:9007   |   node      |   v0.0.17   |
