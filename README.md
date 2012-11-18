# OMF Web

## Installation

    git clone https://github.com/mytestbed/omf_web.git
    cd omf_web
    bundle
    rake install

## Try the simple example

    git init /tmp/foo
    ruby -I lib -rubygems example/demo/demo_viz_server.rb start
    
This will start a web server at port 3000. Point your browser there and you should see somthing like:

![Screenshot of starting page](https://raw.github.com/mytestbed/omf_web/master/doc/screenshot.png "Screenshot")

For additional options start the server with -h.

## What's next

To learn how to use this gem and what is happening under the hood, check out the [docs](doc/index.html)


