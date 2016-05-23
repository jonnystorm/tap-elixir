#!/bin/bash

ip link add dev br0 type bridge

ip link set up dev br0
ip link set up dev tap0
ip link set up dev tap1

ip link set master br0 dev tap0
ip link set master br0 dev tap1

