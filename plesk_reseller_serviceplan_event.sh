#!/bin/bash
###
# This script ensures CPU limits are applied to all service plans created by resellers
# It is triggered by Plesk Event Handlers:
# plesk bin event_handler --create -priority 50 -user root -event template_domain_create -command '/usr/local/bin/plesk_reseller_serviceplan_event.sh'
# plesk bin event_handler --create -priority 50 -user root -event template_domain_update -command '/usr/local/bin/plesk_reseller_serviceplan_event.sh'
###
CPU=100

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