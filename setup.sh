#!/bin/bash

pacman -Sy
pacman -S --noconfirm ca-certificates-mozilla
pacman -Syu --noconfirm
pacman -S --noconfirm rsync 
useradd -m -s /bin/false mirror
mkdir scripts files logs
chown mirror:users scripts files logs

