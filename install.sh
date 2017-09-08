#!/bin/bash

ES_VER="2.4.4"
KB_VER="4.6.6"

# Upgrade Packages
apt-get --yes update
apt-get --yes upgrade

# Install Java
apt-get --yes install openjdk-8-jre

# Cleanup
apt-get --yes autoremove

#
# Make runtime env
#

# Make cache dir in shared drive
mkdir -p /vagrant/cache

# Create /app working dir
rm -rf /app && mkdir /app

#
# Install ES
#

# Downloading version to install
if [ ! -f "/vagrant/cache/elasticsearch-$ES_VER.tar.gz" ]; then
  echo "Downloading Elasticsearch $ES_VER from elastic.co"
  curl -s "https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$ES_VER/elasticsearch-$ES_VER.tar.gz" > "/vagrant/cache/elasticsearch-$ES_VER.tar.gz"
else
  echo "Using cached elasticsearch-$ES_VER.tar.gz from shared folder"
fi

# Extract to app dir
cp "/vagrant/cache/elasticsearch-$ES_VER.tar.gz" "/app/."
( cd /app && tar -xzf "/app/elasticsearch-$ES_VER.tar.gz" )
ln -s "/app/elasticsearch-$ES_VER" "/app/elasticsearch"
mkdir -p "/vagrant/elasticsearch-$ES_VER"

# Copy over configs if they already exist
if [ -d "/vagrant/elasticsearch-$ES_VER/config" ]; then
  echo "Using ES configs from shared folder"
  cp -a "/vagrant/elasticsearch-$ES_VER/config" "/app/elasticsearch/."
fi

# Either copy over plugins or install
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

  echo "Caching ES plugins in shared folder"
  cp -a "/app/elasticsearch/plugins" "/vagrant/elasticsearch-$ES_VER/."
fi

#
# Install Kibana
#

# Downloading version to install
if [ ! -f "/vagrant/cache/kibana-$KB_VER-linux-x86_64.tar.gz" ]; then
  echo "Downloading Kibana $KB_VER from elastic.co"
  curl -s "https://download.elastic.co/kibana/kibana/kibana-$KB_VER-linux-x86_64.tar.gz" > "/vagrant/cache/kibana-$KB_VER-linux-x86_64.tar.gz"
else
  echo "Using cached kibana-$KB_VER-linux-x86_64.tar.gz from shared folder"
fi

# Extract to app dir
cp "/vagrant/cache/kibana-$KB_VER-linux-x86_64.tar.gz" "/app/."
( cd /app && tar -xzf "/app/kibana-$KB_VER-linux-x86_64.tar.gz" )
ln -s "/app/kibana-$KB_VER-linux-x86_64" "/app/kibana"
mkdir -p "/vagrant/kibana-$KB_VER-linux-x86_64"

# Copy over configs if they already exist
if [ -d "/vagrant/kibana-$KB_VER-linux-x86_64/config" ]; then
  echo "Using Kibana configs from shared folder"
  cp -a "/vagrant/kibana-$KB_VER-linux-x86_64/config" "/app/kibana/."
fi

# Either copy over plugins or install
if [ -d "/vagrant/kibana-$KB_VER-linux-x86_64/installedPlugins" ]; then
  echo "Using Kibana plugins from shared folder"
  cp -a "/vagrant/kibana-$KB_VER-linux-x86_64/installedPlugins" "/app/kibana/."
else
  echo "Installing Kibana plugins from provision script"

  KBPLUGINS=()

  # Tools
  KBPLUGINS+=(elastic/sense)

  for P in ${KBPLUGINS[*]}
  do
    /app/kibana/bin/kibana plugin --install $P
  done

  echo "Caching Kibana plugins in shared folder"
  cp -a "/app/kibana/installedPlugins" "/vagrant/kibana-$KB_VER-linux-x86_64/."
fi

# Maybe copy over optimized build artifacts
if [ -d "/vagrant/kibana-$KB_VER-linux-x86_64/optimize" ]; then
  echo "Using pre-optimized Kibana build dir from shared folder"
  cp -a "/vagrant/kibana-$KB_VER-linux-x86_64/optimize" "/app/kibana/."
fi

# Maybe cache optimized build artifacts
if [ ! -d "/vagrant/kibana-$KB_VER-linux-x86_64/optimize" ]; then
  echo "Cacheing optimized Kibana build dir in shared folder"
  cp -a "/app/kibana/optimize" "/vagrant/kibana-$KB_VER-linux-x86_64/."
fi
