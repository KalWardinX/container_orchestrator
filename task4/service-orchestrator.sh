#!/bin/bash

# Complete this script to deploy external-service and counter-service in two separate containers
# You will be using the conductor tool that you completed in task 3.

# Creating link to the tool within this directory
ln -s ../task3/conductor.sh conductor.sh 2> /dev/null
ln -s ../task3/setup.sh setup.sh 2> /dev/null
echo 'done ln'
# use the above scripts to accomplish the following actions -

# Logical actions to do:
# 1. Build images for the containers
./conductor.sh build ext_serv esfile
./conductor.sh build counter_serv csfile
# echo 'done build'

# 2. Run two containers say es-cont and cs-cont which should run in background. Tip: to keep the container running
#    in background you should use a init program that will not interact with the terminal and will not
#    exit. e.g. sleep infinity, tail -f /dev/null
./conductor.sh run ext_serv es_cont -- 'sleep infinity'&
./conductor.sh run counter_serv cs_cont -- 'sleep infinity'&
# echo 'done run'


# 3. Configure network such that:
#    3.a: es-cont is connected to the internet and es-cont has its port 8080 forwarded to port 3000 of the host
./conductor.sh addnetwork es_cont --internet --expose 8080-3000
echo 'done addnetwork es'

#    3.b: cs-cont is connected to the internet and does not have any port exposed
./conductor.sh addnetwork cs_cont --internet
echo 'done addnetwork cs'

#    3.c: peer network is setup between es-cont and cs-cont
./conductor.sh peer cs_cont es_cont
echo 'done peer'

# 5. Get ip address of cs-cont. You should use script to get the ip address. 
#    You can use ip interface configuration within the host to get ip address of cs-cont or you can 
#    exec any command within cs-cont to get it's ip address.
IP_CS=$(./conductor.sh exec -- cs_cont 'hostname -I' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
echo "Counter Service IP: $IP_CS"
echo 'done IP'

# sleep 10
# 6. Within cs-cont launch the counter service using exec [path to counter-service directory within cs-cont]/run.sh
./conductor.sh exec cs_cont -- /counter-service/counter-service 8080 1 &
echo $?
echo 'done exec cs' 

# 7. Within es-cont launch the external service using exec [path to external-service directory within es-cont]/run.sh
./conductor.sh exec es_cont -- python3 /external-service/app.py http://$IP_CS:8080
echo $?
echo 'done exec es'

# 8. Within your host system open/curl the url: http://localhost:3000 to verify output of the service
# 9. On any system which can ping the host system open/curl the url: `http://<host-ip>:3000` to verify
#    output of the service