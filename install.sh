#!/bin/bash

ES_VER="2.4.4"
NUM_NODES=3
ES_HEAP_SIZE=1G

# Upgrade Packages
apt-get --yes update
apt-get --yes upgrade

# Install Java
apt-get --yes install openjdk-8-jre

# Cleanup
apt-get --yes autoremove

# Open up REST API port
iptables -A INPUT -p tcp --dport 9200 -j ACCEPT

#
# Make runtime env and kill existing nodes
#
mkdir -p /var/run/elasticsearch
mkdir -p /var/lib/elasticsearch
mkdir -p /var/log/elasticsearch
for i in $(eval echo "{1..$NUM_NODES}"); do
  if [ -f "/var/run/elasticsearch/node-$i.pid" ]; then
    pkill -e --pidfile "/var/run/elasticsearch/node-$i.pid"
  fi

  # Make persistent data dir across `vagrant provision es` calls
  mkdir -p "/var/lib/elasticsearch/node-$i"

  # Symlink logs dir
  rm -rf "/var/log/elasticsearch/node-$i"
  mkdir -p "/vagrant/var/log/elasticsearch/node-$i"
  ln -s "/vagrant/var/log/elasticsearch/node-$i" "/var/log/elasticsearch/node-$i"
done
chown -R vagrant: /var/run/elasticsearch
chown -R vagrant: /var/lib/elasticsearch/*
chown -R vagrant: /var/log/elasticsearch/*

# Create /app working dir
rm -rf /app && mkdir /app

# Download ES if we don't already have a copy
if [ ! -f "/vagrant/elasticsearch-$ES_VER.tar.gz" ]; then
  echo "Downloading ES from elastic.co"
  curl -s "https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$ES_VER/elasticsearch-$ES_VER.tar.gz" > "/vagrant/elasticsearch-$ES_VER.tar.gz"
else
  echo "Using ES tar file from shared folder"
fi

#
# Install ES
#
echo "Installing base ES"
cp "/vagrant/elasticsearch-$ES_VER.tar.gz" "/app/."
( cd /app && tar -xzf "/app/elasticsearch-$ES_VER.tar.gz" )
ln -s "/app/elasticsearch-$ES_VER" "/app/elasticsearch"

# Copy over configs if they already exist
if [ -d "/vagrant/elasticsearch-$ES_VER/config" ]; then
  echo "Using ES configs from shared folder"
  cp -a "/vagrant/elasticsearch-$ES_VER/config" "/app/elasticsearch/."
fi

#
# Install ES Plugins
# Either user existing copy in shared dir or install from list
#
if [ -d "/vagrant/elasticsearch-$ES_VER/plugins" ]; then
  echo "Using ES plugins from shared folder"
  cp -a "/vagrant/elasticsearch-$ES_VER/plugins" "/app/elasticsearch/."
else
  echo "Installing ES plugins from provision script"

  ESPLUGINS=()

  # Analysis
  ESPLUGINS+=(analysis-icu)
  ESPLUGINS+=(analysis-kuromoji)
  ESPLUGINS+=(analysis-smartcn)
  ESPLUGINS+=(analysis-stempel)

  # Monitoring
  ESPLUGINS+=(mobz/elasticsearch-head)
  ESPLUGINS+=(polyfractal/elasticsearch-inquisitor)
  ESPLUGINS+=(xyu/elasticsearch-whatson/0.1.4)

  # Extensions
  ESPLUGINS+=(http://xbib.org/repository/org/xbib/elasticsearch/plugin/elasticsearch-langdetect/2.4.4.1/elasticsearch-langdetect-2.4.4.1-plugin.zip)
  ESPLUGINS+=(delete-by-query)
  ESPLUGINS+=(lang-javascript)

  for P in ${ESPLUGINS[*]}
  do
    /app/elasticsearch/bin/plugin install $P
  done

  cp -a "/app/elasticsearch/plugins" "/vagrant/elasticsearch-$ES_VER/."
fi

chown -R vagrant: /app

#
# Start ES
#
echo "Starting $NUM_NODES ES nodes with $ES_HEAP_SIZE heap"

# First allow us to lock how ever much memory we want
ulimit -l unlimited

# Start servers
for i in $(eval echo "{1..$NUM_NODES}"); do
  sudo -H -u vagrant env ES_HEAP_SIZE=$ES_HEAP_SIZE /app/elasticsearch/bin/elasticsearch \
    --pidfile "/var/run/elasticsearch/node-$i.pid" \
    --daemonize \
    -Dnode.name="node-$i" \
    -Dhttp.port="920$i" \
    -Dtransport.tcp.port="930$i" \
    -Dpath.data="/var/lib/elasticsearch/node-$i" \
    -Dpath.logs="/var/log/elasticsearch/node-$i"
done
