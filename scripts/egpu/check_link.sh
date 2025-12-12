#!/bin/bash 

sudo dmesg | grep PCIe

sudo lspci -vvv -s 01:00.0 | grep LnkSta
