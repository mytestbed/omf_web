require 'omf_common/lobject'
require 'omf_web'
require 'omf_oml/table'

OMF::Common::Loggable.init_log 'tut02'


# Create a table containing 'amplitude' measurements taken at a certain time for two different 
# devices.
#
schema = [[:t, :float], [:device, :string], [:amplitude, :float], [:x, :float], [:y, :float]]
table = OMF::OML::OmlTable.new 'generator', schema

# Register the table with the web framework
OMF::Web.register_datasource table

# Fill it with some data
samples = 30
ctxt = {
  :timeOffset => Time.now.to_i,
  :timeScale => 300, # Measure every 10 minutes
  :radius => 10,
  :fluctuation => 0.1, # max disturbance of sample
  :rad => 2 * Math::PI / samples
}

def measure(i, table, ctxt) 
  t = ctxt[:timeOffset] + ctxt[:timeScale] * i
  angle = i * ctxt[:rad]
  measure_device('Gen 1', t, angle, table, ctxt)
  measure_device('Gen 2', t, angle + ctxt[:rad] + 0.2 * (rand() - 0.5), table, ctxt)  
end

def measure_device(name, t, angle, table, ctxt)
  r = ctxt[:radius] * (1 + (rand() - 0.5) * ctxt[:fluctuation])
  table.add_row [t, name, r, r * Math.sin(angle), r * Math.cos(angle)]
end

samples.times {|i| measure(i, table, ctxt) }

# Now describe a site with two widgets side by side, one showing the data
# in a table, and the other as a line graph
#
site_description = {
  id: 'top',
  top_level: true,
  name: "Main",
  type: 'layout/two_columns/50_50', # two columns equal width
  left: [
    name: 'Line Chart',
    type: 'data/line_chart3',
    data_source: { name: 'generator' },
    mapping: {
      x_axis: 't',
      y_axis: { 
        property: 'x',
        min: -10.5,
        max: 10.5
      },
      group_by: 'device'
    },
    axis: {
      x: {
        ticks: { type: 'date', format: '%I:%M' },
        legend: 'Time (hours)'
      },
      y: { legend: 'Voltage (V)' }
    }
  ], 
  right: [
    name: 'Table',
    type: 'data/table2',
    data_source: { name: 'generator' }
  ]
}

# Configure the web server
#
opts = {
  :app_name => 'tut02',
  :page_title => 'Tutorial02: Hello Graph'
}

OMF::Web.register_widget(site_description)
OMF::Web.start(opts)
