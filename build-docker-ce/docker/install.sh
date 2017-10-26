#!/bin/bash
wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch.rpm
wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-17.03.2.ce-1.el7.centos.x86_64.rpm
yum localinstall -y docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch.rpm  docker-ce-17.03.2.ce-1.el7.centos.x86_64.rpm 
