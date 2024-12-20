#!/bin/bash

# #memo - This script must be run with root privileges

# Store current directory path
INSTALL_DIR=$(pwd)


#####################
### Env variables ###
#####################

# Ensure .env.example exists
if [ ! -f "$INSTALL_DIR/.env.example" ]; then
    echo "Error: $INSTALL_DIR/.env.example does not exist."
    exit 1
fi

# Create .env file from example if it does not exist
if [ ! -f "$INSTALL_DIR/.env" ]; then
    cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
fi


############
### Base ###
############

# Make sure aptitude cache is up-to-date
apt-get update

# Set timezone to UTC (for sync with containers having UTC as default TZ)
timedatectl set-timezone UTC

# Allow using domains as user names
mv /etc/adduser.conf /etc/adduser.conf.orig
cp "$INSTALL_DIR"/conf/etc/adduser.conf /etc/adduser.conf

# Install vnstat (bandwidth monitoring) and PHP cli (for API) and FTP service
apt-get install -y vnstat php-cli vsftpd

# Custom FTP config
mv /etc/vsftpd.conf /etc/vsftpd.conf.orig
cp "$INSTALL_DIR"/conf/etc/vsftpd.conf /etc/vsftpd.conf

# Restart FTP service
systemctl restart vsftpd

# Add logrotate directive for nginx
cp "$INSTALL_DIR"/conf/etc/logrotate.d/nginx /etc/logrotate.d/nginx


######################
### Install Docker ###
######################

apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o docker.gpg
gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg docker.gpg
rm docker.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Update package list and install Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Start docker
systemctl start docker

# Make sure docker starts on boot
systemctl enable docker

# Prepare directory structure
cp -r "$INSTALL_DIR"/docker /home/docker
cp "$INSTALL_DIR"/conf/ssh-login /usr/local/bin/ssh-login
chmod +x /usr/local/bin/ssh-login

mkdir /var/log/nginx

# Create proxy network
docker network create proxynet

# Install OVH real time monitoring
# wget -qO - https://last-public-ovh-infra-yak.snap.mirrors.ovh.net/yak/archives/apply.sh | OVH_PUPPET_MANIFEST=distribyak/catalog/master/puppet/manifests/common/rtmv2.pp bash

# Build docked-nginx image
cd /home/docker/images/docked-nginx/
./build.sh

# Start reverse proxy and let's encrypt companion
docker compose -f /home/docker/nginx-proxy/docker-compose.yml up -d

# wait for the services to be fully started (to prevent following files to be overwritten)
sleep 30

# make sure a default maintenance page is available
cp /home/docker/images/docked-nginx/maintenance.html /srv/docker/nginx/html

# add custom nginx conf in the newly created dir env
cp "$INSTALL_DIR"/conf/nginx.conf /srv/docker/nginx/conf.d/custom.conf
# (#memo - in latest deployments, file was not created automatically by letsencrypt-companion)
mkdir -p /usr/share/nginx/html
mkdir -p /srv/docker/nginx/vhost.d
cp "$INSTALL_DIR"/conf/vhost.d/default /srv/docker/nginx/vhost.d/default

# force nginx to load new config
docker exec nginx-proxy nginx -s reload


####################
### Install cron ###
####################

apt-get install -y cron

PHP_SCRIPT="cron.php"
CRON_CMD="* * * * * cd /root/aru/seru_admin && /usr/bin/php $PHP_SCRIPT"

# Check if the cron job already exists
if ! crontab -l | grep -q "$PHP_SCRIPT"; then
    # If not, add the cron job
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
fi


###################
### Install F2B ###
###################

# Install F2B service (#memo - we need to do this after nginx init since F2B relies on nginx log folder)
apt-get -y install fail2ban
cp "$INSTALL_DIR"/conf/etc/fail2ban/jail.local /etc/fail2ban/jail.local
cp "$INSTALL_DIR"/conf/etc/fail2ban/action.d/* /etc/fail2ban/action.d/
cp "$INSTALL_DIR"/conf/etc/fail2ban/filter.d/* /etc/fail2ban/filter.d/
touch /etc/fail2ban/emptylog

# Make sure fail2ban starts on boot
systemctl enable fail2ban

# Restart fail2ban service
systemctl restart fail2ban


########################
### Install listener ###
########################

# Add a symbolic link for the eQual instance listener service
ln -s /root/aru/seru_admin/host-admin-listener.service /etc/systemd/system/host-admin-listener.service

# Reload daemon
systemctl daemon-reload

# Enable the listener service
systemctl enable host-admin-listener.service

# Start the listener service
systemctl start host-admin-listener.service
