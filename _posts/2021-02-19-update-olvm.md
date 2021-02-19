---
title: "How-to: Update a self-hosted engine OLVM 4.3 cluster"
date: 2021-02-19
---
Every now and then you need to update the software packages of your OLVM 
cluster. On a regular basis the OLVM sub-components will be updated and made 
available on [Unbreakable Linux Network (ULN)](https://linux.oracle.com/) or the [Oracle Public Yum server](https://yum.oracle.com/).
And on weekly, or even daily basis, 
you also need to track the generic Oracle Linux updates such as security 
updates or major kernel updates. 

Updating the software packages of the OLVM cluster where the OLVM manager is 
deployed as a self-hosted engine requires a specific procedure. In this 
article I describe the steps to do a complete update of the cluster. 

For a complete picture, the below diagram shows an architecture in which a self-hosted engine (OLVM manager) is deployed as virtual machine in the same environment it manages. The OLVM manager is highly available, if the KVM host gets unresponsive the OLVM manager will be restarted on one of the other KVM hosts.

![SHE architecture drawing](/assets/images/2021-02-19-olvm-she.png)

During the software update, the cluster remains available and there is no 
downtime of the virtual machine guests in the cluster. But we should disable 
the HA services of the OLVM manager before we start with the update process 
of the self-hosted engine virtual machine. We do not want to have a 
failover during the update process. After the update of the OLVM manager we 
continue the process with the update of each individual KVM compute host.

## OLVM manager update
Before we make any configuration or update change to the manager we need to bring the cluster in maintenance mode, which is called global maintenance mode for this operation.  In global maintenance mode the high-availability services of the cluster are disabled. In other words, monitoring the health of the self-hosted engine is stopped to prevent an automatic failover of the self-hosted engine during the software update. 

We start to logon on the KVM compute host where the self-hosted engine is running:
```
[root@olvm-kvm1 ~]# hosted-engine --set-maintenance --mode=global
[root@olvm-kvm1 ~]# hosted-engine --vm-status
```
We now can logon to the self-hosted engine virtual machine to start the update process and verify if there are updates available. We start the update with the ovirt-packages, followed by an engine-setup to implement the changes.
```
[root@olvm-kvm1 ~]# ssh root@olvm-mgr.demo.local
[root@olvm-mgr ~]# engine-upgrade-check
[root@olvm-mgr ~]# yum update ovirt\*setup\*
[root@olvm-mgr ~]# engine-setup
```
To update the regular Oracle Linux packages we do the standard yum-update, but first we check if all proper yum-repositories are configured and disable older ovirt-repositories in case they are enabled.
```
[root@olvm-mgr ~]# yum repolist	
[root@olvm-mgr ~]# yum-config-manager --disable ovirt-4.2
[root@olvm-mgr ~]# yum-config-manager --disable ovirt-4.2-extra
[root@olvm-mgr ~]# yum repolist
[root@olvm-mgr ~]# yum update -y
[root@olvm-mgr ~]# exit
```
If the update process updated the Linux kernel you need to reboot the self-hosted engine in order to make the new kernel effective. Start with disabling global maintenance mode and reboot the virtual machine to complete the full update process. On the KVM compute host:
```
[root@olvm-kvm1 ~]# hosted-engine --set-maintenance --mode=none
[root@olvm-kvm1 ~]# hosted-engine --vm-status
[root@olvm-kvm1 ~]# hosted-engine --vm-shutdown
[root@olvm-kvm1 ~]# hosted-engine --vm-start			# might not be necessary in case it start automatically
```

## OLVM KVM compute host update

We will perform an update of each individual KVM compute host (see later for a more automatic cluster update). During the update virtual machines will be live-migrated to another KVM compute host before it will enter Maintenance mode. After the update the KVM compute host will reboot and if all is up and running it will be available again to run virtual machines.

In the OLVM Administration Portal, go to **Compute** and click **Hosts**. If there are updates available you’ll see an update icon in the 2nd column of each KVM-host, see the screenshot.

![Update notification icon](/assets/images/2021-02-19-olvm-kvm1.png)

Select the host and in the **Action items** choose **Upgrade** including the reboot option. Alternative: Select the **Installation** drop-down menu and choose **Upgrade** also including the reboot option.

![Update action item](/assets/images/2021-02-19-olvm-kvm2.png)

If there are virtual machines running on the KVM compute host they will be migrated to another KVM compute host in the cluster, the new updates will be installed and the KVM compute host will be rebooted. After some time you will see the Status of the KVM compute host is **Up** again. Notice, also the little icon to notify us for updates is removed from the KVM compute host’s table entry.

Repeat this step for each KVM compute host in the cluster.

In case you do not want to bother with each individual KVM compute host, then you have the option to update all KVM compute hosts in the cluster in one task. In the Administration Portal, go to **Compute** and click **Clusters**. Select the cluster you want to update and click **Upgrade** and configure the options to start the process. 

