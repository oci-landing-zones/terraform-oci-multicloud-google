#!/bin/bash
set -eou

# Define variables (adjust version as desired)
export BASE_DIR="/opt/oracle"
export INSTANT_CLIENT_DIR="instantclient_23_7"
export BASIC_ZIP="instantclient-basic-linuxx64.zip"
export SQLPLUS_ZIP="instantclient-sqlplus-linuxx64.zip"
export TOOLS_ZIP="instantclient-tools-linuxx64.zip"
export ORACLE_DOWNLOAD_URL="https://download.oracle.com/otn_software/linux/instantclient"

# Download Packages
wget ${ORACLE_DOWNLOAD_URL}/${BASIC_ZIP}
wget ${ORACLE_DOWNLOAD_URL}/${SQLPLUS_ZIP}
wget ${ORACLE_DOWNLOAD_URL}/${TOOLS_ZIP}

# Install dependencies
sudo apt install -y alien libaio1 unzip  wget

# Unzip Packages to installation directory
sudo mkdir -p $BASE_DIR
sudo unzip -o $BASIC_ZIP -d $BASE_DIR
sudo unzip -o $SQLPLUS_ZIP -d $BASE_DIR
sudo unzip -o $TOOLS_ZIP -d $BASE_DIR


# Add Instant Client directory to LD_LIBRARY_PATH and PATH for all users
echo "PATH=\"${PATH}:${BASE_DIR}/${INSTANT_CLIENT_DIR}\"" | sudo tee /etc/environment
echo "$BASE_DIR/$INSTANT_CLIENT_DIR" | sudo tee /etc/ld.so.conf.d/oracle-instantclient.conf
sudo ldconfig
echo "Oracle Instant Client installation completed"
