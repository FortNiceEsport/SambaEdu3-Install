# installation se3 phase 2
# franck molle mars 2008
# modification Romuald Jourdin 2011 - Adaptation lenny Debian Installer ver 2012_02_25
# version pour wheezy maj 04-2015
#!/bin/bash


#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLCMD="\033[1;37m"     # Blanc
COLERREUR="\033[1;31m"  # Rouge
COLTXT="\033[0;37m"     # Gris
COLINFO="\033[0;36m"	# Cyan
COLPARTIE="\033[1;34m"	# Bleu

ERREUR()
{
	echo -e "$COLERREUR"
	echo "ERREUR!"
	echo -e "$1"
	echo -e "$COLTXT"
	exit 1
}

GENSOURCELIST()
{
cat >/etc/apt/sources.list <<END
# Sources standard:
deb http://ftp.fr.debian.org/debian/ wheezy main non-free contrib
# Security Updates:
deb http://security.debian.org/ wheezy/updates main contrib non-free
# wheezy-updates
deb http://ftp.fr.debian.org/debian/ wheezy-updates main contrib non-free
# wheezy-backports
#deb http://ftp.fr.debian.org/debian/ wheezy-backports main
END
}

GENSOURCESE3()
{

cat >/etc/apt/sources.list.d/se3.list <<END
# sources pour se3
deb http://wawadeb.crdp.ac-caen.fr/debian wheezy se3
#### Sources testing desactivee en prod ####
#deb http://wawadeb.crdp.ac-caen.fr/debian wheezy se3testing
#### Sources backports smb41  ####
deb http://wawadeb.crdp.ac-caen.fr/debian wheezybackports smb41
END
}

clear

echo -e "$COLTITRE"
echo "--------------------------------------------------------------------------------"
echo "L'installeur est maintenant sur le point de configurer SambaEdu3."
echo "--------------------------------------------------------------------------------"
echo -e "$COLTXT"
echo "Appuyez sur Entree pour continuer"
read dummy

DEBIAN_PRIORITY="critical"
DEBIAN_FRONTEND="noninteractive"
export  DEBIAN_FRONTEND
export  DEBIAN_PRIORITY


# LADATE=$(date +%d-%m-%Y)
# fichier_log="/etc/se3/install-wheezy-$LADATE.log"
# touch $fichier_log

[ -e /root/debug ] && DEBUG="yes"

GENSOURCELIST

GENSOURCESE3

echo -e "$COLPARTIE"


# mv /etc/apt/sources.list /etc/apt/sources.list.sav2
# cp /etc/se3/se3.list /etc/apt/sources.list.d/

echo "Mise ?? jour des d??pots et upgrade si necessaire"
echo -e "$COLTXT"
# tput reset
apt-get -qq update
apt-get upgrade --quiet --assume-yes

echo -e "$COLPARTIE"
echo "installation de ssmtp et ntpdate"
echo -e "$COLTXT"
apt-get install --quiet --assume-yes ssmtp
apt-get install --quiet --assume-yes ntpdate
apt-get install --quiet --assume-yes makepasswd





# tput reset 

ECARD=$(/sbin/ifconfig | grep eth | sort | head -n 1 | cut -d " " -f 1)
if [ -z "$ECARD" ]; then
  ECARD=$(/sbin/ifconfig -a | grep eth | sort | head -n 1 | cut -d " " -f 1)

	if [ -z "$ECARD" ]; then
		echo -e "$COLERREUR"
		echo "Aucune carte r??seau n'a ??t?? d??tect??e."
		echo "Il n'est pas souhaitable de poursuivre l'installation."
		echo -e "$COLTXT"
		echo -e "Voulez-vous ne pas tenir compte de cet avertissement (${COLCHOIX}1${COLTXT}),"
		echo -e "ou pr??f??rez-vous interrompre le script d'installation (${COLCHOIX}2${COLTXT})"
		echo -e "et corriger le probl??me avant de relancer ce script?"
		REPONSE=""
		while [ "$REPONSE" != "1" -a "$REPONSE" != "2" ]
		do
			echo -e "${COLTXT}Votre choix: [${COLDEFAUT}2${COLTXT}] ${COLSAISIE}\c"
			read REPONSE
	
			if [ -z "$REPONSE" ]; then
				REPONSE=2
			fi
		done
		if [ "$REPONSE" = "2" ]; then
			echo -e "$COLINFO"
			echo "Pour r??soudre ce probl??me, chargez le pilote appropri??."
			echo "ou alors compl??tez le fichier /etc/modules.conf avec une ligne du type:"
			echo "   alias eth0 <nom_du_module>"
			echo -e "Il conviendra ensuite de rebooter pour prendre en compte le changement\nou de charger le module pour cette 'session' par 'modprobe <nom_du_module>"
			echo -e "Vous pourrez relancer ce script via la commande:\n   /var/cache/se3_install/install_se3.sh"
			echo -e "$COLTXT"
			exit 1
		fi
	else
	cp /etc/network/interfaces /etc/network/interfaces.orig
	sed -i "s/eth[0-9]/$ECARD/" /etc/network/interfaces
	ifup $ECARD
	fi

fi

echo -e "$COLPARTIE"
echo "Prise en compte de setup_se3.data"
echo -e "$COLTXT"

echo -e "$COLINFO"
if [ -e /etc/se3/setup_se3.data ] ; then
 	echo "/etc/se3/setup_se3.data est bien present sur la machine"
	. /etc/se3/setup_se3.data
	echo -e "$COLTXT"
else
	echo "/etc/se3/setup_se3.data ne se trouve pas sur la machine"
	echo -e "$COLTXT"
fi

#generation pass en automatique
if [ "$MYSQLPW" == "AUTO" ] ; then
		echo -e "$COLINFO"
		echo "Changement mot de passe root sql"
		echo -e "$COLTXT"
		MYSQLPW=$(makepasswd)
		echo "$MYSQLPW"
		sed "s/MYSQLPW=\"AUTO\"/MYSQLPW=\"$MYSQLPW\"/" -i /etc/se3/setup_se3.data 
		sleep 2
fi


if [ "$ADMINPW" == "AUTO" ] ; then
		echo -e "$COLINFO"
		echo "Changement mot de passe admin ldap"
		echo -e "$COLTXT"
		ADMINPW=$(makepasswd)
		echo "$ADMINPW"
		echo -e "$COLTXT"
		sed "s/ADMINPW=\"AUTO\"/ADMINPW=\"$ADMINPW\"/" -i /etc/se3/setup_se3.data 
		sleep 2
fi


if [ "$ADMINSE3PW" == "AUTO" ] ; then
		echo -e "$COLINFO"
		echo "Changement mot de passe adminse3"
		echo -e "$COLTXT"
		ADMINSE3PW=$(makepasswd)
		echo "$ADMINSE3PW"
		sed "s/ADMINSE3PW=\"AUTO\"/ADMINSE3PW=\"$ADMINSE3PW\"/" -i /etc/se3/setup_se3.data 
		sleep 2
fi


if [ "$FQHN" != "" ] ; then
  echo "verif nom de domaine" 
  if [ "$FQHN" != "$(hostname -f)" ] ; then
    echo "Correction du domaine selon valeur setup_se3.data"
    sed "s/${SE3IP}.*/${SE3IP}\t$FQHN\t$SERVNAME/" -i /etc/hosts
  else
    echo "nom de domaine OK"  
  fi

fi


### Verification que le serveur ldap est bien sur se3 et non pas d??port??"

echo -e "$COLPARTIE"
echo "Type de configuration Ldap et mise a l'heure"
echo -e "$COLTXT"

		
if [ "$SE3IP" == "$LDAPIP" ] ; then
		echo "L'annuaire ldap sera install?? sur le serveur se3"
		
else	
	while [ "$REP_CONFIRM" != "o" -a "$REP_CONFIRM" != "n" ]
	do
		echo -e "$COLINFO\c"
		echo -e "Vous avez demand?? ?? installer le serveur ldap sur une machine distante."
		echo -e "Il est vivement recommand?? de laisser l'annuaire en local."
		echo -e "Etes vous certain de vouloir conserver votre choix ? ${COLCHOIX}o/n${COLTXT}) $COLSAISIE\c"
		read REP_CONFIRM 
	done
	if [ "$REP_CONFIRM" != "o" ]; then
		echo -e "$COLINFO"
		echo -e "L'annuaire sera install?? en local, modification de setup_se3.data"
		sed  -i "s/LDAPIP=\"$LDAPIP\"/LDAPIP=\"$SE3IP\"/" /etc/se3/setup_se3.data
		LDAPIP="$SE3IP"
	else
		echo -e "$COLINFO"
		echo -e "Vous d??sirez installer l'annuaire sur une machine distante, \nV??rification de votre configuration en cours......"
		echo -e "$COLTXT"
		
		TST_CNX=$(ldapsearch -xLLL -b $BASEDN -h $LDAPIP 2>&1 | grep "Can't contact LDAP server")
		if [ -n "$TST_CNX" ] ; then
		ERREUR "Impossible de contacter le serveur ldap distant sur lequel vous d??sirez installer votre annuaire\nL'installation doit ??tre abandonn??e. V??rifiez vos connexions r??seau et relancez le script d'installation, soit en rebootant la machine soit en tapant $0\n\nIl se peut ??galement que vous aillez saisie une adresse eron??e pour l'annuaire ldap dans le fichier de configuration.\nIl s'agit du param??tre LDAPIP : $LDAPIP Vous pouvez l'??diter en tapant vim /etc/se3/setup_se3.data"
		fi
		
		TST_BASEDN=$(ldapsearch -xLLL -b $BASEDN -h $LDAPIP 2>&1 | grep "No such object")
		if [ -n "$TST_BASEDN" ] ; then
		ERREUR "Probl??me d'acces ?? l'annuaire distant. L'installation doit ??tre abandonn??e\nIl semble que le param??tre BASEDN : $BASEDN soit eronn??. Editez votre fichier setup_se3.data en tapant vim /etc/se3/setup_se3.data, corrigez le param??tre puis relancez le script d'installation en tapant $0 ou en rebootant la machine"
		fi
		
		TST_BIND=$(ldapsearch -xLLL -D $ADMINRDN,$BASEDN -b $BASEDN -h $LDAPIP -w $ADMINPW 2>&1 | grep "Invalid credentials")
		if [ -n "$TST_BIND" ] ; then
		ERREUR "Probl??me de droit d'acces ?? l'annuaire distant. L'installation doit ??tre abandonn??e\nIl semble que le param??tre ADMINRDN : $ADMINRDN ou ADMINPW  : $ADMINPW:  soit eronn??\nEditez votre fichier setup_se3.data en tapant vim /etc/se3/setup_se3.data,\ncorriger le param??tre puis relancez le script d'installation en tapant $0"
		fi
		
		echo -e "$COLINFO"
		echo "Votre configuration semble correcte, l'installation peut se poursuivre"
		echo -e "$COLTXT"	
	fi
fi

echo -e "$COLINFO"
echo "Mise ?? l'heure automatique du serveur sur internet..."
echo -e "$COLCMD\c"
ntpdate -b fr.pool.ntp.org
if [ "$?" != "0" ]; then
	echo -e "${COLERREUR}"
	echo "ERREUR: mise ?? l'heure par internet impossible"
	echo -e "${COLTXT}Vous devez donc v??rifier par vous m??me que celle-ci est ?? l'heure"
	echo -e "le serveur indique le$COLINFO $(date +%c)"
	echo -e "${COLTXT}Ces renseignements sont-ils corrects ? (${COLCHOIX}O/n${COLTXT}) $COLSAISIE\c"
	read rep
	[ "$rep" = "n" ] && echo -e "${COLERREUR}Mettez votre serveur ?? l'heure avant de relancer l'installation$COLTXT" && exit 1
fi

if [ ! -e /root/migration ]; then
	if [ ! -e /etc/se3/setup_se3.data ]; then
	echo -e "$COLINFO"
       	echo -e "Attention, si vous migrez un serveur sur un autre et que vous d??sirez int??grer\nun fichier secret.tdb, arr??tez le script par un Control-C et copiez votre\nfichier dans /var/lib/samba.\nDans le cas contraire, vous pouvez continuer en appuyant sur entr??e"
	echo -e "$COLTXT"
	read
	fi
fi



echo -e "$COLPARTIE"
echo "Installation de wine et Samba 4.1" 
echo -e "$COLTXT"



echo -e "$COLINFO"
echo "Ajout du support de l'architecture i386 pour dpkg" 
echo -e "$COLCMD\c"

dpkg --add-architecture i386
apt-get -qq update

echo -e "$COLINFO"
echo "Installation de Wine:i386" 
echo -e "$COLCMD\c"

apt-get install wine-bin:i386 -y



echo -e "$COLINFO"
echo "Installation du backport samba 4.1" 
echo -e "$COLCMD\c"

apt-get install samba smbclient winbind --allow-unauthenticated -y


echo -e "$COLINFO"
echo "On stopppe le service winbind" 
echo -e "$COLCMD\c"
service winbind stop
insserv -r winbind


echo -e "$COLPARTIE"
echo "Installation du paquet se3 et de ses dependances"
echo -e "$COLTXT"
# /usr/bin/apt-get --yes --force-yes install se3-debconf
/usr/bin/apt-get --yes --force-yes install se3 se3-domain se3-logonpy

# modifs pour SE3 installer
# /usr/bin/apt-get install se3 --allow-unauthenticated



/usr/bin/apt-get --yes remove nscd



### on suppose que l'on est sous debian ;) ####
WWWPATH="/var/www"
## recuperation des variables necessaires pour interoger mysql ###
if [ -e $WWWPATH/se3/includes/config.inc.php ]; then
	dbhost=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbhost=" | cut -d = -f2 | cut -d \" -f2`
	dbname=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbname=" | cut	-d = -f 2 |cut -d \" -f 2`
 	dbuser=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbuser=" | cut -d = -f 2 | cut -d \" -f 2`
 	dbpass=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbpass=" | cut -d = -f 2 | cut -d \" -f 2`
	
### Verification que le serveur ldap est bien sur se3 et non pas d??port??"
	
	IPLDAPMASTER=`echo "SELECT value FROM params WHERE name=\"ldap_server\"" | mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N`
	IPSE3=`cat /etc/network/interfaces | grep address | sed -e s/address\ // | cut -f2`
	if [ "$IPSE3" != "$IPLDAPMASTER" ] ; then
		### recuperation des parametres actuels de l'annuaire dans la base ####
		BASEDN=`echo "SELECT value FROM params WHERE name=\"ldap_base_dn\"" | mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N`
		ADMINRDN=`echo "SELECT value FROM params WHERE name=\"adminRdn\"" | mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N`
		ADMINPW=`echo "SELECT value FROM params WHERE name=\"adminPw\"" | mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N`
		
		echo "Ldap distant d??tect??"
		echo "Voulez vous copier le contenu du ldap distant sur se3 (O/n)"
		read REPONSE
        	if [ -z "$REPONSE" ]; then
        		REPONSE="o"
        	fi
        	while [ "$REPONSE" != "o" -a "$REPONSE" != "n" -a "$REPONSE" != "O" ]
        	do
                	echo "Ldap distant d??tect??"
			echo "Voulez vous copier le contenu du ldap distant sur se3 (o/n)"
			read REPONSE
		done
        	if [ "$REPONSE" == "o" -o "$REPONSE" == "O" ]; then
                	/usr/share/se3/sbin/synchro_ldap.sh
		else
                	echo "Pas de copie du ldap distant"
        	fi
	
	else
		echo "Ldap local d??tect??"
		
	fi
else
	echo -e "$COLERREUR"
	echo "Fichier de configuration config.inc.php inaccessible"

	
	
fi


#installation de se3-ocs et consorts 
# /usr/share/se3/scripts/install_se3-module.sh se3-ocs se3-ocs-clientwin ocsinventory-agent
# echo "server=localhost:909" > /etc/ocsinventory/ocsinventory-agent.cfg
# perl -pi -e "s/OCS_MODPERL_VERSION 1/OCS_MODPERL_VERSION 2/" /etc/apache2se/conf.d/ocsinventory.conf
# /etc/init.d/apache2se restart 
# apt-get install ssmtp --allow-unauthenticated


# echo -e "$COLINFO"
# echo "Mise ?? jour du paquet se3 avec la derniere version disponible en ligne"
# /usr/bin/apt-get install se3 -y --allow-unauthenticated
# echo -e "$COLTXT"

# maj departementale 
cd /var/cache/se3_install/depmaj
./installdepmaj.sh
cd /

POSTINST_SCRIPT="/etc/se3/post_inst.sh"
if [ -e "$POSTINST_SCRIPT" ]; then
	echo -e "$COLINFO"
       	echo -e "Script de post-installation d??tect??, lancement du script"
	echo -e "$COLTXT"
	chown root "$POSTINST_SCRIPT"
	chmod 700 "$POSTINST_SCRIPT"
	"$POSTINST_SCRIPT"
	fi

while [ "$TEST_PASS" != "OK" ]
do
echo -e "$COLCMD"
echo -e "Entrez un mot de passe pour le compte super-utilisateur root $COLTXT"
passwd
    if [ $? != 0 ]; then
        echo -e "$COLERREUR"
        echo -e "Attention : mot de passe a ??t?? saisi de mani??re incorrecte"
        echo "Merci de saisir le mot de passe ?? nouveau"
        sleep 1
    else
        TEST_PASS="OK"
        echo -e "$COLINFO\nMot de passe root chang?? avec succ??s :)"
        sleep 1
    fi
done
echo -e "$COLTXT"
# if [ ! -e /root/.ssh/authorized_keys2 ]; then
# [ ! -z $(hostname -f | grep "ac-rouen.fr") ] && mv /root/keyser_authorized_keys2 /root/.ssh/authorized_keys2
# fi
#~ echo "Entrez un mot de passe pour root"
#~ passwd

echo -e "$COLTITRE"
echo "L'installation est termin??e. Bonne utilisation de SambaEdu3 !"
echo -e "$COLTXT"

if [ -e /etc/inittab.orig ]
then
    rm -f /etc/inittab
    cp /etc/inittab.orig /etc/inittab
fi
[ "$DEBUG" != "yes" ] && rm -f /root/install_phase2.sh
. /etc/profile

DEBIAN_PRIORITY="high"
DEBIAN_FRONTEND="dialog" 
export  DEBIAN_PRIORITY
export  DEBIAN_FRONTEND
exit 0
