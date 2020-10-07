#!/bin/bash

DOMAINFILE="domain.txt"
IPFILE="ip.txt"

if [ ! -f $DOMAINFILE ]; then
    echo > ${DOMAINFILE}
fi
if [ ! -f $IPFILE ]; then
 echo > ${IPFILE}
fi
DOMAIN[2]=""
IP=$(dig @resolver1.opendns.com A myip.opendns.com +short -4)
nbrRow=$(wc -l < ${DOMAINFILE})
IPFILEVAL=$(cat ${IPFILE})

PWDETC="/etc/apache2/sites-available/"
PWDVAR="/var/www/"

help()
{
    echo -e "  updateDomain update all the sub domain registered\n"
    echo -e "\n  updateDomain [username] [password] [domain] add domain and create virtual host for Apache2"
    echo -e "  -show, display all the domain registered\n"
    echo -e "  -h, --help display this help and exit\n"
    exit
}

if [ $# == 3 ] || [ $# == 2 ]; then
    DOMAIN[0]=$1
    DOMAIN[1]=$2
    DOMAIN[2]=$3

    echo ${DOMAIN[0]} ${DOMAIN[1]} ${DOMAIN[2]}  >> ${DOMAINFILE}

    echo -e Line \'${DOMAIN[0]} ${DOMAIN[1]} ${DOMAIN[2]}\' has been added to ${DOMAINFILE}
    
    read pause
    clear
    
    echo -e "Do you want to generate the virtual host associated ? [y/n]"
    read answerVH
    if [[ $answerVH == "y" ]] || [[ $answerVH == "Y" ]]; then

        echo "Alias /${DOMAIN[2]} \"${PWDVAR}${DOMAIN[2]}\"" >> ${DOMAIN[2]}.conf
        echo "<Virtualhost *:80>" >> ${DOMAIN[2]}.conf
        echo "  ServerName ${DOMAIN[2]}" >> ${DOMAIN[2]}.conf
        echo "  ServerAlias  www.${DOMAIN[2]}" >> ${DOMAIN[2]}.conf
        echo "  DocumentRoot ${PWDVAR}${DOMAIN[2]}/" >> ${DOMAIN[2]}.conf
        echo "</Virtualhost>" >> ${DOMAIN[2]}.conf
        sudo mv ${DOMAIN[2]}.conf ${PWDETC}
        echo -e "Virtual host successfully created in ${PWDETC}${DOMAIN[2]}.conf"

        read pause
        clear

        echo -e "Do you want to create the virtual host generated ? [y/n]"
        read answerVHA
        if [[ $answerVHA == "y" ]] || [[ $answerVHA == "Y" ]]; then
            sudo a2ensite ${DOMAIN[2]}.conf
            echo -e "\nVirtual host successfully created"
            
            read pause
            clear

            echo -e "Do you want to restart apache2 now to activate your virtual host ? [y/n]"
            read answerVHA2
            if [[ $answerVHA2 == "y" ]] || [[ $answerVHA2 == "Y" ]]; then
                sudo systemctl reload apache2 
                echo -e "Apache2 successfully reloaded\nVirtual host successfully activated"
            fi
        fi
    fi
    read pause
    clear 

    echo -e "Do you want to generate the root folder associated ? [y/n]"
    read answerVAR
    if [[ $answerVAR == "y" ]] || [[ $answerVAR == "Y" ]]; then
        
        mkdir ${DOMAIN[2]}
        cd ${DOMAIN[2]}
        echo "<!DOCTYPE html>" >> index.html
        echo "<html>" >> index.html
        echo "  <head>" >> index.html
        echo "      <title>Title</title>" >> index.html
        echo "  </head>" >> index.html
        echo "  <body><center>" >> index.html
        echo "      Enjoy" >> index.html
        echo "  </body></center>" >> index.html
        echo "</html>" >> index.html
        cd ..
        sudo mv ${DOMAIN[2]} ${PWDVAR}
        echo -e "Root folder successfully created"

        read pause
        clear
    fi
    exit
fi

if [[ $1 == "" ]]; then
    if [ $nbrRow == 0 ]; then
        echo -e "Nothing to do, '${DOMAINFILE}' is empty"
        exit
    fi
    if [[ $IP == $IPFILEVAL ]]; then
        echo -e "Nothing to do, IP=${IP} is up do date"
        exit
    fi

    echo ${IP} > ${IPFILE}
    for ((i=1; i<=$nbrRow; i++)); do
        line=$(head -n $i ${DOMAINFILE} | tail -n 1)
        USERNAME=$(echo -e $line | awk '{print $1}')
        PASSWORD=$(echo -e $line | awk '{print $2}')
        HOSTNAME=$(echo -e $line | awk '{print $3}')

        curl -s "https://${USERNAME}:${PASSWORD}@domains.google.com/nic/update?hostname=${HOSTNAME}&myip=${IP}"
        echo -e " "$HOSTNAME
    done 
    echo -e "\nDone"
    exit
fi
help