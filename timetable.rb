require 'yaml'

class FlexiField

  def initialize
    @fields = []
  end

  def add_field(offset, length)
    @fields << [offset, length]
    puts "add_field(#{offset}, #{length})"
  end

  def parse(line)
    @fields.map do |field|
      offset, len = field
      line[offset, len]
    end
  end

end

class TimetableParser

  def initialize(io)
    @io = io
    @cs = :find_header_row
    @parser = FlexiField.new
    @data = []
    @headers = []
  end
  attr_reader :data, :headers

  def execute
    while(!@io.eof? && @cs != :error && @cs != :finished)
      send(@cs)
    end
    p @cs
  end

  def next_line
    @line = @io.gets
    @p = 0
    @pe = @line.length
    # p line
  end
  attr_reader :line

  def find_header_row
    next_line
    if line =~ /^ Service No\.\s+/
      @pe = $&.length
      @cs = :define_columns
    elsif line[0] == "\r" # New page

    end
  end

  def define_columns
    pos = @pe
    @parser.add_field(0, @pe)
    @headers << "Station"

    line[@pe..line.length].scan(/\d+\s*/) do |match|
      # puts "Field start #{pos} length #{pos + match.length}"
      @parser.add_field(pos, match.length)
      @headers << match
      pos += match.length
    end

    # if pos != @p.length
    #   puts "#{pos} != #{line.length}"
    #   @cs = :error
    # else
    #   @cs = :find_station
    # end
    @cs = :find_station
  end

  def find_station
    next_line
    if line =~ /^ [^\s]/
      @pe = $0.length
      @cs = :parse_row
    elsif line == "\n" # New page
      puts "end of page"
      @cs = :finished
    end
  end

  def parse_row
    @data << @parser.parse(line)
    @cs = :find_station
  end

  def error
    puts "error"
  end

  def finished
  end

end

if ARGV.size < 1
  $stderr.puts "Usage: timetable timetable.txt"
  exit 2
end

File.open(ARGV[0]) do |f|
  parser = TimetableParser.new(f)
  parser.execute

  File.open("timetable.yaml", "w") do |yfile|
    yfile.puts YAML.dump({headers: parser.headers, data: parser.data})
  end
end

