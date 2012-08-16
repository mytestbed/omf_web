
require 'omf-oml/table'

schema = [[:id, :int], [:name, :string], [:value, :float]]
table = OMF::OML::OmlTable.new 'financial_returns', schema 
table2 = OMF::OML::OmlTable.new 'financial_returns_all_positive', schema 

[["CDS / Options" , -29.765957771107],
 ["Cash" , 0],
 ["Corporate Bonds" , 32.807804682612],
 ["Equity" , 196.45946739256],
 ["Index Futures" ,0.19434030906893],
 ["Options" , -98.079782601442],
 ["Preferred" , -13.925743130903],
 ["Not Available" , -5.1387322875705]
].each_with_index do |a, i|
  table.add_row [i, a[0], a[1]]
  table2.add_row [i, a[0], a[1].abs]  
end

require 'omf_web'
OMF::Web.register_datasource table
OMF::Web.register_datasource table2

