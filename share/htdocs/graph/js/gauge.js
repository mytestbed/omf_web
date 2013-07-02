/**
 * Code borrowed from http://tomerdoron.blogspot.com/2011/12/google-style-gauges-using-d3js.html
 * Gist: https://gist.github.com/1499279
 */

L.provide('OML.gauge', ["graph/js/abstract_chart", "#OML.abstract_chart"], function () {

  OML.gauge = OML.abstract_chart.extend({
    //this.opts = opts;
    
    decl_properties: [
      ['value', 'key', {property: 'value'}],
      ['id', 'key'],
      // ['y_axis', 'key', {property: 'y'}], 
      ['radius', 'int', 10],       
      ['stroke_width', 'int', 2], 
      ['stroke_color', 'color', 'black'],
      ['fill_color', 'color', 'orange']
    ],
    
    defaults: function() {
      return this.deep_defaults({
        diameter: 0.9,
        margin: {
          left: 20,
          top:  20,
          right: 20,
          bottom: 20
        },
      }, OML.gauge.__super__.defaults.call(this));      
    },    

    configure_base_layer: function(vis) {
      this.gauges_ctxt = {};  // keep context for each gauge
      
      var base = this.base_layer = vis.append("svg:g")
                                      .attr("class", "gauges")
                                      ;

      this.legend_layer = base.append("svg:g");
      this.gauges = []; // where we keep the gauge instances

    },
    
    redraw: function(data) {
      var self = this;
      var o = this.opts;
      var ca = this.widget_area;
      
      var m = this.mapping;
      var value_f = m.value;
      var id_f = m.id;

      var fd = _.filter(data, function(d) {return value_f(d) >= 0});
      var sd = _.groupBy(fd, id_f);
      var d =  _.map(sd, function(v, k) {return _.last(v)});
      data = d;
      var data_len = self.gauges.length;

      var remove = function(array, from, to) {
        var rest = array.slice((to || from) + 1 || array.length);
        array.length = from < 0 ? array.length + from : from;
        return array.push.apply(array, rest);
      };
      
      var gauges = this.base_layer
                    .selectAll(".gauge")
                    .data(data, function(d) { 
                      return id_f(d); 
                    })
                    ;
      gauges.enter()
              .append("svg:g")
              .attr("class", "gauge")
              .each(function(d, i) {
                var opts = {
                  min: 0, max: 15000,
                  majorTicks: 5, minorTicks: 5
                };
                var g = self.create_gauge(this, ca, opts)();
                var i = self.gauges.length;
                self.gauges.push({el: this, gauge: g});
                g.update(value_f(d), i, i + 1);
              })
              ;
      // update
      gauges.each(function(d, i) {
        var i; var n = self.gauges.length;
        for (i = 0; i < n; i++) {
          var g = self.gauges[i];
          if (g.el == this) {
            g.gauge.update(value_f(d), i, n);
            break;
          }
        }
      });
      gauges.exit()
        .transition().duration(300).style("opacity", 0)
          .each("end", function(d) {
            console.log(d);
            var i; var n = self.gauges.length;
            for (i = 0; i < n; i++) {
              var g = self.gauges[i];
              if (g.el == this) {
                remove(self.gauges, i);
                break;
              }
            }
          })
          .remove();
    },
    
    create_gauge: function(base_el, widget_area, opts) {
      var selection = d3.select(base_el);
      var range;
      var raduis, cx, cy, size;
      var body_layer, pointer_layer;
      
      function g() {
        return g;
      }
      
      g.update = function(value, gauge_idx, gauge_cnt) {
        range = opts.max - opts.min;
        var ca = widget_area;
        var h = ca.h / gauge_cnt;
        var y_off = ca.oh - ca.h - ca.y;
        y_off += h * gauge_idx;
        var w = ca.w;
        var x_off = ca.x;
        
        cx = ca.w / 2
        cy = h / 2;
        size = (h > w ? w : h);
        scale = 1.0 / 2;
        raduis = scale * size;
        
        var t = "translate(" + x_off + ", " + y_off + ")";
        selection.attr("transform", t);
        
        var gb = selection.selectAll(".gauge_body")
                    .data([[opts.max, opts.min, size]], function(d) { return d });
        gb.enter()
          .append("svg:g")
          .attr("class", "gauge_body")
          .each(function(d) {draw_body(this)})
          ;
        gb.exit().remove();

        var gp = selection.selectAll(".gauge_pointer")
                    .data([[value, opts.max, opts.min, size]], function(d) { return d });
        gp.enter()
          .append("svg:g")
          .attr("class", "gauge_pointer")
          .each(function(d) {draw_pointer(value, this)})
          ;
        gp.each(function(d) {draw_pointer(value, this)})
        gp.exit().remove();
        
        return g;
        
      }
      
      function draw_body(body_el) {
        body_layer = d3.select(body_el);
        
        body_layer.append("svg:circle")
              .attr("cx", cx)           
              .attr("cy", cy)               
              .attr("r", raduis)
              .style("fill", "#ccc")
              .style("stroke", "#000")
              .style("stroke-width", "0.5px");
    
        body_layer.append("svg:circle")              
              .attr("cx", cx)           
              .attr("cy", cy)               
              .attr("r", 0.9 * raduis)
              .style("fill", "#fff")
              .style("stroke", "#e0e0e0")
              .style("stroke-width", "2px");
              
              
        draw_scale();
        
      }
      
      function draw_scale() {
        var fontSize = Math.round(size / 16);   
        var majorDelta = range / (opts.majorTicks - 1);
        for (var major = opts.min; major <= opts.max; major += majorDelta) {
          var minorDelta = majorDelta / opts.minorTicks;
          for (var minor = major + minorDelta; minor < Math.min(major + majorDelta, opts.max); minor += minorDelta) {
            var point1 = valueToPoint(minor, 0.75);
            var point2 = valueToPoint(minor, 0.85);
            body_layer.append("svg:line")
                  .attr("x1", point1.x)
                  .attr("y1", point1.y)
                  .attr("x2", point2.x)
                  .attr("y2", point2.y)
                  .style("stroke", "#666")
                  .style("stroke-width", "1px");
          }
    
          var point1 = valueToPoint(major, 0.7);
          var point2 = valueToPoint(major, 0.85);  
          body_layer.append("svg:line")
                .attr("x1", point1.x)
                .attr("y1", point1.y)
                .attr("x2", point2.x)
                .attr("y2", point2.y)
                .style("stroke", "#333")
                .style("stroke-width", "2px");
    
          if (major == opts.min || major == opts.max) {
            var point = valueToPoint(major, 0.63);
            body_layer.append("svg:text")
                  .attr("x", point.x)
                  .attr("y", point.y)           
                  .attr("dy", fontSize / 3)
                  .attr("text-anchor", major == opts.min ? "start" : "end")
                  .text(d3.format('.3s')(major))
                  .style("font-size", fontSize + "px")
                  .style("fill", "#333")
                  .style("stroke-width", "0px");
          }
        }   
      }
      
      function draw_pointer(value, pointer_el) {
        pointer_layer = d3.select(pointer_el);

        var delta = range / 13;
    
        var head = valueToPoint(value, 0.85);
        var head1 = valueToPoint(value - delta, 0.12);
        var head2 = valueToPoint(value + delta, 0.12);
    
        var tailValue = value -  (range * (1/(270/360)) / 2);
        var tail = valueToPoint(tailValue, 0.28);
        var tail1 = valueToPoint(tailValue - delta, 0.12);
        var tail2 = valueToPoint(tailValue + delta, 0.12);
    
        var data = [head, head1, tail2, tail, tail1, head2, head];
    
        var line = d3.svg.line()
                  .x(function(d) { return d.x })
                  .y(function(d) { return d.y })
                  .interpolate("basis");
    
        //var pointerContainer = body.select(".pointerContainer"); 
        var pointer = pointer_layer.selectAll("path").data([data])                   
    
        pointer.enter()
            .append("svg:path")
              .attr("d", line)
              .style("fill", "#dc3912")
              .style("stroke", "#c63310")
              .style("fill-opacity", 0.7)
    
        pointer.transition()
              .attr("d", line) 
              //.ease("linear")
              //.duration(5000);
              
        // pointer_layer = selection.append("svg:g").attr("class", "pointerContainer");   
        // draw_pointer(0);
        // middle knob
        pointer_layer.append("svg:circle")               
                .attr("cx", cx)           
                .attr("cy", cy)               
                .attr("r", 0.12 * raduis)
                .style("fill", "#4684EE")
                .style("stroke", "#666")
                .style("opacity", 1);
              
    
        // Value as text
        var fontSize = Math.round(size / 10);
        var text = d3.format('.2e')(Math.round(value));
        pointer_layer.selectAll("text")
                  .data([value])
                    .text(text)
                  .enter()
                    .append("svg:text")
                      .attr("x", cx)
                      .attr("y", size - cy / 5 - fontSize)            
                      .attr("dy", fontSize / 2)
                      .attr("text-anchor", "middle")
                      .text(text)
                      .style("font-size", fontSize + "px")
                      .style("fill", "#000")
                      .style("stroke-width", "0px");
      }
      
      function valueToDegrees(value) {
        return value / range * 270 - 45;
      }
    
      function valueToRadians(value) {
        return valueToDegrees(value) * Math.PI / 180;
      }
    
      function valueToPoint(value, factor) {
        var point = {
          x: cx - raduis * factor * Math.cos(valueToRadians(value)),
          y: cy - raduis * factor * Math.sin(valueToRadians(value))
        }
        return point;
      }
      
      
      return g;
    },
    
    
    
  })
})

      // for (var index in ctxt.greenZones)
      // {
        // this.drawBand(ctxt.greenZones[index].from, ctxt.greenZones[index].to, self.config.greenColor);
      // }
//   
      // for (var index in ctxt.yellowZones)
      // {
        // this.drawBand(ctxt.yellowZones[index].from, ctxt.yellowZones[index].to, self.config.yellowColor);
      // }
//   
      // for (var index in ctxt.redZones)
      // {
        // this.drawBand(ctxt.redZones[index].from, ctxt.redZones[index].to, self.config.redColor);
      // }
//   
      // if (undefined != ctxt.label)
      // {
        // var fontSize = Math.round(ctxt.size / 9);
        // this.body.append("svg:text")                
              // .attr("x", ctxt.cx)
              // .attr("y", ctxt.cy / 2 + fontSize / 2)           
              // .attr("dy", fontSize / 2)
              // .attr("text-anchor", "middle")
              // .text(ctxt.label)
              // .style("font-size", fontSize + "px")
              // .style("fill", "#333")
              // .style("stroke-width", "0px");  
      // }
//   
//   
      // var pointerContainer = this.body.append("svg:g").attr("class", "pointerContainer");   
      // this.drawPointer(0);
      // pointerContainer.append("svg:circle")               
                // .attr("cx", ctxt.cx)           
                // .attr("cy", ctxt.cy)               
                // .attr("r", 0.12 * ctxt.raduis)
                // .style("fill", "#4684EE")
                // .style("stroke", "#666")
                // .style("opacity", 1);
//       
// *********      
//       
// function Gauge(placeholderName, configuration)
// {
  // this.placeholderName = placeholderName;
// 
  // var self = this; // some internal d3 functions do not "like" the "this" keyword, hence setting a local variable
// 
  // ctxture = function(configuration)
  // {
    // ctxt = configuration;
// 
    // ctxt.size = ctxt.size * 0.9;
// 
    // ctxt.raduis = ctxt.size * 0.97 / 2;
    // ctxt.cx = ctxt.size / 2;
    // ctxt.cy = ctxt.size / 2;
// 
    // ctxt.min = configuration.min || 0; 
    // ctxt.max = configuration.max || 100; 
    // ctxt.range = ctxt.max - ctxt.min;
// 
    // ctxt.majorTicks = configuration.majorTicks || 5;
    // ctxt.minorTicks = configuration.minorTicks || 2;
// 
    // ctxt.greenColor  = configuration.greenColor || "#109618";    
    // ctxt.yellowColor = configuration.yellowColor || "#FF9900";   
    // ctxt.redColor  = configuration.redColor || "#DC3912";
  // }
// 
  // this.render = function()
  // {
    // this.body = d3.select("#" + this.placeholderName)
              // .append("svg:svg")
                // .attr("class", "gauge")
                // .attr("width", ctxt.size)
                // .attr("height", ctxt.size);
// 
    // this.body.append("svg:circle")
          // .attr("cx", ctxt.cx)           
          // .attr("cy", ctxt.cy)               
          // .attr("r", ctxt.raduis)
          // .style("fill", "#ccc")
          // .style("stroke", "#000")
          // .style("stroke-width", "0.5px");
// 
    // this.body.append("svg:circle")              
          // .attr("cx", ctxt.cx)           
          // .attr("cy", ctxt.cy)               
          // .attr("r", 0.9 * ctxt.raduis)
          // .style("fill", "#fff")
          // .style("stroke", "#e0e0e0")
          // .style("stroke-width", "2px");
// 
    // for (var index in ctxt.greenZones)
    // {
      // this.drawBand(ctxt.greenZones[index].from, ctxt.greenZones[index].to, self.config.greenColor);
    // }
// 
    // for (var index in ctxt.yellowZones)
    // {
      // this.drawBand(ctxt.yellowZones[index].from, ctxt.yellowZones[index].to, self.config.yellowColor);
    // }
// 
    // for (var index in ctxt.redZones)
    // {
      // this.drawBand(ctxt.redZones[index].from, ctxt.redZones[index].to, self.config.redColor);
    // }
// 
    // if (undefined != ctxt.label)
    // {
      // var fontSize = Math.round(ctxt.size / 9);
      // this.body.append("svg:text")                
            // .attr("x", ctxt.cx)
            // .attr("y", ctxt.cy / 2 + fontSize / 2)           
            // .attr("dy", fontSize / 2)
            // .attr("text-anchor", "middle")
            // .text(ctxt.label)
            // .style("font-size", fontSize + "px")
            // .style("fill", "#333")
            // .style("stroke-width", "0px");  
    // }
// 
    // var fontSize = Math.round(ctxt.size / 16);   
    // var majorDelta = ctxt.range / (ctxt.majorTicks - 1);
    // for (var major = ctxt.min; major <= ctxt.max; major += majorDelta)
    // {
      // var minorDelta = majorDelta / ctxt.minorTicks;
      // for (var minor = major + minorDelta; minor < Math.min(major + majorDelta, ctxt.max); minor += minorDelta)
      // {
        // var point1 = this.valueToPoint(minor, 0.75);
        // var point2 = this.valueToPoint(minor, 0.85);
// 
        // this.body.append("svg:line")
              // .attr("x1", point1.x)
              // .attr("y1", point1.y)
              // .attr("x2", point2.x)
              // .attr("y2", point2.y)
              // .style("stroke", "#666")
              // .style("stroke-width", "1px");
      // }
// 
      // var point1 = this.valueToPoint(major, 0.7);
      // var point2 = this.valueToPoint(major, 0.85);  
// 
      // this.body.append("svg:line")
            // .attr("x1", point1.x)
            // .attr("y1", point1.y)
            // .attr("x2", point2.x)
            // .attr("y2", point2.y)
            // .style("stroke", "#333")
            // .style("stroke-width", "2px");
// 
      // if (major == ctxt.min || major == ctxt.max)
      // {
        // var point = this.valueToPoint(major, 0.63);
// 
        // this.body.append("svg:text")
              // .attr("x", point.x)
              // .attr("y", point.y)           
              // .attr("dy", fontSize / 3)
              // .attr("text-anchor", major == ctxt.min ? "start" : "end")
              // .text(major)
              // .style("font-size", fontSize + "px")
              // .style("fill", "#333")
              // .style("stroke-width", "0px");
      // }
    // }   
// 
    // var pointerContainer = this.body.append("svg:g").attr("class", "pointerContainer");   
    // this.drawPointer(0);
    // pointerContainer.append("svg:circle")               
              // .attr("cx", ctxt.cx)           
              // .attr("cy", ctxt.cy)               
              // .attr("r", 0.12 * ctxt.raduis)
              // .style("fill", "#4684EE")
              // .style("stroke", "#666")
              // .style("opacity", 1);
  // }
// 
  // this.redraw = function(value)
  // {
    // this.drawPointer(value);
  // }
// 
  // this.drawBand = function(start, end, color)
  // {
    // if (0 >= end - start) return;
// 
    // this.body.append("svg:path")
          // .style("fill", color)
          // .attr("d", d3.svg.arc()
            // .startAngle(this.valueToRadians(start))
            // .endAngle(this.valueToRadians(end))
            // .innerRadius(0.65 * ctxt.raduis)
            // .outerRadius(0.85 * ctxt.raduis))
          // .attr("transform", function() { return "translate(" + self.config.cx + ", " + self.config.cy + ") rotate(270)" });
  // }
// 
// 
// 
  // // initialization
  // ctxture(configuration);  
// }