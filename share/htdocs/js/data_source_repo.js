
define(['omf/data_source3'], function(data_source) {
  function data_source_repo() {
    console.log("Creating data source repo");
    var sources = {};

    function context() {};

    context.register = function(opts) {
      var id = opts.id || opts.stream || opts.name;
      if (sources[id] == null) {
        sources[id] = data_source(opts);
      }
      return context;
    };

    context.lookup = function(ds_descr) {
      var name;
      var dynamic = false;

      if (typeof(ds_descr) != 'object') {
        ds_descr = {name: ds_descr};
      }
      name = ds_descr.id || ds_descr.stream || ds_descr.name;
      dynamic = ds_descr.dynamic;
      var source = sources[name];
      if (! source) {
        // Let's see if we can create one out of
        if (ds_descr.data_url) {
          // We can try to fetch it directly
          if (! name) {
            name = ds_descr.id = ds_descr.data_url;
          }
          source = sources[name] = data_source(ds_descr);
        } else {
          throw("Unknown data source '" + name + "'.");
        }
      }
      if (dynamic) {
        source.is_dynamic(dynamic);
      }
      return source;
    };

    context.deregister = function(ds_name) {
      var ds = sources[ds_name];
      if (! ds) return; // silently ignore request for unknown repos

      ds.close();
      delete sources[ds_name];
    }

    context.each = function(f) {
      _.each(sources, function(ds, name) {
        f(ds, name);
      })
    }

    return context;
  }
  return data_source_repo(); // Create the singleton
});


