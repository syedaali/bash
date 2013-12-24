#!/bin/bash
#Script to connect to one or more Apache servers, collect /server-status and push to graphite
#Run this script in cron every 5 minutes or whatever other interval you want
#You should change the below 3 variables, and nothing else

#Syed Ali
#syed_a_ali@yahoo.com
# December 2013

#change the below three
#replace one two three with your server names
servers=(one two)
#replace the below location with the place where you want data stored
storage='/root/exp/'
#replace the below with the hostname of the graphite server
graphite_server='localhost'
graphite_port='2003'
#you should not have to change anything below this line

curl='/usr/bin/curl'
cat='/bin/cat'
sed='/bin/sed'
tr='/usr/bin/tr'
wc='/usr/bin/wc'
grep='/bin/grep'

function usage() {
${cat} <<EOF

usage: $0 [ -d ] [ -h ]

EOF
exit 1
}

while getopts "dh" OPTION; do
  case "$OPTION" in
    d) DEBUG=1 ;;
    h) usage ;;
  esac
done


for host in ${servers[@]}; do

dateStamp=`date +%s`

${curl} -k -s https://${host}:8443/server-status > ${storage}serverstatus.${host}
${curl} -k -s https://${host}:8443/server-status?auto > ${storage}serverstatusauto.${host}

#<p>Scoreboard Key:<br />
#"<b><code>_</code></b>" Waiting for Connection,
#"<b><code>S</code></b>" Starting up,
#"<b><code>R</code></b>" Reading Request,<br />
#"<b><code>W</code></b>" Sending Reply,
#"<b><code>K</code></b>" Keepalive (read),
#"<b><code>D</code></b>" DNS Lookup,<br />
#"<b><code>C</code></b>" Closing connection,
#"<b><code>L</code></b>" Logging,
#"<b><code>G</code></b>" Gracefully finishing,<br />
#"<b><code>I</code></b>" Idle cleanup of worker,
#"<b><code>.</code></b>" Open slot with no current process</p>


waiting=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${grep} -o '_' | ${tr} -d '\n' | ${wc} -m`
starting=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${grep} -o 'S' | ${tr} -d '\n' | ${wc} -m`
reading=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${grep} -o 'R' | ${tr} -d '\n' | ${wc} -m`
sendingreply=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${grep} -o 'W' | ${tr} -d '\n' | ${wc} -m`
keepalive=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${grep} -o 'K' | ${tr} -d '\n' | ${wc} -m`
dnslookup=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${grep} -o 'D' | ${tr} -d '\n' | ${wc} -m`
closing=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${grep} -o 'C' | ${tr} -d '\n' | ${wc} -m`
logging=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${grep} -o 'L' | ${tr} -d '\n' | ${wc} -m`
finishing=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${grep} -o 'G' | ${tr} -d '\n' | ${wc} -m`
openslot=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${grep} -o '\.' | ${tr} -d '\n' | ${wc} -m`
total=`${cat} ${storage}serverstatusauto.${host} | ${sed} '$!d' | ${tr} -d 'Scoreboard: ' | ${tr} -d '\n' | ${wc} -m`

bsworkers=`${cat} ${storage}serverstatusauto.${host} | ${grep} BusyWorkers | ${sed} 's/.*\ //'`
bytesperrequest=`${cat} ${storage}serverstatusauto.${host} | ${grep} BytesPerReq | ${sed} 's/.*\ //'`
bytespersecond=`${cat} ${storage}serverstatusauto.${host} | ${grep} BytesPerSec | ${sed} 's/.*\ //'`
requestspersecond=`${cat} ${storage}serverstatusauto.${host} | ${grep} ReqPerSec | ${sed} 's/.*\ //'`
idleworkers=`${cat} ${storage}serverstatusauto.${host} | ${grep} IdleWorkers | ${sed} 's/.*\ //'`

waitingvars="prod.${host}.apache.scoreboard.waiting_for_connection "$waiting" "$dateStamp
startingvars="prod.${host}.apache.scoreboard.starting_up "$starting" "$dateStamp
readingvars="prod.${host}.apache.scoreboard.reading_request "$reading" "$dateStamp
sendingreplyvars="prod.${host}.apache.scoreboard.sending_reply "$sendingreply" "$dateStamp
keepalivevars="prod.${host}.apache.scoreboard.keepalive "$keepalive" "$dateStamp
dnslookupvars="prod.${host}.apache.scoreboard.dnslookup "$dnslookup" "$dateStamp
closingvars="prod.${host}.apache.scoreboard.closing_connection "$closing" "$dateStamp
loggingvars="prod.${host}.apache.scoreboard.logging "$logging" "$dateStamp
finishingvars="prod.${host}.apache.scoreboard.gracefully_finishing "$finishing" "$dateStamp
openslotvars="prod.${host}.apache.scoreboard.open_slot "$openslot" "$dateStamp
totalvars="prod.${host}.apache.scoreboard.total "$total" "$dateStamp

bsworkersvars="prod.${host}.apache.busy_workers "$bsworkers" "$dateStamp
bytesperrequestvars="prod.${host}.apache.bytes_per_request "$bytesperrequest" "$dateStamp
bytespersecondvars="prod.${host}.apache.bytes_per_second "$bytespersecond" "$dateStamp
requestspersecondvars="prod.${host}.apache.requests_per_second "$requestspersecond" "$dateStamp
idleworkersvars="prod.${host}.apache.idle_workers "$idleworkers" "$dateStamp

if [[ $DEBUG ]]; then

echo $waitingvars
echo $startingvars
echo $readingvars
echo $sendingreplyvars
echo $keepalivevars
echo $dnslookupvars
echo $closingvars
echo $loggingvars
echo $finishingvars
echo $openslotvars
echo $totalvars
echo " "
echo $bsworkersvars
echo $bytesperrequestvars
echo $bytespersecondvars
echo $requestspersecondvars
echo $idleworkersvars

else

#echo $graphitevar | nc  graphite_server ${graphite_port}
echo $waitingvars | nc  ${graphite_server} ${graphite_port} &
echo $startingvars | nc  ${graphite_server} ${graphite_port} &
echo $readingvars | nc  ${graphite_server} ${graphite_port} &
echo $sendingreplyvars | nc  ${graphite_server} ${graphite_port} &
echo $keepalivevars | nc  ${graphite_server} ${graphite_port} &
echo $dnslookupvars | nc  ${graphite_server} ${graphite_port} &
echo $closingvars | nc  ${graphite_server} ${graphite_port} &
echo $loggingvars | nc  ${graphite_server} ${graphite_port} &
echo $finishingvars | nc  ${graphite_server} ${graphite_port} &
echo $openslotvars | nc  ${graphite_server} ${graphite_port} &
echo $totalvars | nc  ${graphite_server} ${graphite_port} &
echo $bsworkersvars | nc  ${graphite_server} ${graphite_port} &
echo $bytesperrequestvars | nc  ${graphite_server} ${graphite_port} &
echo $bytespersecondvars | nc  ${graphite_server} ${graphite_port} &
echo $requestspersecondvars | nc  ${graphite_server} ${graphite_port} &
echo $idleworkersvars | nc  ${graphite_server} ${graphite_port} &

fi
done
