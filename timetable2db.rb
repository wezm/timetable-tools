require 'csv'
require 'station_storer'

unless ARGV.size >= 2
  $stderr.puts "Usage: timetable2db timetable.tsv timetable.sqlite"
  exit 2
end

storer = StationStorer.new(ARGV[1])
state = :skip_to_services

def insert_station(row, storer)
  station = row[0].downcase.gsub(/[\(\)]/, '').gsub(/\b\w/) { $&.upcase } # Title Case
  storer.service_indexes.each do |idx|
    if row[idx] && row[idx] =~ /^(\d{2}:\d{2})(.?)$/
      time = Time.parse($1).strftime("%H:%M:%S")
      flag = $2
      storer.add_stop(station, :service => idx, :time => time)
    end
  end
end

# Read and process the timetable data
CSV.foreach(ARGV[0], :col_sep => "\t") do |row|
  # Skip until service definitions
  case state
  when :skip_to_services
    if row[0] == "Service No."
      row.each_with_index do |service, idx|
        if service =~ /^\d+$/
          storer.add_service idx, service.to_i
        end
      end
      state = :skip_to_departure
    end
  when :skip_to_departure
    if row[1] == 'dep'
      state = :read_station
      insert_station(row, storer)
    end
  when :read_station
    insert_station(row, storer)
  else
    puts "Unknown state: #{state}"
    exit 1
  end
end
