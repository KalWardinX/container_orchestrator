#!/bin/bash

SIMPLE_CONTAINER_ROOT=container_root

mkdir -p $SIMPLE_CONTAINER_ROOT

gcc -o container_prog container_prog.c

## Subtask 1: Execute in a new root filesystem

cp container_prog $SIMPLE_CONTAINER_ROOT/

# 1.1: Copy any required libraries to execute container_prog to the new root container filesystem 
for i in $(ldd ./container_prog | grep -v 'linux-vdso.so' | awk '{ if ($2=="=>") print $3; else print $1}'); do
    dirname=$(dirname "$i")
    filename=$(basename "$i")
    mkdir -p $SIMPLE_CONTAINER_ROOT/$dirname
    cp $i $SIMPLE_CONTAINER_ROOT/$dirname/$filename
done

echo -e "\n\e[1;32mOutput Subtask 2a\e[0m"
# 1.2: Execute container_prog in the new root filesystem using chroot. You should pass "subtask1" as an argument to container_prog
sudo chroot $SIMPLE_CONTAINER_ROOT /container_prog subtask1


echo "__________________________________________"
echo -e "\n\e[1;32mOutput Subtask 2b\e[0m"
## Subtask 2: Execute in a new root filesystem with new PID and UTS namespace
# The pid of container_prog process should be 1
# You should pass "subtask2" as an argument to container_prog
sudo cgcreate -g cpuset:cpuset_limit
sudo cgset -r cpuset.cpus=0 cpuset_limit
sudo cgset -r cpuset.mems=0 cpuset_limit
sudo cgexec -g cpuset:cpuset_limit unshare --pid --uts --fork chroot $SIMPLE_CONTAINER_ROOT /container_prog subtask2
sleep 1
sudo cgdelete cpuset:cpuset_limit

echo -e "\nHostname in the host: $(hostname)"


## Subtask 3: Execute in a new root filesystem with new PID, UTS and IPC namespace + Resource Control
# Create a new cgroup and set the max CPU utilization to 50% of the host CPU. (Consider only 1 CPU core)
sudo cgcreate -g cpuset:cpuset_limit
sudo cgset -r cpuset.cpus=0 cpuset_limit
sudo cgset -r cpuset.mems=0 cpuset_limit

sudo cgcreate -g cpu:cpu_limit
sudo cgset -r cpu.max=50000 cpu_limit


echo "__________________________________________"
echo -e "\n\e[1;32mOutput Subtask 2c\e[0m"
# Assign pid to the cgroup such that the container_prog runs in the cgroup
# Run the container_prog in the new root filesystem with new PID, UTS and IPC namespace
# You should pass "subtask1" as an argument to container_prog
sudo cgexec -g cpuset:cpuset_limit -g cpu:cpu_limit unshare --pid --uts --ipc --fork chroot $SIMPLE_CONTAINER_ROOT /container_prog subtask3

# Remove the cgroup
sudo cgdelete cpu:cpu_limit
sudo cgdelete cpuset:cpuset_limit

# If mounted dependent libraries, unmount them, else ignore
rm -rf $SIMPLE_CONTAINER_ROOT