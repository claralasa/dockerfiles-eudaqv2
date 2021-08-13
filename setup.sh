#!/bin/bash

# EUDAQ2 integration docker image setup
# Run it first time to create all the needed
# infrastructure,
#!/bin/bash
# 
# Setup the enviroment to use the EUDAQ2 docker
# container. It will create in the host machine
#  - $HOME/eudaq_data/logs -> the logs files created by the logger
#  - $HOME/eudaq_data/data -> the raw data
#  - $HOME/repos/eudaq     -> the cloned EUDAQ2 source
#  - the docker-compose yaml files 
# 
# clarsa.lasaosa.garcia@cern.ch (CERN/IFCA)
#

# 1. Check it is running as regular user
if [ "${EUID}" -eq 0 ];
then
    echo "Do not run this as root"
    exit -2
fi

# 2. Check if the setup was run:
if [ -e ".setupdone" ];
then
    echo "DO NOT DOING ANYTHING, THE SETUP WAS ALREADY DONE:"
    echo "=================================================="
    cat .setupdone
    exit -3
fi

DOCKERDIR=${PWD}

# 3. Download the code: XXX This can be done in the image actually
CODEDIR=${HOME}/PhD/TESTBEAM_v2/repos/eudaq
mkdir -p ${CODEDIR} && cd ${CODEDIR}/.. ;
if [ "X$(command -v git)" == "X" ];
then
    echo "You will need to install git (https://git-scm.com/)"
    exit -1;
fi

echo "Cloning EUDAQ into : $(pwd)"
git clone https://github.com/claralasa/eudaq.git eudaq

if [ "$?" -eq 128 ];
then
    echo "Repository already available at '${CODEDIR}'"
    echo "Remove it if you want to re-clone it"
else
    # Change to the v2.4.6
    echo "Switch to v2.4.6"
    cd ${CODEDIR} && git checkout v2.4.6
    echo "======================================================="
    echo "If this is for developing purposes, it is convenient to"
    echo "fork the https://github.com/eudaq/eudaq.git into your  "
    echo "github account and perform regular updates:"
    echo "1. Define your github forked repository as origin"
    echo "2. Define the original eudaq repository as upstream"
    echo "3. Perform regularly to keep your repo updated:"
    echo "4.   git pull upstream" 
    echo "======================================================="
    # Copying files for the TLU 
    tar xzf ${DOCKERDIR}/ZestSC1.tar.gz -C ${CODEDIR}
    tar xzf ${DOCKERDIR}/tlufirmware.tar.gz -C ${CODEDIR}
fi

# 3. Fill the place-holders of the .templ-Dockerfile 
#    and .templ-docker-compose.yml and create the needed
#    directories
DATADIR=${HOME}/PhD/TESTBEAM_v2/eudaq_data/data
LOGSDIR=${HOME}/PhD/TESTBEAM_v2/eudaq_data/logs
mkdir -p $DATADIR
mkdir -p $LOGSDIR
cd ${DOCKERDIR}
# -- copying relevant files
for dc in .templ-docker-compose.yml .templ-production.yml .templ-docker-compose.override.yml;
do
    finalf=$(echo ${dc}|sed "s/.templ-//g")
    cp $dc $finalf
    sed -i "s#@CODEDIR#${CODEDIR}#g" $finalf
    sed -i "s#@DATADIR#${DATADIR}#g" $finalf
    sed -i "s#@LOGSDIR#${LOGSDIR}#g" $finalf
done

# 4. Create a .setupdone file with some info about the
#    setup
cat << EOF > .setupdone
EUDAQ2 integration docker image and services
-------------------------------------------
Last setup performed at $(date)
DATA DIRECTORY: ${DATADIR}
LOGS DIRECTORY: ${LOGSDIR}
CODE DIRECTORY: ${CODEDIR}
EOF
cat .setupdone

