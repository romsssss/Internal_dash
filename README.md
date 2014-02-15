Internal_dash
=============

Internal Dashboard bsed on dashing used at Wattics.

The following `credentials.yml` file containign all the APIs key is expected at the root of the project:
<pre><code>#continuous_integration:
jenkins_server: [jenkins server url]
jenkins_server_port: [jenkins server port (string)]
jenkins_username: [login]
jenkins_password: [pass]

#google_analytics:
ga_service_account_email: [email]
ga_key_file: [path/to/key/file]
ga_key_secret: [secret]
ga_profile_id_dash: [id]
ga_profile_id_website: [id]

#public_transports:
dublin_bikes_api_key: [api_key]

#twitter:
twitter_consumer_key: [key]
twitter_consumer_secret: [secret]
twitter_oauth_token: [token]
twitter_oauth_token_secret: [token_secret]
</code></pre>