L.baseURL = "/resource";
OML = {
  data_sources: {},
  widgets: {},
  
};
  
var OHUB = {};
_.extend(OHUB, Backbone.Events);

$(window).resize(function(x) {
  var w = $(window);
  OHUB.trigger('window.resize', {width: w.width(), h: w.height()});
  OHUB.trigger('layout.resize', {});
});      
