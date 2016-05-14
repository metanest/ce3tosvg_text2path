#! /usr/local/bin/ruby22

require 'rexml/document'

font_filename = ARGV[0]
font_filename ||= "myfont.svg"

def read_font svg_filename
  result = {}

  doc = nil
  open(svg_filename){|fp|
    doc = REXML::Document.new fp.read
  }

  REXML::XPath.match(doc, "/svg/defs/g").each{|elem|
    font_id = elem.attribute('id').to_s
    result[font_id] = elem
  }

  return result
end

font_elems = read_font font_filename

doc = REXML::Document.new STDIN

embed_elems = {}

REXML::XPath.match(doc, '//svg:text').each{|elem|
  txt = elem.text || ''
  mid_flag = (elem.attribute('text-anchor').to_s == 'middle')
  parent_elem = elem.parent
  pos_x = elem.attribute('x')
  if pos_x then
    pos_x = pos_x.to_s.to_f
  else
    pos_x = 0
  end
  pos_y = elem.attribute('y')
  if pos_y then
    pos_y = pos_y.to_s.to_f
  end
  if mid_flag then
    pos_x -= 4 * txt.length
  end
  tgroup = REXML::Element.new 'svg:g'
  parent_elem.replace_child elem, tgroup
  txt.each_char{|c|
    font_id = "myfont-U+%04X" % [c.ord]
    font_elem = font_elems[font_id]
    unless font_elem then
      font_id = "myfont-U+3013"
      font_elem = font_elems["myfont-U+3013"]
    end
    embed_elems[font_elem] = true
    e = REXML::Element.new 'svg:use', tgroup
    e.add_attribute 'stroke', "black"
    e.add_attribute 'xlink:href', "##{font_id}"
    e.add_attribute 'x', "#{pos_x}"
    if pos_y then
      e.add_attribute 'y', "#{pos_y}"
    end
    pos_x += 8
  }
}
svg_elem = nil
REXML::XPath.match(doc, '/svg:svg').each {|e|
  svg_elem = e
  break
}
defs_elem = REXML::Element.new 'svg:defs'
svg_elem.unshift defs_elem
embed_elems.keys.each {|elem|
  defs_elem.add elem
}
doc.write
