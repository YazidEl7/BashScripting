#!/bin/bash
# Please report any errors with screenshots, for improvement purpose
																					
#############				HTTPS Configuration					############
###################################################################################################################
#################################		Header			###########################################
function Header {
	echo "***					  	  ***"
	echo "*****************************************************"
	echo "*** 		$1 		  ***"
	echo "*****************************************************"
	echo "***					  	  ***"
}
#################################		Three			##########################################
function Three {
	
	for var in "$@"
	do
   	echo "***	$var"
	done
}
#################################		Line			##########################################
function Line {
	echo "***					  	  ***"
	echo "*****************************************************"
}
#########################			Question			##################################
function Question {
	echo "*** 		$1"
}
############################			Interface_File			##################################
function Interface_File {
	if [ $1 == 1 ]
		then
		printf "TYPE=Ethernet\nDEVICE=$2\nBOOTPROTO=dhcp\nONBOOT=yes\nNAME=$2\n" >> /etc/sysconfig/network-scripts/ifcfg-$2

	elif [ $1 == 2 ]
		then
		printf "TYPE=Ethernet\nDEVICE=$2\nBOOTPROTO=static\nONBOOT=yes\nNAME=$2\nIPADDR=$3\nNETMASK=$4\nPREFIX=$5\nGATEWAY=$6\nDNS1=$7\n" >> /etc/sysconfig/network-scripts/ifcfg-$2

	fi	
}
############################			Http_Redirection			##########################
function Http_Redirection {
	Redirection_File="/etc/httpd/conf.d/redirect_http.conf"
	printf "<VirtualHost _default_:80>\nServername $1\nRedirect permanent / https://$1/\n</VirtualHost>\n" > $Redirection_File
}
############################			start_enable				##########################
function start_enable {
	Started=$(systemctl start $1 2> /dev/null; echo $?)
	Enabled=$(systemctl enable $1 2> /dev/null; echo $?)
	if [ $Started == 0 ] && [ $Enabled == 0 ]
	then
		S=$2

	elif [ $Started == 0 ] && [ $Enabled != 0 ]
	then
		Three "Error while enabling the $1 service !! "

	elif [ $Started != 0 ] && [ $Enabled == 0 ]
	then
		Three "Error while starting the service !! " "Fix the problem and start the script again, choose step 2 !!"

	else
		Three "Failed to start and enable the service !! " "Fix the problem and start the script again, choose step 2 !!"
	fi
}
###############################################################################################################

Header "HTTPS Configuration"
Three "1 - Configuring Network interface" "2 - Configuring HTTP" "3 - Configuring Firewall" 
Header "Ethernet Status"
read -p "***	Enter step number then press [Enter]: " S

###############################################################################################################
####################            Configuring Network Interface             #####################################
if [ $S == 1 ]
then

	printf "***	"; nmcli device status | head -n 1 
	Count_Devices=$(nmcli device status | grep ethernet | wc -l)
	
	for (( j=1; j<=$Count_Devices; j++ ))
	do
	printf "***	"; nmcli device status | grep ethernet | cut -d $'\n' -f $j
	done

Line
	Question "is there a disconnected device you'd like to configure ?"
	read -p "***	type yes/no and press [Enter]: " Answer
Line
set +m; shopt -s lastpipe

# Using nmcli to get ethernet configured and not configured devices, cuz the new ones won't have a file at /network-scripts/
Interfaces=($(nmcli device status | grep ethernet | cut -d " " -f 1 ))             ##

: 'Now we should check if their files existed upon modification, the /network-scripts/ will have files ordered by connection name and the nmcli will have it ordered by device name, and we won t always find a device and its name same '
##FEx=($(cat /etc/sysconfig/network-scripts/ifcfg-* | grep DEVICE | cut -d "=" -f 2))##
##FEx2=($(cat /etc/sysconfig/network-scripts/ifcfg-* | grep NAME | cut -d "=" -f 2))##

FilesNames=($(ls /etc/sysconfig/network-scripts/ifcfg-* | cut -d "-" -f 3 ))

# nmcli connection
T=0	# Modification Loop
j=0	# initialisation
i=0	# initialisation

# putting the number of ethernet devices in variable "i"
i=$Count_Devices 

##echo $((3 == $i))## statement eval
#################################################################################################
#####################	Looping To Modify interfaces configs 	#################################
TT=0 # Outer loop will give second chances if invalid interface choices has been chosen
while [ "$TT" -ne 1 ]
do
while [ "$T" -ne 1 ]
do
	#####################################################################

	if [ "$Answer" == "yes" ]
	then
	Three "Choose an interface :"	

		#############################################################	

		for (( j=0; j<$i; j++ ))
		do
		Three "$j- ${Interfaces[$j]}"
		done

   		#############################################################

	Three " "
	read -p "***	Enter its number (ex: 2) : " InterfaceNum

		#############################################################

		if [ $InterfaceNum -lt $i ]
		then
		Three " " "- ${Interfaces[$InterfaceNum]}"

			#####################################################
			# Checking if the choosed interface got already a file so that we remove it and create a new one
			
			for (( j=0; j<$i; j++))
			do
				DIR="/etc/sysconfig/network-scripts/ifcfg-${FilesNames[$j]}"

				if [ -f "$DIR" ]
				then
				File_Device=$(cat "/etc/sysconfig/network-scripts/ifcfg-${FilesNames[$j]}" | grep DEVICE | cut -d "=" -f 2) 

					if [ "${Interfaces[$InterfaceNum]}" == "$File_Device" ]
					then
					Three "File Name	${FilesNames[$j]} "
					Devices_File=${FilesNames[$j]} 
					rm "/etc/sysconfig/network-scripts/ifcfg-${FilesNames[$j]}"    ##
					fi
				fi
			done
			#####################################################
			Three "Choose :" "		1 - DHCP " "		2 - Static " " "
			K=0
			while [ $K -ne 1 ]
			do
				read -p "***	Type 1/2 and press [ENTER] : " BootProtocol
				touch "/etc/sysconfig/network-scripts/ifcfg-$Devices_File"

				if [ $BootProtocol == 1 ]
					then
					Interface_File "1" "$Devices_File"
					K=1
			
				elif [ $BootProtocol == 2 ]
					then
					read -p "Type IP Address and press [ENTER] : " IP_Adress
					read -p "Type Network Mask [ENTER] (ex: 255.255.255.0): " Net_Mask
					read -p "Type IP Prefix and press [ENTER] (ex: 24) : " IP_Prefix
					read -p "Type Gateway's IP Address  and press [ENTER] : " IP_Gateway
					read -p "Type DNS's IP Address and press [ENTER] : " IP_DNS1
					Interface_File "2" "$Devices_File" "$IP_Adress" "$Net_Mask" "$IP_Prefix" "$IP_Gateway" "$IP_DNS1"
					printf "search Space\nnameserver $IP_DNS1\n" | tee /etc/resolv.conf
					K=1
				else 
					Three "Invalid Choice !! " " "
				fi
			done
		else 
			Three "Invalid Choice !! " " "
			break 1
		fi
		#############################################################
	elif [ "$Answer" == "no" ] 
	then
		T=1 
		TT=1
		break 1
	else 
		Three "Invalid Choice !! " " "
		read -p "***	type yes/no and press [Enter]: " Answer
		break 1
	fi
        #####################################################################
Three " "
Question "would you like to configure another device?"
read -p "***		Type yes/no and press [Enter]: " Answer2
Three " "

	if [ "$Answer2" == "yes" ]
		then
		Answer="yes"
	else
		T=1 
		TT=1
	fi
done
done
## End of Modification loop ##
## while loop to keep restarting network manager
Restarted=1
Counter=1
while [ $Restarted -ne 0 ] && [ $Counter -ne 4 ]
do
	Restarted=$(systemctl restart NetworkManager; echo $?)
	Counter=$((Counter+1))
done
	if [ $Restarted -ne 0 ]
	then
	Three "Network Manager hasn't been restarted successfully !!" "We recommend that you fix the problem" "then launch the script again"
	fi
Line
Question "Do you want to Choose another step ? "
read -p "***	Type yes/no [Enter]: " Answer2
	if [ "$Answer2" == "yes" ]
	then
		read -p "***	Enter step number then press [Enter]: " S
		else
		S=2											
	fi
fi
##############################################################################################################
####################        	    Configuring HTTPS    		          ####################################
if [ $S == 2 ]
then
	exist=$((rpm -qa | grep -q httpd && rpm -qa | grep -q mod_ssl); echo $?) 
	if [ $exist == 0 ]
	then
		Three "httpd and mod_ssl are already installed"
	else
		K=0
		while [ $K -ne 1 ]
		do
			Installation_Success=$(dnf install httpd mod_ssl -y 2> /dev/null; echo $?)
			if [ $Installation_Success == 0 ]
			then
				Three "Installation Succeded"
				k=1
			else
				Three "Installation of Failed !! "
			fi
		done

	fi
	start_enable "httpd" 3
	Mod=$(apachectl -M | grep -q ssl; echo $?)
	if [ $Mod != 0 ]
	then		
		Restarted=1
		Counter=1
		while [ $Restarted -ne 0 ] && [ $Counter -ne 4 ]
		do
			Restarted=$(systemctl restart httpd; echo $?)
			Counter=$((Counter+1))
		done
	fi

	if [ $Restarted -ne 0 ]
	then
		Three "httpd hasn't been restarted successfully !!" "We recommend that you fix the problem" "then launch the script again"
	fi
Line
	openssl req -newkey rsa:2048 -nodes -keyout /etc/pki/tls/private/httpd.key -x509 -days 365 -out /etc/pki/tls/certs/httpd.crt
	sed -i 's/SSLCertificateFile \/etc\/pki\/tls\/certs\/localhost.crt/SSLCertificateFile \/etc\/pki\/tls\/certs\/httpd.crt/g' /etc/httpd/conf.d/ssl.conf
	sed -i 's/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/localhost.key/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/httpd.key/g' /etc/httpd/conf.d/ssl.conf

		Restarted=1
		Counter=1
		while [ $Restarted -ne 0 ] && [ $Counter -ne 4 ]
		do
			Restarted=$(systemctl restart httpd; echo $?)
			Counter=$((Counter+1))
		done
read -p "***	Enter the server\'s name [Enter]: " Srvname
Http_Redirection $Srvname

fi
##############################################################################################################
####################        	    Configuring Firewall    	          ####################################
if [ $S == 3 ]
then
	#############################################
	Line
	start_enable "firewalld" 4                       
	#############################################
DefaultZone=$(firewall-cmd --get-default-zone)

#Serv=($(firewall-cmd --list-services))
# firewall-cmd --info-zone=public | grep services

Interfaces=($(firewall-cmd --list-interfaces))

## "i" is the number of active zones
i=$(firewall-cmd --get-active-zones | cut -d " " -f 1 | wc -w)

ActiveZone=($(firewall-cmd --get-active-zones | cut -d " " -f 1))

#--add-interface=
#--change-interface=
#--query-interface=
#--remove-interface=

	################################################################
	############		Active Zones			########
	Header "Active Zones"

	for (( j=0; j<$i; j++ ))
	do
	Zone_Interfaces=($(firewall-cmd --list-interfaces --zone=${ActiveZone[$j]}))
	Three " " "Zone's Name : ${ActiveZone[$j]}, bonded to : ${Zone_Interfaces[@]}"
	done
	################################################################
	############		Default Zone			########

	Three " " "Default Zone : $DefaultZone" " "
	Question "Would you like to change Default zone ? "
	read -p "***	Type yes/no : " Answer
		
		if [ "$Answer" == "yes" ]
		then
		read -p "***	Type zone's name : " Zone_Name
		Changed=$(firewall-cmd --set-default-zone=$Zone_Name --permanent 2>&1 /dev/null; echo $?)
			if [ $Changed == 0 ]
			then
				Three " " "Default Zone changed successfully"
			else
				Three " " "Failed to change Default zone, Might be due to invalid zone name !!"
			fi
		fi
	################################################################
	############		Interfaces Zones		########
	Header "Interface's zones"

	# "i" is the number of interfaces 
	i=$(firewall-cmd --list-interfaces | wc -w)

	for (( j=0; j<$i; j++ ))
	do
		Interfaces_Zone=$(firewall-cmd --get-zone-of-interface=${Interfaces[$j]})
		echo "***	 	"$((j+1))"-" ${Interfaces[$j]} ", Zone : "$Interfaces_Zone
		Allowed_Services=($(firewall-cmd --info-zone=$Interfaces_Zone | grep services))
		Three " " "Zone : $Interfaces_Zone, ${Allowed_Services[@]}" " "
	done
	################################################################
	#####	##	Changing Interfaces Zones		########
	Three " " 
	Question "Would you like to change the zone of an interface ? "
	read -p "***	Type yes/no : " Answer
	k=0
	kk=0
		while [ $k -eq 0 ] || [ $kk -eq 1 ]
		do
		if [ "$Answer" == "yes" ]
		then
			read -p "***	Type zone's name : " Zone_Name
			read -p "***	Type Interface's Name : " Interface_Name
			Changed=$(firewall-cmd --zone=$Zone_Name --change-interface=$Interface_Name --permanent 2>&1 /dev/null; echo $?)
				if [ $Changed == 0 ]
				then
					Three " " "The zone of the interface changed successfully"
				else
					Three " " "Failed to change The zone of the interface, Might be due to invalid zone or interface name !!"
					kk=1
				fi
			k=1
		elif [ "$Answer" == "no" ]
		then
			Three " test"
			k=1
		else
			Three " " "Invalid !!"
		read -p "***	Type yes/no : " Answer
		fi
		done
	################################################################
	###############    Allowing the service  	################
	Header "Allowing service"
	read -p "***	Type the name of zone you wanna add the service to : " Zone_Name
	if [ "$Zone_Name" != '' ]
	then
		Added1=$(firewall-cmd --zone=$Zone_Name --add-service=http --permanent > /dev/null; echo $?)
		Added2=$(firewall-cmd --zone=$Zone_Name --add-service=https --permanent > /dev/null; echo $?)
		Added=$((Added1+Added2)) 
			if [ $Added == 0 ]
			then
				Three " " "Service Added successfully"
			else
				Three " " "Failed to add the service, Might be due to invalid zone name !!"
			fi
	else
		Added1=$(firewall-cmd --add-service=http --permanent > /dev/null; echo $?)
		Added2=$(firewall-cmd --add-service=https --permanent > /dev/null; echo $?)
		Added=$((Added1+Added2)) 
			if [ $Added == 0 ]
			then
				Three " " "Service Added successfully"
			else
				Three " " "Failed to add the service !!"
			fi
	fi   
	firewall-cmd --runtime-to-permanent           
	reloaded=$(firewall-cmd --reload > /dev/null; echo $?)  
		if [ $reloaded == 0 ]
		then
			Three " " "Firewall Reloaded successfully"
			Three "test on a client by typing on a navigator : Https://Server-IP (ex: Https://192.168.23.52)"
		else
			Three " " "Failed to reload firewall !!"
		fi                                                 

fi

	
##############################################################################################################

