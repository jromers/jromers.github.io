---
title: "How-to: Running a cool CLI based demo without typing failures"
date: 2019-10-31
---
## Introduction
You plan to run a cool Ksplice demo for a potential customer, all well prepared, but it miserably failed because you never had typing lessons or started to use the wrong CLI commands.

Big deal or not, even the [world's most famous presenters have failures](https://youtu.be/zNlBLyf39Bk) while running demos. Continue to read this article and minimize your risk on demo failures !

## Prerequisite
I'm using the software below on an Oracle Linux 7 system, it's based on two software packages:
* [Pipe Viewer](http://www.ivarch.com/programs/pv.shtml) - is a terminal-based tool for monitoring the progress of data through a pipeline.
* [Demo Magic](https://github.com/paxtonhare/demo-magic) - a handy shell script that enables you to write repeatable demos in a bash environment.

## Pipe Viewer install
Download and install the pv-package on your Oracle Linux server:
```
$ wget http://www.ivarch.com/programs/rpms/pv-1.6.6-1.x86_64.rpm
$ yum localinstall -y pv-1.6.6-1.x86_64.rpm
```
If you prefer to use a YUM repository, see [the Pipe Viewer author's instructions](http://www.ivarch.com/programs/yum.shtml) to install Pipe Viewer with a YUM repository.

## Demo Magic install
The Demo Magic script installation is easy, clone from [Demo Magic Github](https://github.com/paxtonhare/demo-magic) and copy the `demo-magic.sh` file to the destination directory where you run your demo:
```
$ git clone https://github.com/paxtonhare/demo-magic.git
$ mkdir $HOME/demo
$ cp demo-magic/demo-magic.sh $HOME/demo/demo-magic.sh
```
Or use `wget` if you prefer to download and unzip:
```
$ wget https://github.com/paxtonhare/demo-magic/archive/master.zip
$ unzip master.zip
$ mkdir $HOME/demo
$ cp demo-magic/demo-magic.sh $HOME/demo/demo-magic.sh
```
I'm not going to to explain the Demo Magic script, you can read it in the README file, but the most important features are (copied from README):
* Simulates typing. It looks like you are actually typing out commands
* Allows you to actually run commands or pretend to do so.
* Can hide commands from presentation. Useful for behind the scenes stuff that doesn't need to be shown.

Only thing you have to do during the demo is tell your story and push the `RETURN` button on your keyboard. It's still a live demo, only the typing is automated.

## Ksplice Demo Magic Bash Script 

Store the following code in a file and change file-permissions to execute. Run the script during the Ksplice demo and explain the steps based on the inline comments.
```
#!/bin/bash

########################
# include the magic
########################
. /$HOME/demo/demo-magic.sh

# some supporting functions

HOST=`hostname -s`
UNIXPROMPT="[root@$HOST ~]# "
#UNIXPROMPT="# "

function prompt
{
    echo; echo "------> $*"
    echo; echo -n "$UNIXPROMPT"
}

# hide the evidence
clear

# start the live Ksplice demo
prompt What is the host I am running on ?
pe "hostname"

prompt What is the current uptime ?
pe "uptime"

prompt Is Ksplice installed ?
pe "rpm -qa uptrack*"

prompt What is the Installed kernel version ?
pe "uname -r"

prompt How many Ksplice kernel patches are available for this kernel ?
pe "sudo uptrack-show --available"

prompt Install Ksplice kernel patches without reboot.
pe "sudo uptrack-upgrade -y"

prompt Check the kernel version again.
pe "uname -r"

prompt INSTALLED kernel version same as before, but EFFECTIVE kernel changed.
pe "sudo uptrack-uname -r"

if [ -f "/etc/uptrack/uptrack.conf" ]; then
    prompt Are there any Ksplice settings I need to configure ?
    p "more /etc/uptrack/uptrack.conf"
    sed -e 's/accesskey = .*/accesskey = dfc21b3-------HIDDEN_API_KEY--------ce5903e/g' \
        /etc/uptrack/uptrack.conf | more
fi

prompt Proof me you did not reboot !
pe "uptime"

prompt Can I remove Ksplice kernel patches without reboot ?
pe "sudo uptrack-remove --all -y"

prompt Thank you !
pe "clear"
```
Or in more detailed steps, download the script, make it executable and Go!:
```
$ wget https://jromers.github.io/assets/files/ksplice.sh
$ chmod 755 ksplice.sh
$ ./ksplice.sh
```
## Example Ksplice Demo Magic
Play the screen recording and see how the Ksplice Demo Magic script works in real time:

## Credits
Recently I did a Ksplice presentation for Oracle consultants and my co-presenter [Harald Van Breederode](https://prutser.wordpress.com/) did the live demo. Always good to see colleagues doing demos and this one inspired me to write the Ksplce Demo Magic script.
<script id="asciicast-278117" src="https://asciinema.org/a/278117.js" async></script>
