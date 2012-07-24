#!/bin/sh

DATABASE=/var/lib/oml2/4.sq3

BRIDGE_DIR="$( cd "$( dirname "$0" )" && pwd )"
TOP_DIR=$BRIDGE_DIR/../..

cd $TOP_DIR
ruby -I lib example/bridge/viz_server.rb -e production -p 80 -l /tmp/bridge_server.log -P /tmp/bridge.pid --oml-database $DATABASE -d $*