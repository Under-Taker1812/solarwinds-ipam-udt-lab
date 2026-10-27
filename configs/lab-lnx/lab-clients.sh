#!/bin/bash
# Rebuilds the six simulated clients (network namespaces + macvlan) on LAB-LNX.
# Install: /usr/local/sbin/lab-clients.sh, chmod +x. Tested after a snapshot rollback.
#
#   c1..c4  VLAN 50 (tagged, behind the SRX220 firewall) 192.168.50.{11,12,131,132}
#   c5      VLAN 20 (untagged), address from DHCP via the relay on GW-BENCH
#   c7      VLAN 20, static 203.0.113.50 (simulated public host, no NAT)
NIC=ens33          # NIC1, attached to VMnet10 (the USB Ethernet adapter)
ips=(192.168.50.11 192.168.50.12 192.168.50.131 192.168.50.132)

for ns in c1 c2 c3 c4 c5 c7; do ip netns del $ns 2>/dev/null; done
ip link del $NIC.50 2>/dev/null
ip link set $NIC up

# VLAN 50 sub-interface (tagged), used by c1..c4
ip link add link $NIC name $NIC.50 type vlan id 50
ip link set $NIC.50 up
for i in 1 2 3 4; do
  ip netns add c$i
  ip link add mv$i link $NIC.50 type macvlan mode bridge
  ip link set mv$i netns c$i
  ip netns exec c$i ip addr add ${ips[$((i-1))]}/24 dev mv$i
  ip netns exec c$i ip link set mv$i up
  ip netns exec c$i ip route add default via 192.168.50.1
done

# c5: untagged VLAN 20, DHCP from DC01 through the relay
ip netns add c5
ip link add mv5 link $NIC type macvlan mode bridge
ip link set mv5 netns c5
ip netns exec c5 ip link set mv5 up
ip netns exec c5 dhclient -pf /run/dhclient-c5.pid -lf /var/lib/dhcp/dhclient-c5.leases mv5

# c7: simulated public host, attached directly (no NAT)
ip netns add c7
ip link add mv7 link $NIC type macvlan mode bridge
ip link set mv7 netns c7
ip netns exec c7 ip addr add 203.0.113.50/24 dev mv7
ip netns exec c7 ip link set mv7 up
