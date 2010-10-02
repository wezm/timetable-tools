require 'spec_helper'
require 'timetable/table'

describe Timetable::Table do

  let(:table) { Timetable::Table.new(5, 5) }

  describe "histogram" do

    before do
      table.add_point 1, 2
      table.add_point 2, 3
      table.add_point 1, 2
      table.add_point 1, 1
    end

    describe "for rows" do
      it "is a hash with counts for each row added" do
        table.row_histogram.should == {1 => 3, 2 => 1}
      end
    end

    describe "for columns" do
      it "is a hash with counts for each column added" do
        table.column_histogram.should == {2 => 2, 3 => 1, 1 => 1}
      end
    end

  end

  describe "finding boundaries" do

    before do
      table.add_point(1, 1)
      table.add_point(10, 1)
      table.add_point(13, 1)
      table.add_point(20, 1)
    end

    it "begins with zero" do
      table.find_boundaries(table.row_histogram, 5).first.should be_zero
    end

    it "defines boundaries between gaps bigger than the supplied width" do
      table.find_boundaries(table.row_histogram, 2).should == [0, 5, 11, 16]
      table.find_boundaries(table.row_histogram, 5).should == [0, 5, 16]
      table.find_boundaries(table.row_histogram, 8).should == [0, 5]
    end

  end

  describe "rows after defining cells and adding data" do
    
    let(:points) { [[1,1,"one"], [10,2,"two"], [13,12,"three"], [20,15,"four"]] }
    
    before do
      points.each { |p| table.add_point p[0], p[1] }
    end

    it "should be placed according to the row width and column height" do
      table.define_cells!
      points.each { |p| table.add_data(*p) }
      
      table.rows.should == [
        [ 'one', nil     ],
        [ 'two', "three" ],
        [ nil,   "four"  ]
      ]
    end
    
  end

end
