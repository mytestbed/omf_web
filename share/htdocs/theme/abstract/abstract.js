
if (typeof(OML) == "undefined") OML = {};
_.extend(OML, {
  data_sources: {},
  widgets: {},
  window_size: {width: null, height: null}
});

var OHUB = {};
_.extend(OHUB, Backbone.Events);

$(window).resize(function(x) {
  var w = $(window);
  var width = w.width();
  var height = w.height();
  var current = OML.window_size;

  if (current.width != width || current.height != height) {
    current.width = width; current.height = height;
    OHUB.trigger('window.resize', current);
    OHUB.trigger('layout.resize', {});
  }
});
