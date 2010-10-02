module Timetable
  
  class Partitioner
    
    def initialize(boundaries)
      @boundaries = boundaries
    end
    
    attr_reader :boundaries
    
    # It seems that since these boundaries are sorted a binary search
    # or similar would be a better way to find the bucket
    def place(value)
      bucket = nil
      boundaries.each_with_index do |boundary, i|
        if value > boundary
          bucket = i
        else
          break
        end
      end
      bucket
    end
    
  end
end