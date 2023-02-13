#!/usr/bin/env bash

# Instalación de MISP-Dashboard para una instalación previa de MISP 2.4 realizada en Ubuntu 18.4.04 LTS Server.
#
# Escenario A: Instalación previa hecha sin el modificador -D o con una versión de INSTALL.sh 2.4.122 o posterior
# que lo inhabilita por defecto.
# 
# Realizado por Enrique Rossel - KMHCORP - 13/3/2020. 
#
#-------------------------------------------------------------------------------------------------|
#
#    20200313: Ubuntu 18.04.4 LTS Server tested and working. -- ER
#
#-------------------------------------------------------------------------------------------------|
#
# Instrucciones de instalación.
#
# El presente script supone la existencia de INSTALL_DEPENDENCIES_MOD.sh en el directorio actual.
# INSTALL_DEPENDENCIES_MOD.sh es una versión modificada del original install_dependencies.sh 
#
# IMPORTANTE!! - Leer y verificar que las variables declaradas (ruta de MISP, usuario de MISP) correspondan con
# la instalación existente.
#
# Ejecutar como usuario sin privilegios:
#
# $ bash INSTALL_MISP_DASHBOARD.sh
#
#-------------------------------------------------------------------------------------------------|
#
#### BEGIN AUTOMATED SECTION ####
#

## Vars Section ##

MISPvars () {
  echo "Creating variables"
  # MISP configuration variables
  PATH_TO_MISP='/var/www/MISP'
  WWW_USER="www-data"

  CAKE="$PATH_TO_MISP/app/Console/cake"

  # sudo config to run $LUSER commands
  SUDO_WWW="sudo -H -u ${WWW_USER} "
}

## End Vars Section ##

## Function Section ##

# Main MISP Dashboard install function
mispDashboard () {
  echo "Install misp-dashboard"
  # Install pyzmq to main MISP venv
  echo "Installing PyZMQ"
  $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install pyzmq
  cd /var/www
  sudo mkdir misp-dashboard
  sudo chown $WWW_USER:$WWW_USER misp-dashboard

  $SUDO_WWW git clone https://github.com/MISP/misp-dashboard.git

  #Línea agregada para sustituir install_dependencies.sh
  sudo cp $HOME/INSTALL_DEPENDENCIES_MOD.sh /var/www/misp-dashboard/install_dependencies.sh

  cd misp-dashboard
  sudo -H /var/www/misp-dashboard/install_dependencies.sh
  sudo sed -i 's/^host\ =\ localhost/host\ =\ 0.0.0.0/g' /var/www/misp-dashboard/config/config.cfg
  sudo sed -i '/Listen 80/a Listen 0.0.0.0:8001' /etc/apache2/ports.conf
  sudo apt install libapache2-mod-wsgi-py3 net-tools -y
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

  # Enable misp-dashboard in apache and reload
  sudo a2ensite misp-dashboard
  sudo systemctl restart apache2

  # Needs to be started after apache2 is reloaded so the port status check works
  $SUDO_WWW bash /var/www/misp-dashboard/start_all.sh

  # Add misp-dashboard to rc.local to start on boot.
  sudo sed -i -e '$i \sudo -u www-data bash /var/www/misp-dashboard/start_all.sh > /tmp/misp-dashboard_rc.local.log\n' /etc/rc.local
}

dashboardCAKE () {
  # Enable ZeroMQ for misp-dashboard
  echo "Enabling ZMQ" 
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_enable" true
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_event_notifications_enable" true
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_object_notifications_enable" true
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_object_reference_notifications_enable" true
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_attribute_notifications_enable" true
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_sighting_notifications_enable" true
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_user_notifications_enable" true
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_organisation_notifications_enable" true
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_port" 50000
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_redis_host" "localhost"
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_redis_port" 6379
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_redis_database" 1
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_redis_namespace" "mispq"
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_include_attachments" false
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_tag_notifications_enable" false
  $SUDO_WWW $CAKE Admin setSetting "Plugin.ZeroMQ_audit_notifications_enable" true
}

## End Function Section ##

### END AUTOMATED SECTION ###

MISPvars
mispDashboard
dashboardCAKE
echo "Done"


