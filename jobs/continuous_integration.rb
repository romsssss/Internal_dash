require 'jenkins_api_client'
require 'json'


SCHEDULER.every '20s', :first_in => '1s'  do
  @jobs= []

  client = JenkinsApi::Client.new(server_url: settings.jenkins_server, server_port:settings.jenkins_server_port, username: settings.jenkins_username, password:settings.jenkins_password)
  jobs_name = client.job.list_all

  jobs_name.each do |job|
   begin
    job_details = client.job.list_details(job)
    last_build_details = client.job.get_build_details(job, job_details['lastBuild']['number'])

    # Branch name
    branch_name = last_build_details['actions'].select {|h| h.has_key?('lastBuiltRevision')}.first['lastBuiltRevision']['branch'][0]['name'].split('/')
    branch_name.shift() # get ride of 'origin' in the name
    branch_name.join('/')

    # Build status
    if last_build_details['result'] == 'SUCCESS'
      build_status = "passed"
    else
      build_status = "failed"
    end
    build_status.insert(0, 'pending_') if last_build_details['building']

    # Avatar url
    if last_build_details['actions'].select{ |h| h.has_key?('causes') }.first['causes'].first.has_key?('userId')
      user_id = last_build_details['actions'].select{ |h| h.has_key?('causes') }.first['causes'].first['userId']
      avatar_url = "#{settings.jenkins_server}:#{settings.jenkins_server_port}/user/#{user_id}/avatar/image"
    elsif !last_build_details['culprits'].empty?
      user_id = last_build_details['culprits'][0]['absoluteUrl'].split('/').last
      avatar_url = "#{settings.jenkins_server}:#{settings.jenkins_server_port}/user/#{user_id}/avatar/image"
    else
      avatar_url = "assets/unknown_user.png"
    end

    @jobs.push({
      repo: job_details['displayName'],
      branch: branch_name,
      build_number: last_build_details['number'],
      build_start: pretty_time(Time.at(last_build_details['timestamp']/1000)),
      build_status: build_status,
      avatar_url: avatar_url
    })
   rescue
    puts "+++++ Error for #{job}"
   end
  end

  # Dynamic avatar size depending on the number of jobs
  @avatar_size = case @jobs.size
    when 0..2
      90
    when 3
      80
    when 4
      60
    else
      45

  end

  send_event('continuous_integration', { items: @jobs, avatar_size: @avatar_size})
end


def pretty_time(t)
  a = (Time.now-t).to_i

  case a
    when 0 then 'just now'
    when 1 then 'a second ago'
    when 2..59 then a.to_s+' seconds ago'
    when 60..119 then 'a minute ago' #120 = 2 minutes
    when 120..3540 then (a/60).to_i.to_s+' minutes ago'
    when 3541..7100 then 'an hour ago' # 3600 = 1 hour
    when 7101..82800 then ((a+99)/3600).to_i.to_s+' hours ago'
    when 82801..172000 then 'a day ago' # 86400 = 1 day
    when 172001..518400 then ((a+800)/(60*60*24)).to_i.to_s+' days ago'
    when 518400..1036800 then 'a week ago'
    else ((a+180000)/(60*60*24*7)).to_i.to_s+' weeks ago'
  end
end