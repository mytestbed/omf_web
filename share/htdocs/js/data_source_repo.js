
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

      if (typeof(ds_descr) == 'object') {
        name = ds_descr.id || ds_descr.stream || ds_descr.name;
        dynamic = ds_descr.dynamic;
      } else {
        name = ds_descr;
      }
      var source = sources[name];
      if (! source) {
        throw("Unknown data source '" + name + "'.");
      }
      if (dynamic) {
        source.is_dynamic(dynamic);
      }
      return source;
    };

    return context;
  }
  return data_source_repo(); // Create the singleton
});


