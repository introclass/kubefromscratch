---
layout: default
title: README
author: lijiaocn
createdate: 2017/10/16 15:10:14
changedate: 2017/11/23 10:14:06

---

## 背景

如果这还可以算作一个项目的话，那么这个项目的前身是很久之前的[HoneyComb][1]。

## 为什么这么原始？

这里的做法很原始。

这个项目没有打算发展成一个产品，它面向的是像我一样的开发人员：

	需要能够在改动了代码之后，很快捷的完成编译部署
	需要能够很方便的调整每一个组件的参数
	能够很方便查看它们的日志

更期待它能够成为[linuxfromscratch][2]一样的存在。

## 有哪些好处？

第一，不用翻墙。

第二，简单，所见即所得。

## 几个原则 

原则1：部署就是把文件拷贝到目标环境中，不需要调整参数。

原则2：在一个目录下就可以`看到且只看到`一个组件的所有内容。

原则3：组件尽量不打包到容器中，除非有非常明显的好处。

一个组件的每一份部署，都生成了一个对应的压缩文件，这个文件不仅包括了这个组件的二进制文件，还包括
它在目标环境上运行时需要的配置，所以部署时只需要将文件拷贝到目标环境中，不需要调整配置。

不将组件打包到容器中，是因为容器中的环境、工具有时候太简陋了，远不如在宿主机上操作起来方便。

## 看一个组件部署

以kubernetes的apiserver为例，假设要在一台名为apiserver1.local的机器上部署apiserver，
当你按照后面章节中的内容完成操作之后，会在output目录下生成一个名为`apiserver1.local.tar.gz`
的文件。

你只需要将这个文件复制到apiserver1.local的任意一个目录下，并解压:

	▾ apiserver1.local/
	  ▸ bin/               <-- 存放apiserver的二进制文件
	  ▸ cert/              <-- 存放用到的证书
	  ▸ data/              <-- 如果有数据生成，存放到这里
	  ▸ log/               <-- 运行时产生的日志
	    start.sh*          
	    stop.sh*
	    supervisord.conf

如果目标环境没有安装有supervisord，需要先安装supervisord。

执行`./start.sh`即完成了apiserver的启动。

如果你要查看apiserver的日志，只需要查看log目录中文件，这里只有apiserver的日志，你不会陷入到一堆目录中。

## 组件清单

kubernetes集群的master：

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

## 部署etcd

部署一个3 node的etcd集群，3个node地址是：etcd1.local，etcd2.local, etcd3.local

在目标机器的/etc/hosts中添加：

	192.168.40.10  etcd1.local
	192.168.40.11  etcd2.local
	192.168.40.12  etcd3.local

编译etcd:

	cd build-etcd; ./build.sh

生成etcd的client证书:

	cd build-certs/etcd-client
	mkdir -p iterms/{etcd1.local,etcd2.local,etcd3.local}
	./gen.sh

生成etcd的peer证书:

	cd build-certs/etcd-peer
	mkdir -p iterms/{etcd1.local,etcd2.local,etcd3.local}
	./gen.sh

生成etcd的server证书:

	cd build-certs/etcd-server
	mkdir -p iterms/{etcd1.local,etcd2.local,etcd3.local}
	./gen.sh

生成部署文件:

	cd collect/etcd
	mkdir -p iterms/{etcd1.local,etcd2.local,etcd3.local}
	./collect.sh

将collect/etcd/output目录中的文件复制到对应的node上。

## 部署kubernetes

部署一个3master的kubernetes cluster。

在node的/etc/hosts中添加:

	192.168.40.10  apiserver1.local
	192.168.40.11  apiserver2.local
	192.168.40.12  apiserver3.local

编译kubernetes：

	cd build-kubernetes
	./build.sh

生成apiserver使用的证书:

	cd build-certs/apiserver
	mkdir -p iterms/{apiserver1.local,apiserver2.local,apiserver3.local}
	./gen.sh

生成访问etcd的client证书:

	cd build-certs/etcd-client
	mkdir -p iterms/{apiserver1.local,apiserver2.local,apiserver3.local}
	./gen.sh

生成serviceAccount的证书:

	cd build-certs/serviceAccount
	./gen.sh

生成访问kubelet使用的证书:

	cd build-certs/kubelet-client/
	mkdir -p iterms/{apiserver1.local,apiserver2.local,apiserver3.local}
	./gen.sh

生成kubelet的ca证书:

	cd build-certs/kubelet/
	./gen.sh     //生成ca即可退出

生成访问apiserver的client证书:

	cd build-certs/apiserver-client
	
	mkdir -p iterms/{controller-manager1.local,controller-manager2.local,controller-manager3.local}
	echo "system:kube-controller-manager" >iterms/controller-manager1.local/COMMONNAME
	echo "system:kube-controller-manager" >iterms/controller-manager2.local/COMMONNAME
	echo "system:kube-controller-manager" >iterms/controller-manager3.local/COMMONNAME
	
	mkdir -p iterms/{scheduler1.local,scheduler2.local,scheduler3.local}
	echo "system:kube-scheduler" >iterms/scheduler1.local/COMMONNAME
	echo "system:kube-scheduler" >iterms/scheduler2.local/COMMONNAME
	echo "system:kube-scheduler" >iterms/scheduler3.local/COMMONNAME
	
	./gen.sh

生成apiserver的部署文件:

	cd collect/apiserver
	mkdir -p iterms/{apiserver1.local,apiserver2.local,apiserver3.local}
	./collect.sh

生成controller-manager的部署文件:

	cd collect/controller-manager
	mkdir -p iterms/{controller-manager1.local,controller-manager2.local,controller-manager3.local}
	./collect.sh

生成scheduler的部署文件:

	cd collect/scheduler
	mkdir -p iterms/{scheduler1.local,scheduler2.local,scheduler3.local}
	./collect.sh

## 创建集群管理员

创建集群管理员的证书：

	cd build-certs/apiserver-client
	
	mkdir -p iterms/{admin.cluster,}
	echo "system:masters"  >iterms/admin.cluster/ORGNIZATION
	./gen.sh

生成kubectl的部署文件(for admin.cluster):

	cd collect/kubectl
	mkdir -p iterms/{admin.cluster,}
	./collect.sh

## 部署coredns

三个coredns部署在:

	192.168.40.10  coredns1.local
	192.168.40.11  coredns2.local
	192.168.40.12  coredns3.local

编译coredns:

	cd build-coredns; ./build.sh

生成访问apiserver的client证书:

	cd build-certs/apiserver-client
	mkdir -p iterms/{coredns1.local,coredns2.local,coredns3.local}
	./gen.sh

生成coredns的部署文件

	cd collect/coredns;
	mkdir -p iterms/{coredns1.local,coredns2.local,coredns3.local}
	./collect.sh

在kubernetes中使用coredns时，需要创建、绑定角色(可以用前面创建的admin.cluster用户操作):

	./kubectl.sh create clusterrole coredns --verb=list,watch --resource=endpoints,services,pods,namespaces 
	./kubectl.sh create clusterrolebinding coredns --clusterrole=coredns --user=coredns3.local --user=coredns1.local --user=coredns2.local

## 添加node

添加3个node，在/etc/hosts中添加:

	192.168.40.10  kubelet1.local
	192.168.40.11  kubelet2.local
	192.168.40.12  kubelet3.local

如果要在node上通过域名访问集群内的服务，将node的/etc/resolve.conf修改为

	nameserver 192.168.40.10
	nameserver 192.168.40.11
	nameserver 192.168.40.12
	search default.svc.cluster.local svc.cluster.local cluster.local 
	options ndots:5

生成docker的部署文件（只适用于centos7以及以上版本）:

	cd collect/docker
	mkdir -p iterms/{docker1.local,docker2.local,docker3.local}
	./collect.sh

编译cni插件:

	cd build-cni/
	./build.sh
	
	cd build-cni-plugins/
	./build.sh

生成kubelet使用的证书:

	cd build-certs/kubelet-client
	mkdir -p iterms/{kubelet1.local,kubelet2.local,kubelet3.local}
	./gen.sh

生成用来访问apiserver的证书:

	cd build-certs/apiserver-client
	mkdir -p iterms/{kubelet1.local,kubelet2.local,kubelet3.local}
	./gen.sh

生成kubelet的部署文件:

	cd collect/kubelet/
	mkdir -p iterms/{kubelet1.local,kubelet2.local,kubelet3.local}
	
	echo "192.168.40.10" >iterms/kubelet1.local/NODEIP
	echo "192.168.40.11" >iterms/kubelet2.local/NODEIP
	echo "192.168.40.12" >iterms/kubelet3.local/NODEIP
	
	echo "192.168.40.10" >iterms/kubelet1.local/BINDIP
	echo "192.168.40.11" >iterms/kubelet2.local/BINDIP
	echo "192.168.40.12" >iterms/kubelet3.local/BINDIP

	echo "192.168.40.10,192.168.40.11,192.168.40.12" >iterms/kubelet1.local/DNSSERVER
	echo "192.168.40.10,192.168.40.11,192.168.40.12" >iterms/kubelet2.local/DNSSERVER
	echo "192.168.40.10,192.168.40.11,192.168.40.12" >iterms/kubelet3.local/DNSSERVER
	
	./collect.sh

添加了node之后，需要编辑clusterrolebindings，`./kubectl.sh edit clusterrolebindings system:node`:

	subjects:
	- apiGroup: rbac.authorization.k8s.io
	  kind: User
	    name: kubelet1.local 
	- apiGroup: rbac.authorization.k8s.io
	  kind: User
	    name: kubelet2.local 
	- apiGroup: rbac.authorization.k8s.io
	  kind: User
	    name: kubelet3.local 

## 安装kube-router

在每个node上安装kube-router。

编译kube-router:

	cd build-kube-router/
	./build.sh

生成kube-router访问apiserver的client证书:

	cd build-certs/apiserver-client/
	mkdir -p iterms/{kube-router1.local,kube-router2.local,kube-router3.local}
	./gen.sh

生成kube-router的部署文件:

	cd collect/kube-router/
	mkdir -p iterms/{kube-router1.local,kube-router2.local,kube-router3.local}
	echo "kubelet1.local"  >iterms/kube-router1.local/HOSTNAME
	echo "kubelet2.local"  >iterms/kube-router2.local/HOSTNAME
	echo "kubelet3.local"  >iterms/kube-router3.local/HOSTNAME
	./collect.sh

安装kube-router依赖的软件:

	yum install -y ipset iptables iproute2 ipvsadm

在kubernetes集群中创建ClusterRole，`kuber-router`:

	$ cat collect/kube-router/yaml/ClusterRole.kube-router.yaml
	kind: ClusterRole
	apiVersion: rbac.authorization.k8s.io/v1beta1
	metadata:
	  name: kube-router
	  namespace: kube-system
	rules:
	  - apiGroups:
	    - ""
	    resources:
	      - namespaces
	      - pods
	      - services
	      - nodes
	      - endpoints
	    verbs:
	      - list
	      - get
	      - watch
	  - apiGroups:
	    - "networking.k8s.io"
	    resources:
	      - networkpolicies
	    verbs:
	      - list
	      - get
	      - watch
	  - apiGroups:
	    - extensions
	    resources:
	      - networkpolicies
	    verbs:
	      - get
	      - list
	      - watch

将用户kube-router1.local绑定到ClusterRole:

	./kubectl.sh create clusterrolebinding kube-router --clusterrole=kube-router --user=kube-router1.local

然后编辑、添加其它kube-router用户，“./kubectl.sh edit clusterrolebinding kube-router”:

	subjects:
	- apiGroup: rbac.authorization.k8s.io
	  kind: User
	  name: kube-router1.local
	- apiGroup: rbac.authorization.k8s.io
	  kind: User
	  name: kube-router2.local
	- apiGroup: rbac.authorization.k8s.io
	  kind: User
	  name: kube-router3.local

## 参考

1. [HoneyComb][1]
2. [linuxfromscratch][2]

[1]: https://github.com/lijiaocn/honeycomb "HoneyComb"
[2]: http://www.linuxfromscratch.org/ "linuxfromscratch"
