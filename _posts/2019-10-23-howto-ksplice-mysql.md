---
title: "How-to: Use MySQL Sample Database with Ksplice demo"
date: 2019-10-23
---
## Introduction
This is a short article with instructions to use a MySQL database during a Ksplice demo to proof that applications continue to run while you are patching the Linux kernel with Ksplice.

A standard MySQL 8 database is used and data is loaded from a [MySQL Employees Sample Database](https://dev.mysql.com/doc/employee/en/) that is available on [Github](https://github.com/datacharmer/test_db). If you like to know more about Ksplice, check this [Ksplice Demonstration video](https://youtu.be/H9Ga_ndoOwA) or have a look at my [Hands-on Lab: Zero downtime patching with Oracle Linux Ksplice](https://jromers.github.io/article/2019/05/handson-lab-ksplice-offline/).

The following video shows the demo running SQL queries on a MySQL database, while patching the Linux kernel without reboot:
<iframe width="853" height="480" src="https://www.youtube.com/embed/tesrSZIUBxQ" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Prerequisite
I installed the MySQL 8.0 Database in my Oracle Linux 7.7 server, the procedure on other Oracle Linux versions might be different for the setup of yum channels.

If your server is receiving updates from ULN then you should select the "MySQL 8.0 for Oracle Linux 7 (x86_64)" channel. For the Oracle Linux public yum server you should do:
```
# yum install -y mysql-release-el7
```
If you want to use the older 5.7 version you need to do:
```
# yum-config-manager --disable ol7_MySQL80
# yum-config-manager --enable ol7_MySQL57
```

## Install and Configure MySQL
Install MySQL as usual and start the service. During installation, you will be asked if you want to accept the results from the .rpm file’s GPG verification. If no error or mismatch occurs, enter y.
```
# yum install -y mysql-server
# systemctl enable mysqld
# systemctl start mysqld
```
Harden the MySQL server to address several security concerns in a default MySQL installation. You have to change the random generated, temporary database root password. The hardening script also removes some settings for remote root login, anonymous user accounts and test databases.
```
# grep 'temporary password' /var/log/mysqld.log
# /usr/bin/mysql_secure_installation
<It is recommended that you answer yes to most of the questions>
```

Create a new MySQL user, in the example below I use `dbadmin` as username, replace `yourpasswd` with your password of choice.
```
# mysql -u root -p
<enter DB root password>
mysql> CREATE USER 'dbadmin'@'localhost' IDENTIFIED BY ‘yourpasswd’;
mysql> GRANT ALL PRIVILEGES ON *.* TO 'dbadmin'@'localhost';
mysql> flush privileges;
mysql> exit
#
```

## How to setup the Employee Sample Database

I'm now logged in as a standard Linux user and to run MySQL queries in the bash shell or in a bash script I created an option file to store my DB username and password (don't do this in a real production environment, storing passwords in a file is unsafe):
```
$ more $HOME/.my.cnf
[client]
user=dbadmin
password=yourpasswd
$ chmod 600 $HOME/.my.cnf
```

The [MySQL Employees Sample Database](https://dev.mysql.com/doc/employee/en/) is a combination of a large base of data (approximately 160MB) spread over six separate tables and consisting of 4 million records in total. This is a perfect starting point for my database bash-script that I want to run during my Ksplice demo. Load the database as shown in the below steps:
```
$ wget https://github.com/datacharmer/test_db/archive/master.zip
$ unzip master.zip
$ cd test_db-master
$ mysql < employees.sql
$ mysql -t < test_employees_md5.sql             (this will test the database)
```

### MySQL Bash Script 

Store the following code in a file and change file-permissions to execute. Run the script during the Ksplice demo in the background as the standard database user (in my case `dbadmin`):
```
#!/bin/bash

function run
{
    echo '$ '$*
    sleep 3
    eval $*
    echo
}

# hide the evidence
clear

run 'mysql -e "show databases"'
run 'mysql -e "show tables" employees'
run 'mysql -e "SELECT COUNT(emp_no) FROM employees" employees'

COUNTER=0
while [  $COUNTER -lt 5 ]; do
    run "mysql -e \"select emp_no,birth_date,first_name,last_name,gender,hire_date from employees WHERE birth_date LIKE '1952-02-01%' ORDER BY last_name\" employees"
    run 'mysql -e "select emp_no,salary,from_date,to_date FROM salaries order by salary desc limit 10" employees'
    run 'mysql -e "SELECT DISTINCT title FROM titles" employees'
    let COUNTER=COUNTER+1
done
```
Feel free to change the script and change or add MySQL queries such as adding or updating entries to the database (generate writes).
