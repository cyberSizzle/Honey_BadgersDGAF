#!/bin/bash
clear
user=$(id -u)
if [[ $user != 0 ]] ; then
	echo "This program must be run as root... Exiting."
	exit 0
fi
echo
#configure the firewall
/usr/local/sbin/set_fwprofile

#set the trusted hosts file
read -p "What are the trusted hosts? For multiple subets: comma separate them. " trusted
echo $trusted > /home/assessor/trusted.txt
tr ',' '\n' < /home/assessor/trusted.txt > /etc/trusted.hosts
rm /home/assessor/trusted.txt
echo 

#set the target hosts file
read -p "What are the target hosts? For multiple subets: comma separate them. " target
echo $target > /home/assessor/target.txt
tr ',' '\n' < /home/assessor/target.txt > /etc/target.hosts
rm /home/assessor/target.txt
echo 

#set the exclude hosts file
read -p "What are the no strike hosts? For multiple subets: comma separate them. " exclude
echo $exclude > /home/assessor/exclude.txt
tr ',' '\n' < /home/assessor/exclude.txt > /home/assessor/range
grep -v "-" /home/assessor/range > /etc/exclude.hosts

	if [[ $exclude = *"-"* ]] ; then
		grep "-" /home/assessor/range > /home/assessor/range.txt
		nope=$(</home/assessor/range.txt)
		nmap -n -sL $nope | grep "Nmap scan" | cut -d" " -f5 >> /etc/exclude.hosts
	fi

rm /home/assessor/exclude.txt /home/assessor/range*
echo 

#set the firewall rules 
/usr/local/sbin/set_firewall -tt -eh /etc/exclude.hosts
echo 
echo

#establish the interface
ifconfig | grep ":" | cut -f1
echo
read -p "What interface are you working with? " interface
echo 
echo


#set the IP/netmask/gateway
read -p "Enter the IP address: " ips
echo
read -p "Netmask (dotted decimal): " nets
echo 
read -p "Gateway: " gate
echo
ifconfig $interface $ips netmask $nets
route add default gw $gate $interface

#set the DNS 
read -p "Enter the DNS Server IP: " dom
echo -e "search dmss\nnameserver $dom" > /etc/resolv.conf
echo

#set the host name
read -p "Do you want to set a different hostname (y/n)? " hostquest
	if [[ $hostquest == "y" ]]; then
	read -p "Enter the hostname: " hosts
	echo $hosts > /etc/hostname
	fi
echo

#reset the interface
ifconfig $interface down
sleep 5
ifconfig $interface up

#set the MAC
read -p "Do you want to set a different MAC (y/n)? " macquest
	if [[ $macquest == "y" ]]; then
	read -p "Enter the MAC Address: " mac
	ip link set $interface address $mac
	fi
echo

cat /etc/resolv.conf
echo
echo
ifconfig
echo
echo

read -p "What is the working directory's full path? (don't include the trailing '/'): " workdir

mkdir -p $workdir

echo "Now generating the target, alive, and unreachable files..."

#make the targs file
targets=$(</etc/target.hosts)
for i in $targets; do
	nmap -n -sL $i | grep "Nmap scan" | cut -d" " -f5 >> $workdir/targs
done

#make the alives file
fping -aq -f $workdir/targs > $workdir/alives

#make the unreachable file
fping -uq -f $workdir/targs > $workdir/unreachables

echo
echo
echo -e "The target, alives, unreachables files have all been created.\n The firewall rules have been set according to the exclude, target, and trusted hosts input.\n The MAC, Network and Hostname have all been set and Interface cycled so it would take effect."
echo
echo "Good Luck!"











