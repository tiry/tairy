#!/bin/bash

grep -E "DRIVER|PCI_SLOT_NAME" /sys/class/drm/card*/device/uevent
