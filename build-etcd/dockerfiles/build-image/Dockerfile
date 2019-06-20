FROM golang:1.12.6

RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/' /etc/apt/sources.list
RUN apt-get update 
RUN apt-get install rsync -y 
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV HOME /go/src/github.com/coreos/etcd
RUN mkdir -p $HOME

ADD rsyncd.password /
RUN chmod a+r /rsyncd.password

ADD rsyncd.sh /
RUN chmod a+rx /rsyncd.sh
