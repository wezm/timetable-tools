require 'timetable/models'

module Timetable

  class Importer

    attr_reader :timetable

    def import(data)
      @timetable = create_timetable! data[1] # data[0] is the source URL
    end

  protected

    def create_timetable!(row)
      name = "#{row[0]} to #{row[1]}"
      inbound = row[1] == 'Melbourne'
      Timetable.create :name => name, :inbound => inbound
    end

  end

end
