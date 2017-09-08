#!/bin/bash

# Make runtime and data dirs
mkdir -p /var/run/elastic
mkdir -p /var/log/elastic
mkdir -p /var/lib/elastic

# Cleanup log files
rm -rf /var/log/elastic/*

# Symlink logs dir for Kibana
mkdir -p "/vagrant/var/log/elastic/kibana"
ln -s "/vagrant/var/log/elastic/kibana" "/var/log/elastic/kibana"

# Symlink logs dir for ES
for i in $(eval echo "{1..$NUM_NODES}"); do
  mkdir -p "/vagrant/var/log/elastic/es-node-$i"
  ln -s "/vagrant/var/log/elastic/es-node-$i" "/var/log/elastic/es-node-$i"
done

#
# Fix perms so vagrant user can run everything
#
chown -R vagrant: /app
chown -R vagrant: /var/run/elastic
chown -R vagrant: /var/lib/elastic
chown -R vagrant: /var/log/elastic

# Also allow us to lock however much memory we want
ulimit -l unlimited

#
# Start ES servers
#
echo "Starting $NUM_NODES ES nodes with $ES_HEAP_SIZE heap..."
for i in $(eval echo "{1..$NUM_NODES}"); do
  sudo -H -u vagrant env ES_HEAP_SIZE=$ES_HEAP_SIZE /app/elasticsearch/bin/elasticsearch \
    --pidfile "/var/run/elastic/es-node-$i.pid" \
    --daemonize \
    -Dnode.name="es-node-$i" \
    -Dhttp.port="920$i" \
    -Dtransport.tcp.port="930$i" \
    -Dpath.data="/var/lib/elastic/es-node-$i" \
    -Dpath.logs="/var/log/elastic/es-node-$i"
done

#
# Start kibana
#
echo "Starting Kibana..."
sudo -H -u vagrant /app/kibana/bin/kibana &
disown

#
# Wait for ok
#
while true; do
  if ( curl -s -I -XHEAD http://127.0.0.1:9201/ > /dev/null ); then
    break
  fi
  sleep 2
done

while true; do
  if ( curl -s -I -XHEAD http://127.0.0.1:5601/ > /dev/null ); then
    break
  fi
  sleep 2
done

# Maybe cache optimized build artifacts
if [ ! -d "/vagrant/kibana-$KB_VER-linux-x86_64/optimize" ]; then
  echo "Cacheing optimized Kibana build dir in shared folder"
  cp -a "/app/kibana/optimize" "/vagrant/kibana-$KB_VER-linux-x86_64/."
fi

echo "==========================================================="
echo "Elastic Cluster Started!"
echo "  ES is up at     : http://127.0.0.1:9200/_plugin/whatson"
echo "  Kibana is up at : http://127.0.0.1:5600/app/sense"
