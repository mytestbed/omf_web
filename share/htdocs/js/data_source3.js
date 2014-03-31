

function omf_web_data_source(opts) {

  var name = opts.id || opts.name;
  var event_name = "data_source." + name + ".changed";
  var rows = opts.rows || [];
  //var offset = opts.offset || -1; // Number of (initial) rows skipped (count towards 'max_rows')
  var offset = opts.offset || 0; // Number of (initial) rows skipped (count towards 'max_rows')
  var schema = opts.schema;

  var data_source = {
    version: "0.1",
    name: name,
    schema: schema,
    rows: function() { return rows; },
    index_for_column: index_for_column,
    is_dynamic: is_dynamic,
    event_name: event_name,
  };

  var indexes = {};
  var unique_index_check = null;

  var update_interval = -1;
  var ws = null; // points to web socket instance

  function index_for_column(col_descr) {
    var i = col_descr.index;
    var index = indexes[i];
    if (!index) {
      index = indexes[i] = {};
      _.each(rows, function(r) { index[r[i]] = r; });
    }
    return function(key) {
      return indexes[i][key]; // need fresh lookup as we may redo index
    };
  }

  function update_indexes() {
    // This can most likley be done more efficiently if we consider what has changed
    _.each(indexes, function(ignore, i) {
      var index = indexes[i] = {};
      _.each(rows, function(r) { index[r[i]] = r; });
    });
  }

  function is_dynamic(_) {
    if (!arguments.length) {
      return update_interval > 0 || ws;
    }

    var opts = _;
    var interval = -1;
    if (typeof(opts) == 'number') {
      interval = opts;
    } else if (opts == true) {
      interval = 3;
    }
    if (interval < 0) return false;

    if (window.WebSocket) {
    //if (false) {  // web sockets don't work right now
      //start_web_socket();
    } else {
      start_polling_backend();
    }
  }

  var ws = null; // Websocket identifier
  function start_web_socket() {
    if (ws) return; // already running

    var host = (typeof window_location_host == 'function') ? window_location_host() : window.location.host;
    var url = 'ws://' + host + '/_ws?sid=' + (opts.sid || OML.session_id);
    ws = new WebSocket(url);
    ws.onopen = on_open;
    ws.onmessage = on_message;
    ws.onclose = function() {
      var status = "onclose";
    };
    ws.onerror = function(evt) {
      var status = "onerror";
    };
  }

  // Send a message to the server
  //
  // @params type - Type of message
  // @params args - Hash of additional args ('ds_name' of this data source will be added)
  //
  // TODO: Would need to cache messages if connection isn't established yet
  //
  function send_server_msg(type, args) {
    args.ds_name = name;
    msg = {type: type, args: args}
    ws.send(JSON.stringify(msg));
  }


  function on_open() {
    if (!active_slice_col_name) {
      send_server_msg('register_data_source', {offset: offset + rows.length})
    }
  };

  function on_message(evt) {
    // evt.data contains received string.
    var msg = jQuery.parseJSON(evt.data);
    switch(msg.type) {
      case 'datasource_update':
        on_update(msg);
        break;
      case 'reply':
        // great
        break;
      default:
        throw "Unknown message type '" + msg.type + "'.";
    }
  };

  function on_update(msg) {
    if (unique_index_check) {
      // Let's first see if we simply replace a row
      _.each(msg.rows, function(r) {
        if (!unique_index_check(r)) {
          rows.push(r); // new index
        }
      });
    } else {
      // need to append to 'rows' as it's referenced in other closures
      // _.each(msg.rows, function(r) { rows.push(r) });
      // var chop = msg.offset - offset;
      // if (offset >= 0 && chop > 0) {
        // rows = _.rest(rows, chop);
      // }
      switch (msg.action) {
        case 'added':
          _.each(msg.rows, function(r) { rows.push(r) });
          break;
        case 'removed':
          // This could most likely be made a bit faster.
          _.each(msg.rows, function(row) {
            var id = row[0]; // first column is ALWAYS a unique row id
            var l = rows.length;
            var row_no;
            for (row_no = 0; row_no < l; row_no++) {
              if (rows[row_no][0] == id) break;
            }
            if (row_no < l) {
              rows.splice(row_no, 1);
            } else {
              var xxx = 0; // Removing non existing row
            }
          });
          break;
        default:
          throw "Unknown message action '" + msg.action + "'.";
      }
    }

    update_indexes();
    var evt = {data_source: data_source};
    OHUB.trigger(event_name, evt);
    OHUB.trigger("data_source.changed", evt);
  }

  // Request a new slice from the server. Clear existing state
  function set_slice_column(col_value) {
    if (active_slice_value == col_value) return;

    active_slice_column_id = col_value;
    // Reset state
    rows = [];
    update_indexes();
    var sm = {col_name: active_slice_col_name, col_value: col_value};
    send_server_msg('request_slice', {slice: sm});
  }
  var active_slice_col_name = null;
  var active_slice_value = null;

  function start_polling_backend() {
    var first_time = this.update_interval < 0;

    if (this.update_interval < 0 || this.update_interval > interval) {
      this.update_interval = interval;
    }

    if (first_time) {
      var self = this;
      L.require(['vendor/jquery/jquery.js', 'vendor/jquery/jquery.periodicalupdater.js'], function() {
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

  function fetch_data(data_url) {
    require(['vendor/jquery/jquery'], function() {
      $.ajax({
        url: data_url,
        dataType: 'json',
        //data: opts,
        type: 'GET'
      }).done(function(reply) {
        var data = reply.data;
        rows.splice(0, rows.length); // this is an update, not an add
        _.each(data, function(r) { rows.push(r); });

        update_indexes();
        var evt = {data_source: data_source};
        OHUB.trigger(event_name, evt);
        OHUB.trigger("data_source.changed", evt);
      }).error(function(ajax, textStatus, errorThrown) {
        console.log("ERROR: '" + textStatus + "' - " + errorThrown);
      });
    });
  }

  // Let's check if this data_source maintains uniqueness along one axis (column)
  if (opts.unique_column) {
    var col_name = opts.unique_column;
    var index = -1;
    _.find(schema, function(cd) {
      index += 1;
      return cd.name == col_name;
    });
    if (index >= 0) {
      var key2row = {};
      unique_index_check = function (row) {
        var key = row[index];
        var existing_row = key2row[key];
        if (existing_row) {
          // replace content of existing row with 'row'
          // Need to replace in place, there may be a better way
          existing_row.length = 0;
          _.each(row, function(e) { existing_row.push(e); })
          return true;
        }
        key2row[key] = row;
        return false;
      };
      // pre-seed
      rows = _.uniq(rows, false, function(r) { return r[index]; });
      _.each(rows, function(r) { key2row[r[index]] = r; });
    } else {
      throw "Error in processing option 'unique_column'. Unknown column '" + col_name + "'."
    }
  }

  // In slice mode, only fetch a 'slice' of the underlying data source. A slice
  // is defined by specific value in the 'slice_column' of all rows.
  //
  // opts.slice:
  //      slice_column: id
  //      event:
  //        name: graph.static_network.links.changed
  //        key: id
  if (opts.slice) {
    var so = opts.slice;
    active_slice_col_name = so.slice_column;

    if (so.event) {
      var evt_name = so.event.name;
      if (! evt_name)
        throw "Missing event name in slice definition for data source '" + name + "'.";
      OHUB.bind(evt_name, function(msg) {
        var schema = msg.schema || msg.data_source.schema;

        var key = so.event.key;
        var col = _.find(schema, function(cd) { return cd.name == key; });
        if (col) {
          var event = msg.datum;
          var col_id = event[col.index];
          if (col_id) {
            set_slice_column(col_id);
          }
        }
      });
    }
  }

  if (window.WebSocket && opts.ws_url) {
    start_web_socket();
  } else if (opts.update_url) {
    throw "Missing implementation for NON web socket browsers";
  } else if (opts.data_url) {
    fetch_data(opts.data_url);
  } else {
    throw "Don't know how to fetch data source '" + name + "'.";
  }

  // Bind to event directly
  // this.on_changed = function(update_f) {
    // OHUB.bind(this.event_name, update_f);
  // }

  return data_source;
}

define(function() {
  return function(opts) {
    return omf_web_data_source(opts);
  };
});


