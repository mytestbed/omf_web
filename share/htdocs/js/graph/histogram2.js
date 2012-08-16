L.provide('OML.histogram2', ["graph/abstract_nv_chart", "#OML.abstract_nv_chart"], function () {

  OML.histogram2 = OML.abstract_nv_chart.extend({
    decl_properties: [
      ['value', 'key', {property: 'value'}], 
      ['group_by', 'key', {property: 'id', optional: true}],             
      ['fill_color', 'color', 'category10()'],
    ],
        
    defaults: function() {
      return this.deep_defaults({
        bins: null, // number of bins to use. The default bin function will 
                  // divide the values into uniform bins using Sturges' formula. 
        rotate_labels: -45,
        tooltips: true,
        show_legend: true,
        show_controls: true,        
        // reduceXTicks
        // showControls
        // stacked', 
        // delay
  
        margin: {
          top: 20, right: 0, bottom: 50, left: 80 
        }    
      }, OML.histogram2.__super__.defaults.call(this));      
    },

    _create_model: function() {
      return  nv.models.multiBarChart();      
    },
    
    // _configure_mapping: function(m, chart) {
      // // var x_index = m.x_axis;
      // // var y_index = m.y_axis;
      // // chart.x(function(d) {
        // // var v = x_index(d);        
        // // return v;
      // // })
      // // chart.y(function(d) {
        // // var v = y_index(d);
        // // return v;
      // // })
    // },
    
    _configure_options: function(opts, chart) {
      OML.histogram2.__super__._configure_options.call(this, opts, chart);
      chart
        .rotateLabels(opts.rotate_labels)
        .tooltips(opts.tooltips)
        .showLegend(opts.show_legend)
        .showControls(opts.show_control)        
        .margin(opts.margin)
        ;
      this._configure_xy_axis(opts, chart)
    },
    
    _datum: function(data, chart) {
      var o = this.opts;
      var m = this.mapping;

      // We first calculate a histogram across all data rows to establish 
      // the bins. We then fix the bins, separate the data accoording to
      // the 'group-by' property and then calculate individual histograms
      // for each group with fixed bins.
      //
      var hdata;      
      var histogram = d3.layout.histogram();
      histogram.value(m.value);
      var bins = o.bins ? histogram.bins(o.bins) : histogram.bins();
      // To calculate density, we would need to calibrate that across
      // all groups.
      //if (o.density != 'undefined"') histogram.frequency(! o.density);
      hdata = histogram(data);
      
      var group_by = m.group_by;
      var datum;
      if (group_by != null) {
        var bins = hdata.map(function(b) {
          return b.x + b.dx;
        })
        bins.splice(0, 0, hdata[0].x);
        histogram.bins(bins);
        var groups  = this.group_by(data, group_by);
        datum = groups.map(function(g) {
          return {
            key: g.length > 0 ? group_by(g[0]) : '???',
            values: histogram(g).map(function(b) {
              return {x: (b.x + 0.5 * b.dx), y: b.y}
            })
          }
        })
      } else {
        datum = [{
          key: '???',
          values: hdata.map(function(b) {
            return {x: (b.x + 0.5 * b.dx), y: b.y}
          })
        }];
      };
      
      if (m.fill_color) {
        datum = datum.map(function(d) {
          d.color = m.fill_color(d.key);
          return d;
        })
      }
      
      if (o.show_legend) chart.showLegend(datum.length > 1);
      if (o.show_controls) chart.showControls(datum.length > 1);

      return datum;
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