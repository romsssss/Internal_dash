require 'twitter'

SCHEDULER.every '1m', :first_in => '1s' do |job|
  twitter = Twitter::REST::Client.new do |config|
    config.consumer_key = settings.twitter_consumer_key
    config.consumer_secret = settings.twitter_consumer_secret
    config.oauth_token = settings.twitter_oauth_token
    config.oauth_token_secret = settings.twitter_oauth_token_secret
  end
  search_term = URI::encode('Wattics')

  begin
    tweets = twitter.search("#{search_term}")

    if tweets
      tweets = tweets.map do |tweet|
        { name: tweet.user.name, body: tweet.text, avatar: tweet.user.profile_image_url_https }
      end
      send_event('twitter_mentions', comments: tweets)
    end
  rescue Twitter::Error
    puts "\e[33mWrong API keys\e[0m"
  end
end