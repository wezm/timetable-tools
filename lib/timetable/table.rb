require 'timetable/partitioner'

module Timetable
  class Table

    def initialize(row_height, column_width)
      @row_histogram = Hash.new(0)
      @column_histogram = Hash.new(0)
      @row_height = row_height
      @column_width = column_width
    end

    attr_reader :row_histogram, :column_histogram

    def add_point(top, left)
      row_histogram[top] += 1
      column_histogram[left] += 1
    end

    def find_boundaries(freq, width)
      boundaries = [0]
      freq.keys.sort.each_cons(2) do |left, right|
        if right - left > width
          finish = left + ((right - left) / 2)
          boundaries << finish
        end
      end
    
      boundaries
    end

    def define_cells!
      row_boundaries = find_boundaries(row_histogram, @row_height)
      column_boundaries = find_boundaries(column_histogram, @column_width)
      @table = Array.new(row_boundaries.count) { |i| Array.new(column_boundaries.count) }
      @row_partitioner = Partitioner.new(row_boundaries)
      @column_partitioner = Partitioner.new(column_boundaries)
    end

    def add_data(top, left, data)
      row = @row_partitioner.place top
      col = @column_partitioner.place left
      @table[row][col] = data
    end

    def rows
      @table
    end

  protected

    # def draw_histogram(freq, output_path)
    #   # Determine the dimensions of the canvas
    #   width = freq.keys.max + (2 * PADDING)
    #   height = freq.values.max + (2 * PADDING)
    # 
    #   surface = Cairo::ImageSurface.new(Cairo::Format::RGB24, width, height)
    #   c = Cairo::Context.new(surface)
    # 
    #   # Draw the white background
    #   c.set_source_color(Cairo::Color::WHITE)
    #   c.rectangle(0,0,width,height)
    #   c.fill
    # 
    #   c.set_source_color(Cairo::Color::RED)
    #   freq.each do |x, y|
    #     next unless y > 0
    #     c.move_to(x + PADDING, height - PADDING)
    #     c.line_to(x + PADDING, height - y - PADDING)
    #     c.stroke
    #   end
    # 
    #   # Write out the image
    #   surface.write_to_png(output_path)
    # end
    # 

  end
end