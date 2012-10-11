
L.provide('OML.bridge', ["graph/abstract_chart", "#OML.abstract_chart", ["/resource/vendor/d3/d3.js"]],

  function () {

  OML.bridge = OML.abstract_chart.extend({
    decl_properties: [
      ['health', 'key'], 
      ['fill_color', 'color', 'blue'], 
    ],
    
    defaults: function() {
      return this.deep_defaults({
        width: 1.0,  // <= 1.0 means set width to enclosing element
        height: 200,  // <= 1.0 means fraction of width
        
        /*
        axis: {
          orientation: 'horizontal'
        }
        */
      }, OML.bridge.__super__.defaults.call(this));      
    },    
    
    base_css_class: 'oml-bridge',
    
    initialize: function(opts) {
      OML.bridge.__super__.initialize.call(this, opts);
      
      var self = this;
      OHUB.bind("bridge.event_selected", function(evt) {
        var joint_id = evt.event[evt.schema.jointID.index];
        self.redraw_sensor_locator(joint_id);
      });
    },
    
    
    configure_base_layer: function(vis) {
      var base = this.base_layer = vis.append("svg:g")
                                      .attr("class", "bridge")
                                      ;
    
      var ca = this.chart_area; 
      var bgl = this.background_layer = base.append("svg:g");
      this.draw_background(bgl);

      this.selector_layer = base.append("svg:g");
      this.data_layer = base.append("svg:g");
    },

    redraw: function(data) {
      var self = this;
      var o = this.opts;
      var ca = this.widget_area;
      var m = this.mapping;
      
      var events = this.data_layer.selectAll('.event')
                    .data(data)
                    ;
      events.enter()
        .append('svg:circle')
          .attr('cx', m.x)
          .attr('cy', m.y)
          .attr('r', 10)
          .attr('class', 'event')
          .attr('fill', m.fill_color)
          .transition()
            .duration(1000)
            .ease(Math.sqrt)
            .attr("r", 2)
            .attr('cy', m.y + 50)
            .style("stroke-opacity", 1e-6)
            .remove();          
          ;
    },
    
    redraw_sensor_locator: function(joint_id) {
      var self = this;
      var o = this.opts;
      var ca = this.widget_area;
      var m = this.mapping;
      var self= this;
      
      function locator(g) {
        g.append('svg:rect')
          .attr('x', m.joint2x)
          .attr('y', 20)
          .attr('width', 4)
          .attr('height', self.h)
          .attr('fill', 'blue')
          .attr('opacity', 0.5)
          ;
        g.append("text")
            .attr('x', m.joint2x)
            .attr('y', 10)
            .attr('text-anchor', 'middle')
            .text(function(d) {
              return d;
            })
            ;
         return g;
      }
      
      var selector = this.selector_layer.selectAll('.locator')
                    .data([joint_id], function(d) { return d; })
                    ;
      selector
        .enter().append('g')
            .attr('class', 'locator')
            .call(locator)
      selector.exit().remove();
    },
    
    draw_background: function(bgl) {
      
      var bw = 600, bh = 180; // bridge dim       
      var y = -977.36218 + bh - 75; 
      var boffset = 70;
      
      var lmargin = (this.w - (2 * boffset + bw)) / 2;
  
      var stroke = 'silver';
      
      bgl.append('g')
        .attr("transform", 'translate(' + (boffset + lmargin) + ', ' + y + ')')
        .append('path')
          .attr('d', "m 0,977.36218 c 90.943759,-42.38013 169.5164,-85 300,-85 130.51627,-0.39668 210.6141,43.53389 300,85 l 0,0 0,75.00002 C 525.47235,1001.8883 430.85399,921.13875 300,922.0728 169.19905,922.68682 73.345644,999.90863 0,1052.3622 c 0,0 2.020305,-4.2894 0,-75.00002 z")
          .attr('fill', 'none')
          .attr('stroke', stroke)
          .attr('stroke-width', '2px')
          .attr('stroke-linecap', 'butt')
          .attr('stroke-linejoin', 'miter')
          .attr('stroke-opacity', '1')
        ;
      var ly = 130;
      bgl.append('g')
        .attr("transform", 'translate(' + lmargin + ', 0)')
        .append('line')
          .attr('x1', 0)
          .attr('x2', 2 * boffset + bw)
          .attr('y1', ly)
          .attr('y2', ly)        
          .attr('stroke', stroke)
          .attr('stroke-width', '4px')
        ;
        
      var self = this;
      var jid = this.schema.jointID.index;
      var scale = d3.scale.linear().domain([0, 60]).range([lmargin, lmargin + 2 * boffset + bw]);
      var joint2x = this.mapping.joint2x = function(joint_name) {
        var joint_s = joint_name.substr(4);
        var joint = parseInt(joint_s);
        var x = scale(joint);
        return x;
      }
      this.mapping.x = function(d) {
        return joint2x(d[jid]);
      }
      
      this.mapping.y = ly;
    },
    
    
  }) // end of histogram
}) // end of provide
