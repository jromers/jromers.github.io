---
title: "How-to: Ansible with Oracle Linux Virtualization Manager (OLVM)"
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

This article has been moved to the [Oracle Linux KVM and Oracle Linux Virtualization Manager](https://community.oracle.com/docs/DOC-1037000) community website.
