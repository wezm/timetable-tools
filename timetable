#!/usr/bin/env ruby

require 'nokogiri'
require 'csv'
require 'cairo'

unless ARGV.size > 0
  $stderr.puts "Usage: timetable timetable.xml"
  exit 2
end

def draw_histogram(freq, output_path)
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
  freq.each do |x, y|
    next unless y > 0
    c.move_to(x + PADDING, height - PADDING)
    c.line_to(x + PADDING, height - y - PADDING)
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
tables = Array.new(table_count) { |i| { :rows => Hash.new(0), :columns => Hash.new(0) } }

f = File.open(ARGV[0])
xml = Nokogiri::XML.parse(f)
f.close()

page_number = 1

page = xml.at_css("page[number='#{page_number}']")
page_width = page['width'].to_i
page_height = page['height'].to_i

xml.css("page[number='#{page_number}'] text").each do |text|
  left = text['left'].to_i
  top  = text['top'].to_i

  # partition into tables
  table = tables[top / (page_height / table_count)]
  
  table[:columns][left] += 1
  table[:rows][top] += 1
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

def group(key, bucket_defs)
  bucket = nil
  bucket_defs.each_with_index do |boundary, i|
    if key > boundary
      bucket = i
    else
      break
    end
  end
  bucket
end

table_count.times do |table|
  [:rows, :columns].each do |dimension|
    draw_histogram(tables[table][dimension], "histogram-#{dimension}-table-#{table + 1}.png")
    tables[table]["#{dimension}_boundaries".to_sym] = gap(tables[table][dimension])
    # group(tables[table][dimension], boundaries).map(&:flatten).each do |bucket|
    #   p bucket.map(&:inner_text)
    # end
    # puts
  end

  timetable = Array.new(tables[table][:rows_boundaries].count) { |i| Array.new(tables[table][:columns_boundaries].count) }

  # Partition the elements
  xml.css("page[number='#{page_number}'] text").each do |text|
    left = text['left'].to_i
    top  = text['top'].to_i

    row = group(top,  tables[table][:rows_boundaries])
    col = group(left, tables[table][:columns_boundaries])
    timetable[row][col] = text.inner_text.strip
  end

  CSV.open("timetable-table-#{table + 1}.tsv", "w", :col_sep => "\t") do |csv|
    timetable.each do |row|
      csv << row
    end
  end
end
