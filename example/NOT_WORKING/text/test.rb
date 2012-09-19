require 'rubygems'
require 'maruku'

doc = Maruku.new(%{
# Foo & More

PPPPP

## Whatever

})
puts doc.to_html
