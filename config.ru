require 'dashing'
require 'yaml'

configure do
  yaml = YAML::load_file('./credentials.yml')
  yaml.each_pair do |key, value|
    set(key.to_sym, value)
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application