
//OML.require_dependency("vendor/nv_d3/js/nv.d3", ["vendor/d3/d3", "css!vendor/nv_d3/css/nv.d3"]);
//OML.require_dependency("vendor/nv_d3/js/models/line", ["vendor/nv_d3/js/nv.d3"]);
//OML.require_dependency("vendor/nv_d3/js/models/lineChart", ["vendor/nv_d3/js/models/line"]);
//OML.require_dependency("echarts/chart/bar", ["echarts/echarts"]);


define(["graph/ec/abstract_echart",
  "echarts/chart/bar",
  "echarts/chart/line"
], function (abstract_echart, ec) {

  var context = abstract_echart.extend({
    decl_properties: [
      ['x_axis', 'key', {property: 'x'}],
      ['y_axis', 'key', {property: 'y'}],
      ['group_by', 'key', {property: 'id', optional: true}],
      ['stroke_width', 'int', 2],
      ['stroke_color', 'color', 'category10()'],
      ['stroke_fill', 'color', 'blue']
    ],

    get_chart_option: function() {
      this.first_time = true;
      return option = {
        //title : {
        //    text: 'Title',
        //    subtext: 'Subtext'
        //},
        tooltip : {
            trigger: 'axis'
        },
        //legend: {
        //    data:['Line1','Line2']
        //},
        toolbox: {
          show : true,
          show : false,
          feature : {
              //mark : {show: true},
              //dataView : {show: true, readOnly: false},
              //magicType : {show: true, type: ['line', 'bar']},
              restore : {show: true},
              saveAsImage : {show: true}
          }
        },
        calculable : true,
        dataZoom : {
          show : true,
          show: false,
          realtime : true,
          //start : 20,
          //end : 80
        },
        //xAxis : [
        //  {
        //    type : 'category',
        //    axisLabel : {
        //      formatter: '{value} sec'
        //    },
        //    //boundaryGap : false,
        //    //data : ['A','B','C','D','E','F','F']
        //    data : []
        //  }
        //],
        yAxis : [
          {
            type : 'value',
            axisLabel : {
              formatter: '{value} %'
            }
          }
        ],
        //series : [
        //    {
        //        name:'Line1',
        //        type:'line',
        //      data: []
        //        //
        //        //markPoint : {
        //        //    data : [
        //        //        {type : 'max', name: 'Max'},
        //        //        {type : 'min', name: 'Min'}
        //        //    ]
        //        //},
        //        //markLine : {
        //        //    data : [
        //        //        {type : 'average', name: 'Avg'}
        //        //    ]
        //        //}
        //    },
        //    {
        //        name:'Line2',
        //        type:'line',
        //        data:[1, -2, 2, 5, 3, 2, 0],
        //        //markPoint : {
        //        //    data : [
        //        //        {name : 'MarkPoint1', value : -2, xAxis: 1, yAxis: -1.5}
        //        //    ]
        //        //},
        //        //markLine : {
        //        //    data : [
        //        //        {type : 'average', name : 'Avg'}
        //        //    ]
        //        //}
        //    }
      //  ]
      }

    },

    _draw: function(data, chart) {
      if (data == undefined || data.length == 0) return;

      var chart = this.echart;
      var m = this.mapping;

      var x = _.map(data, function(d) { return m.x_axis(d); });
      var y = _.map(data, function(d) { return m.y_axis(d); });

      if (this.first_time) {
        this.first_time = false;

        var o = {
          xAxis: [
            {
              type: 'category',
              axisLabel: {
                formatter: '{value} s'
              },
              //boundaryGap : false,
              data: x
              //data : []
            }
          ],
          series: [{
            type: 'line',
            name: 'Line1',
            data: y,
          }]
        };
        chart.setOption(o);
      } else {
        chart.addData([
          [0, y.slice(-1)[0], false, false, x.slice(-1)[0]]
        ])
      }
    }

  });

  return context;
});

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/
