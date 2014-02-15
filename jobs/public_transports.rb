require 'open-uri'
require 'json'
require 'mechanize'

# CONSTANTS
DUBLIN_BIKES_STATIONS = [4]
DUBLIN_LUAS_STOP = 'Ranelagh'
DUBLIN_BUS_INBOUND_STOP = 887
DUBLIN_BUS_OUTBOUND_STOP = 852

# Start the scheduler
SCHEDULER.every '30s', :first_in => '1s' do

  ## Rendering variables
  @trams_in  = []
  @trams_out = []
  @bikes     = []
  @buses_in  = []
  @buses_out = []

  ## Dublin trams
  infos = Mechanize.new.get("http://www.luas.ie/luaspid.html?get=#{DUBLIN_LUAS_STOP}")
  infos.at('div.Inbound').search('div.location').children.each {|c| @trams_in.push({dest: c.content, time: nil }) }
  infos.at('div.Outbound').search('div.location').children.each {|c| @trams_out.push({dest: c.content, time: nil }) }

  infos.at('div.Inbound').search('div.time').children.each_with_index do |c, i|
    time = c.content
    unless time.upcase == "DUE"
      time = (time.to_i == 1) ? "#{time} min" : "#{time} mins"
    end
    @trams_in[i][:time]= time
  end

  infos.at('div.Outbound').search('div.time').children.each_with_index do |c, i|
    time = c.content
    unless time.upcase == "DUE"
      time = (time.to_i == 1) ? "#{time} min" : "#{time} mins"
    end
    @trams_out[i][:time]= time
  end


  ## Dublin Bikes
  temp_bikes = JSON.parse(open("http://opendata.nets.upf.edu/osn2/api/datasets/data/#{settings.dublin_bikes_api_key}/aHR0cDovL2FwaS5jaXR5YmlrLmVzL2R1Ymxpbi5qc29u").read)
  temp_bikes.select! {|station| DUBLIN_BIKES_STATIONS.include?(station['id'].to_i) }
  temp_bikes.each do |station|
    val = "#{station['bikes']}/#{station['bikes'].to_i+station['free'].to_i}"
    @bikes.push({name: station['name'], val: val})
  end

  ## Dublin Buses
  inbound_infos   = Mechanize.new.get("http://dublinbuslive.com/index.php?id=#{DUBLIN_BUS_INBOUND_STOP}").at('#content').search('ul').first
  outbound_infos  = Mechanize.new.get("http://dublinbuslive.com/index.php?id=#{DUBLIN_BUS_OUTBOUND_STOP}").at('#content').search('ul').first
  @buses_in       = collect_buses_info(inbound_infos)
  @buses_out      = collect_buses_info(outbound_infos)

  ## Send results
  send_event('public_transports', { trams_in: @trams_in, trams_out: @trams_out, bikes: @bikes, buses_in: @buses_in, buses_out: @buses_out })

end


def collect_buses_info(list)
  res = []
  list.children.each do |b|
    res.push({
      number: (b.at('.number').content.include?("0 Mins")) ? "DUE" : b.at('.number').content,
      dest: truncate(b.at('.name').content, 18),
      time: b.at('.time').content
    })
  end
  res
end

def truncate(text, size =30)
  unless text.length < size+3
    text = text[0, size] + " ..."
  end
  text
end