#!/bin/bash


# configure firewall, DNS and DHCP
# ----------------------------------
firewall-cmd --zone=trusted --change-interface="hashi_network1" --permanent

lxc network set lxdbr0 ipv4.nat false
lxc network set lxdbr0 ipv6.nat false
lxc network set lxdbr0 ipv6.firewall false
lxc network set lxdbr0 ipv4.firewall false
IP_RANGE="10.150.19.1/24"
firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -i lxdbr0 -s $IP_RANGE -m comment --comment "generated by firewalld for LXD" -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 -o lxdbr0 -d $IP_RANGE -m comment --comment "generated by firewalld for LXD" -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i lxdbr0 -s $IP_RANGE -m comment --comment "generated by firewalld for LXD" -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s $IP_RANGE ! -d $IP_RANGE -m comment --comment "generated by firewalld for LXD" -j MASQUERADE
firewall-cmd --reload


# also this?  (can't remember where I saw this)
#echo "net.ipv4.conf.$PARENT_NETWORK.forwarding=1" > /etc/sysctl.conf
