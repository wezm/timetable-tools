require 'nokogiri'
# require 'csv'
require 'cairo'

unless ARGV.size > 0
  $stderr.puts "Usage: timetable timetable.xml"
  exit 2
end

def draw_histogram(freq, output_path)
  # Determine the dimensions of the canvas
  width = freq.keys.max + (2 * PADDING)
  height = freq.values.map(&:count).max + (2 * PADDING)
  
  surface = Cairo::ImageSurface.new(Cairo::Format::RGB24, width, height)
  c = Cairo::Context.new(surface)
  
  # Draw the white background
  c.set_source_color(Cairo::Color::WHITE)
  c.rectangle(0,0,width,height)
  c.fill
  
  c.set_source_color(Cairo::Color::RED)
  freq.each do |x, y|
    next unless y.count > 0
    c.move_to(x + PADDING, height - PADDING)
    c.line_to(x + PADDING, height - y.count - PADDING)
    c.stroke
  end
  
  # Write out the image
  surface.write_to_png(output_path)
end

def draw_sorted_value_histogram(freq, output_path)
  # Determine the dimensions of the canvas
  width = freq.keys.max + (2 * PADDING)
  height = freq.values.max + (2 * PADDING)
  
  surface = Cairo::ImageSurface.new(Cairo::Format::RGB24, width, height)
  c = Cairo::Context.new(surface)
  
  # Draw the white background
  c.set_source_color(Cairo::Color::WHITE)
  c.rectangle(0,0,width,height)
  c.fill
  
  c.set_source_color(Cairo::Color::RED)
  freq.values.sort.reverse.each_with_index do |y, x|
    next unless y > 0
    c.move_to(x + PADDING, height - PADDING)
    c.line_to(x + PADDING, height - y - PADDING)
    c.stroke
  end
  
  # Write out the image
  surface.write_to_png(output_path)
end

table_count = 2 # TODO: Pull form ARGV
tables = Array.new(table_count) { |i| { :rows => {}, :columns => {} } }
page_width = 0
page_height = 0

File.open(ARGV[0]) do |f|
  xml = Nokogiri::XML.parse(f)
  page = xml.at_css("page[number='1']")
  page_width = page['width'].to_i
  page_height = page['height'].to_i
  
  xml.css("page[number='1'] text").each do |text|
    left = text['left'].to_i
    top  = text['top'].to_i

    # partition into tables
    table = tables[top / (page_height / table_count)]
    
    table[:columns][left] = table[:columns].fetch(left, []) << text
    table[:rows][top] = table[:rows].fetch(top, []) << text
  end
end

PADDING = 5
GAP = 10

def gap(freq)
  gaps = [0]
  freq.keys.sort.each_cons(2) do |left, right|
    if right - left > GAP
      finish = left + ((right - left) / 2)
      gaps << finish
    end
  end
  
  gaps
end

def group(freq, bucket_defs)
  buckets = Array.new(bucket_defs.count) { |i| [] }
  freq.keys.each do |key|
    bucket = 0
    bucket_defs.each_with_index do |boundary, i|
      if key > boundary
        bucket = i
      else
        break
      end
    end
    buckets[bucket] << freq[key]
  end
  
  buckets
end

table_count.times do |table|
  [:rows, :columns].each do |dimension|
    draw_histogram(tables[table][dimension], "histogram-#{dimension}-table-#{table + 1}.png")
    boundaries = gap(tables[table][dimension])
    group(tables[table][dimension], boundaries).map(&:flatten).each do |bucket|
      p bucket.map(&:inner_text)
    end
    puts
  end
end

# Scan for GAP or more more zero points





