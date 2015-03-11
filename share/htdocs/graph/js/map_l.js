

//OML.append_require({paths: {leaflet: '/vendor/leaflet'}, shim: {leaflet: {exports: 'L'}}}
OML.append_require_shim("vendor/leaflet/leaflet-src", {
  exports: 'L',
  deps: ["vendor/d3/d3", "css!vendor/leaflet/leaflet"]
});

define(["graph/abstract_widget", "vendor/leaflet/leaflet-src", "vendor/leaflet/TileLayer.Grayscale"], function (abstract, L) {

  var ctxt = abstract.extend({
    //this.opts = opts;

    decl_properties: {
      nodes: [
        ['id', 'key', {property: 'id', optional: true}],
        ['site', 'key', {property: 'site', optional: true}],
        ['status', 'key', {property: 'status', optional: true}], // this is used to create the pie for status distribution
        // If set, the visibility can be switched on/off depending on zoom level
        ['zoom_visibility', 'key', {property: 'zoom_visibility', optional: true}],
        ['latitude', 'key', {property: 'latitude'}],
        ['longitude', 'key', {property: 'longitude'}],
        //['radius', 'key', {property: 'radius', type: 'int', default: 10}],
        ['radius', 'int', 10],
        ['site_radius', 'int', 20],
        ['fill_color', 'color', 'mediumpurple'],
        ['stroke_width', 'int', 1],
        ['stroke_color', 'color', 'white'],
      ],
      links: [
        ['id', 'key', {property: 'id', optional: true}],
        ['from', 'key', {property: 'from_id'}],
        ['to', 'key', {property: 'to_id'}],
        ['from_site', 'key', {property: 'from_site', optional: true}],
        ['to_site', 'key', {property: 'to_site', optional: true}],
        ['fill_color', 'color', 'red'],
        ['stroke_width', 'int', 2],
        ['stroke_color', 'color', 'gray'],
      ]
    },

    defaults: function() {
      return this.deep_defaults({
        margin: {
          left: 0,
          top:  10,
          right: 20,
          bottom: 0
        },
        map: {
          lat: 39.0997300, lon: -94.5785700, // Kansas City
          zoom_level: 4,
          tile_provider: 'esri_world_topo'
        },
        nodes: {
          anchor: {
            radius: 5,
            fill: 'black'
          },
          stick: {
            color: "gray",
            width: 2
          }
        },
        links: {
          min_distance: 50
        },
        interaction_mode: 'click',
        events: {
          // click: event_name
        }
      }, ctxt.__super__.defaults.call(this));
    },

    // See http://leaflet-extras.github.io/leaflet-providers/preview/ for more options
    tile_providers: {
      osm: {
        url: 'http://{s}.tile.osm.org/{z}/{x}/{y}.png',
        attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a>, under CC BY SA'
      },
      //mapbox: {
      //  url: 'http://{s}.tiles.mapbox.com/v3/...Insert MapID.../{z}/{x}/{y}.png',
      //  attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>',
      //},
      surfer: {
        url: 'http://openmapsurfer.uni-hd.de/tiles/roads/x={x}&y={y}&z={z}',
        minZoom: 0,
        maxZoom: 20,
        attribution: 'Imagery from <a href="http://giscience.uni-hd.de/">GIScience Research Group @ University of Heidelberg</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
      },
      esri_nat_geo_world: {
        url: 'http://server.arcgisonline.com/ArcGIS/rest/services/NatGeo_World_Map/MapServer/tile/{z}/{y}/{x}',
        attribution: 'Tiles &copy; Esri &mdash; National Geographic, Esri, DeLorme, NAVTEQ, UNEP-WCMC, USGS, NASA, ESA, METI, NRCAN, GEBCO, NOAA, iPC',
        maxZoom: 16
      },
      esri_world_topo: {
        url: 'http://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
        attribution: 'Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community'
      },
      esri_world_imagery: {
        url: 'http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'
      },
      stamen_watercolor: {
        url: 'http://{s}.tile.stamen.com/watercolor/{z}/{x}/{y}.png',
        attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        subdomains: 'abcd',
        minZoom: 1,
        maxZoom: 16
      },
      stamen_toner_lite: {
        url: 'http://{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png',
        attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        subdomains: 'abcd',
        minZoom: 0,
        maxZoom: 20
      },
      stamen_toner_background: {
        url: 'http://{s}.tile.stamen.com/toner-background/{z}/{x}/{y}.png',
        attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        subdomains: 'abcd',
        minZoom: 0,
        maxZoom: 20
      },
      stamen_toner: {
        url: 'http://{s}.tile.stamen.com/toner/{z}/{x}/{y}.png',
        attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        subdomains: 'abcd',
        minZoom: 0,
        maxZoom: 20
      },
      stamen_terrain: {
        url: 'http://{s}.tile.stamen.com/terrain/{z}/{x}/{y}.png',
        attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        subdomains: 'abcd',
        minZoom: 4,
        maxZoom: 18
      },
      stamen_terrain_background: {
        url: 'http://{s}.tile.stamen.com/terrain-background/{z}/{x}/{y}.png',
        attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        subdomains: 'abcd',
        minZoom: 4,
        maxZoom: 18
      }
    },

    initialize: function(opts) {
      ctxt.__super__.initialize.call(this, opts);
      this.map = this._create_map(opts);

      var m = this.opts.margin;
      var mh = this.h - m.top - m.bottom;
      var mw = this.w - m.left - m.right;
      var svg_wrapper = this.svg_wrapper_div = d3.select(this.map.getPanes().overlayPane).append("div")
        .style('height', mh + 'px')
        .style('width', mw + 'px');
      ;
      //var svg = this.svg = d3.select(this.map.getPanes().overlayPane).append("svg")
      var svg = this.svg = svg_wrapper.append("svg")
        .attr("height", mh)
        .attr("width", mw)
        ;
      this.data_layer = svg.append("g").attr("class", "leaflet-zoom-hide");
      this.stick_layer = this.data_layer.append("g").attr("class", "oml-mapl-stick");
      this.anchor_layer = this.data_layer.append("g").attr("class", "oml-mapl-anchor");
      this.link_layer = this.data_layer.append("g").attr("class", "oml-mapl-link");
      this.marker_layer = this.data_layer.append("g").attr("class", "oml-mapl-marker");
      this.data_layer_ne = this.map.getBounds()._northEast;
      this.nodes_state = {};
      this.marker_force = d3.layout.force()
        .gravity(0)
        .linkDistance(0)
        // .charge(-200) // Defined dynamically later
        .size([this.w, this.h])
      ;

      this._on_map_changed();

    },

    // Find the appropriate data sources and bind to it.
    // If we only get one, we use it for 'nodes', otherwise we expect
    // one with labels 'nodes' and 'links' respectively.
    //
    init_data_source: function() {
      var o = this.opts;
      var sources = o.data_sources;
      var self = this;
      var dss = this.data_sources = {};

      if (sources instanceof Array) {
        sources.forEach(function (ds) {
          if (ds.label == null) ds.label = 'nodes';
          var label = ds.label;
          if (label == 'nodes' || label == 'links') {
            dss[label] = self.init_single_data_source(ds);
          } else {
            OML.error("received unknown data source: %s", ds);
          }
        });
      } else if (sources instanceof Object) {
        _.each(_.pairs(sources), function(p) {
          var label = p[0];
          var ds = p[1];
          if (label == 'nodes' || label == 'links') {
            dss[label] = self.init_single_data_source(ds);
          } else {
            OML.error("received unknown data source: %s", label);
          }
        })
      } else {
        throw "Unexpected datasource description type: " + sources;
      }
    },

    _create_map: function(opts) {
      var m = this.opts.margin;
      var inner_h = this.h - m.top - m.bottom;
      var inner_w = this.w - m.left - m.right;
      var map_div = this.map_div = this.base_el.append("div")
        //.class("mapl-container")
        .style('height', inner_h + 'px')
        .style('width', inner_w + 'px');
      ;

      var mopts = opts.map;
      var map_dom = map_div[0][0];
      var map = L.map(map_dom);
      var self = this;
      map.on('load', function(e) {
        self.update();
      });
      map.setView(
           [mopts.lat, mopts.lon],
           mopts.zoom_level
      );
      map.on("viewreset", function(e) {
        self._on_map_changed();
        console.log("view reset", e);
      });
      map.on("dragend", function(e) {
        self._on_map_changed();
      });
      this._create_tile_layer(mopts).addTo(map);
      return map;
    },

    _on_map_changed: function() {
      var map = this.map;
      var old_ne = map.getBounds()._northEast;
      var offset = this.offset = map.latLngToLayerPoint(old_ne);
      offset.x = offset.x - map.getSize().x;
      this.svg
        .attr("style", "transform: translate3d(" + offset.x + "px, " + offset.y + "px, 0px);")
        ;
      this.update();
    },

    _create_tile_layer: function(opts) {
      var use_grayscale = opts.grayscale || false;
      var tp = opts.tile_provider;
      if (typeof(tp) == "string") {
        tp = this.tile_providers[tp];
      }
      if (tp == null) {
        OML.warn("Unknown tile_provider. Use default one");
        tp = _.values(this.tile_providers)[0];
      }
      var url = tp.url;
      if (url == null) {
        OML.warn("Missing URL for tile_provider. Use default one");
        opts.tile_provider = _.values(this.tile_providers)[0];
        return this._tile_layer(opts); // Better make sure that default has URL
      }
      var topts = _.omit(tp, 'url');
      var tl = use_grayscale ? L.tileLayer.grayscale(tp.url, topts) : L.tileLayer(tp.url, topts);
      return tl;
    },

    _resize: function(w, h) {
      ctxt.__super__._resize.call(this, w, h);
      var m = this.opts.margin;
      if (this.map_div) {
        this.map_div
          .style('height', this.h + 'px')
          .style('width', this.w + 'px');
      }
      if (this.svg) {
        var mh = this.h - m.top - m.bottom;
        var mw = this.w - m.left - m.right;
        this.svg_wrapper_div
          .style('height', mh + 'px')
          .style('width', mw + 'px');
        ;
        this.svg
          .attr("height", mh)
          .attr("width", mw)
        ;

        //this.svg
        //  .attr("height", this.h)
        //  .attr("width", this.w);
      }
      if (this.map) {
        this.map.invalidateSize();
        this._on_map_changed();
      }
    },

    //_resize: function() {
    //  var self = this;
    //
    //  if (self.svg_layer) {
    //    var map_el = self.map_el;
    //    var map = $('#' + map_el);
    //    var div = $('#' + map_el + '_div');
    //    var svg = $('#' + map_el + '_svg');
    //    var map_offset = map.offset();
    //    var div_offset = div.offset();
    //
    //    svg.width($('#' + map_el).width());
    //    svg.height($('#' + map_el).height());
    //
    //
    //  }
    //},

    redraw: function(data) {
      if (this.data_layer) {
        this._draw(data, this.data_layer);
      }
    },

    _draw: function(data, overlay) {
      /** Check if we want to hide the site internals for this zoom level ***/
      var hide_site_internals = false;
      var shopts = this.opts.hide_site_internals
      if (shopts && this.mapping.nodes.site) {
        var zoom = this.map.getZoom();
        var from = shopts.from || 0;
        var to = shopts.to || 10000;
        hide_site_internals =  from <= zoom && zoom <= to;
      }

      this._draw_nodes(data, overlay, hide_site_internals);
      if (data.links) {
        this._draw_links(data.links, overlay, hide_site_internals);
      }
    },

    _draw_nodes: function(data, overlay, hide_site_internals) {
      var self = this;
      var map = this.map;
      var m = this.mapping.nodes;
      var offset = this.offset;
      var anchors_moved = false;

      var x_f = function (d) {
        var lat = d.state.lat;
        var lng = d.state.lon;
        var point = map.latLngToLayerPoint(new L.LatLng(lat, lng));
        var a = d.state.anchor;
        a.p = point;
        var new_x = point.x - offset.x;
        var new_y = point.y - offset.y;
        if (a.x != new_x || a.y != new_y) {
          a.x = a.px = new_x;
          a.y = a.py = new_y;
          anchors_moved = true;
        }
        a.fixed = true; // fixed as far as the graph layout is concerned
        return a.x ;
      };
      var y_f = function (d) {
        return d.state.anchor.y;
      };

      var nodes = hide_site_internals ? this._prepare_sites(data) : this._prepare_nodes(data);

      // anchor point to tie marker off
      var aopts = this.opts.nodes.anchor;
      var anchors = overlay.select('.oml-mapl-anchor').selectAll('.anchor')
          .data(nodes.filter(function(d) {
            return d.state.visibility && d.state.showAnchor;
          }), function (d) {
            return d.key;
          })
          .attr("cx", x_f)
          .attr("cy", y_f)
        ;
      var ae = anchors.enter().append('svg:circle')
        .attr("class", "anchor")
        .attr("cx", x_f)
        .attr("cy", y_f)
        .attr("r", aopts.radius)
        .style("fill", aopts.fill)
      ;
      anchors.exit().remove();

      this._update_markers(nodes, overlay, data, anchors_moved, hide_site_internals);
    },

    _prepare_nodes: function(data) {
      var self = this;
      var map = this.map;
      var m = this.mapping.nodes;
      var id_f = m.id || self.data_sources.nodes.row_id();
      var state = self.nodes_state;
      var zoom = map.getZoom();
      var zopts = this.opts.zoom_visibility;
      var zm = m.zoom_visibility;
      var nodes = _.map(data.nodes, function(d) {
        var key = "k" + id_f(d);
        var s = state[key];
        if (s == null) {
          s = state[key] = {
            anchor: {key: key},
            marker: {}
          };
        }
        // Check if node is visible at the current zoom level
        s.visibility = true;
        if (zm) {
          var k = zm(d);
          var o = zopts[k];
          if (o) { // default is visible
            var from = o.from || 0;
            var to = o.to || 10000;
            s.visibility =  from <= zoom && zoom <= to
          }
        }
        // Check if the node has a proper location, otherwise don't display anchor
        var lat = s.lat = m.latitude(d);
        var lon = s.lon = m.longitude(d);
        s.showAnchor = s.marker.isAnchored = (Math.abs(lat) <= 90 && Math.abs(lon) <= 180);
        if (!s.showAnchor) {
          var i = 0;
        }
        return {
          key: key,
          value: d,
          state: s,
          isSite: false
        };
      });
      return nodes;
    },

    _prepare_sites: function(data) {
      var self = this;
      var map = this.map;
      var m = this.mapping.nodes;
      var id_f = m.id || self.data_sources.nodes.row_id();
      var state = self.nodes_state;

      var sites = _.map(_.groupBy(data.nodes, function(d) { return m.site(d) }), function(ds, site_name) {
        var key = "s" + site_name;
        var s = state[key];
        var fn = ds[0];
        if (s == null) {
          s = state[key] = {
            anchor: {key: key},
            marker: {},
            visibility: true
          };
        }
        // Check if the site has a proper location, otherwise don't display anchor
        var lat = s.lat = m.latitude(fn);
        var lon = s.lon = m.longitude(fn);
        s.showAnchor = s.marker.isAnchored = (Math.abs(lat) <= 90 && Math.abs(lon) <= 180);
        if (!s.showAnchor) {
          var i = 0;
        }
        return {
          key: key,
          values: ds,
          state: s,
          isSite: true
        };
      });
      return sites;
    },


    _update_markers: function(nodes, overlay, data, anchors_moved, hide_site_internals) {
      var markers;
      if (hide_site_internals) {
        markers = this._update_site_markers(nodes, overlay);
      } else {
        markers = this._update_node_markers(nodes, overlay);
      }
      this._update_marker_position(nodes, markers, overlay, data, anchors_moved, hide_site_internals);
    },

    _update_node_markers: function(nodes, overlay) {
      var self = this;
      var m = this.mapping.nodes;
      var m_f = function (d, m) {
        return m(d.value || d.values[0]);
      };

      var markers = overlay.select('.oml-mapl-marker').selectAll('.marker')
          .data(nodes.filter(function(d) {
            return d.state.visibility;
          }), function (d) {
            return d.key;
          })
          .call(this._style_marker, m_f, m)
        ;

      markers.enter().append('svg:circle')
        .attr("class", "marker")
        .call(this._style_marker, m_f, m)
        .call(self._configure_events, self.opts.events, self)
        .style("cursor", 'pointer')
        .on('click', function (d) {
          var x = self;
          var i = 0;
        })
        // .on('mouseover', function(d) {
        // var x = self;
        // var i = 0;
        // })
      ;
      markers.exit().remove();
      return markers;
    },

    _update_site_markers: function(sites, overlay) {
      var self = this;
      var m = this.mapping.nodes;
      var m_f = function (d, m) {
        return m(d.value || d.values[0]);
      };

      var arc = d3.svg.arc()
        .outerRadius(function(d) {
          // TODO: FIX ME
          return m.site_radius(d.data[0]);
        })
        .innerRadius(0);

      var markers = overlay.select('.oml-mapl-marker').selectAll('.marker')
          .data(sites, function (d) {
            return d.key;
          })
        ;
      markers.enter().append('svg:g')
        .attr("class", "marker")
        .style("cursor", 'pointer')
      ;
      markers.exit().remove();

      var pie_f = d3.layout.pie()
        .sort(null)
        .value(function(d) {
          return d.length;
        });
      function style_pie(sel) {
        sel.attr("d", arc)
          .style("fill", function(d) {
            var first = d.data[0];
            var c = m.fill_color(first);
            return c;
          })
        ;
      }
      var pies = markers.selectAll('.arc')
        .data(function(d) {
          var g = _.groupBy(d.values, function(d) {
            var status = m.status(d);
            return status;
          });
          var arcs = pie_f(_.values(g));
          return arcs;
        })
        .call(style_pie);

      pies.enter().append("path")
        .attr("class", "arc")
        .call(style_pie);
      //  .attr("d", arc)
      //  .style("fill", function(d) {
      //    var first = d.data[0];
      //    var c = m.fill_color(first);
      //    return c;
      //  });
      //;
      pies.exit().remove();

      return markers;
    },

    _style_site_marker: function(sel, m_f, m) {
      sel
        //.attr("cx", x_f)
        //.attr("cx", function(d) {
        //  var x = x_f(d);
        //  return x;
        //})
        //.attr("cy", y_f)
        //.attr("r", function(d) {return m_f(d, m.radius);})
        .attr("r", m.radius)
        .style("fill", function(d) {return m_f(d, m.fill_color);})
        .style("stroke", function(d) {return m_f(d, m.stroke_color);})
        .style("stroke-width", function(d) {
          return m_f(d, m.stroke_width);
        })
      ;

    },


    _update_marker_position: function(node_data, markers, overlay, data, anchors_moved, hide_site_internals) {
      var nodes = [];
      var links = [];
      node_data.forEach(function(d) {
        var s = d.state;
        if (!(s.visibility)) return;
        var m = s.marker;
        nodes.push(m);
        if (!(s.showAnchor)) return;
        var a = s.anchor;
        nodes.push(a);
        links.push({source : m, target: a, weight : 1, stick: true, anchored: true});
      });

      // Also add links between markers if there is a link and the corresponding anchors are very close together
      // as to keep them separated.
      // Also add links where at least one of them is NOT anchored.
      if (data.links && !hide_site_internals) {
        var key2node = _.reduce(node_data, function (h, n) {
          h[n.key] = n;
          return h;
        }, {});
        var m = this.mapping.links;
        var min_distance = this.opts.links.min_distance;
        var d2_thres = min_distance * min_distance;
        data.links.forEach(function (d) {
          var from = key2node['k' + m.from(d)];
          var to = key2node['k' + m.to(d)];
          if (from == null || to == null) {
            throw "Unknown node references"
          }
          if (! (from.state.visibility && to.state.visibility)) return;

          if (from.state.showAnchor && to.state.showAnchor) {
            // stick
            var a1 = from.state.anchor;
            var a2 = to.state.anchor;
            var dx = a1.x - a2.x;
            var dy = a1.y - a2.y;
            var d2 = dx * dx + dy * dy;
            if (d2 < d2_thres)
              links.push({source: from.state.marker, target: to.state.marker, weight: 1, anchored: true, stick: false});
          } else {
            // un-anchored
            links.push({source: from.state.marker, target: to.state.marker, weight: 1, anchored: false, stick: false});
          }
        });
      }


      // Draw a line between the anchor and the marker
      var sticks = overlay.select('.oml-mapl-stick').selectAll("line.link")
          .data(_.filter(links, function(d) { return d.stick; }), function(d) { return d.target.key; });
      // Enter any new links.
      var so = this.opts.nodes.stick;
      sticks.enter().insert("svg:line", ".node")
        .attr("class", "link")
        .attr("stroke", so.color)
        .attr("stroke-width", so.width)
      ;
      // Exit any old links.
      sticks.exit().remove();

      if (! anchors_moved) return;

      // Restart the label force layout.
      var self = this;
      function position_node(sel) {
        sel.attr("cx", function(d) {
          return d.state.marker.x;
        })
          .attr("cy", function(d) {
            return d.state.marker.y;
          })
        ;
      }
      function position_site(sel) {
        sel.attr("style", function(d) {
          var m = d.state.marker;
          return "transform: translate(" + m.x + "px, " + m.y + "px);"
        });
      }

      this.marker_force
        .nodes(nodes)
        .links(links)
        .charge(function(d) {
          // fixed anchors don't repel
          return d.fixed ? 0 : -100;
        })
        .linkDistance(function(d) {
          if (d.stick) {
            return 0;
          } else {
            if (d.anchored) {
              return min_distance;
            } else {
              return 30;
            }
          }
        })
        .on("tick", function(e) {
          var offset = self.offset;
          var offx = offset.x;
          var offy = offset.y;

          markers.call(hide_site_internals ? position_site : position_node);
          //  .attr("cx", function(d) {
          //    return d.state.marker.x;
          //  })
          //  .attr("cy", function(d) {
          //    return d.state.marker.y;
          //  })
          //;
          sticks
            .attr("x1", function(d) {
              return d.source.x;
            })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; })
          ;
          if (self.links) {
            self.links
              .attr("x1", function(d) { return d.from.x; })
              .attr("y1", function(d) { return d.from.y; })
              .attr("x2", function(d) { return d.to.x; })
              .attr("y2", function(d) { return d.to.y; })
            ;
          }

        })
        .start();
    },

    _style_marker: function(sel, m_f, m) {
      sel
        //.attr("cx", x_f)
        //.attr("cx", function(d) {
        //  var x = x_f(d);
        //  return x;
        //})
        //.attr("cy", y_f)
        //.attr("r", function(d) {return m_f(d, m.radius);})
        .attr("r", m.radius)
        .style("fill", function(d) {return m_f(d, m.fill_color);})
        .style("stroke", function(d) {return m_f(d, m.stroke_color);})
        .style("stroke-width", function(d) {
          return m_f(d, m.stroke_width);
        })
      ;

    },

    _draw_links: function(rows, overlay, hide_site_internals) {
      var self = this;
      var m = this.mapping.links;
      var offset = this.offset;
      var data = hide_site_internals ? this._prepare_site_links(rows) : this._prepare_node_links(rows);
      //var state = this.nodes_state;
      //var id_f = m.id || self.data_sources.nodes.row_id();
      //var data = _.compact(_.map(rows, function(d) {
      //  var from = state["k" + m.from(d)];
      //  var to = state["k" + m.to(d)];
      //  if (from == null || to == null) {
      //    throw "Unknown node references"
      //  }
      //  if (! (from.visibility && to.visibility)) return;
      //  var key = id_f(d);
      //  return {
      //    key: key,
      //    from: from.marker,
      //    to: to.marker,
      //    data: d
      //  };
      //}));
      var offx = offset.x;
      var offy = offset.y
      function x1_f(d) {
        return d.from.x - offx;
      }
      function y1_f(d) {
        return d.from.y - offy;
      }
      function x2_f(d) {
        return d.to.x - offx;
      }
      function y2_f(d) {
        return d.to.y - offy;
      }
      // Draw a line between the anchor and the marker
      this.links = overlay.select('.oml-mapl-link').selectAll("line.link")
          .data(data, function(d) { return d.key; })
          .call(self._style_links, x1_f, y1_f, x2_f, y2_f, m)
        ;
      // Enter any new links.
      this.links.enter().insert("svg:line", ".link")
        .attr("class", "link")
        //.style("cursor", 'pointer')
        .call(self._style_links, x1_f, y1_f, x2_f, y2_f, m)
        .call(self._set_link_interaction_mode, self)
        //.on('click', function (d) {
        //  var x = self;
        //  var i = 0;
        //})
      ;
      // Exit any old links.
      this.links.exit().remove();
    },

    _prepare_node_links: function(rows) {
      var self = this;
      var m = this.mapping.links;
      var state = this.nodes_state;
      var id_f = m.id || self.data_sources.nodes.row_id();
      var links = _.compact(_.map(rows, function(d) {
        var from = state["k" + m.from(d)];
        var to = state["k" + m.to(d)];
        if (from == null || to == null) {
          throw "Unknown node references"
        }
        if (! (from.visibility && to.visibility)) return;
        var key = id_f(d);
        return {
          key: key,
          from: from.marker,
          to: to.marker,
          data: d
        };
      }));
      return links;
    },

    _prepare_site_links: function(rows) {
      var self = this;
      var m = this.mapping.links;
      var state = this.nodes_state;
      var id_f = m.id || self.data_sources.nodes.row_id();
      var links = _.compact(_.map(_.groupBy(rows, function(d) {
        return [m.from_site(d), m.to_site(d)];
      }), function(ls, key) {
        var first = ls[0];
        var from_site = m.from_site(first);
        var to_site = m.to_site(first);
        if (from_site == to_site) return null;

        var from = state["s" + from_site];
        var to = state["s" + to_site];
        if (from == null || to == null) {
          throw "Unknown node references"
        }
        if (! (from.visibility && to.visibility)) return;
        return {
          key: key,
          from: from.marker,
          to: to.marker,
          data: first  /* TODO: This ignores any other link between two sites */
        };
      }));
      return links;
    },



    _style_links: function(sel, x1_f, y1_f, x2_f, y2_f, m) {
      sel
        .attr("x1", x1_f)
        .attr("y1", y1_f)
        .attr("x2", x2_f)
        .attr("y2", y2_f)
        .attr("stroke", function(d) {
          return m.stroke_color(d.data);
        })
        .attr("stroke-width", function(d) {
          return m.stroke_width(d.data);
        })
      ;

    },

    _set_link_interaction_mode: function(le, self) {
      var o = self.opts;

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
        .style('cursor', 'pointer')
        ;
      }
    },

    _on_link_selected: function(d) {
      var id = d.key;

      if (this.selected_link == id) {
        // if same link is clicked twice, unselect it
        this._render_selected_link(null);
        //this._render_selected_node(null);
      } else {
        this._render_selected_link(id);
        //this._render_selected_node('_NONE_');
        this._report_selected(id, 'links', d.data);
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

      var opacity = this.opts.links.selected_opacity || 0.3
      this.links
        .transition()
        .style("opacity", function(d) {
          if (selected_id) {
            return d.key == selected_id ? 1 : opacity;
          } else {
            return 1;
          }
        })
        .delay(0)
        .duration(300);
      ;
      //// Ensure that selected link is shown fully
      //this.graph_layer.selectAll("path.link")
      // .filter(function(d) {
      //   var key = key_f(d);
      //   return selected_id == null || key == selected_id;
      // })
      // .transition()
      //   .style("opacity", 1.0)
      //   .delay(0)
      //   .duration(300);

    },

    _configure_events: function(el, events, self) {
      _.each(events, function(v, event) {
        el.on(event, function(d) {
          var ev_name = v;
          OHUB.trigger(ev_name, {el: self, datum: d.value, schema: self.schema});
        });
      });
    },

    //// Should only call this after Google map is initialised
    //_configure_base_layer: function(vis) {
    //  var overlay = this.overlay = new google.maps.OverlayView();
    //  var self = this;
    //
    //  // Add the container when the overlay is added to the map.
    //  overlay.onAdd = function() {
    //    var overlay_layer = this.getPanes().overlayMouseTarget;
    //    d3.select(overlay_layer).attr('id', self.map_el + '_over');
    //    self.div_layer = d3.select(overlay_layer).append("div")
    //        .attr('id', self.map_el + '_div')
    //        //.style("position", "absolute")
    //        //.attr('class', this.base_css_class);
    //        ;
    //    self.svg_layer = self.div_layer.append("svg:svg")
    //        .attr('id', self.map_el + '_svg')
    //        //.style("position", "absolute")
    //        .style('z-index', '10')
    //        ;
    //    self.draw_layer = self.svg_layer.append("svg:g")
    //        ;
    //    self._resize();
    //
    //    overlay.draw = function() {
    //      //console.log("overlay draw");
    //      self._draw(this);
    //    };
    //  };
    //  overlay.setMap(this.map);
    //}

    _report_selected: function(selected_id, type, datum) {
      var ds = this.data_sources[type];
      var msg = {id: selected_id, type: type, source: this, data_source: ds, datum: datum};
      OHUB.trigger("graph.selected", msg);
      OHUB.trigger("graph." + ds.name + ".selected", msg);
      var tname = this.opts.name;
      if (tname) {
        OHUB.trigger("graph." + tname + ".selected", msg);
        OHUB.trigger("graph." + tname + "." + type + ".selected", msg);
      }
    },

    _report_deselected: function(selected_id, type, datum) {
      var ds = this.data_sources[type];
      var msg = {id: selected_id, type: type, source: this, data_source: ds, datum: datum};
      OHUB.trigger("graph.deselected", msg);
      OHUB.trigger("graph." + ds.name + ".deselected", msg);
      var tname = this.opts.name;
      if (tname) {
        OHUB.trigger("graph." + tname + ".deselected", msg);
        OHUB.trigger("graph." + tname + "." + type + ".deselected", msg);
      }
    }
  });

  return ctxt;
});


/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/
