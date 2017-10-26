---
layout: default
title: 在墙内编译kubernetes
author: lijiaocn
createdate: 2017/09/29 15:15:54
changedate: 2017/09/29 15:59:40

---

## 说明

大概对于国外的筒子们来说，从互联网上获取数据就跟拧开自来水一样自然。
因此他们并不觉得在`gcr.io`、`quay.io`等站点上发布容器镜像会有什么不妥。
这样子，可就苦了墙内的同学们了。

另外，编译、构建过程中，还需要联网获取数据，也是一件很奇葩的事情。

我总觉得，C语言时代时的做法才是正确的：

	下载代码包
	准备好编译工具和编译器
	make

一个项目当然应该包含了所有的文件，并且在断网情况下能够完成构建。
构建的时候需要联网下载这个、下载那个，是奇葩的、且怀有`深深的恶意`的做法。

`build-kubernetes`，只要能够访问github和docker.io，就可以从零完成kubernetes的构建。幸好github的国内用户足够多，docker.io的国内的镜像源也很多。

不打算去掉对docker.io的依赖，自行制作base镜像，感觉产出/投入有点低。

## tag说明

tag命名格式:

	<kubernetes的版本>-<针对该kubernetes版本的build-kubernetes版本>

例如，`v1.8.0-v2`的意思是，针对kubernetes的v1.8.0发布的第二个版本。

## v1.8.0-v1

first.
