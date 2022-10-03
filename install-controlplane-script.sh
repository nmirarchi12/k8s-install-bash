#!/bin/bash

sudo modprobe overlay
sudo modprobe br_netfilter
 
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
 
# Reload sysctl
sudo sysctl --system

# Configure persistent loading of modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
 
# Load at runtime
sudo modprobe overlay
sudo modprobe br_netfilter
 
# Ensure sysctl params are set
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
 
# Reload configs
sudo sysctl --system
 
# Install required packages
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
 
# Add Docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
 
# Install containerd
sudo apt update
sudo apt install -y containerd.io
 
# Configure containerd and start service
sudo su -
mkdir -p /etc/containerd
containerd config default>/etc/containerd/config.toml
 
# restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
systemctl status  containerd

sudo systemctl enable kubelet

sudo kubeadm config images pull


sudo kubeadm init \
  --apiserver-advertise-address=192.168.56.2 \
  --apiserver-cert-extra-sans=192.168.56.2 \
  --node-name=$(hostname -s) \
  --pod-network-cidr=192.168.0.0/16 \
  --upload-certs \
  --cri-socket /var/run/containerd/containerd.sock
  
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
