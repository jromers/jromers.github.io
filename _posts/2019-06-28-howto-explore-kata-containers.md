---
title: "How-to: Use KVM nested virtualization to explore Kata Containers"
date: 2019-06-28
---
## Introduction
Kata Containers is an interesting technology, it combines the speed of deployment of Docker containers with the isolation of virtual machines and its security advantages.

After reading the article [Kata Containers: An Important Cloud Native Development Trend](https://blogs.oracle.com/linux/kata-containers:-an-important-cloud-native-development-trend-v2) on the [Oracle Linux Blog](https://blogs.oracle.com/linux/), I was inspired to explore the software.

Instead of using a [bare metal compute instance on OCI](https://cloud.oracle.com/compute/bare-metal/features), I wanted to run the software on my own system. I found out I can use nested virtualization on my existing KVM server to explore Kata Containers, just by creating a KVM VM with an Oracle Linux guest OS. 

By default nested virtualization is disabled in the Oracle Linux KVM server. This article describes how to enable nested virtualization and then start exploring Kata Containers in the nested VM.

## Enable Nested Virtualization in KVM server.
I'm running an Oracle Linux 7.5 KVM server, but I expect it also works with other Oracle Linux KVM versions. This is what I did on my Lab server:

First, verify if nested is enabled or disabled:
```
# cat /sys/module/kvm_intel/parameters/nested
N
```
If you run a server with AMD processor the filepath is different. "N" indicates nested is disabled, to enable nested virtualization create the following file:
```
# vi /etc/modprobe.d/kvm-nested.conf
options kvm-intel nested=1 
options kvm-intel enable_shadow_vmcs=1 
options kvm-intel enable_apicv=1 
options kvm-intel ept=1
```
I did a reboot of my Lab server, but you can also use modprobe (make sure other VMs are shutdown) to enable the functionality. After the reboot verify again if  nested virtualization is enabled:
```
# cat /sys/module/kvm_intel/parameters/nested
Y
```

## Use Nested Virtualization on Virtual Machine.

Before you can test and use the nested functionality you need to configure CPU model for the Virtual Machine. This is to tell KVM to passthrough the host CPU with no modifications in order to use nested virtualization.

This is rather easy for an existing Virtual Machine, let's say the name of my test VM is ``kata-test``:
```
# virsh edit "kata-test"
...
<cpu mode='host-passthrough' check='partial'/>
...
#
```
Startup your VM and login as root:
```
# lsmod | grep kvm 
kvm_intel             229376  0 
kvm                   655360  1 kvm_intel irqbypass              16384  1 kvm
# lscpu
...
Virtualization:        VT-x
Hypervisor vendor:     KVM
...
```
Configuration complete ! 

## Explore Kata Containers

In the tech-preview channels of the Oracle Linux public yum server Oracle released Oracle Container Runtime for Kata. There is no need to explain the steps in this documents as all the steps to test and use Kata Containers are explained in the earlier mentioned and excellent blog post [Kata Containers: An Important Cloud Native Development Trend](https://blogs.oracle.com/linux/kata-containers:-an-important-cloud-native-development-trend-v2).
