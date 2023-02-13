#!/usr/bin/env bash

# Modificación de MISP-Dashboard para una instalación previa de MISP 2.4 realizada en Ubuntu 18.4.04 LTS Server.
#
# Escenario B: Instalación previa realizada con INSTALL.sh versión 2.4.121 o anterior donde se haya hecho uso del
# modificador -D.
# 
# Realizado por Enrique Rossel - KMHCORP - 13/3/2020.
#
#-------------------------------------------------------------------------------------------------|
#
#    20200313: Ubuntu 18.04.4 LTS Server tested and working. -- ER
#
#-------------------------------------------------------------------------------------------------|
#
# Ejecutar como usuario sin privilegios:
#
# $ bash MODIFY_MISP_DASHBOARD.sh
#
#-------------------------------------------------------------------------------------------------|
#
#### BEGIN AUTOMATED SECTION ####
#

## Function Section ##

# MaxMind DB Download

dbdownload () {
cd /var/www/misp-dashboard/
rm -rf data/GeoLite2-City*
mkdir -p data
pushd data
read -p "Please paste your Max Mind License key: " MM_LIC
while [ "$(sha256sum -c GeoLite2-City.tar.gz.sha256 >/dev/null; echo $?)" != "0" ]; do
  echo "Redownloading GeoLite Assets, if this loops, CTRL-C and investigate"
  wget "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=${MM_LIC}&suffix=tar.gz" -O GeoLite2-City.tar.gz
  wget "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=${MM_LIC}&suffix=tar.gz.sha256" -O GeoLite2-City.tar.gz.sha256
  sed -i 's/_.*/.tar.gz/g' GeoLite2-City.tar.gz.sha256
  sleep 3
done
tar xvfz GeoLite2-City.tar.gz
ln -s GeoLite2-City_* GeoLite2-City
rm -rf GeoLite2-City.tar.gz*
popd
}

# MISP Dashboard adding SSL function
addssl () {
  echo "<VirtualHost *:8001>
      ServerAdmin admin@misp.local
      ServerName misp.local

      DocumentRoot /var/www/misp-dashboard

      WSGIDaemonProcess misp-dashboard \
         user=misp group=misp \
         python-home=/var/www/misp-dashboard/DASHENV \
         processes=1 \
         threads=15 \
         maximum-requests=5000 \
         listen-backlog=100 \
         queue-timeout=45 \
         socket-timeout=60 \
         connect-timeout=15 \
         request-timeout=60 \
         inactivity-timeout=0 \
         deadlock-timeout=60 \
         graceful-timeout=15 \
         eviction-timeout=0 \
         shutdown-timeout=5 \
         send-buffer-size=0 \
         receive-buffer-size=0 \
         header-buffer-size=0 \
         response-buffer-size=0 \
         server-metrics=Off

      WSGIScriptAlias / /var/www/misp-dashboard/misp-dashboard.wsgi

      <Directory /var/www/misp-dashboard>
          WSGIProcessGroup misp-dashboard
          WSGIApplicationGroup %{GLOBAL}
          Require all granted
      </Directory>

      SSLEngine On
      SSLCertificateFile /etc/ssl/private/misp.local.crt
      SSLCertificateKeyFile /etc/ssl/private/misp.local.key

      LogLevel info
      ErrorLog /var/log/apache2/misp-dashboard.local_error.log
      CustomLog /var/log/apache2/misp-dashboard.local_access.log combined
      ServerSignature Off
  </VirtualHost>" | sudo tee /etc/apache2/sites-available/misp-dashboard.conf
}


## End Function Section ##

### END AUTOMATED SECTION ###

dbdownload
addssl
echo "Done"


