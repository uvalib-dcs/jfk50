#!/usr/bin/env ruby

require 'csv'

@limit = 120
@limit = ARGV[0].to_i if ARGV[0].to_i > 0

@bad_row_count = 0

quote_chars = %w(" | ~ ^ & *)

file=File.open("./TeletypeForTweeting.csv")
begin
  tweet_data = CSV.read(file, { :col_sep => "\t", :quote_char => quote_chars.shift })
rescue
  quote_chars.empty? ? raise : retry
end
tweet_data.shift # remove CSV header row

def parse(row)
  one   = row[0] || "" 
  two   = row[1] || ""
  three = row[2] || ""
  four  = row[3] || ""
  two.gsub(/;/, ':')

  return one, two, three, four
end

tweet_data.each_with_index do |line,index| 
  code,timestamp,content,url = parse(line)
  if content.length > @limit
    puts "#{index} #{content}" 
    @bad_row_count += 1
  end
end
puts "#{@bad_row_count} rows with tweets longer than #{@limit}"
