#!/bin/bash

DOMAIN=$(hostname -f)
APACHE_LOG_DIR=/var/log/apache2

check_installed() {
    command -v htpasswd &>/dev/null
        if [[ $? -ne 0 ]]; then
            apt install apache2-utils -y
        fi
    which apache2 &>/dev/null
        if [[ $? -ne 0 ]]; then
            apt install apache2 -y
            systemctl enable apache2 && systemctl start apache2
        fi
}
gather_info() {
    clear
    echo "############################################"
    echo "#    Pass-Protect Web Directories Script    #"
    echo "#############################################"
    echo ""
    echo "Enter your name:"
    read username
    echo ""
    echo "Enter a password:"
    read userpass
    echo ""
    echo "Enter the path to your web root directory:"
    read webroot
}
v_host() {
    a2dissite 000-default.conf
    rm -rf /etc/apache2/sites-available/000-default.conf
cat << _EOF_ > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ServerAdmin webmaster@${DOMAIN}
    DocumentRoot ${webroot}
    ErrorLog ${APACHE_LOG_DIR}/${DOMAIN}_error.log
    CustomLog ${APACHE_LOG_DIR}/${DOMAIN}access.log combined

    <Directory "${webroot}">
        AuthType Basic
        AuthName "Restricted Content"
        AuthUserFile /etc/apache2/.htpasswd
        Require valid-user
    </Directory>
</VirtualHost>
_EOF_
a2ensite 000-default.conf
systemctl reload apache2
}
if [[ $EUID -ne 0 ]]; then
    clear
    echo "****** ONLY ROOT CAN RUN THIS SCRIPT! ******"
    sleep 3
    exit 1
fi

check_installed

gather_info

htpasswd -b -c /etc/apache2/.htpasswd ${username} ${userpass}

v_host

sed 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

cat << _EOF_ > ${webroot}/.htaccess
AuthType Basic
AuthName "Restricted Content"
AuthUserFile /etc/apache2/.htpasswd
Require valid-user
_EOF_

systemctl reload apache2
