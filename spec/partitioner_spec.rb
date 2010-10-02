require 'spec_helper'
require 'timetable/partitioner'

describe Timetable::Partitioner do

  describe "partition" do

    let(:partitioner) { Timetable::Partitioner.new([0, 5, 16]) }

    it "places values in the last bucket it is greater than" do
      partitioner.place(1).should == 0
      partitioner.place(5).should == 0
      partitioner.place(6).should == 1
      partitioner.place(15).should == 1
      partitioner.place(20).should == 2
    end

    it "returns nil for invalid values" do
      partitioner.place(-1).should be_nil
    end

  end
  
end