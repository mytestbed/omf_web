
define(["graph/abstract_chart"], function (abstract_chart) {

  var network2 = abstract_chart.extend({
    decl_properties: {
      nodes:  [['key', 'key', {property: 'id'}],
               ['radius', 'int', 30],
               ['fill_color', 'color', 'blue'],
               ['stroke_width', 'int', 1],
               ['stroke_color', 'color', 'black'],
               ['x', 'int', 10],
               ['y', 'int', 10],
               ['label_text', 'key', {property: 'name'}],
               ['label_font', 'string', null],
               ['label_size', 'int', 16],
               ['label_color', 'color', 'white'],

              ],
      links:  [['key', 'key', {property: 'id'}],
               ['stroke_width', 'int', 2],
               ['stroke_color', 'color', 'black'],
               ['stroke_fill', 'color', 'blue'],
               ['from', 'index', {key: 'from_id', join_stream: 'nodes', join_key: 'id'}],
               ['to', 'index', {key: 'to_id', join_stream: 'nodes'}]  // join_key: 'id' ... default
              ]
    },

    defaults: function() {
      return this.deep_defaults({
        line_mode: 'curved', // 'straight'
        interaction_mode: 'none',   // none, hover, click
        force: {
          // see https://github.com/mbostock/d3/wiki/Force-Layout
          link_distance: null, // 150,
          link_strength: null, // [0, 1] set to 1
          charge: null, // -30 -500,
          charge_distance: null,
          gravity: null, // default: 0.1
          theta: null, // default: 0.8
        }
      }, network2.__super__.defaults.call(this));
    },

    configure_base_layer: function(vis) {
      var ca = this.widget_area;

      this.graph_layer = vis.append("svg:g")
                 .attr("transform", "translate(0, " + ca.h + ")")
                 ;
      this.link_layer = this.graph_layer.append("svg:g");
      this.node_layer = this.graph_layer.append("svg:g");
      this.legend_layer = this.graph_layer.append("svg:g");
    },

    base_css_class: 'oml-network',

    // Find the appropriate data source and bind to it
    //
    init_data_source: function() {
      var o = this.opts;
      var sources = o.data_sources;
      var self = this;

      if (! (sources instanceof Array)) {
        throw "Expected an array";
      }
      if (sources.length == 1) {
        // Check if we can find
        // a _links and _nodes source
        var s = sources[0];
        var ss = s.stream || s.name;
        if (typeof(ss) != 'object') {
          ss = { name: ss };
        }
        var prefix = ss.name;
        var sn = {}; for (var p in ss) { sn[p] = ss[p]; }; sn.name = 'nodes'; sn.stream = prefix + '/nodes';
        var sl = {}; for (var p in ss) { sl[p] = ss[p]; }; sl.name = 'links'; sl.stream = prefix + '/links';
        sources = [sn, sl];
      }
      if (sources.length != 2) {
        throw "Expected TWO data source, one for nodes and one for links";
      }
      var dsh = this.data_source = {};
      _.map(sources, function(s) {
        dsh[s.name] = self.init_single_data_source(s);
      });
      if (dsh.links == undefined || dsh.nodes == undefined) {
        throw "Data sources need to be named 'links' and 'nodes'. Missing one or both.";
      }
    },

    process_schema: function() {
      var self = this;
      var ds_names = ['nodes', 'links'];
      var outstanding_schemas = ds_names.slice(0); // real copy

      // CHeck for all the schemas first and when we have them, really
      // process the schemas
      _.each(ds_names, function(name) {
        self.data_source[name].on_schema(function() {
          outstanding_schemas = _.without(outstanding_schemas, name);
          if (_.isEmpty(outstanding_schemas.length)) {
            self._process_schema();
          }
        });
      });
    },

    _process_schema: function() {
      var self = this;
      var ds_names = ['nodes', 'links'];
      var om = self.opts.mapping;
      if (om == undefined) {
        throw "Missing mapping instructions in 'options'.";
      }
      self.mapping = {};
      var schemas = self.schema = {};

      _.each(ds_names, function(ds_name) {
        schemas[ds_name] = self.process_single_schema(self.data_source[ds_name]);
      });

      _.each(ds_names, function(ds_name) {
        var mapping = om[ds_name];
        if (mapping == undefined) {
          throw "Missing mapping instructions in 'options' for '" + ds_name + "'.";
        }
        self.mapping[ds_name] = self.process_single_mapping(ds_name, mapping, self.decl_properties[ds_name]);
      });
      self.init_mapping();
    },


    // process_schema: function() {
//
//
      // var self = this;
      // var schemas = this.schema = {};
      // var mappings = this.mapping = {};
      // var om = this.opts.mapping;
      // // if (om.links == undefined || om.nodes == undefined) {
        // // throw "Missing mapping instructions in 'options' for either 'links' or 'nodes', or both.";
      // // }
        // // links: this.process_single_schema(this.data_source.links)
      // // };
      // // this.data_source.nodes.on_schema(function() {
        // // schemas.nodes = self.process_single_schema(self.data_source.nodes);
        // // mappings.nodes = self.process_single_mapping('nodes', om.nodes, self.decl_properties.nodes);
      // // });
//
      // _.each(['nodes', 'links'], function(name) {
        // if (om[name] == undefined) {
          // throw "Missing mapping instructions in 'options' for '" + name + "'.";
        // }
        // self.data_source[name].on_schema(function() {
          // schemas[name] = self.process_single_schema(self.data_source[name]);
          // mappings[name] = self.process_single_mapping(name, om[name], self.decl_properties[name]);
        // });
      // });
//
//
      // // this.mapping = {
        // // nodes: this.process_single_mapping('nodes', om.nodes, this.decl_properties.nodes),
        // // links: this.process_single_mapping('links', om.links, this.decl_properties.links)
      // // };
    // },

    /*
     * Return schema for +stream+.
     */
    schema_for_stream: function(stream) {
      var schema = this.schema[stream];
      return schema;
    },

    data_source_for_stream: function(stream) {
      var ds = this.data_source[stream];
      if (ds == undefined) {
        throw "Unknown data_source '" + stream + "'.";
      }
      return ds;
    },

    // This is called once and just before update()
    init_chart: function() {
      network2.__super__.init_chart.call(this);

      this.auto_placement = this.mapping.nodes.x == 'auto';
      if (!this.auto_placement) return;

      var self = this;
      var o = this.opts.force;
      var nmapping = this.mapping.nodes;
      nmapping.x = function(d) {
        return d.__force__.x / self.widget_area.w;
      };
      nmapping.y = function(d) {
        return d.__force__.y / self.widget_area.h;
      };

      var ca = this.widget_area;
      var force = this.force = d3.layout.force().size([ca.w, ca.h]);

      if (o.link_distance) force.linkDistance(o.link_distance);
      if (o.link_strength) force.linkStrength(o.link_strength);
      if (o.charge) force.charge(o.charge);
      if (o.charge_distance) force.chargeDistance(o.charge_distance);
      if (o.gravity) force.gravity(o.gravity);
      if (o.theta) force.theta(o.theta);

      this.force.on('tick', function() {
        var data = self.data;
        self.redraw(data);
      });
    },

    resize: function() {
      network2.__super__.resize.call(this);

      if (this.force) {
        var ca = this.widget_area;
        this.force.size([ca.w, ca.h]).start();
      }
    },


    update: function() {

      var ldata = this.data_source.links.rows();
      var ndata = this.data_source.nodes.rows();

      if (this.force) {
        // The following sets up data structures to be used by
        // force layout. It also needs node and link arrays but
        // in a different format from how we use it here.
        // To still work with the rest of the library, we are
        // attaching an '__force__' entry to each data element
        // which we then hand over to the force layouter but also
        // can revert to when drawing the graph.
        //
        var nm = this.mapping.nodes;
        var nmap = {};
        var nodes = _.map(ndata, function(d) {
          var f = d.__force__;
          if (!f) {
            var id = nm.key(d);
            f = d.__force__ = {index: id, d: d};
          }
          nmap[f.index] = f;
          return f;
        });

        var lm = this.mapping.links;
        var links = _.map(ldata, function(d) {
          var f = d.__force__;
          if (!f) {
            var s = lm.from(d);
            var t = lm.to(d);
            var id = nm.key(d);
            f = d.__force__ = {index: id, source: s.__force__, target: t.__force__, d: d};
          }
          return f;
        });

        // TODO: We need to check if any new data items have been added or old ones
        // removed. So the following may be a bit slow.
        function isDiff(a1, a2) {
          if (a1.length != a2.length) return true;

          var i1 = _.map(a1, function(d) {return d.index; });
          var i2 = _.map(a2, function(d) {return d.index; });
          var d = _.difference(i1, i2);
          return d.length > 0;
        }
        var force = this.force;
        if (isDiff(force.nodes(), nodes) || isDiff(force.links(), links)) {
          force.nodes(nodes);
          force.links(links);
          force.start();
        }
      }

      this.redraw({links: ldata, nodes: ndata});
    },

    redraw:  function(data) {
      var self = this;
      self.data = data;
      var o = this.opts;
      var mapping = this.mapping; //o.mapping || {};
      var ca = this.widget_area;

      var x = function(v) {
        //var x = v * ca.w + ca.x;
        var x = v * ca.w;
        return x;
      };
      var y = function(v) {
        //var y = -1 * (v * ca.h + ca.y);
        var y = -1 * (v * ca.h);
        return y;
      };

      var vis = this.base_layer;
      var lmapping = mapping.links;
      var nmapping = mapping.nodes;
      var iline_f = d3.svg.line().interpolate('basis');

      // curved line or straight depending on line_mode
      var line_f = function(d) {
        var a = 0.2;
        var b = 0.3;
        var o = 30;

        var from = lmapping.from(d);
        var to = lmapping.to(d);

        var x1 = x(nmapping.x(from));
        var y1 = y(nmapping.y(from));
        var x3 = x(nmapping.x(to));
        var y3 = y(nmapping.y(to));

        var dx = x3 - x1;
        var dy = y3 - y1;
        var l = Math.sqrt(dx * dx + dy * dy);
        if (l == 0 || self.opts.line_mode != 'curved') {
          return iline_f([[x1, y1], [x3, y3]]);
        }

        var mx = x1 + a * dx;
        var my = y1 + a * dy;
        var x2 = mx - (dy * o / l);
        var y2 = my + (dx * o / l);

        return iline_f([[x1, y1], [x2, y2], [x3, y3]]);
      };

      var ldata = data.links;
      var link2 = this.link_layer.selectAll("path.link")
                    .data(d3.values(ldata), function(d) {
                      var k = lmapping.key(d);
                      return lmapping.key(d);
                    });
      link2
        //.each(position) // update existing markers
        .style("stroke", lmapping.stroke_color)
        .style("stroke-width", lmapping.stroke_width)
        .attr("d", line_f)
        ;
      var le = link2.enter().append("svg:path");
      le.attr("class", "link")
        .style("stroke", lmapping.stroke_color)
        .style("stroke-width", lmapping.stroke_width)
        .attr("fill", "none")
        .attr("d", line_f)
        ;
      this._set_link_interaction_mode(le);


      var ndata = data.nodes;
      // first draw white circle to allow actual node to become transparent
      // without links showing through
      var bg_node = this.node_layer.selectAll("circle.bg_node")
                        .data(ndata, function(d) {
                          return nmapping.key(d);
                        })
          .attr("cx", function(d) { return x(nmapping.x(d)); })
          .attr("cy", function(d) { return y(nmapping.y(d)); })
          .attr("r", nmapping.radius)
          .style("fill", 'white')
        .enter().append("svg:circle")
          .attr("class", "bg_node")
          .attr("cx", function(d) { return x(nmapping.x(d)); })
          .attr("cy", function(d) { return y(nmapping.y(d)); })
          .attr("r", nmapping.radius)
          .style("fill", 'white');
          ;


      function node_f(sel) {
        sel.attr("cx", function(d) { return x(nmapping.x(d)); })
          .attr("cy", function(d) { return y(nmapping.y(d)); })
          .attr("r", nmapping.radius)
          .style("fill", nmapping.fill_color)
          .style("stroke", nmapping.stroke_color)
          .style("stroke-width", nmapping.stroke_width)
          ;
      }
      var node = this.node_layer.selectAll("circle.node")
                        .data(ndata, function(d) {
                            return nmapping.key(d);
                            });
                        //.data(d3.values(ndata));
                        //function(d) { return d.time; }
      var enx = node.call(node_f);
      // node.enter().append("svg:circle")
        // .call(node_f)
        // .attr("fixed", true)
        // .transition()
          // .attr("r", nmapping.radius)
          // .delay(0)
        // ;
      var en = node.enter().append("svg:circle");
      en.attr("class", "node")
        .attr("cx", function(d) { return x(nmapping.x(d)); })
        .attr("cy", function(d) { return y(nmapping.y(d)); })
        .attr("r", nmapping.radius)
        .style("fill", nmapping.fill_color)
        .style("stroke", nmapping.stroke_color)
        .style("stroke-width", nmapping.stroke_width)
        .attr("fixed", true)
        .transition()
          .attr("r", nmapping.radius)
          .delay(0)
        ;
      this._set_node_interaction_mode(node);

      function label_f(sel) {
        sel.attr("class", "node_label")
          .attr('dy', '0.4em')
          .attr("x", function(d) { return x(nmapping.x(d)); })
          .attr("y", function(d) { return y(nmapping.y(d)); })
          .attr('text-anchor', 'middle')
          .style("fill", nmapping.label_color)
          .style("font-size", nmapping.label_size)
          .text(function(d) { return nmapping.label_text(d); });
      }
      var label = this.node_layer.selectAll("text.node_label")
                        .data(ndata, function(d) {
                            return nmapping.key(d);
                            });
      label.call(label_f);
      label.enter().append("svg:text").call(label_f);

    },

    _set_link_interaction_mode: function(le) {
      var self = this;
      var o = this.opts;

      if (o.interaction_mode == 'hover') {
        le.on("mouseover", function(d) {
          self._on_link_selected(d);
        })
        .on("mouseout", function(d) {
          self._on_link_selected(d);
        })
        ;
      } else if (o.interaction_mode == 'click') {
        le.on("click", function(d) {
          self._on_link_selected(d);
        })
        .style('cursor', 'hand')
        ;
      }
    },

    _on_link_selected: function(d) {
      var key_f = this.mapping.links.key;
      var id = key_f(d);
      var msg = {id: id, type: 'link', source: this, data_source: this.data_source.links};

      if (this.selected_link == id) {
        // if same link is clicked twice, unselect it
        this._render_selected_link(null);
        this._render_selected_node(null);
      } else {
        this._render_selected_link(id);
        this._render_selected_node('_NONE_');
        this._report_selected(id, 'links', d);
      }
    },

    // Make all but 'selected_id' link semi-transparent. If 'selected_id' is null
    // revert selection.
    //
    _render_selected_link: function(selected_id) {
      if (selected_id == null || selected_id == '_NONE_') {
        if (this.selected_link) {
          this._report_deselected(this.selected_link, 'links');
          this.selected_link = null;
        }
      } else {
        this.selected_link = selected_id;
      }

      var key_f = this.mapping.links.key;
      if (selected_id) {
        // grey out non-selected
        this.graph_layer.selectAll("path.link")
         .filter(function(d) {
           var key = key_f(d);
           return selected_id == '_NONE_' || key != selected_id;
         })
         .transition()
           .style("opacity", 0.1)
           .delay(0)
           .duration(300);
      }
      // Ensure that selected link is shown fully
      this.graph_layer.selectAll("path.link")
       .filter(function(d) {
         var key = key_f(d);
         return selected_id == null || key == selected_id;
       })
       .transition()
         .style("opacity", 1.0)
         .delay(0)
         .duration(300);

    },

    _set_node_interaction_mode: function(en) {
      var self = this;
      var o = this.opts;

      var msg_frag = {type: 'node', data_source: this.data_source.nodes};
      if (o.interaction_mode == 'hover') {
        en.on("mouseover", function(d) {
          self._on_node_selected(d);
        })
        .on("mouseout", function(d) {
          self._on_node_selected(d);
        })
        ;
      } else if (o.interaction_mode == 'click') {
        en.on("click", function(d) {
          self._on_node_selected(d);
        })
        .style('cursor', 'hand');
      }

    },

    _on_node_selected: function(d) {
      var key_f = this.mapping.nodes.key;
      var id = key_f(d);
      //var msg = {id: id, type: 'node', source: this, data_source: this.data_source.nodes};

      if (this.selected_node == id) {
        // if same link is clicked twice, unselect it
        this._render_selected_link(null);
        this._render_selected_node(null);
      } else {
        this._render_selected_link('_NONE_');
        this._render_selected_node(id);
        this._report_selected(id, 'nodes', d);
      }
    },

    // Make all but 'selected_id' node semi-transparent. If 'selected_id' is null
    // revert selection.
    //
    _render_selected_node: function(selected_id) {
      if (selected_id == null || selected_id == '_NONE_') {
        if (this.selected_node) {
          this._report_deselected(this.selected_node, 'nodes');
          this.selected_node = null;
        }
      } else {
        this.selected_node = selected_id;
      }
      var key_f = this.mapping.nodes.key;
      if (selected_id) {
        // grey out non-selected
        this.graph_layer.selectAll("circle.node")
         .filter(function(d) {
           var key = key_f(d);
           return selected_id == '_NONE_' || key != selected_id;
         })
         .transition()
           .style("opacity", 0.1)
           .delay(0)
           .duration(300);
      }
      // Ensure that selected node is shown fully
      this.graph_layer.selectAll("circle.node")
       .filter(function(d) {
         var key = key_f(d);
         return selected_id == null || key == selected_id;
       })
       .transition()
         .style("opacity", 1.0)
         .delay(0)
         .duration(300);

    },

    _report_selected: function(selected_id, type, datum) {
      var ds = this.data_source[type];
      var msg = {id: selected_id, type: type, source: this, data_source: ds, datum: datum};
      OHUB.trigger("graph.selected", msg);
      OHUB.trigger("graph." + ds.name + ".selected", msg);
    },

    _report_deselected: function(selected_id, type, datum) {
      var ds = this.data_source[type];
      var msg = {id: selected_id, type: type, source: this, data_source: ds, datum: datum};
      OHUB.trigger("graph.deselected", msg);
      OHUB.trigger("graph." + ds.name + ".deselected", msg);
    }

  });

  return network2;
});

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/
