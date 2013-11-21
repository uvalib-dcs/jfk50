#!/usr/bin/env ruby
#
# line_reporter.rb
#
# simple command-line script for scanning
# a CSV file of potential tweets
# and identifying long lines
# (for editing)
#

require 'csv'

@limit = ARGV[0].to_i || 120

tweet_data=[]

CSV.foreach("./TeletypeForTweeting.csv") do |row| 
  tweet_data << row.to_csv.chop
end

def parse(row)
  one, two, three = "", "", ""
  match = row.match(/^([^,]*),([^,]*),(.*)$/)
  if ! match.nil?
    one = match[1] || ""
    two = match[2] || ""
    three = match[3] || ""
  end
  return one, two, three
end

tweet_data.each_with_index do |line,index| 
  code,timestamp,content=parse(line)
  puts "#{index} #{content}" if content.length > @limit
end
puts "rows with tweets longer than #{@limit}"
