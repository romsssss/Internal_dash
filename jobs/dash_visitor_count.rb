require 'google/api_client'
require 'date'


# Start the scheduler
SCHEDULER.every '1m', :first_in => '1s' do

  # Get the Google API client
  client = Google::APIClient.new(:application_name => 'Wattics',
    :application_version => '1.0')

  # Load your credentials for the service account
  key = Google::APIClient::KeyUtils.load_from_pkcs12(settings.ga_key_file, settings.ga_key_secret)
  client.authorization = Signet::OAuth2::Client.new(
    :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
    :audience => 'https://accounts.google.com/o/oauth2/token',
    :scope => 'https://www.googleapis.com/auth/analytics.readonly',
    :issuer => settings.ga_service_account_email,
    :signing_key => key)

  # Request a token for our service account
  client.authorization.fetch_access_token!

  # Get the analytics API
  analytics = client.discovered_api('analytics','v3')

  dash_visit_count = client.execute(:api_method => analytics.data.realtime.get, :parameters => {
    'ids' => "ga:" + settings.ga_profile_id_dash,
    'metrics' => "ga:activeVisitors"
  })
  dash_visits = (dash_visit_count.data.rows.empty?) ? 0 : dash_visit_count.data.rows[0][0].to_i
  send_event('dash_visitor_count',   { current: dash_visits })


  website_visit_count = client.execute(:api_method => analytics.data.realtime.get, :parameters => {
    'ids' => "ga:" + settings.ga_profile_id_website,
    'metrics' => "ga:activeVisitors"
  })
  website_visits = (website_visit_count.data.rows.empty?) ? 0 : website_visit_count.data.rows[0][0].to_i
  send_event('website_visitor_count',   { current: website_visits })

end