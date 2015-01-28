
if (typeof(OML) == "undefined") OML = {};

OML.log = function(msg) {
  console.log(arguments);
};

OML.warn = function(msg) {
  console.warn(arguments);
};

OML.error = function(msg) {
  console.error(arguments);
};


OML.require_config = {
  //By default load any module IDs from js/lib
  baseUrl: '/resource',
  //except, if the module ID starts with "app",
  //load it from the js/app directory. paths
  //config is relative to the baseUrl, and
  //never includes a ".js" extension since
  //the paths config could be for a directory.
  paths: {
    omf: 'js',
    vendor: '/resource/vendor',
    graph: 'graph/js',
    graph_css: 'graph/css',
    //echarts: 'http://echarts.baidu.com/build/dist'
    echarts: '/resource/vendor/echarts'
  },
  shim: {
    'vendor/jquery/jquery': {
        //deps: ['jquery'],
        exports: 'jQuery'
    }
  },
  map: {
    '*': {
      'css': 'vendor/require-css/css'
    }
  }
};

require.config(OML.require_config);

OML.append_require = function(opts) {
  var cfg = OML.require_config;
  var path = opts.path || opts.paths;
  if (path) {
    _.extend(cfg.paths, path)
  }
  var shim = opts.shim;
  if (shim) {
    _.extend(cfg.shim, shim);
  }
  var map = opts.map;
  if (map) {
    _.extend(cfg.map, map);
  }
  require.config(cfg);
};

OML.append_require_shim = function(name, opts) {
  var s = {};
  s[name] = opts;
  OML.append_require({shim: s});
};

OML.require_dependency = function(name, deps) {
  OML.append_require_shim(name, {deps: deps});
};


//OML.require_dependency = function(target, dependencies) {
//        OML._shim[target] = dependencies
//        require.config({shim: OML._shim});
//      }
//    }


// Start the main app logic.
// requirejs(['vendor/jquery', 'vendor/backbone'],
  // function($, _) {
    // //jQuery, canvas and the app/sub module are all
    // //loaded and can be used here now.
    // var i = 0;
// });

require(['css!graph_css/graph'],
  function(css) {
    //jQuery, canvas and the app/sub module are all
    //loaded and can be used here now.
    var i = 0;
});
