#!/usr/bin/env ruby

require 'date'
require 'twitter'
require 'rufus-scheduler'
require 'csv'

REQ_TOKEN_URL="https://api.twitter.com/oauth/request_token"
AUTH_URL="https://api.twitter.com/oauth/authorize"
ACCESS_TOKEN_URL="https://api.twitter.com/oauth/access_token"

$hash_tag_1="#JFK50"
$hash_tag_2="#UVA"
$link_to_exhibit="http://bit.ly/1cGRk6e"

# app credentials
CONSUMER_KEY=""
CONSUMER_SECRET=""
ACCESS_TOKEN=""
ACCESS_TOKEN_SECRET=""


client = Twitter::REST::Client.new do |config|
  config.consumer_key        = CONSUMER_KEY
  config.consumer_secret     = CONSUMER_SECRET
  config.access_token        = ACCESS_TOKEN
  config.access_token_secret = ACCESS_TOKEN_SECRET
end


scheduler = Rufus::Scheduler.new

start_time=Time.now
tweet_data=[]

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

def scheduler.handle_exception(job, exception)
    $stderr.puts "job #{job.job_id} caught exception '#{exception}'"
end

def build_chyron(timestamp, content)
  "You are following the UPI teletype as broadcast #{timestamp} November 22nd, 1963 #{$hash_tag_1} #{$hash_tag_2} #{$link_to_exhibit}"
end

@last_timestamp = Time.now
@time_adjust =  (6 * (60 * 60)) + (17 * 60)

tweet_data[0..26].each_with_index do |data,index|
  next if data.to_s.length < 5
  code,timestamp,content,url = parse(data)

  $stdout.puts "read #{timestamp} from row.  Last tweet time was #{@last_timestamp}"
  if timestamp == "" 
    timestamp = @last_timestamp.strftime("%H:%M") 
    tweet_time = Time.parse(timestamp)
  else
    tweet_time = Time.parse(timestamp)
    tweet_time = tweet_time + @time_adjust  # kluge for testing at a different time
  end

   # header rows should be turned into tweet reminders
  if content == code
    content=build_chyron(data[1],content)
  elsif ! url.nil?
    if content.length < 125
      content = content + " #{$hash_tag_1} #{$hash_tag_2}"
    end
    if content.length < 115 and url.to_s.length < 24
      content = content + " #{url}"
    end
  else
    if content.length < 125
      content = content + " #{$hash_tag_1} #{$hash_tag_2}"
    end
  end
  

  # see if we're already tweeting at this time
  if tweet_time > @last_timestamp
    # go ahead
    $stdout.puts "Tweet #{index} at #{tweet_time} requested, marker is at #{@last_timestamp}. \n"
    @last_timestamp = tweet_time unless not tweet_time.is_a?(Time)
  else
    # move this up 1m, change counter
    @last_timestamp = @last_timestamp + 15
    tweet_time = @last_timestamp # 15s boost
    $stdout.puts "Tweet #{index} time bumped to #{tweet_time} (+15s). Marker changed to match #{@last_timestamp} \n"
  end

  scheduler.at(tweet_time) do
    begin
      # choose which client to call
      if index % 2 == 0
        tweet = client.update(content)
      else
        tweet = client.update(content)
      end
      id = tweet.id
      brief = content[0..19]
      # could also try making a Twitter::Client and using #post('statuses/update' @content)
      report = %Q(Tweet ##{index} (#{brief}) id: #{id} scheduled for #{timestamp} #{tweet_time.to_s} runtime is \t)
      $stdout.puts report, Time.now, "\n"
    rescue => e
      puts "something wrong happened " + e.inspect
    end
  end
end

scheduler.jobs.each {|job| 
  $stdout.puts "#{job.original}\n"
}

scheduler.at start_time do
  $stdout.puts "Starting at #{start_time}..."
end
scheduler.at Time.now do
  # do something at a given point in time
  a,b,c = tweet_data[1][0], tweet_data[1][1], tweet_data[1][2]
  t = Time.parse(b) + @time_adjust
  client.update("We'll be tweeting the 1963 UPI Teletype in a few minutes. Stay tuned! #{$hash_tag_1} #{$hash_tag_2} #{$link_to_exhibit}")
  s="#{$0} it is now #{Time.now}. Starting at #{t.to_s}..."
  $stdout.puts s
end


while 1 > 0 do
end
