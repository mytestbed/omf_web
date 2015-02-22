

//OML.append_require({paths: {leaflet: '/vendor/leaflet'}, shim: {leaflet: {exports: 'L'}}}
OML.append_require_shim("vendor/leaflet/leaflet-src", {
  exports: 'L',
  deps: ["vendor/d3/d3", "css!vendor/leaflet/leaflet"]
});

define(["graph/abstract_widget", "vendor/leaflet/leaflet-src"], function (abstract, L) {

  var ctxt = abstract.extend({
    //this.opts = opts;

    defaults: function() {
      return this.deep_defaults({
        margin: {
          left: 0,
          top:  10,
          right: 20,
          bottom: 0
        },
        location: { lat: 39.0997300	, lon: -94.5785700}, // Kansas City
        zoom_level: 4,
        tile_provider: 'esri_world_topo',

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
      var svg = this.svg = d3.select(this.map.getPanes().overlayPane).append("svg")
        .attr("height", this.h - m.top - m.bottom)
        .attr("width", this.w - m.left - m.right)
        ;
      this.data_layer = svg.append("g").attr("class", "leaflet-zoom-hide");
      this.data_layer_ne = this.map.getBounds()._northEast;
      this._add_data_layers();

      this._on_map_changed();

    },

    _add_data_layers: function() {},

    _create_map: function(opts) {
      var m = this.opts.margin;
      var inner_h = this.h - m.top - m.bottom;
      var inner_w = this.w - m.left - m.right;
      var map_div = this.map_div = this.base_el.append("div")
        //.class("mapl-container")
        .style('height', inner_h + 'px')
        .style('width', inner_w + 'px');
      ;

      var loc = opts.location;
      var map_dom = map_div[0][0];
      var map = L.map(map_dom);
      var self = this;
      map.on('load', function(e) {
        self.update();
      });
      map.setView(
           [loc.lat, loc.lon],
           opts.zoom_level
      );
      map.on("viewreset", function(e) {
        self._on_map_changed();
        console.log("view reset", e);
      });
      map.on("dragend", function(e) {
        self._on_map_changed();
      });
      this._create_tile_layer(opts).addTo(map);
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
      var zoom = map.getZoom();
      if (this.zoomLevel != zoom) {
        this.zoomLevel = zoom;
        this._on_zoom_changed(zoom);
      }
      this.update();
    },

    _on_zoom_changed: function(zoom) {},

    _create_tile_layer: function(opts) {
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
      var tl = L.tileLayer(tp.url, topts);
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
        this.svg
          .attr("height", this.h)
          .attr("width", this.w);
      }
      if (this.map) {
        this.map.invalidateSize();
        this._on_map_changed();
      }
    },

    redraw: function(data) {
      if (this.data_layer) {
        this._draw(data, this.data_layer);
      }
    },

    _draw: function(data, overlay) {
      //this._draw_nodes(data, overlay);
      //if (data.links) {
      //  this._draw_links(data.links, overlay);
      //}
    },



    _report_selected: function(selected_id, type, datum) {
      var ds = this.data_sources[type];
      var msg = {id: selected_id, type: type, source: this, data_source: ds, datum: datum};
      OHUB.trigger("graph.selected", msg);
      OHUB.trigger("graph." + ds.name + ".selected", msg);
    },

    _report_deselected: function(selected_id, type, datum) {
      var ds = this.data_sources[type];
      var msg = {id: selected_id, type: type, source: this, data_source: ds, datum: datum};
      OHUB.trigger("graph.deselected", msg);
      OHUB.trigger("graph." + ds.name + ".deselected", msg);
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
