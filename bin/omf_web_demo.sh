#!/bin/sh


TOP_DIR=`ruby -rubygems -e "require 'omf-web/version'; puts OMF::Web::TOP_DIR"`

cd $TOP_DIR
ruby -rubygems $TOP_DIR/example/demo/demo_viz_server.rb $* start