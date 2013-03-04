# Openflow Demo at GEC'15

This directory contains most of the code used for our Openflow demo at GEC'15.

The following will start the visualization front-end:

    cd OMF_WEB_HOME
    ruby1.9 -I lib example/openflow-gec15/of_viz_server.rb start
    
If you want to run it in **pure** demo mode, then add the '--local-testing' flag before the 'start' command.

This will start a web server at port 3000. Point your browser there and you should see somthing like:

![Screenshot of dashboard](https://raw.github.com/mytestbed/omf_web/master/example/openflow-gec15/doc/screenshot.png "Screenshot")

Clicking on the 'Code' tab will show the 'OIDL' script describing the experiment, and the 'Trema' code of the Openflow controller
used in the experiment.
 
For reference, this is the topology used in the experiment:

![Topology](https://raw.github.com/mytestbed/omf_web/master/example/openflow-gec15/doc/gec15_topo.png "Topology")


