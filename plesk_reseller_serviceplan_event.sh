#!/bin/bash
###
# This script ensures CPU limits are applied to all service plans created by resellers
# It's triggered by Plesk event handlers when resellers create or update their service plans
# Simply run it once to both install Event Handlers and update existing reseller service plans
###
CPU=100
BIN=/usr/local/bin/plesk_reseller_serviceplan_event.sh

if [ ! -e "$BIN" ]; then
        echo "Installing to $BIN"
        cp "$0" $BIN
        chmod +x $BIN
fi

if ! plesk bin event_handler --list | grep "$BIN"; then
        echo 'Creating Plesk Events...'
        plesk bin event_handler --create -priority 50 -user root -event template_domain_create -command "$BIN"
        plesk bin event_handler --create -priority 50 -user root -event template_domain_update -command "$BIN"
fi

plesk db -ENe "SELECT Templates.name,clients.login FROM Templates LEFT JOIN clients ON Templates.owner_id=clients.id WHERE clients.type='reseller';" |
while read -r  line
do
        if [[ "$line" == "*"* ]]; then
                line=''
                prevline=''
                continue
        fi
        plan_name=$prevline
        reseller_login=$line
        prevline=$line
        if [[ "$plan_name" == "" ]]; then
                continue
        else
                echo "Checking service plan '$plan_name' owned by '$reseller_login'..."
                if ! plesk bin service_plan -i "$plan_name" -owner "$reseller_login" | grep -E "Maximum CPU usage\s+$CPU"; then
                        echo "Updating service plan '$plan_name' owned by '$reseller_login'..."
                        plesk bin service_plan --update "$plan_name" -owner "$reseller_login" -cgroups_cpu_usage $CPU -cgroups_cpu_period 3600
                fi
        fi
done