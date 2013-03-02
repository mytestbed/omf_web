require 'omf_common/lobject'
require 'omf_web'
require 'omf_oml/table'
require 'omf_oml/sql_source'
include OMF::OML
OMF::Common::Loggable.init_log 'tut03'

# Name of database to visualize
DB_URL = "sqlite://#{File.dirname(__FILE__)}/nmetric.sq3"

# Create a table containing measurements fetched from a database
# devices.
#
ep = OMF::OML::OmlSqlSource.new(DB_URL)
opts = {
  max_size: 1000,  # max rows to maintain in table (FIFO) 
  include_oml_internals: false, # don't add the OML header columns to the table
  limit: 100,  # to slow things down, fetch 100 rows at a time
  query_interval: 0.5  # ... and wait that many seconds before fetching the next batch
}
ds = ep.create_table('traffic', opts)
OMF::Web.register_datasource ds 

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
    data_source: { name: 'traffic' },
    mapping: {
      x_axis: 'ts',
      y_axis: { 
        property: 'tx_byte_rate',
        # min: -10.5,
        # max: 10.5
      },
      group_by: 'name'
    },
    axis: {
      x: {
        #ticks: { type: 'date', format: '%I:%M' },
        legend: 'Time (s)',
        ticks: { format: ',s' }
      },
      y: { legend: 'Rate (bytes)', ticks: { format: ',s' }}
    }
  ], 
  right: [
    name: 'Table',
    type: 'data/table2',
    data_source: { name: 'traffic' }
  ]
}

# Configure the web server
#
opts = {
  :app_name => 'tut02',
  :page_title => 'Tutorial03: Hello Database'
}

OMF::Web.register_widget(site_description)
OMF::Web.start(opts)
