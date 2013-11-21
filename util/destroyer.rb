#!/usr/bin/env ruby
#
# destroyer.rb
#
# A utility script for deleting Tweets
# in batches of 200
# (used during testing LiveTweeter.rb)
#

require 'date'
require 'twitter'

REQ_TOKEN_URL="https://api.twitter.com/oauth/request_token"
AUTH_URL="https://api.twitter.com/oauth/authorize"
ACCESS_TOKEN_URL="https://api.twitter.com/oauth/access_token"

# first app
CONSUMER_KEY=""
CONSUMER_SECRET=""
ACCESS_TOKEN=""
ACCESS_TOKEN_SECRET=""

username="Your Name Here"

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = CONSUMER_KEY
  config.consumer_secret     = CONSUMER_SECRET
  config.access_token        = ACCESS_TOKEN
  config.access_token_secret = ACCESS_TOKEN_SECRET
end


timeline=client.user_timeline(username, :count => 200)
list = timeline.map(&:id)
puts "Retrieved #{list.count} tweets in user timeline."
list.each  {|i| client.status_destroy(i.to_s)  }
puts "Destroyed!"
exit 0
