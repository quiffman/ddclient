#!/bin/bash

#########################################
##       ENVIRONMENTAL CONFIG          ##
#########################################

# Configure user nobody to match unRAID's settings
usermod -u 99 nobody
usermod -g 100 nobody
usermod -d /home nobody
mkdir /home/nobody
chown -R nobody:users /home/nobody


# Disable SSH
rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh


#########################################
##    REPOSITORIES AND DEPENDENCIES    ##
#########################################

# Repositories
echo 'deb http://archive.ubuntu.com/ubuntu trusty main universe restricted' > /etc/apt/sources.list
echo 'deb http://archive.ubuntu.com/ubuntu trusty-updates main universe restricted' >> /etc/apt/sources.list


# Install Dependencies
apt-get update -qq
apt-get install -qy wget sendmail libio-socket-inet6-perl libio-socket-ssl-perl libnet-libidn-perl libnet-ssleay-perl libsocket6-perl ssl-cert libio-socket-ip-perl libjson-any-perl sendmail-bin sasl2-bin libsasl2-modules

#########################################
## FILES, SERVICES AND CONFIGURATION   ##
#########################################

# Initiate config directory
mkdir -p /config
mkdir -p /ddclient


# Config
cat <<'EOT' > /etc/my_init.d/00_config.sh
#!/bin/bash
# Set cache directory
mkdir -p /config/cache
# Checking if sample configuration exists
if [ -f "/config/sample-etc_ddclient.conf" ]; then
  echo "Sample config exists, nothing to do!"
else
  echo "Sample config dosent exist, creating a new one."
  cp /ddclient/sample-etc_ddclient.conf /config/sample-etc_ddclient.conf
fi
# Create auth file for gmail
if [ -f "/config/gmail.txt" ]; then
  echo "Mail auth-file already in config directory."
else
  echo 'AuthInfo:smtp.gmail.com "U:root" "I:<YOUR_EMAIL>@gmail.com" "P:<YOUR_EMAIL_PASSWORD>"' > /config/gmail.txt
fi
# Setting up pid directory for ddclient
if [ ! -d "/ddclient/pid" ]; then
mkdir -p /ddclient/pid
chown nobody:users /ddclient/pid
fi
#checking crontab if entry to force update exists
if [ -f "/etc/cron.d/ddclient" ]; then
  rm /etc/cron.d/ddclient
fi
if [ -f "/config/ddclient.conf" ]; then
  echo '15 06 * * 1	root    su nobody -s /bin/bash -c "/usr/sbin/ddclient -daemon=0 -syslog -quiet -force -file /config/ddclient.conf -cache /config/cache/ddclient.cache"' > /etc/cron.d/ddclient
fi
# Setting permissions so that host can edit config
chown -R nobody:users /config
EOT


# Mail Config
cat <<'EOT' > /etc/my_init.d/01_mail.sh
#!/bin/bash
# setup mail enviorment if mail is enabled in dicker run
# create gmail authentication file directory
if [ ! -d "/etc/mail/auth" ]; then
  mkdir -m 700 -p /etc/mail/auth
fi
# clear old auth-file and db if user changes password etc..
if [ -f "/etc/mail/auth/auth-info" ]; then
  rm /etc/mail/auth/auth*
fi
# copy user data to the right location
if [ -v "MAIL" ]; then
  cp /config/gmail.txt /etc/mail/auth/auth-info
fi
# create password db
if [ -v "MAIL" ]; then
  makemap hash /etc/mail/auth/auth-info < /etc/mail/auth/auth-info
fi
#generate base gmail sendmail conf
check=$( grep -ic "/auth-info" /etc/mail/sendmail.mc )
if [[ $check -eq 1 && -v "MAIL" ]]; then
  echo "Sendmail is already configured as a gmail-relay"
fi
if [[ $check -eq 0 && -v "MAIL" ]]; then
  echo "Configuring sendmail as a gmail-relay"
  sed -i 's/.*MAILER_DEFINITIONS.*/define(`SMART_HOST'\'',`smtp.gmail.com'\'')dnl\n&/' /etc/mail/sendmail.mc
  sed -i 's/.*MAILER_DEFINITIONS.*/define(`RELAY_MAILER_ARGS'\'', `TCP $h 587'\'')dnl\n&/' /etc/mail/sendmail.mc
  sed -i 's/.*MAILER_DEFINITIONS.*/define(`ESMTP_MAILER_ARGS'\'', `TCP $h 587'\'')dnl\n&/' /etc/mail/sendmail.mc
  sed -i 's/.*MAILER_DEFINITIONS.*/define(`confAUTH_MECHANISMS'\'', `EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN'\'')dnl\n&/' /etc/mail/sendmail.mc
  sed -i 's|.*MAILER_DEFINITIONS.*|FEATURE(`authinfo'\'',`hash /etc/mail/auth/auth-info'\'')dnl\n&|' /etc/mail/sendmail.mc
  sed -i 's/.*MAILER_DEFINITIONS.*/TRUST_AUTH_MECH(`EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN'\'')\n&/' /etc/mail/sendmail.mc
  m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf
fi
# set permissions for db and sendmail
chmod 0600 /etc/mail/auth/*
chmod 0755 / /etc /etc/mail
# Start sendmail service if MAIL varable is set and mail auth file cinfigured
check2=$( grep -ic "YOUR_EMAIL_PASSWORD" /config/gmail.txt )
if [[ $check2 -eq 0 && -v "MAIL" ]]; then
  /etc/init.d/sendmail restart
  sleep 2
else
  echo "Docker is not configured to use email (MAIL) variable or Gmail credentials is not set in mail.txt"
fi
EOT


# ddclient Service
mkdir -p /etc/service/ddclient

cat <<'EOT' > /etc/service/ddclient/run
#!/bin/bash
# ddclient startup service
if [ -f "/ddclient/pid/ddclient.pid" ]; then
  rm /ddclient/pid/ddclient.pid
fi
if [ -v "PIPEWORK" ]; then
  echo "Pipework is enabled waiting for network to come up..."
  pipework --wait
fi
if [ ! -f "/config/ddclient.conf" ]; then
  echo "ddclient.conf does not exist in host directory!!!"
  echo "Rename sample-etc_ddclient.conf to ddclient.conf and configure it or create a new file..."
else
  echo "Configuration exists starting ddclient"
  su nobody -s /bin/bash -c "ddclient -foreground -syslog -pid /ddclient/pid/ddclient.pid -file /config/ddclient.conf -cache /config/cache/ddclient.cache"
fi
EOT



#########################################
##             INTALLATION             ##
#########################################

# Download pipework
wget -O /usr/local/bin/pipework https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework
chmod +x /usr/local/bin/pipework

# Install ddclient
cd /tmp/
wget "http://sourceforge.net/projects/ddclient/files/ddclient/ddclient-3.8.3/ddclient-3.8.3.tar.bz2"
tar -xvf ddclient-3.8.3.tar.bz2
mv ddclient-3.8.3/* /ddclient/
chown -R nobody:users /ddclient
cp /ddclient/ddclient /usr/sbin/

# Make start scripts executable
chmod -R +x /etc/my_init.d/ /etc/service/



#########################################
##              CLEANUP                ##
#########################################

# Clean APT install files
apt-get clean -y
rm -rf /var/lib/apt/lists/* /var/cache/* /var/tmp/*
