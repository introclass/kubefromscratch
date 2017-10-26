FROM golang:1.8.3-alpine

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/' /etc/apk/repositories
RUN apk update && apk upgrade
RUN apk add --no-cache tzdata  \
	&& apk add --no-cache rsync \
	&& apk add --no-cache git \
	&& apk add --no-cache bash \
	&& apk add --no-cache make \
	&& apk add --no-cache grep \
	&& apk add --no-cache findutils \
	&& apk add --no-cache gcc \
	&& apk add --no-cache libc-dev \
	&& apk add --no-cache linux-headers \
	&& apk add --no-cache coreutils

RUN rm /bin/grep && ln -s /usr/bin/grep /bin/grep
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV HOME /go/src/github.com/lijiaocn
RUN mkdir -p $HOME

ADD rsyncd.password /
RUN chmod a+r /rsyncd.password

ADD rsyncd.sh /
RUN chmod a+rx /rsyncd.sh

RUN chmod a+rx /rsyncd.sh
