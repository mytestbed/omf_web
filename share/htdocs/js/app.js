
var i = 0;
require.config({
    //By default load any module IDs from js/lib
    baseUrl: '/resource',
    //except, if the module ID starts with "app",
    //load it from the js/app directory. paths
    //config is relative to the baseUrl, and
    //never includes a ".js" extension since
    //the paths config could be for a directory.
    paths: {
        omf: 'js',
        vendor: 'vendor',
        graph: 'graph/js',
        graph_css: 'graph/css'
    },
    shim: {
      'vendor/jquery/jquery': {
          //deps: ['jquery'],
          exports: 'jQuery'
      },
    },
    map: {
      '*': {
        'css': 'vendor/require-css/css'
      }
    }
});

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
