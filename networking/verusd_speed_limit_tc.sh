#!/bin/bash

####
# Script using traffic control/shaping to limit bandwidth
# Useful for seed and other nodes when bandwidth is limited
#### 

# Configuration
IFACE="eth0"         # Replace with system interface if different
PORT="27485"         # Verus P2P port
RATE="50mbit"        # Desired speed rate
BURST="128b"         # Burst rate
CBURST="128b"        # CBurst rate
SFQ_PERTURB="10"     # Seconds between rehashing of flows (prevents hash collisions)

echo "Clearing any existing qdisc..."
sudo tc qdisc del dev $IFACE root 2>/dev/null

echo "Setting up root HTB qdisc..."
sudo tc qdisc add dev $IFACE root handle 1: htb default 30

echo "Creating HTB class with rate limit..."
sudo tc class add dev $IFACE parent 1: classid 1:1 htb rate $RATE ceil $RATE burst $BURST cburst $CBURST

echo "Adding SFQ under the HTB class for fairness..."
sudo tc qdisc add dev $IFACE parent 1:1 handle 10: sfq perturb $SFQ_PERTURB

echo "Adding ipv4 filter for TCP source port $PORT..."
sudo tc filter add dev $IFACE protocol ip parent 1:0 prio 1 u32 \
    match ip protocol 6 0xff \
    match ip sport $PORT 0xffff \
    flowid 1:1

echo "Adding ipv6 filter for TCP source port $PORT..."
sudo tc filter add dev $IFACE protocol ipv6 parent 1:0 prio 2 u32 \
    match ip6 protocol 6 0xff \
    match ip6 sport $PORT 0xffff \
    flowid 1:1

echo "Adding ipv4 filter for TCP destination port $PORT..."
sudo tc filter add dev $IFACE protocol ip parent 1:0 prio 3 u32 \
    match ip protocol 6 0xff \
    match ip dport $PORT 0xffff \
    flowid 1:1

echo "Adding ipv6 filter for TCP destination port $PORT..."
sudo tc filter add dev $IFACE protocol ipv6 parent 1:0 prio 4 u32 \
    match ip6 protocol 6 0xff \
    match ip6 dport $PORT 0xffff \
    flowid 1:1

echo "Done. Showing current tc state:"
sudo tc -s qdisc show dev $IFACE
sudo tc -s class show dev $IFACE
sudo tc -s filter show dev $IFACE
