
require 'maruku'

OpenMatch = /^\s*\{\{\{\s*(.*)$/
CloseMatch = /(.*)\}\}\}/

def handle(doc, src, context)
  lines = []
    
  line = src.shift_line
  line =~ OpenMatch
  line = $1
  while line && !(line =~ CloseMatch)
    lines << line
    line = src.shift_line
  end
  lines << $1
  i = 0
  c = context[5]
  k = c.class
  context << MaRuKu::MDElement.new(:viz)
  true
end

MaRuKu::In::Markdown::register_block_extension(
  :regexp  => OpenMatch,
  :handler => lambda { |doc, src, context|
    handle(doc, src, context)
  }
)

module MaRuKu; module Out; module HTML

  def to_html_viz
      span = Element.new 'javascript'
      span.attributes['class'] = 'maruku_section_number'
      span << Text.new('Foooo')
    add_ws  span
  end
  
end end end


doc = Maruku.new(%{
  

{{{  foo }}}

* TOC
{:toc}

+---------
| text
+----------

# Foo & More


PPPPP

## Whatever

})
puts doc.to_html
