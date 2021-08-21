#!/bin/bash
#
# Author: Ryan
# https://github.com/ryanc410
# Date: Modified on 08/21/2021

# VARIABLES - fill in these variables before running the script
########################

DOMAIN=
USERNAME=
USERPASS=
WEBROOT=

# DONT CHANGE

APACHE_LOG_DIR=/var/log/apache2

# FUNCTIONS
########################

checkroot()
{
    if [[ $EUID -ne 0 ]]; then
        clear
        echo "Must be root to run this script!"
        sleep 2
        exit 1
    fi
}

header()
{
    clear
    echo "#############################################"
    echo "#    Pass-Protect Web Directories Script    #"
    echo "#############################################"
    echo ""
}

check()
{
    header
    echo "Checking system for required components.."
    sleep 2
    which apache2 &>/dev/null
        if [[ $? -ne 0 ]]; then
            apt install apache2 -y &>/dev/null
            systemctl enable apache2 &>/dev/null && systemctl start apache2 &>/dev/null
        fi
    command -v htpasswd &>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Installing required components.."
            apt install apache2-utils -y &>/dev/null
        fi
        echo "Components installed.."
        sleep 2
}

v_host() 
{
    a2dissite 000-default.conf &>/dev/null
    cat <<- _EOF_ > /etc/apache2/sites-available/$DOMAIN.conf
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    
    ServerAdmin webmaster@${DOMAIN}
    
    DocumentRoot $WEBROOT
    ErrorLog ${APACHE_LOG_DIR}/$DOMAIN_error.log
    CustomLog ${APACHE_LOG_DIR}/$DOMAIN-access.log combined
    <Directory "$WEBROOT">
        AuthType Basic
        AuthName "Restricted Content"
        AuthUserFile /etc/apache2/.htpasswd
        Require valid-user
    </Directory>
</VirtualHost>
_EOF_
a2ensite $DOMAIN.conf &>/dev/null
systemctl reload apache2 &>/dev/null
}

# SCRIPT 
########################

checkroot

check

echo "Generating .htpasswd file now.."
sleep 2
htpasswd -b -c /etc/apache2/.htpasswd $USERNAME $USERPASS &>/dev/null

echo "Creating new virtual host file.."
sleep 2
v_host

echo "Modifying apache2.conf file.."
sleep 2
sed 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf &>/dev/null

echo "Creating .htaccess file.."
sleep 2
cat << _EOF_ > $WEBROOT/.htaccess
AuthType Basic
AuthName "Restricted Content"
AuthUserFile /etc/apache2/.htpasswd
Require valid-user
_EOF_

systemctl reload apache2 &>/dev/null

echo "Script Complete"
sleep 2
