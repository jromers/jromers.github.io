---
title: "Hands-on Lab: Zero downtime patching with Oracle Linux Ksplice"
date: 2019-05-15
---

## Introduction

This hands-on lab takes you through several steps on how-to provide zero downtime kernel updates to your Oracle Linux server thanks to Oracle Ksplice, the service and utility capable of introducing hot-patch capabilities for the Linux Kernel and User-Space components like glibc and openssl.

The entire hands-on lab runs on an Oracle VM VirtualBox virtual machine based on Oracle Linux 7.2, it receives the Ksplice updates from a local repository. In the lab we do the following steps:
* Inspect the kernel and search for vulnerabilities
* Perform Local Denial of Service attack based on found vulnarability
* Apply Ksplice kernel patches as rebootless updates

The Ksplice client is available in online or offline mode, in this hands-on lab we use the offline Ksplice client.  The offline version of the Ksplice client removes the requirement that a server on your intranet has a direct connection to the Oracle Ksplice server or to Unbreakable Linux Network (ULN). 

All available Ksplice updates for each supported kernel version or user-space package are bundled into an RPM that is specific to that version. This package is updated every time a new Ksplice patch becomes available for the kernel.



##  Preparation

First, import the Virtual Machine template in VirtualBox on your laptop, use the preconfigured OVA template from the instructor:
```
oraclelinux-7.2-gui_kspliceoffline		(GUI version)
```
When imported start the VM with a normal start. When the VM is ready, login with the following credentials:
```
Username:	demo
Password:	demo
```

## Inspect the Oracle Linux server

We can use the Ksplice Inspector to review the security patches available for the installed kernel on the server. This can be done online via the Ksplice website or via a CLI command connecting to the Ksplice API server.

We will use one of the found vulnarabilities as an example to show how easy it is to attack a system.

Open a terminal and use the following ksplice inspector script and search for CVE 14489 or CVE 5195:
```
$ more ksplice-inspector.sh
$ ./ksplice-inspector.sh
$ ./ksplice-inspector.sh | grep 14489
$ ./ksplice-inspector.sh | grep 5195
```

You can also use the ksplice inspector from the original Ksplice website and search for the specified CVEs. Run the following command in your terminal.
```
$ echo "`uname -s`//`uname -m`//`uname -r`//`uname -v`"

Launch a browser and goto http://www.ksplice.com/inspector
Copy the output of the echo command into the text box and click Find Updates.
```

In the list with available Ksplice Updates you will find several CVEs including the one we are interested in (CVE-2016-5195 or CVE-2017-14489). It's easy to find the code for the exploits, we've already found it and compiled it and made it available to you for this exercise. 

Let's try the DirtyCOW exploit, this exploit gives you root access to the system and after a while panic the system (at the very least this is denial of service and can cause havoc):

```
$ cd cve-2016-5195
$ id
$ cat /etc/shadow
$ ./CVE-2016-5195
# id
# cat /etc/shadow
```
The Oracle Linux server will crash because of the local denial of service. The only thing we can do is a power reset and reboot the VM.

## Install Ksplice in Offline Mode

The Ksplice Offline client eliminates the need having a server on your intranet with a direct connection to Oracle's online Ksplice service. In this lab we use a local yum server that has Oracle Linux packages, updates and Ksplice updates synchronized with Oracle ULN. This is a very common deployment model for Ksplice deployments.

![Architecture diagram for Ksplice offline client](/assets/images/2019-05-15-ksplice-offline.png)

Also, a Ksplice Offline client does not require a network connection to be able to apply the update package to the kernel. For example, you could use the yum command to install the update package directly from a memory stick. 

After the reboot of the Oracle Linux VM login as the root user.
```
Username:	root
Password:	demo
```

Verify you are able to connect to the local Ksplice repository for the Ksplice tools and patches.
```
# yum repolist                      # you will see the two kplice channels
```
Install the Ksplice Offline client package.
```
# yum -y install uptrack-offline
```
Clear the yum metadata cache.
```
# yum clean metadata
```

## How to use Ksplice in Offline Mode

When Ksplice has applied updates to a running kernel, the kernel has an effective version that is different from the original boot version that is displayed by the `uname` command.

Verify the current, installed (and running) kernel and use the `uptrack-uname` command to display the effective version of the kernel (version should be the same as the running kernel):
```
# uname -r
# uptrack-uname -r
```

Install the Ksplice updates that are available for the kernel in use. This will be done with the `yum install` command. By default it unpacks the rpm and immediatly applies the Ksplice patches, but we used an option to skip applying patches immediatly as we like to explore additional commands.
```
# yum -y install uptrack-updates-`uname -r`
```
The skip applying patches option is configured in the uptrack configuration file `/etc/uptrack/uptrack.conf` (`skip_apply_after_pkg_install=yes`).

View the updates that are available for installation as follows:
```
# uptrack-show --available
```
Apply the available Ksplice to the kernel:
```
# uptrack-install --all
```
Verify the current effective kernel again and compare with installed kernel version.
```
# uptrack-uname -r
# uname -r
```

Print the number of ksplice updates installed (also run without `--count`, it shows the installed updates).
```
# uptrack-show --count
# uptrack-show
```

Verify if the Ksplice updates were effective and run the CVE-2016-5195 exploit and see if the VM crashes. It doesn't :-)

Open a new terminal window and change to the demo user:
```
# su - demo
$ cd cve-2016-5195
$ ./CVE-2016-5195
Use Ctrl-C to exit the program.
```

## Remove installed Ksplices

It's easy to remove a single Ksplice update or even all off the updates, again this happens without a reboot. 

Remove a single ksplice update (notice it also removes depending updates) by specifying the ID or remove all ksplice updates.
```
# uptrack-remove
# uptrack-remove 51tkixls                 (the ID is just an example)
# uptrack-remove —all
```

## Update to a Specific Effective Kernel
Under some circumstances, you might want to limit the set of updates that uptrack-upgrade installations. For example, the security policy at your site might require a senior administrator to approve Ksplice updates before you can install them on production systems. In such cases, you can direct uptrack-upgrade to upgrade to a specific effective kernel version instead of the latest available version.

This scenario is only available in the Ksplice Offline client which we use in this Hands-on Lab (not with the Ksplice online client).

Use the `uptrack-uname -r` command to display the current effective kernel version:
```
# uptrack-uname -r
3.8.13-98.7.1.el7uek.x86_64
```
To list all of the effective kernel versions that are available, specify the `--list-effective` option to the `uptrack-upgrade` command:
```
# uptrack-upgrade --list-effective

Available effective kernel versions:
3.8.13-98.7.1.el7uek.x86_64/#2 SMP Wed Nov 25 13:51:41 PST 2015
3.8.13-98.8.1.el7uek.x86_64/#2 SMP Thu Dec 17 13:19:44 PST 2015
3.8.13-118.19.7.el7uek.x86_64/#2 SMP Fri Sep 15 18:15:47 PDT 2017
3.8.13-118.19.10.el7uek.x86_64/#2 SMP Tue Oct 24 09:01:57 PDT 2017
3.8.13-118.19.12.el7uek.x86_64/#2 SMP Tue Oct 31 12:27:33 PDT 2017
3.8.13-118.20.1.el7uek.x86_64/#2 SMP Thu Dec 7 08:20:41 PST 2017
```
You can set the effective kernel version that you want the system to use in the following way:
```
# uptrack-upgrade --effective="3.8.13-118.19.10.el7uek.x86_64/#2 SMP Tue Oct 24 09:01:57 PDT 2017"
The following steps will be taken:
...
...
Effective kernel version is 3.8.13-118.19.10.el7uek
# uptrack-uname -r
3.8.13-118.19.10.el7uek
# uptrack-show --count
159
```

## Remove Ksplice packages
To remove the offline Ksplice Uptrack software from a system, use the following command.
```       
# yum -y remove uptrack-offline
```
