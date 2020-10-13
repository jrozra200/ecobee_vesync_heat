#!/bin/bash
# LOG ROTATION

echo $(date)': Log Rotation Script Started.'

# MOVE THE ECOBEE LOG FILE
ecobeefilename='/home/jacobrozran/ecobee/ecobee.log'
newecobeefilename='/home/jacobrozran/ecobee/logs/ecobee'$(date +%Y%m%d)'.log'

mv $ecobeefilename $newecobeefilename

echo $(date)': Moved Ecobee Logs.'

# MOVE THE SEND NOTIFICATION LOG FILE
sendfilename='/home/jacobrozran/ecobee/send_notification.log'
newsendfilename='/home/jacobrozran/ecobee/logs/send_notification'$(date +%Y%m%d)'.log'

mv $sendfilename $newsendfilename

echo $(date)': Moved Notification Sent Logs.'

# MOVE THE VESYNC LOG FILE
vesyncfilename='/home/jacobrozran/ecobee/vesync.log'
newvesyncfilename='/home/jacobrozran/ecobee/logs/vesync'$(date +%Y%m%d)'.log'

mv $vesyncfilename $newvesyncfilename

# MOVE THE LOG ROTATION LOG FILE
logrotatefilename='/home/jacobrozran/ecobee/log_rotation.log'
newlogrotatefilename='/home/jacobrozran/ecobee/logs/log_rotation'$(date +%Y%m%d)'.log'

mv $logrotatefilename $newlogrotatefilename

echo $(date)': Moved Vesync Logs.'

# DELETE THE LOGS OLDER THAN A WEEK

find /home/ec2-user/ecobee/logs/ -type f -mtime +7 -delete

echo $(date)': Deleted logs that are older than 7 days.'
