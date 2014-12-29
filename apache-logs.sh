# This script can help you sort through Apache log file

#Get entries within last X hours [Here two hours]
awk -vDate=`date -d'now-2 hours' +[%d/%b/%Y:%H:%M:%S` ' { if ($4 > Date) print Date FS $0}' access_log

#Get most active IPs within the last X hours [Here two hours]
awk -vDate=`date -d'now-2 hours' +[%d/%b/%Y:%H:%M:%S` ' { if ($4 > Date) print $1}' access_log | sort  |uniq -c |sort -n | tail

#Get entries within absolute timespan
awk -vDate=`date -d '13:20' +[%d/%b/%Y:%H:%M:%S` -vDate2=`date -d'13:30' +[%d/%b/%Y:%H:%M:%S` ' { if ($4 > Date && $4 < Date2) print $0}' access_log 

#Get most active IPs within absolute timespan
awk -vDate=`date -d '13:20' +[%d/%b/%Y:%H:%M:%S` -vDate2=`date -d'13:30' +[%d/%b/%Y:%H:%M:%S` ' { if ($4 > Date && $4 < Date2) print $1}' access_log | sort  |uniq -c |sort -n | tail

#Get entries within relative timespan
awk -vDate=`date -d'now-4 hours' +[%d/%b/%Y:%H:%M:%S` -vDate2=`date -d'now-2 hours' +[%d/%b/%Y:%H:%M:%S` ' { if ($4 > Date && $4 < Date2) print Date FS Date2 FS $0}' access_log
