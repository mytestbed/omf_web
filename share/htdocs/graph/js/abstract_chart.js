
define(["graph/abstract_widget"], function (abstract_widget) {

  var abstract_chart = abstract_widget.extend({

    decl_color_func: {
      // scale
      "green_yellow80_red()": function() {
                                return d3.scale.linear()
                                        .domain([0, 0.8, 1])
                                        .range(["green", "yellow", "red"]);
                              },
      "green_red()":          function() {
                                return d3.scale.linear()
                                        .domain([0, 1])
                                        .range(["green", "red"]);
                              },
      "red_yellow20_green()": function() {
                                return d3.scale.linear()
                                        .domain([0, 0.2, 1])
                                        .range(["red", "yellow", "green"]);
                              },
      "red_green()":          function() {
                                return d3.scale.linear()
                                        .domain([0, 1])
                                        .range(["red", "green"]);
                              },
      // category
      "category10()":         function() {
                                return d3.scale.category10();
                              },
      "category20()":         function() {
                                return d3.scale.category20();
                              },
      "category20b()":        function() {
                                return d3.scale.category20b();
                              },
      "category20c()":        function() {
                                return d3.scale.category20c();
                              },
    },

    defaults: function() {
      return this.deep_defaults({
        margin: {
          left: 80, //100,
          top:  40,
          right: 50,
          bottom: 40
        },
      }, abstract_chart.__super__.defaults.call(this));
    },


    //base_css_class: 'oml-chart',

    initialize: function(opts) {
      abstract_chart.__super__.initialize.call(this, opts);


      var vis = this.init_svg(this.w, this.h);
      if (vis) this.configure_base_layer(vis);

      var self = this;
      OHUB.bind("graph.highlighted", function(evt) {
        if (evt.source == self) return;
        self.on_highlighted(evt);
      });
      OHUB.bind("graph.dehighlighted", function(evt) {
        if (evt.source == self) return;
        self.on_dehighlighted(evt);
      });

      this.init_filter();

      //this.update(null);
      this.init_chart();
      this.update();
    },

    configure_base_layer: function(vis) {
      this.base_layer = vis.append("svg:g");
      if (this.base_css_class) {
        this.base_layer.attr("class", this.base_css_class);
      }
    },

    // This is called once and just before update()
    init_chart: function() {
      // Do nothing, but allow override
    },

    _resize_base_el: function(w, h) {
      // Do not add margins to the base_el, but to the inside of the SVG panes
      this.w = w;
      this.h = h;
      this.base_el
        .style('height', this.h + 'px')
        .style('width', this.w + 'px')
        .style('margin-left', 0 + 'px')
        .style('margin-right', 0 + 'px')
        .style('margin-top', 0 + 'px')
        .style('margin-bottom', 0 + 'px')
        ;

      //var m = _.defaults(opts.margin || {}, this.defaults.margin);
      var m = this.opts.margin;
      var ca = this.widget_area = {
        x: m.left,
        rx: w - m.left,
        y: m.bottom,
        ty: m.top,
        w: w - m.left - m.right,
        h: h - m.top - m.bottom,
        ow: w,  // outer dimensions
        oh: h
      };

    },


    init_svg: function(w, h) {
      var opts = this.opts;

      var vis = opts.svg = this.svg_base = this.base_el.append("svg:svg")
        // .attr("width", w)
        // .attr("height", h)
        .attr("width", '100%')
        .attr("height", '100%')
        .attr('class', this.base_css_class);
      var offset = opts.offset;
      if (offset.x) {
        // the next two lines do the same, but only one works
        // in the specific context
        vis.attr("x", offset.x);
        vis.style("margin-left", offset.x + "px");
      }
      if (offset.y) {
        vis.attr("y", offset.y);
        vis.style("margin-top", offset.y + "px");
      }
      return vis;
    },

    // Split tuple array into array of tuple arrays grouped by
    // the tuple element at +index+.
    //
    group_by: function(in_data, index_f) {
      var data = [];
      var groups = {};

      _.map(in_data, function(d) {
        var key = index_f(d);
        var a = groups[key];
        if (!a) {
          a = groups[key] = [];
          data.push(a);
        }
        a.push(d);
      });
      // Sort by 'group_by' index to keep the same order and with it same color assignment.
      var data = _.sortBy(data, function(a) {
        return index_f(a[0])
      });
      return data;
    },

    // Return a data array which may be filtered by some criteria
    //
    // Examples:
    //    filter: {
    //      property: site_id,
    //      value: 5
    //      value: {min: 0, max: 10}
    //      value: event_id: foo.graph.update
    //
    filter_data: function(data) {
      var f = this.filter;
      if (!f) return data;
      return _.filter(data, f);
    },

    init_filter: function() {
      var self = this;
      var fdecl = this.opts.filter;
      if (!fdecl) return;

      var fp = fdecl.property;
      if (!fp) {
        this.error("No 'property' field in 'filter' declaration");
        return;
      }
      var col = this.schema[fp];
      if (!col) {
        this.error("Unknown filter property '" + fp + "'.");
        return;
      }
      var col_id = col.index;
      var v = fdecl.value;
      if (!v) {
        this.error("No 'value' field in 'filter' declaration");
        return;
      }
      var target, min, max;
      var filterAll = false; // Used for event, in case it is canceled
      if (_.isObject(v)) {
        min = v.min;
        max = v.max;
        if (v.event) {
          var eName = v.event.name;
          filterAll = true;
          OHUB.bind(eName + ".selected", function(evt) {
            // TODO: Not sure what to do here
            var ds = evt.data_source;
            var d = evt.datum;
            var cs = _.find(ds.schema, function(s) {
              return s.name == v.event.property
            });
            target = d[cs.index];
            filterAll = false;
            self.update();
          });
          OHUB.bind(eName + ".deselected", function(evt) {
            filterAll = true;
            self.update();
          });
        }
      } else {
        target = v;
      }
      this.filter = function(d) {
        if (filterAll) return false;

        var v = d[col_id];
        if (target) {
          return v == target;
        }
        if (min != null && v < min) return false;
        if (max != null && v > max) return false;
        return true;
      }
    },

    init_selection: function(handler) {
      var self = this;
      this.ic = {
           handler: handler,
      };

      var ig = this.base_layer.append("svg:g")
        .attr("pointer-events", "all")
        .on("mousedown", mousedown);

      var ca = this.chart_area;
      var frame = ig.append("svg:rect")
        .attr("class", "graph-area")
        .attr("x", ca.x)
        .attr("y", -1 * (ca.y + ca.h))
        .attr("width", ca.w)
        .attr("height", ca.h)
        .attr("fill", "none")
        .attr("stroke", "none")
        ;

      function mousedown() {
        var ic = self.ic;
        if (!ic.rect) {
          ic.rect = ig.append("svg:rect")
            .attr("class", "select-rect")
            .attr("fill", "#999")
            .attr("fill-opacity", .5)
            .attr("pointer-events", "all")
            .on("mousedown", mousedown_box)
            ;
        }
        ic.x0 = d3.svg.mouse(ic.rect.node());
        ic.is_dragging = true;
        ic.has_moved = false;
        ic.move_event_consumed = false;
        d3.event.preventDefault();
      }

      function mousedown_box() {
        var ic = self.ic;
        mousedown();
        if (ic.minx) {
          ic.offsetx = ic.x0[0] - ic.minx;
        }
      }

      function mousemove(x, d, i) {
        var ic = self.ic;
        var ca = self.chart_area;

        if (!ic.rect) return;
        if (!ic.is_dragging) return;
        ic.has_moved = true;

        var x1 = d3.svg.mouse(ic.rect.node());
        var minx;
        if (ic.offsetx) {
          minx = Math.max(ca.x, x1[0] - ic.offsetx);
          minx = ic.minx = Math.min(minx, ca.x + ca.w - ic.width);
        } else {
          minx = ic.minx = Math.max(ca.x, Math.min(ic.x0[0], x1[0]));
          var maxx = Math.min(ca.x + ca.w, Math.max(ic.x0[0], x1[0]));
          ic.width = maxx - minx;
        }
        self.update_selection({screen_minx: minx});
      }

      function mouseup() {
        var ic = self.ic;
        if (!ic.rect) return;
        ic.offsetx = null;
        ic.is_dragging = false;
        if (!ic.has_moved) {
          // click only. Remove selction
          ic.width = 0;
          ic.rect.attr("width", 0);
          if (ic.handler) ic.handler(this, 0, 0);
        }
      }

      d3.select(window)
          .on("mousemove", mousemove)
          .on("mouseup", mouseup);
    },

    update_selection: function(selection) {
      if (!this.ic) return;

      var ic = this.ic;
      var ca = this.chart_area;

      var sminx = selection.screen_minx;
      if (sminx) {
        ic.rect
          .attr("x", sminx)
          .attr("y", -1 * (ca.y + ca.h)) //self.y(self.y_max))
          .attr("width", ic.width)
          .attr("height",  ca.h); //self.y(self.y_max) - self.y(0));
        ic.sminx = sminx;
      }
      sminx = ic.sminx;
      var h = ic.handler;
      if (sminx && ic.handler) {
        var imin = this.x.invert(sminx);
        var imax = this.x.invert(sminx + ic.width);
        ic.handler(this, imin, imax);
      }
    },

    /*************
     * Deal with schema and turn +mapping+ instructions into actionable functions.
     */


    on_highlighted: function(evt) {},
    on_dehighlighted: function(evt) {},


    // Return an array with the 'min' and 'max' value returned by running 'f' over 'data'
    // However, any 'min' and 'max' values in 'opts' take precedence.
    //
    extent: function(data, f, opts) {
      var o = opts || {};
      var max = o.max != undefined ? o.max : d3.max(data, f);
      var min = o.min != undefined ? o.min : d3.min(data, f);
      return [min, max];
    },

    extent_2d: function(data, f, opts) {
      var o = opts || {};
      var max = o.max != undefined ? o.max : d3.max(data, function(s) {return d3.max(s, f)});
      var min = o.min != undefined ? o.min : d3.min(data, function(s) {return d3.min(s, f)});
      return [min, max];
    }
  });

  return abstract_chart;
});
