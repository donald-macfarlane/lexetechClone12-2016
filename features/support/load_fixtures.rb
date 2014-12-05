require 'rest_client'

Before do
  json = File.read(File.expand_path('../lexicon.json', __FILE__))
  RestClient.post "http://localhost:8001/queries",
     json,
     :content_type => :json,
     :accept => :json
end