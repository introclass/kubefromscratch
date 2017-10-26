---
layout: default
title: README
author: lijiaocn
createdate: 2017/10/16 13:36:50
changedate: 2017/10/16 13:45:29

---

## 使用说明

进入编译环境:

	./build.sh  bash

在容器中编译:

	./build.sh build

将在容器中编译得到的文件复制出来：

	./build.sh copy

执行需要在宿主机进行的操作:

	./build.sh host

打包名为${PROJECT_NAME}:${PROJECT_VERSION}的镜像:

	./build.sh release

清理编译环境:

	./build.sh reset

如果不指定任何参数，直接运行`./build.sh`，相当于:

	./build.sh build
	./build.sh copy
	./build.sh host
	./build.sh release
