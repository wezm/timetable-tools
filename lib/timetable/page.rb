require 'timetable/table'
require 'timetable/partitioner'

module Timetable
  class Page

    def initialize(page, table_boundary, row_height, column_width)
      @page = page
      @width = page['width'].to_i
      @height = page['height'].to_i
      @tables = Array.new(2) { Table.new(row_height, column_width) }
      @partitioner = Partitioner.new([0,table_boundary])

      process
    end

    attr_reader :page, :width, :height, :tables

  protected

    def process
      # Define the tables
      page.css("text").each do |text|
        left = text['left'].to_i
        top  = text['top'].to_i

        # partition into tables
        table = tables[@partitioner.place(top)]
        table.add_point top, left
      end
    
      tables.each(&:define_cells!)
    
      # Seems a shame to do this loop again but it works.
      # Perhaps add point could take the data and stash it
      # away for later
      page.css("text").each do |text|
        left = text['left'].to_i
        top  = text['top'].to_i

        table = tables[@partitioner.place(top)]
        table.add_data(top, left, text.inner_text.strip)
      end
    end
  end
end