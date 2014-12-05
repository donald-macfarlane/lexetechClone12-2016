require 'rest-client'

Before do
  json = JSON.parse(File.read(File.expand_path('./lexicon.json', __FILE__)))
  RestClient.post "http://localhost:8000/queries",
     { 'x' => 1 }.to_json,
     :content_type => :json,
     :accept => :json
end