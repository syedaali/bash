#!/bin/bash
# Syed Ali
# December 2013
# This script may be used to start/stop services on remote hosts using 'ssh'

# fill in the below variables with what you want
# provide a file name that has hosts in it, one line per host
INFILE='/home/username/myfile'
# provide the stop start command
REMOTE_START_CMD='/bin/uname'
# provide the stop command
REMOTE_STOP_CMD='/bin/uname'
# fill in the process name on the remote host
P_NAME='uname'
# number of seconds to wait between stop and start
RESTART_SLEEP=0
#any seconds to wait before moving onto the next host
SLEEP_TIME=0
# any SSH options you want
SSHOPTIONS='-o ConnectTimeout=5 -o StrictHostKeyChecking=no'
#any particular user you must run this script as
USER='syedaali'

# you should not have to modify anything below this line, hopefully
SEQ='/usr/bin/seq'
TPUT='/usr/bin/tput'
CAT='/bin/cat'
WC='/usr/bin/wc'
ECHO='/bin/echo'
SSH='/usr/bin/ssh'
CUT='/bin/cut'
DATE='/bin/date'
SLEEP='/bin/sleep'
ID='/usr/bin/id'
PRINTF='/usr/bin/printf'
EXPR='/usr/bin/expr'
HEAD='/usr/bin/head'
YES='/usr/bin/yes'
NETSTAT='/bin/netstat'
AWK='/bin/awk'
GREP='/bin/grep'
SED='/bin/sed'
CUT='/bin/cut'


# process trapped signals
function mysignal () {
    echo -n "Are you sure you want to quit? [y/n]: "
    read
    if [ "$REPLY" = "y" ]
        then
        echo "Quitting, bye!"
        exit
    fi
    continue

}

# calculates percentages
function percent () {
    percent=$(($1*100/$total))
    $ECHO "`${DATE} +%Y%m%d-%H:%M:%S` INFO: remaining $percent%"
}

#ensures script is running as a particular user
function check_user() {
    username=$($ID -u -n)
    if [ $username != "tentakel" ]
        then
        $ECHO "`${DATE} +%Y%m%d-%H:%M:%S` ERROR: must run this script as user ${USER}"
        exit 1
    fi
}

#does the countdown between stopping and starting
function countdown() {
    
    timer=${SLEEP_TIME}    

    until [ $timer = 0 ]
    do
        ${PRINTF} "\r`${DATE} +%Y%m%d-%H:%M:%S` INFO: Sleeping for $timer seconds"
        timer=$(($timer-1))
        sleep 1
    done   
    $PRINTF "\n" 
    
}

#print a divider line between hosts
function print_banner() { 
    cols=`${TPUT} cols`
    for num in `${SEQ} 1 ${cols}`
    do
        $ECHO -n "*"
    done
    $ECHO 
}

#catches signales    
trap mysignal SIGHUP SIGINT SIGTERM

#checks if script is being run as a user
check_user

count=`$WC -l $INFILE`

numofhosts=${count:0:3}
total=${count:0:3}

print_banner
$ECHO "`${DATE} +%Y%m%d-%H:%M:%S` INFO: starting script at `$DATE`"
$ECHO "`${DATE} +%Y%m%d-%H:%M:%S` INFO: processing $numofhosts hosts in file $INFILE"

for host in `$CAT $INFILE`
do
    print_banner
	$ECHO "`${DATE} +%Y%m%d-%H:%M:%S` INFO: stopping ${P_NAME} on $host"
	$SSH $SSHOPTIONS $host "$REMOTE_STOP_CMD" 2>/dev/null
	
    # skip trying to connect after ssh timeout
	if [ $? -ne 0 ]
		then
		$ECHO "`${DATE} +%Y%m%d-%H:%M:%S` WARN: unable to connect to $host, skipping and moving to next host	"
		continue
	fi
	
    $ECHO "`${DATE} +%Y%m%d-%H:%M:%S` INFO: waiting for ${RESTART_SLEEP} seconds before starting ${P_NAME}"  
    ${SLEEP} ${RESTART_SLEEP}
    
	$ECHO "`${DATE} +%Y%m%d-%H:%M:%S` INFO: starting ${P_NAME} on $host"
	$SSH $SSHOPTIONS $host "$REMOTE_START_CMD"
    
    #now that a single host is done, begin countdown
    countdown
    
    let numofhosts-=1
    $ECHO "`${DATE} +%Y%m%d-%H:%M:%S` INFO: remaining hosts $numofhosts"
    percent $numofhosts
    
    elapsed_minutes=$(echo "scale=2; $SECONDS/60" | bc)    
    $ECHO "`${DATE} +%Y%m%d-%H:%M:%S` INFO: minutes elapsed $elapsed_minutes"
            
done

$ECHO "`${DATE} +%Y%m%d-%H:%M:%S` INFO: stopping script at `$DATE`"

# Another possible countdown() function in case the above one is not suitable
# This one displays output in format 10..9..8..7..6
#function countdown(){
#    seconds=$SLEEP_TIME
#    since=$(date +%s)
#    remaining=$seconds
#    while (( $remaining >= 1 ))
#    do
#        $ECHO -n "`${DATE} +%Y%m%d-%H:%M:%S` $remaining.."
#        sleep 1
#        remaining=$(( $seconds - $(date +%s) + $since ))
#    done
#    if [ $remaining -eq '0' ]
#        then
#        $ECHO -e
#    fi
#}
