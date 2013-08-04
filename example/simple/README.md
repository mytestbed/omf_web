
# Example/Simple

Essentially the 'Hello World' example of a viz server. Taking data out of a database and putting it into a graph.

Start the server through:

    ruby -I$OMF_WEB_HOME/lib $OMF_WEB_HOME/example/simple/simple_viz_server.rb start
    ruby --I$OMF_WEB_HOME/lib $OMF_WEB_HOME/bin/omf_web_server.rb --config simple.yaml start
    
where $OMF_WEB_HOME points to the directory containing the __omf_web__ code. You will also need to __omf_oml__ package. 
You may either install the Gem, or download the source code from https://github.com/mytestbed/omf_oml. In the later case you
will need to add a '-I$OMF_OML_HOME/lib' flag to the above command.

After all that, the console putput should look like:

    DEBUG OmlSqlSource: Opening DB (sqlite://sample.sq3)
    DEBUG OmlSqlSource: DB: #<Sequel::SQLite::Database: "sqlite://sample.sq3">
    DEBUG OmlSchema: schema: '[{:name=>:oml_sender_id, :type=>:integer, :title=>"Oml Sender Id"} ...
    DEBUG OmlSqlRow-wave: Read 1000 (total 1000) rows from 'wave'
    INFO Server: >> Thin web server (v1.5.1 codename Straight Razor)
    DEBUG Server: >> Debugging ON
    DEBUG Server: >> Tracing ON
    INFO Server: >> Maximum connections set to 1024
    INFO Server: >> Listening on 0.0.0.0:4050, CTRL+C to stop


This starts a web server on the local machine listening on port 4050. Now point your browser there and you should see the
result of a some experiment.