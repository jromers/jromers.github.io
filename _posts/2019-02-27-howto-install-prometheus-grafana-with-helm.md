---
title: "How-to: Install Prometheus &amp; Grafana with Helm for on-premise Oracle Linux and Kubernetes deployments"
date: 2019-02-27
---


In this How-to guide I’ll describe the configuration steps to setup Prometheus and Grafana on an Oracle Linux on-premise Kubernetes cluster. 

I use this configuration in Kubernetes demos, workshops or even in small proof of concept installations where you want to have a quick installation experience. But do not hesitate to use this How-to guide for bare-metal or other virtual deployments.

## Prerequisites

I run this deployment on a laptop using Vagrant and VirtualBox. I follow the standard installation as published on the Oracle Community website: [Use Vagrant and VirtualBox to setup Oracle Container Services for use with Kubernetes](https://community.oracle.com/docs/DOC-1022800). Here's my Kubernetes cluster:
```
# kubectl get nodes
NAME                 STATUS   ROLES    AGE   VERSION
master.vagrant.vm    Ready    master   43h   v1.12.5+2.1.1.el7
worker1.vagrant.vm   Ready    <none>   43h   v1.12.5+2.1.1.el7
worker2.vagrant.vm   Ready    <none>   43h   v1.12.5+2.1.1.el7
```

The Prometheus Operator uses by default non-persistent storage which means that when the pod restarts, the historical monitoring data is lost. This is OK for a quick demo, but for a workshop, PoC or production deployment you like to have persistent volumes. In this guide I use an example with a NFS share based on the configuration that is explained in my [NFS Client Provisioner How-to guide](https://jromers.github.io/article/2019/02/howto-install-nfs-client-provisioner/).

In this Howto-guide we use the Kubernetes Helm package-manager, please make sure to follow Oracle Linux Helm installation steps as described in this [Helm Howto-guide](https://jromers.github.io/article/2019/03/howto-install-helm-package-manager/).

## Install Prometheus and Grafana

Prometheus is used to monitor Oracle Linux nodes in the cluster, the health and status of the Kubernetes resources and it dynamically adds installed resources to the monitoring system. Grafana is the graphical interface with several dashboards to visualize the collected Prometheus metrics.

First, start with adding the repo with the Prometheus Operator charts:
```
# helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
```

The Helm chart installs out-of-the-box, but I use a yaml file with customized settings. Change the default password in the yaml file to your own, preferred admin password and install Prometheus and Grafana, based on the fully autoconfigured Prometheus Operator. It's a nice exercise to further explore what you can add to the values.yaml file to customize your deployment. For the non-persistent storage volumes deployment use the following commands:
```
# wget https://raw.githubusercontent.com/jromers/k8s-ol-howto/master/prometheus-nfs/values-prometheus.yaml
# vi values-prometheus.yaml
  change default password
# helm install --namespace monitoring --name prometheus-operator coreos/prometheus-operator
# helm install coreos/kube-prometheus --name kube-prometheus --namespace monitoring \
    --set deployKubeDNS=false --set deployCoreDNS=true \
    --values values-prometheus.yaml
```
Since [version 1.1.12 of Oracle Container Services for use with Kubernetes](https://blogs.oracle.com/linux/announcing-oracle-container-services-1112-for-use-with-kubernetes) CoreDNS is the default cluster DNS service, in the configuration of prometheus we need to change from the default KubeDNS to CoreDNS as monitoring target.

For the persistent storage volumes with the NFS Client Provisioner I use a yaml file with customized settings. Like before, change the admin password. By default the StorageClass is *nfs-client* (if you use the NFS Client Provisioner) but for your deployment this may be different. Also the amount of claimed space is something you might want to change (8Gi in my deployment):
```
# wget https://raw.githubusercontent.com/jromers/k8s-ol-howto/master/prometheus-nfs/values-nfs-prometheus.yaml
# vi values-nfs-prometheus.yaml
  change default password
# helm install --namespace monitoring --name prometheus-operator coreos/prometheus-operator
# helm install coreos/kube-prometheus --name kube-prometheus --namespace monitoring \
    --set deployKubeDNS=false --set deployCoreDNS=true \
    --values values-nfs-prometheus.yaml
```

The Prometheus GUI and the Grafana GUI endpoints are exposed as ClusterIP and not reachable for outside access. To access the dashboard from outside the cluster change from  ClusterIP to NodePort.
```
# kubectl edit svc kube-prometheus -n monitoring
  change "type: ClusterIP" to "type: NodePort"
# kubectl edit svc kube-prometheus-grafana -n monitoring
  change "type: ClusterIP" to "type: NodePort"
# kubectl get services -n monitoring
  this will provide you the port nrs to access the GUI
```

Connect to the Prometheus GUI or the Grafana Dashboards with the URL pointing to one of the worker nodes in the cluster and the provided NodePort numbers (yours are different):
```
# kubectl get services -n monitoring |grep NodePort
kube-prometheus                       NodePort    10.102.21.69     <none>        9090:31287/TCP      2m
kube-prometheus-grafana               NodePort    10.99.2.105      <none>        80:32216/TCP        2m

http://worker1.vagrant.vm:31287/
http://worker1.vagrant.vm:32216/
```

## Troubleshooting
### Problem 1: kubelet metrics down 

If you point your browser to the Prometheus Targets (in my server example this is *http://worker1.vagrant.vm:31287/targets*) you will see a page with all the scrape targets currently configured for this Prometheus server. Check the status of the kubelet processes running on each node in the Kubernetes cluster. 

If the state is down with the error message *"server returned HTTP status 403 Forbidden"*, than change the kubelet startup command in the systemd files and restart the process. On each node of the cluster do:

```
# sudo vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf 
Environment="KUBELET_EXTRA_ARGS=--authentication-token-webhook"
# sudo systemctl daemon-reload
# sudo systemctl stop kubelet
# sudo systemctl start kubelet
```

If you use the Vagrant Kubernetes installation with a local Container Registry you need to change another systemd file:
```
# sudo vi /etc/systemd/system/kubelet.service.d/20-pod-infra-image.conf 
add to KUBELET_EXTRA_ARGS "--authentication-token-webhook"
# sudo systemctl daemon-reload
# sudo systemctl stop kubelet
# sudo systemctl start kubelet
```

### Problem 2: node-exporter metrics down 

On the same Prometheus Target page, if you see the state of the node-exporter is down than most likely it can't connect to the node-exporter process running on port 9100 on the Oracle Linux nodes in the Kubernetes cluster. Change the firewall settings:
```
# firewall-cmd --zone=public --add-port=9100/tcp
# firewall-cmd --zone=public --permanent --add-port=9100/tcp
# firewall-cmd --reload
```
