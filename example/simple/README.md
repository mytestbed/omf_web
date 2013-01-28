
# Example/Simple

Essentially the 'Hello World' example of a viz server. Taking data out of a database and putting it into a graph.

Start the server through:

    ruby -I$OMF_WEB_HOME/lib $OMF_WEB_HOME/example/simple/simple_viz_server.rb start

where $OMF_WEB_HOME points to the directory containing the __omf_web__ code. You will also need to __omf_oml__ package. 
You may either install the Gem, or download the source code from https://github.com/mytestbed/omf_oml. In the later case you
will need to add a '-I$OMF_OML_HOME/lib' falg to the above command.

After all that, the console putput should look like:

    DEBUG OmlSqlSource: Opening DB (sqlite:///Users/max/src/omf_web/example/simple/data_sources/gimi31.sq3)
    DEBUG OmlSqlSource: DB: #<Sequel::SQLite::Database: "sqlite:///Users/max/src/omf_web/example/simple/data_sources/gimi31.sq3">
    DEBUG OmlSqlSource: Finding tables [:_senders, :_experiment_metadata, :pingmonitor_myping]
    DEBUG OmlSqlSource: Found table: pingmonitor_myping
    DEBUG OmlSchema: schema: '[{:name=>:oml_sender, :type=>:string, :title=>"Oml Sender"}, {:name=>:oml_sender_id, :type=>:integer, :title=>"Oml Sender Id"}, {:name=>:oml_seq, :type=>:integer, :title=>"Oml Seq"}, {:name=>:oml_ts_client, :type=>:float, :title=>"Oml Ts Client"}, {:name=>:oml_ts_server, :type=>:float, :title=>"Oml Ts Server"}, {:name=>:dest_addr, :type=>:string, :title=>"Dest Addr"}, {:name=>:ttl, :type=>:integer, :title=>"Ttl"}, {:name=>:rtt, :type=>:float, :title=>"Rtt"}, {:name=>:rtt_unit, :type=>:string, :title=>"Rtt Unit"}]'
    INFO PingDB: Stream: pingmonitor_myping
    DEBUG OmlSqlRow-pingmonitor_myping: Read 145/145 rows from 'pingmonitor_myping'
    INFO Server: >> Thin web server (v1.3.1 codename Triple Espresso)
    DEBUG Server: >> Debugging ON
    DEBUG Server: >> Tracing ON
    INFO Server: >> Maximum connections set to 1024
    INFO Server: >> Listening on 0.0.0.0:3000, CTRL+C to stop

This starts a web server on the local machine listening on port 3000. Now point your browser there and you should see the
result of a  'ping' experiment.