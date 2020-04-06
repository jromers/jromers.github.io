---
title: "Ansible with Oracle Linux Virtualization Manager (OLVM)"
date: 2020-04-06
---
## Introduction

Recently I started to work with Ansible, as part of the learning curve I wanted to automate Virtual Machine creation on my Oracle Linux OLVM lab cluster. As you may know, [Oracle Linux Virtualization Manager](https://docs.oracle.com/en/virtualization/index.html) is a server virtualization management platform for Oracle Linux KVM servers and based on open-source oVirt.

For this lab configuration there are the following pre-requisites:
- Have a running Oracle Linux OLVM manager server connected to one or more Oracle Linux KVM hosts
- Have a Linux-user configured on your OLVM manager with sudo access.
- Have a Template imported  in your OLVM cluster with Cloud-init enabled (see later)
- Replace passwords, hostnames, dns domain, IP-addresses, etc, etc in example files for your own network

## Installation
At the moment of writing the current release of OLVM is 4.3, and I want to use the [Ansible ovirt module for oVirt 4.3](https://docs.ansible.com/ansible/latest/modules/ovirt_vm_module.html) to write my playbooks. 

The installation is straight forward, just enable the correct repositories. For ansible you enable the Oracle Linux EPEL and for the Ansible ovirt module you need the SDK which is included in the ovirt 4.3 repository.

```
$ sudo yum install oracle-epel-release-el7
$ sudo yum --showduplicates list ansible
```
Install Ansible and test if it works with pinging the localhost.
```
$ sudo yum install ansible
$ sudo yum info ansible
$ ansible localhost -m ping
```
Install the ovirt 4.3 SDK, make sure you disable the ovirt 4.2 repositories.
```
$ sudo yum install oracle-ovirt-release-el7   
$ sudo yum --showduplicates list python-ovirt-engine-sdk4
$ sudo yum-config-manager --disable ovirt-4.2
$ sudo yum-config-manager --disable ovirt-4.2-extra
$ sudo yum install python-ovirt-engine-sdk4
```
Ansible is an agentless system and it follows a push approach. There is no need
to install an agent on a target host that you intend to manage with Ansible. The
 only requirement is SSH access at the target host (in my case the OLVM manager) and you need to setup SSH keys to allow access between Ansible host and target hosts.
```
$ ssh-keygen
$ ssh-copy-id user@olvm.localdomain
```
It's easy to test the SSH configuration, just try to logon without a password or even nicer use ansible to test the connection with a ping or run an ad-hoc command on the target server:
```
$ ssh user@olvm.localdomain
$ exit
$ ansible olvm.localdomain -u user -m ping
$ ansible olvm.localdomain -u user -a "cat /etc/hostname"
```

## OLVM Ansible example configuration files

Download my example files from github, use `git clone` or download the zip file.
```
$ git clone https://github.com/jromers/olvm-ansible.git
```

I wanted to work as much as possible with variables/parameters to be flexible in creation of new virtual machines. 

### Ansible hosts inventory setup

Ansible works with a list of hosts or groups of hosts in order to know the nodes to manage. This is called inventory and the default inventory file is `/etc/ansible/hosts` or you can specify a different inventory file (I use `hosts.ini`).

Besides adding my OLVM manager host to the inventory, I also wanted to add the virtual machines that I want to create with the Ansible playbook. In the inventory file `hosts.ini` I also add information to access the OLVM manager server.

```
$ more hosts.ini
#
# Define group with one host, which is the OLVM host (manager)
#
[olvm]
olvm.localdomain

#
# Define the variables for the OLVM host, admin password will be
# defined in password.yml
#
[olvm:vars]
olvm_fqdn=olvm.localdomain
olvm_user=admin@internal
olvm_cafile=/etc/pki/ovirt-engine/ca.pem

#
# Define the VMs you want to create on the OLV cluster
#
[virtualmachines]
vm01 ansible_host=vm01.localdomain ansible_ssh_host=192.168.100.41
vm02 ansible_host=vm02.localdomain ansible_ssh_host=192.168.100.42
vm03 ansible_host=vm03.localdomain ansible_ssh_host=192.168.100.43

#
# Define variables used for VM creation, in this case only vm_ram is used
# but can be extended with whatever you want.
#
# If vm_ram is undefined, the default is 1GiB
#
[virtualmachines:vars]
vm_ram=512MiB
```

### VM and cloud-init setup
There are more variables to define, such as the VM template I want to use and also the information for [cloud-init](https://cloud-init.io/) to be used by first start-up of the new virtual machine. 

In my OLVM cluster I use a little Oracle Linux template that I have build with the [Oracle Linux Image Tools](https://blogs.oracle.com/linux/building-small-oracle-linux-images-for-the-cloud). This is a cool project where you automatically build (SLIM) images to be provisioned in cloud infrastructures or OLVM servers.  

The variables are configured in a so called group_vars file, Ansible automaticaly looks for variables on startup in a sub-directory `group_vars` of current working directory.
```
$ more group_vars/all
# Variables applicable to all vms
#

# OLVM VM create details
#
olvm_cluster: Default
olvm_template: OL7u7-SLIM

# Cloud init variables
#
vm_dns: 192.168.100.13
vm_dns_domain: localdomain
vm_gateway: 192.168.100.1
vm_netmask: 255.255.255.0
vm_timezone: Europe/Amsterdam
```

### Secure passwords file

Last step in the configuration is the creation of a secure password file. It contains the admin password to access the OLVM manager host and the root password that is used in the created virtual machine. Create a plaintext yaml file with the admin password of your OLVM manager and the VM root password and encrypt the file to secure the password.
```
$ cp password-example.yml password.yml
$ more password.yml
---
olvm_password: your_olvm_admin_passwd
vm_root_passwd: your_vm_root_passwd

$ ansible-vault encrypt password.yml
New Vault password:
Confirm New Vault password:
Encryption successful

$ more password.yml
$ANSIBLE_VAULT;1.1;AES256
66356539646634323261383663336237613164376338353839303639303764646138336531653366
3063636162306666616133313061306330656130646337350a303539623736626338316130376561
....
....
....
3137376333656631370a663235663266336134333631316565653634386237323439633463303462
39633531663361336562396465616464386135616266316533613963663835333430
```


## Use Ansible to create OLVM virtual machines

Last step is to run the Ansible playbook with our inventory file and the secured password file to access the OLVM manager server. There is no need to change the below `create-vm.yml` playbook, should run out-of-the-box, but feel free to add your own configuration options ! Check the [Ansible ovirt_vm documentation](https://docs.ansible.com/ansible/latest/modules/ovirt_vm_module.html), there are plenty of options to add.

Run below command and when asked for a password enter the password of the OLVM manager.
```
$ ansible-playbook -i hosts.ini -u user --ask-vault-pass create-vm.yml
Vault password:

PLAY [olvm] ********************************************************************

TASK [Login to OLVM manager] ***************************************************
ok: [olvm.localdomain]

TASK [Create Virtual Machine(s)] ***********************************************
changed: [olvm.localdomain] => (item=vm01)
changed: [olvm.localdomain] => (item=vm01)
changed: [olvm.localdomain] => (item=vm01)

TASK [Cleanup OLVM auth token] *************************************************
ok: [olvm.localdomain]

PLAY RECAP *********************************************************************
olvm.localdomain           : ok=3    changed=1    unreachable=0    failed=0

$
```

