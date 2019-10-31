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
