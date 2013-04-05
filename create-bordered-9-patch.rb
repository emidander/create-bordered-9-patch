#!/usr/bin/env ruby
require 'chunky_png'
require 'trollop'

def parse_color(color_string)
  color_values = (0..(color_string.length - 1)).step(2).collect {|index| color_string[index..index+1].to_i(16)}
  if color_values.size == 4
    return ChunkyPNG::Color.rgba(*color_values)
  elsif color_values.size == 3
    return ChunkyPNG::Color.rgb(*color_values)
  else
    return nil
  end
end

 opts = Trollop::options do
  version "create-bordered-9-patch 1.0 (c) 2013 Erik Midander"
  banner <<-EOS
Create 9-patch png images with borders!

Usage:
       create-bordered-9-patch [options] <backgroundcolor> <bordercolor> <borders>

Borders are specified as T (top), R (right), B (bottom) and L (left). E.g. LR for left and right border,
T for only top border, BLT for all borders except the right.

Colors should be specified as RRGGBB (e.g. C0C0C0) or RRGGBBAA.

Options:
EOS

  opt :width, "Image width", :type => :int
  opt :height, "Image height", :type => :int

  opt :margin, "All margins", :default => 2
  opt :topmargin, "Top margin", :type => :int
  opt :bottommargin, "Bottom margin", :type => :int
  opt :leftmargin, "Left margin", :type => :int
  opt :rightmargin, "Right margin", :type => :int

  opt :padding, "All paddings", :default => 2
  opt :toppadding, "Top padding", :type => :int
  opt :bottompadding, "Bottom padding", :type => :int
  opt :leftpadding, "Left padding", :type => :int
  opt :rightpadding, "Right padding", :type => :int

  opt :output, "Output file name", :default => 'image.9.png'
end

Trollop::die "Wrong number of arguments" if ARGV.size != 3

# colors
background_color = parse_color(ARGV[0])
Trollop::die "Bad color: '%s'" % ARGV[0] if !background_color
border_color = parse_color(ARGV[1])
Trollop::die "Bad color: '%s'" % ARGV[1] if !border_color

# borders
borders = ARGV[2].upcase
border_top = borders.include? "T"
border_right = borders.include? "R"
border_bottom = borders.include? "B"
border_left = borders.include? "L"

# margins
topmargin = opts[:topmargin] || opts[:margin]
rightmargin = opts[:rightmargin] || opts[:margin]
bottommargin = opts[:bottommargin] || opts[:margin]
leftmargin = opts[:leftmargin] || opts[:margin]

if topmargin < 2 || rightmargin < 2 || bottommargin < 2 || leftmargin < 2
  puts "WARNING: Images with margin smaller than 1 will not look very nice!"
end

# paddings
toppadding = opts[:toppadding] || opts[:padding]
rightpadding = opts[:rightpadding] || opts[:padding]
bottompadding = opts[:bottompadding] || opts[:padding]
leftpadding = opts[:leftpadding] || opts[:padding]

# size
min_width = leftmargin + rightmargin + 3
min_height = topmargin + bottommargin + 3
width = opts[:width] || min_width
height = opts[:height] || min_height
if width < min_width || height < min_height
  puts "ERROR: width and height must be large enough to include margins (minimum size with current margin settings is %dx%d)." % [min_width, min_height]
  exit(1)
end

# generate image
def fill_png png, color, origin_x, origin_y, size_x, size_y
  (origin_x..(origin_x + size_x - 1)).each do |x|
    (origin_y..(origin_y + size_y - 1)).each do |y|
      png[x, y] = color
    end
  end
end

output_file_name = opts[:output]
black_color = ChunkyPNG::Color.rgb(0, 0, 0)

png_width = width + 2
png_height = height + 2
png = ChunkyPNG::Image.new(png_width, png_height, ChunkyPNG::Color::TRANSPARENT)

fill_png png, background_color, 1, 1, width, height

fill_png png, black_color, 0, 1 + topmargin, 1, height - topmargin - bottommargin   # left edge
fill_png png, black_color, 1 + leftmargin, 0, width - leftmargin - rightmargin, 1  # top edge

fill_png png, black_color, png_width - 1, 1 + toppadding, 1, height - toppadding - bottompadding   # right edge
fill_png png, black_color, 1 + leftpadding, png_height - 1, width - leftpadding - rightpadding, 1   # bottom edge

fill_png png, border_color, 1, 1, 1, height if border_left
fill_png png, border_color, png_width - 2, 1, 1, height if border_right
fill_png png, border_color, 1, 1, width, 1 if border_top
fill_png png, border_color, 1, png_height - 2, width, 1 if border_bottom

png.save(output_file_name, :interlace => true)

puts "Wrote file to %s" % output_file_name



