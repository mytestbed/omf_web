



define(["graph/abstract_map_l", "vendor/leaflet/leaflet-src", "graph/quad_tree", "css!vendor/leaflet/leaflet"], function (abstract, L, QTree) {

  var ctxt = abstract.extend({

    decl_properties: {
      map: [
        ['id', 'key', {property: 'id', optional: true}],
        // latitude
        ['north', 'key', {property: 'north'}],
        ['lat', 'key', {property: 'lat'}],
        ['south', 'key', {property: 'south'}],
        // longitude
        ['east', 'key', {property: 'east'}],
        ['lon', 'key', {property: 'lon'}],
        ['west', 'key', {property: 'west'}]
      ],
      data: [
        ['id', 'key', {property: 'id', optional: true}],
        ['value', 'key', {property: 'value'}],
        ['fill_color', 'color', 'mediumpurple'],
        ['stroke_width', 'int', 1],
        ['stroke_color', 'color', 'white']
      ]
    },

    defaults: function() {
      return this.deep_defaults({

      }, ctxt.__super__.defaults.call(this));
    },

    initialize: function(opts) {
      // Lat range: 43.7 - 50.0
      // Lon range: -123.0 - -65.0
      this.qtree = QTree(24, -65, 50, -123, 0, -99.0, 50.0);
      ctxt.__super__.initialize.call(this, opts);
      d3.select(this.map.getPanes().overlayPane).style("opacity", "0.7");
    },

    _add_data_layers: function() {
      this.dot_layer = this.svg.append("g").attr("class", "leaflet-zoom-hide");
    },

    // Find the appropriate data sources and bind to it.
    // If we only get one, we use it for 'nodes', otherwise we expect
    // one with labels 'nodes' and 'links' respectively.
    //
    init_data_source: function() {
      var o = this.opts;
      var sources = o.data_sources;
      var self = this;

      if (! (sources instanceof Array)) {
        throw "Expected an array";
      }
      var dss = this.data_sources = {};
      sources.forEach(function(ds) {
        if (ds.label == null) ds.label = 'map';
        var label = ds.label;
        if (label == 'map' || label == 'data') {
          dss[label] = self.init_single_data_source(ds);
        } else {
          OML.error("received unknown data source: %s", ds);
        }
      });
    },

    _draw: function(data, overlay) {
      if (data.map.length == 0) return;
      if (data.map.length != data.data.length) return;
      var self = this;
      var map = this.map;
      var m = this.mapping.map;
      var offset = this.offset;
      var qt = this.qtree;
      if (! qt) {
        return;
      }
      var ds_map = this.data_sources.map;
      if (ds_map.generation_id != this.last_map_generation) {
        this.last_map_generation = ds_map.generation_id;
        qt.clear();
        _.each(data.map, function (d) {
          var x = m.lon(d);
          var y = m.lat(d);
          qt.insert(x, y, d);
        });
      }

      var b = map.getBounds();
      var ne = b._northEast;
      var sw = b._southWest;
      var dm = this.mapping.data;
      var values = {};
      var max_value = 0;
      _.each(data.data, function(d) {
        values[dm.id(d)] = d;
        var v = dm.value(d);
        if (v > max_value) max_value = v;
      });
      var squares = qt.map(this.zoomLevel + 3, sw.lat, ne.lng, ne.lat, sw.lng, function(points, q) {
        var cnt = 0;
        var sum = 0;
        var max = -99999;
        var min = 99999;
        if (points.length == 2) {
          var i = 0;
        }
        _.each(points, function(p) {
          var d = values[m.id(p)];
          var v = dm.value(d);
          if (v > max) max = v;
          if (v < min) min = v;
          sum += v;
          cnt += 1;
        });


        var nw = map.latLngToLayerPoint(new L.LatLng(q.s, q.w))
        var se = map.latLngToLayerPoint(new L.LatLng(q.n, q.e))
        return {k: nw.x * 1000 + nw.y,
          x: nw.x, y: nw.y, w: se.x - nw.x, h: se.y - nw.y,
          v: sum / cnt, min: min, max: max
        };
      });

      var color_f = this.decl_color_func["green_red()"]();
      function mapToColor(v) {
        var sv = v / max_value;
        var color = color_f(sv);
        return color;
      }

      var squares = overlay.selectAll('.square')
          .data(squares, function(d) { return d.k })
          .attr("x", function(d) { return d.x - offset.x; })
          .attr("y", function(d) { return d.y - offset.y; })
        ;
      squares.enter().append('svg:rect')
        .attr("class", "square")
         // x="50" y="20" width="150" height
        .attr("x", function(d) { return d.x - offset.x; })
        .attr("y", function(d) { return d.y - offset.y; })
        .attr("width", function(d) { return d.w; })
        .attr("height", function(d) { return d.h; })
        .style("fill", function(d) {
          return mapToColor(d.v);
        })
        //.style("fill", "yellow")
        .style("stroke", function(d) {
          return mapToColor(d.max);
        })
      ;
      squares.exit().remove();

      //this._show_data_points(data);
    },

    _show_data_points: function(data) {
      var m = this.mapping.map;
      var map = this.map;
      var offset = this.offset;

      var dots = this.dot_layer.selectAll('.dot')
          .data(data.map, function(d) { return d[0] })
          .attr("cx", function(d) {
            var p = map.latLngToLayerPoint(new L.LatLng(m.lat(d), m.lon(d)));
            return p.x - offset.x;
          })
          .attr("cy", function(d) {
            var p = map.latLngToLayerPoint(new L.LatLng(m.lat(d), m.lon(d)));
            return p.y - offset.y;
          })
          ;
      dots.enter().append('svg:circle')
        .attr("class", "dot")
        .attr("cx", function(d) {
          var p = map.latLngToLayerPoint(new L.LatLng(m.lat(d), m.lon(d)));
          //var y = m.lat(d);d[3], d[7]));
          return p.x - offset.x;
        })
        .attr("cy", function(d) {
          var p = map.latLngToLayerPoint(new L.LatLng(m.lat(d), m.lon(d)));
          return p.y - offset.y;
        })
        .attr("r", 2)
        .style("fill", "black")
      ;
      dots.exit().remove();
    }

  });

  return ctxt;
});


//var QTree = function(n, e, s, w, level) {
//  var cx = w + (e - w) / 2;
//  var cy = n + (s - n) / 2;
//  var ne, se, sw, nw;
//  var point;
//
//  var ctxt = {
//    n: n, e: e, s: s, w: w,
//    level: level,
//    isLeaf: false
//  };
//
//  function findQuad(q, n, e, s, w) {
//    if (! q) {
//      q = QTree(n, e, s, w, level + 1);
//    }
//    return q;
//  }
//
//  // Insert data into a sub quad
//  function splitInsert(p) {
//    var qt;
//    if (x >= cx) {
//      if (y >= cy) {
//        qt = se = findQuad(se, cy, e, s, cx);
//      } else {
//        qt = sw = findQuad(sw, cy, cx, s, w);
//      }
//    } else {
//      if (y >= cy) {
//        qt = ne = findQuad(ne, n, e, cy, cx);
//      } else {
//        qt = nw = findQuad(nw, n, cx, cy, w);
//      }
//    }
//    return qt.insertPoint(p);
//  }
//
//  ctxt.insert = function(x, y, data) {
//    ctxt.insertPoint({x: x, y: y, data: data})
//  }
//
//
//  ctxt.insertPoint = function(p) {
//    if (ne || se || sw || nw) {
//      return splitInsert(p);
//    } else {
//      // not split yet
//      if (point) {
//        splitInsert(point);
//        point = null;
//        return splitInsert(p);
//      } else {
//        point = p;
//        return ctxt;
//      }
//    }
//  }
//
//  ctxt.data = function () {
//    if (point) {
//      return [point];
//    } else {
//      var r = [];
//      if (ne) r.concat(ne.data());
//      if (se) r.concat(se.data());
//      if (sw) r.concat(sw.data());
//      if (nw) r.concat(nw.data());
//      return r;
//    }
//  };
//
//  ctxt.isInside = function(bn, be, bs, bw) {
//    return (n >= bn && e <= be && s <= bs && w >= bw);
//  };
//
//  // Returns true if this quad intersects with the passed
//  // in bounding box.
//  ctxt.isIntersecting = function(bn, be, bs, bw) {
//    var v = w <= bw && bw < e || w <= be && be < e || bw < w && be >= e;
//    var h = n <= bn && bn < s || n <= bs && bs < s || bn < n && bs >= s;
//    return v & h;
//  };
//
//  //function map(q, r, targetLevel, bn, be, bs, bw, callback) {
//  //  if (q == null) return r;
//  //  if (!q.isInside(bn, be, bs, bw)) return r;
//  //  var qr = q.map(targetLevel, callback);
//  //  return r.concat(qr);
//  //  //if (q.level == targetLevel) {
//  //  //  r.push(qr);
//  //  //} else {
//  //  //  // append
//  //  //  _.
//  //  //}
//  //}
//
//  ctxt.map = function(bn, be, bs, bw, callback) {
//    if (! ctxt.isIntersecting(bn, be, bs, bw)) {
//      return [];
//    }
//    if (point) {
//      return callback(point, ctxt);
//    }
//    var r = [];
//    if (ne) r.concat(ne.map(bn, be, bs, bw, callback));
//    if (se) r.concat(se.map(bn, be, bs, bw, callback));
//    if (sw) r.concat(sw.map(bn, be, bs, bw, callback));
//    if (nw) r.concat(nw.map(bn, be, bs, bw, callback));
//    return r;
//  };
//
//  return ctxt;
//};
//
////var QLeaf = function(x, y, level) {
////  var data;
////
////  var ctxt = {
////    level: level,
////    isLeaf: true
////  };
////
////  ctxt.insert = function (x, y, d) {
////    data = d;
////    return ctxt;
////  };
////
////  ctxt.data = function () {
////    return [data];
////  };
////
////  ctxt.isInside = function(bn, be, bs, bw) {
////    return (y >= bn && x <= be && y <= bs && x >= bw);
////  }
////
////  ctxt.map = function(targetLevel, callback) {
////    if (level == targetLevel) {
////      return callback(ctxt, y, x, y, x, level);
////    }
////  };
////
////
////  return ctxt;
////};

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/
