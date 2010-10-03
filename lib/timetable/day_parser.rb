# vi: set fileencoding=utf-8 :

module Timetable
  module DayParser
    
    DAYS = %w[SUN MON TUE WED THU FRI SAT]
    
    def self.match(text)
      @days_re ||= Regexp.new(DAYS.join('|'), true)
      @days_re.match(text)
    end

    def self.parse(text)
      from, to = text.split(/\s*[­-]\s*/) # utf-8 dash, ASCII dash

      from = DAYS.index(from[0,3].upcase) + 1
      to = DAYS.index(to[0,3].upcase) + 1 if(to)

      to ? (from..to) : [from]
    end

  end
end