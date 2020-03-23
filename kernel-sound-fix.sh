#!/usr/bin/env bash
set -e

echo "options snd-hda-intel dmic\_detect=0" | sudo tee -a /etc/modprobe.d/alsa-base.conf
echo "blacklist snd\_soc\_skl" | sudo tee -a /etc/modprobe.d/blacklist.conf
