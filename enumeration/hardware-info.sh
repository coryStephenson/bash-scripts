#! /usr/bin/env bash
# Script originally written by Théo Grébeude (https://github.com/theogrebeude/LinuxInfo.git)
# I started tweaking Evens SOLIGNAC's fork of the original script (https://github.com/slgevens/LinuxInfo.git)

echo "---------------------------"
echo "-----INFO-OS---------------"
echo "---------------------------"
uname -a
release='cat /etc/*-release'
eval $release
echo "---------------------------"
echo "-----INFO-CPU--------------"
echo "---------------------------"
lscpu
more /proc/cpuinfo | grep -m1  "model name"
echo "---------------------------"
echo "-----INFO-RAM--------------"
echo "---------------------------"
awk '$3=="kB"{$2=$2/(1000*1000);$3="GB";} 1' /proc/meminfo  | column -t | grep MemTotal
echo "---------------------------"
echo "-----INFO-GPU--------------"
echo "---------------------------"
test=$(cat /etc/*-release)
if [[ $test == *"raspbian"* ]]
then
	echo "GPU raspberry Pi "
else
	lspci | grep Graphics
fi
echo "---------------------------"
echo "-----INFO-NETWORK----------"
echo "---------------------------"
if [[ $test == *"raspbian"* ]]
then
	echo "reseau raspberry Pi "
else
	lspci | grep "Ethernet controller"
fi
echo ""
ip a
echo "---------------------------"
echo "-----INFO-DISK-------------"
echo "---------------------------"
df -h

echo ""

if [[ $STRING == *"raspbian"* ]]; then
    echo "C'est un pi "
fi
STRING="raspbian"
if grep -q foo <<<$STRING; then
  echo "It's there"
fi
