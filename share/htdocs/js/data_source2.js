

OML.data_sources = function() {
  var sources = {};
  
  function context() {};
  
  context.register = function(name, updateURL, schema, events) {
    sources[name] = new OML.data_source(name, updateURL, schema, events);
    return context;
  };
  
  context.lookup = function(ds_descr) {
    var name;
    var dynamic = false;
    
    if (typeof(ds_descr) == 'object') {
      name = ds_descr.name;
      dynamic = ds_descr.dynamic;
    } else {
      name = ds_descr;
    } 
    var source = sources[name];
    if (! source) {
      raise("Unknown data source '" + name + "'.");
    }
    if (dynamic) {
      source.is_dynamic(dynamic);
    }
    return source;
  };
  
  return context;
}();

OML.data_source = function(name, updateURL, schema, events) {
  var event_name = "data_source." + this.name + ".changed";
  var indexes = [];
  var update_interval = -1;
  var ws = null; // points to web socket instance
  
  function ds() {};
  ds.version = "0.1";
  
  this.create_index = function(index) {
    var idx = this.indexes[index];
    if (idx) return;
    
    this._create_index(index);
  };
    
  ds.create_index = function(index) {
    var idx = indexes[index] = {};
    // index ignores rows with identical index
    _.map(events, function(r) {
      idx[r[index]] = r;
    });
  };
  
  ds.get_indexed_row = function(index, key) {
    var idx = indexes[index];
    if (idx == undefined) {
      throw "Need to create index first";
    }
    return idx[key];
  }
  
  ds.update_indexes = function() {
    var self = this;
    _.each(indexes, function(value, key) {
      var i = 0;
      self._create_index(key);
    });
    
  }
  
  ds.is_dynamic = function(_) {
    if (!arguments.length) {
      return update_interval > 0 || ws;
    }
    
    var opts = _;
    var interval = -1;
    if (typeof(opts) == 'number') {
      interval = opts
    } else if (opts == true) {
      interval = 3;
    }
    if (interval < 0) return false;

    //if (window.WebSocket) {
    if (false) {  // web sockets don't work right now
      _start_web_socket();
    } else {
      _start_polling_backend();
    }
  }
    
  ds._start_web_socket = function() {
    if (ws) return; // already running
    
    var url = 'ws://' + window.location.host + '/_ws';
    var ws = new WebSocket(url);
    var self = this;
    ws.onopen = function() {
      ws.send('id:' + name);
    };
    ws.onmessage = function(evt) {
      // evt.data contains received string.
      var msg = jQuery.parseJSON(evt.data);
      var data = msg;
      self.events.append(data);
    };
    ws.onclose = function() {
      var status = "onclose";
    };
    ws.onerror = function(evt) {
      var status = "onerror";
    };
  } 
 
  ds._start_polling_backend = function() {    
    var first_time = this.update_interval < 0;
    
    if (this.update_interval < 0 || this.update_interval > interval) {
      this.update_interval = interval;
    }
    
    if (first_time) {
      var self = this;
      L.require(['/resource/vendor/jquery/jquery.js', '/resource/vendor/jquery/jquery.periodicalupdater.js'], function() {
        var update_interval = self.update_interval * 1000;
        if (update_interval < 1000) update_interval = 3000;
        var opts = {
              method: 'get',          // method; get or post
              data: '',                   // array of values to be passed to the page - e.g. {name: "John", greeting: "hello"}
              minTimeout: update_interval,       // starting value for the timeout in milliseconds
              maxTimeout: 4 * update_interval,       // maximum length of time between requests
              multiplier: 2,          // if set to 2, timerInterval will double each time the response hasn't changed (up to maxTimeout)
              type: 'json',           // response type - text, xml, json, etc.  See $.ajax config options
              maxCalls: 0,            // maximum number of calls. 0 = no limit.
              autoStop: 0             // automatically stop requests after this many returns of the same data. 0 = disabled.
        };
        $.PeriodicalUpdater(self.update_url, opts, function(reply) {
          self.events = reply.events;
          self.update_indexes();
          reply.data_source = self;
          OHUB.trigger(self.event_name, reply);
        });
      });
    }
    return true;
  }
  
  this.on_changed = function(update_f) {
    OHUB.bind(this.event_name, update_f);
  }
  
  return ds;
}

