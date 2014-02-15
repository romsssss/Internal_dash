require 'date'
require 'mechanize'


SCHEDULER.every '1h', :first_in => 0  do

  strip_date = Date.today

  @url=  Mechanize.new.get("http://www.dilbert.com/strips/comic/#{strip_date.year}-#{strip_date.month.to_s.rjust(2, '0')}-#{strip_date.day.to_s.rjust(2, '0')}/").images[1].url.to_s

  send_event('dilbert_strip', { url: @url})
end
