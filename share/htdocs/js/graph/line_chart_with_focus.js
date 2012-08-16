L.provide('OML.line_chart_with_focus', ["graph/line_chart3", "#OML.line_chart3"], function () {

  OML.line_chart_with_focus = OML.line_chart3.extend({
    
    _create_model: function() {
      return nv.models.lineWithFocusChart();
    },
    
    _configure_xy_axis: function(opts, chart) {
      var oaxis = opts.axis || {};
      var a_defaults = this.axis_defaults;
      
      var xao = _.defaults(oaxis.x || {}, a_defaults);
      xao['legend'] = null;
      this._configure_axis('x', chart.xAxis, xao);
      var xao2 = _.defaults(oaxis.x2 || {}, a_defaults);
      this._configure_axis('x2', chart.x2Axis, xao2);
         
      var yao = _.defaults(oaxis.y || {}, a_defaults);
      this._configure_axis('y', chart.yAxis, yao);
      var yao2 = _.defaults(oaxis.y2 || {}, a_defaults);
      yao2['legend'] = null;
      this._configure_axis('y2', chart.y2Axis, yao2);
    },
    
  })
})

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/
