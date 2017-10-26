---
layout: default
title: 构建docker-ce
author: lijiaocn
createdate: 2017/09/29 16:45:17
changedate: 2017/10/18 15:22:24

---

* auto-gen TOC:
{:toc}

## 说明

[Moby、docker-ce与docker-ee][1]中解释了moby、docker-ce、docker-ee的关系。

docker已经是一个标准产品了，并且有了很清晰的发布计划，还有必要自己构建吗？

很多人都会使用mysql，但没有多少人会去构建它。

暂时先使用docker公司发布的安装包，以后或许会自己修改docker的源码？

## 下载安装包

[https://download.docker.com/][2]中提供了linux、mac和win三个平台上的安装包。

需要解释一下里面的edge与stable目录的区别：

	edge:   月版本，每月发布一次，命名格式为YY.MM，维护到下个月的版本发布
	stable: 季度版本，每季度发布一次，命名格式为YY.MM，维护4个月

以centos为例：

	# wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-17.03.2.ce-1.el7.centos.x86_64.rpm
	# yum localinstall docker-ce-17.03.2.ce-1.el7.centos.x86_64.rpm 

## 参考

1. [Moby、docker-ce与docker-ee][1]
2. [docker download][2]

[1]: http://www.lijiaocn.com/%E9%A1%B9%E7%9B%AE/2017/07/18/docker-commnuity.html  "Moby、docker-ce与docker-ee" 
[2]: https://download.docker.com/  "docker download"
