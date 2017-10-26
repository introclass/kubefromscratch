FROM golang:1.8.3-jessie

RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/' /etc/apt/sources.list
RUN apt-get update 
RUN apt-get install rsync -y 
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
