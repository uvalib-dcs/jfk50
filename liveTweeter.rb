#!/usr/bin/env ruby

# LiveTweeter
#
# A simple Ruby program for scheuduling tweets
# stored in a CSV file.  Written for the 
# 50th anniversary of the assassination of the
# President in Dallas, TX.
#
# Digital Curation Services, University of Virginia Library
# Charlottesville, VA
#
# see https://dev.twitter.com/docs for details on
# the Twitter API


require 'date'
require 'twitter'
require 'rufus-scheduler'
require 'csv'

REQ_TOKEN_URL="https://api.twitter.com/oauth/request_token"
AUTH_URL="https://api.twitter.com/oauth/authorize"
ACCESS_TOKEN_URL="https://api.twitter.com/oauth/access_token"

$hashtags="#JFK50 #UVA"
$link_to_exhibit="http://bit.ly/1cGRk6e"

# twitter account credentials (go to http://dev.twitter.com to register your app)
CONSUMER_KEY="your_consumer_key"
CONSUMER_SECRET="your_consumer_secret"
ACCESS_TOKEN="your_access_key"
ACCESS_TOKEN_SECRET="your_access_secret"


client = Twitter::REST::Client.new do |config|
  config.consumer_key        = CONSUMER_KEY
  config.consumer_secret     = CONSUMER_SECRET
  config.access_token        = ACCESS_TOKEN
  config.access_token_secret = ACCESS_TOKEN_SECRET
end


scheduler = Rufus::Scheduler.new

start_time=Time.now
tweet_data=[]

CSV.foreach("./TeletypeForTweeting.csv", { :col_sep => "\t" }) do |row| 
  tweet_data << row.to_csv.chop
end
tweet_data.shift # remove CSV header row

def parse(row)
  one, two, three = "", "", ""
  match = row.match(/^([^,]*),([^,]*),(.*)$/)
  if ! match.nil?
    one = match[1] || ""
    two = match[2].gsub(/;/, ':') || ""
    three = match[3] || ""
  end
  return one, two, three
end

def scheduler.handle_exception(job, exception)
    $stderr.puts "job #{job.job_id} caught exception '#{exception}'"
end

def build_chyron(timestamp, content)
  "You are following the UPI teletype as broadcast #{timestamp} November 22nd, 1963 #{$hashtags} #{$link_to_exhibit}"
end

@last_timestamp = Time.now
@time_adjust =  (120 * 60)

tweet_data[0..200].each_with_index do |datum,index|
  next if datum.length < 5
  code,timestamp,content = parse(datum)

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
    content=build_chyron(timestamp,content) 
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
        tweet = backup_client.update(content)
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
  a,b,c = parse(tweet_data[1])
  t = Time.parse(b) + @time_adjust
  client.update("Stay tuned for our live tweeting the United Press International wire feed from Nov 22, 1936 #{$hashtags} #{$link_to_exhibit}")
  s="#{$0} it is now #{Time.now}. Starting at #{t.to_s}..."
  $stdout.puts s
end


while 1 > 0 do
  # suspend program in execution until your tweets have been completed.
end
