Camscan scripts using shodan and censys to gt target ip:port

###################################################
# install the following stuff
# censys_io.py (cp censys_io.py /usr/bin/censys_io.py) 
# GeoLiteCity.dat (
# wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
# gunzip GeoLiteCity.dat.gz
# cp GeoLiteCity.dat /usr/bin/GeoLiteCity.dat
###################################################

#Usage
./camscan.sh -a censys -e -c 500 -d
./camscan.sh -a shodan -e -c 500 -d
./camscan.sh -a single -e -i 193.250.224.180:80
./camscan.sh -e -f <IP:PORT list>

