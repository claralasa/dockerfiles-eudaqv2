#!/bin/bash

# Wait some time to allow the runControl to wake up

echo "Initializing SERVICE: $1"
if [ "X$1" == "XrunControl" ];
then
    CMD="euRun.exe -a tcp://44000"
elif [ "X$1" == "XlogCollector" ];
then
    sleep 3;
    CMD="euLog.exe -r tcp://172.20.128.2:44000"
elif [ "X$1" == "XdataCollector" ];
then
    sleep 6;
    # Change the uid for the data 
    CMD="euDataCollector.exe -r tcp://172.20.128.2:44000"
elif [ "X$1" == "XonlineMonitor" ];
then
    sleep 10;
    CMD="OnlineMon.exe -tc 0 -sc 0 -r tcp://172.20.128.2:44000";
elif [ "X$1" == "XTestProducer" ];
then
    sleep 20;
    CMD="TestProducer.exe -r tcp://172.20.128.2:44000";
elif [ "X$1" == "XNIProducer" ];
then
    sleep 20;
    CMD="echo 'NOT IMPLEMENTED YET: NIProducer.exe -r tcp://172.20.128.2:44000'";
elif [ "X$1" == "XTLU" ];
then
    # Deal with the permissions for the TLU
    # 1. check if the tlunoroot utility is compiled
    #    otherwise compile it
    TLUCH=$(which tlunoroot)
    if [ "X${TLUCH}" == "X" ]; 
    then
        sudo g++ -o /usr/bin/tlunoroot /eudaq/eudaq/producers/tlu/src/tlunoroot.cxx -lusb
        TLUCH=$(which tlunoroot)
        if [ "X${TLUCH}" == "X" ]; 
        then
            echo "ERROR: the utility tlunoroot NOT has been created!!"
            exit -1;
        fi;
        # Change permissions
        sudo chown root ${TLUCH}
        sudo chmod u+s ${TLUCH}
    fi;
    # 2. Change permissions to the tlu
    ${TLUCH}
    sleep 20;
    CMD="TLUProducer.exe -r tcp://172.20.128.2:44000";
fi

exec ${CMD}
