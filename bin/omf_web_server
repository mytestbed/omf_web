#!/usr/bin/env ruby
# encoding: utf-8
BIN_DIR = File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)
TOP_DIR = File.join(BIN_DIR, '..')
$: << File.join(TOP_DIR, 'lib')

require 'json'
require 'omf-web/thin/server'

DESCR = %{
Start an OMF Web based Visualisation Server
}

opts = {
  #footer_right: "V#{TuhuraViz::VERSION}",
}

OMF::Web::Server.start('omf_web_server', DESCR, TOP_DIR, opts)