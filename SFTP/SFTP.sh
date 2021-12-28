#!/bin/bash
####################################################################################################################																					
#############					SFTP Configuration					############
#############						Root folder of sftp : /Data			############
#############						sftp users group : sftpusers			############
#############						sftp user : mysftpuser				############
#############					Directory of mysftpuser : /Data/mysftpuser/Upload	############
####################################################################################################################
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

	elif [ $1 == 2]
		then
		printf "TYPE=Ethernet\nDEVICE=$2\nBOOTPROTO=static\nONBOOT=yes\nNAME=$2\nIPADDR=$3\nNETMASK=$4\nPREFIX=$5\nGATEWAY=$6\nDNS1=$7\n" >> /etc/sysconfig/network-scripts/ifcfg-$2

	fi	
}
############################			sshd_File_config			##########################
function sshd_File_config {
	printf "Match Group sftpusers\n" >> $1
	printf '%s\n' "ChrootDirectory /Data/%u" >> $1
	printf "AllowTcpForwarding no\nForceCommand internal-sftp\n" >> $1
}
###############################################################################################################

Header "SFTP Configuration"
Three "1 - Configuring Network interface" "2 - Configuring SSH" "3 - Configuring FTP" "4 - Configuring Firewall"
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
Interfaces=($(nmcli device status | grep ethernet | cut -d " " -f 1 ))

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

		if [ $(($InterfaceNum < $i)) ]
		then
		Three " " "- ${Interfaces[$InterfaceNum]}"

			#####################################################
			# Checking if the choosed interface got already a file so that we remove it and create a new one
			
			for (( j=0; j<$i; j++))
			do
				DIR="/etc/sysconfig/network-scripts/ifcfg-${FilesNames[$j]}"

				if [ -f "$DIR" ]
				then
				File_Device=($(cat "/etc/sysconfig/network-scripts/ifcfg-${FilesNames[$j]}" | grep DEVICE | cut -d "=" -f 2)) 

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
			read -p "***	Type 1/2 and press [ENTER] : " BootProtocol
			touch "/etc/sysconfig/network-scripts/ifcfg-$Devices_File"

			if [ $BootProtocol == 1 ]
				then
				Interface_File "1" "$Devices_File"

			elif [ $BootProtocol == 2 ]
				then
				read -p "Type IP Address and press [ENTER] : " IP_Adress
				read -p "Type Network Mask [ENTER] (ex: 255.255.255.0): " Net_Mask
				read -p "Type IP Prefix and press [ENTER] (ex: 24) : " IP_Prefix
				read -p "Type Gateway's IP Address  and press [ENTER] : " IP_Gateway
				read -p "Type DNS's IP Address and press [ENTER] : " IP_DNS1
				Interface_File "2" "$Devices_File" "$IP_Adress" "$Net_Mask" "$IP_Prefix" "$IP_Gateway" "$IP_DNS1"
				printf "search Space\nnameserver $IP_DNS1\n" | tee /etc/resolv.conf
			else 
				Three "Invalid Choice"
				break 1
			fi
		else 
			Three "Invalid Choice"
			break 1
		fi
		#############################################################
	else 
	T=1 
	TT=1
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

systemctl restart NetworkManager
read -p "***	Do you want to Choose another step ? Type yes/no [Enter]: " Answer2
	if [ "$Answer2" == "yes" ]
	then
	read -p "***	Enter step number then press [Enter]: " S
	else
	S=2
	fi
fi
##############################################################################################################
####################        	    Configuring SSH    		          ####################################
if [ $S == 2 ]
then
	dnf install openssh-server -y
	systemctl start sshd
	systemctl enable sshd
	S=3
fi
##############################################################################################################
####################        	    Configuring FTP    		          ####################################
if [ $S == 3 ]
then
	Line
	# Creating SFTP's root folder
	mkdir /Data/ 
	chmod 701 /Data
	# Creating Users
	groupadd sftpusers
	useradd -g sftpusers -d /Upload -s /usr/sbin/nologin mysftpuser
	Three "Type the password you wanna use for \"mysftpuser\""		
	passwd mysftpuser
	mkdir -p /Data/mysftpuser/Upload
	chown -R root:sftpusers /Data/mysftpuser
	chown -R mysftpuser:sftpusers /Data/mysftpuser/Upload
	# Configuring SSH daemon for sftpusers group
	# Add at the end of the file :
	sshd_File_Config "/etc/ssh/sshd_config"

	#################################
	systemctl restart sshd
	S=4
fi
##############################################################################################################
####################        	    Configuring Firewall    	          ####################################
if [ $S == 4 ]
then
	#############################################
	Line
	systemctl enable firewalld                        
	systemctl start firewalld                        
	#############################################
DefaultZone=$(firewall-cmd --get-default-zone)

#Serv=($(firewall-cmd --list-services))
# firewall-cmd --info-zone=public | grep services

Interfaces=($(firewall-cmd --list-interfaces))

## "i" is the number of active zones
i=($(firewall-cmd --get-active-zones | cut -d " " -f 1 | wc -w))

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
		firewall-cmd --set-default-zone=$Zone_Name --permanent
		fi
	################################################################
	############		Interfaces Zones		########
	Header "Interface's zones"

	# "i" is the number of interfaces 
	i=($(firewall-cmd --list-interfaces | wc -w))

	for (( j=0; j<$i; j++ ))
	do
		Interfaces_Zone=($(firewall-cmd --get-zone-of-interface=${Interfaces[$j]}))
		echo "***	 	"$((j+1))"-" ${Interfaces[$j]} ", Zone : "$Interfaces_Zone
		Allowed_Services=($(firewall-cmd --info-zone=$Interfaces_Zone | grep services))
		Three " " "Zone : $Interfaces_Zone, ${Allowed_Services[@]}" " "
	done
	################################################################
	#####	##	Changing Interfaces Zones		########
	Three " " 
	Question "Would you like to change the zone of an interface ? "
	read -p "***	Type yes/no : " Answer
		if [ "$Answer" == "yes" ]
		then
		read -p "***	Type zone's name : " Zone_Name
		read -p "***	Type Interface's Name : " Interface_Name
		firewall-cmd --zone=$Zone_Name --change-interface=$Interface_Name --permanent
		fi
	################################################################
	###############    Allowing the service  	################
	Header "Allowing service"
	read -p "***	Type the name of zone you wanna add the service to : " Zone_Name
	if [ $Zone_Name != '' ]
	then
		firewall-cmd --zone=$Zone_Name --add-service=ssh --permanent 
	else
		firewall-cmd --add-service=ssh --permanent
	fi   
	firewall-cmd --runtime-to-permanent           
	firewall-cmd --reload                                                   

fi

	Three "test on a client by typing : sftp mysftpuser@IP (ex: sftp mysftpuser@192.168.5.5)"
##############################################################################################################





