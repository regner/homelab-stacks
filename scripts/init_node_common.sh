#!/bin/bash
#
# Setup common things accross both Docker Swarm manager and
# worker nodes such as NFS mounts and packages. This could
# be done with Ansible or something, but this is simple home
# lab, not production.
#
# Note:
# This script is for my needs and makes many assumptions
# such as the OS being CentOS 7.

# TODO: Add docker version here
DOCKER_PACKAGE="docker-ce-19.03.1-3.el7"
NFS_SERVER="<ip of manager node>"
USERNAME="dockerdata"

echo "Installing base packages..."
yum install -y \
  device-mapper-persistent-data \
  epel-release \
  git \
  htop \
  jq \
  lsof \
  lvm2 \
  nfs-utils \
  unzip \
  vim \
  yum-utils

echo "Adding Docker repo..."
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "Installing Docker package..."
yum install "${DOCKER_PACKAGE}"

echo "Enabling and Starting the docker service..."
systemctl enable docker.service
systemctl start docker.service

echo "Creating NFS mount directories..."
mkdir -p /data/app_data
mkdir -p /data/video

echo "Mounting NFS shares..."
mount "${NFS_SERVER}":/volume1/video /data/video
mount "${NFS_SERVER}":/volume1/app_data /data/app_data

echo "Adding NFS share to fstab..."
"${NFS_SERVER}":/volume1/video /data/video nfs rw,sync,hard,intr 0 0
"${NFS_SERVER}":/volume1/app_data /data/app_data nfs rw,sync,hard,intr 0 0

echo "Checking if group exists..."
if grep -q -E "^${USERNAME}:" /etc/group; then
  echo "${USERNAME} group already exists, moving on..."
else
  echo "${USERNAME} group does not exist, creating..."
  groupadd -g 1000 ${USERNAME}
fi

echo "Checking if user exists..."
if grep -q -E "^${USERNAME}:" /etc/passwd; then
  echo "${USERNAME} user already exists, moving on..."
else
  echo "${USERNAME} user does not exist, creating..."
  useradd -u 1000 -g ${USERNAME} ${USERNAME}
fi
