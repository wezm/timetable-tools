require 'csv'
require 'nokogiri'
require 'timetable/page'

module Timetable

  class Processor

    def initialize(xml_path, options)
      @options = {
        :tables => 2,
        :histograms => false,
        :row_height => 10,
        :column_width => 20,
      }.merge(options)
      @xml_path = xml_path

      f = File.open(@xml_path)
      @xml = Nokogiri::XML.parse(f)
      f.close()
    end

    attr_reader :options, :xml

    def write(output_path)
      basename = File.basename(@xml_path, File.extname(@xml_path))
      
      page_idx = 0
      xml.css("page").each do |xml_page|
        page_idx += 1
        page = Page.new(xml_page, options[:tables], options[:row_height], options[:column_width])
        
        page.tables.each_with_index do |table, idx|
          write_csv(table, File.join(output_path, basename + "-page-#{page_idx}-table-#{idx + 1}.csv"))
        end
      end
    end

  protected
  
    def write_csv(table, path)
      CSV.open(path, "w") do |csv|
        table.rows.each do |row|
          csv << row
        end
      end
    end

  end
end
