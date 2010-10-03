# vi: set fileencoding=utf-8 :

require 'spec_helper'
require 'timetable/day_parser'

describe Timetable::DayParser do

  describe "match" do
    it "should be true for MONDAY - FRIDAY" do
      Timetable::DayParser.match("MONDAY - FRIDAY").should be_true
      Timetable::DayParser.match("Monday ­ Friday").should be_true # Multibyte dash
    end
    
    it "should be true for FRI, SAT & SUN" do
      Timetable::DayParser.match("Fri").should be_true
      Timetable::DayParser.match("FRI").should be_true
      Timetable::DayParser.match("Sat").should be_true
      Timetable::DayParser.match("Sun").should be_true
    end
  end
  
  describe "parse" do
    
    it "should return 2..6 for Monday ­ Friday (utf-8 dash)" do
      Timetable::DayParser.parse("Monday ­ Friday").should == (2..6)
    end
    
    it "should return 2..6 for MONDAY ­ FRIDAY (utf-8 dash)" do
      Timetable::DayParser.parse("MONDAY ­ FRIDAY").should == (2..6)
    end

    it "should return 2..6 for Monday - Friday (ASCII dash)" do
      Timetable::DayParser.parse("Monday - Friday").should == (2..6)
    end

    it "should return [6] for Fri" do
      Timetable::DayParser.parse("Fri").should == [6]
    end

    it "should return [1] for Sun" do
      Timetable::DayParser.parse("Sun").should == [1]
    end

    it "should raise an error if the day can't be found" do
      lambda { Timetable::DayParser.parse("Asdf") }.should raise_error
      lambda { Timetable::DayParser.parse("Monday - ASDF") }.should raise_error
    end
  end
end