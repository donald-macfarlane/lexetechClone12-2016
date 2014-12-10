require 'rest_client'

Before do
  json = File.read(File.expand_path('../lexicon.json', __FILE__))
  RestClient.post "http://api:squidandeels@localhost:8001/api/queries",
     json,
     :content_type => :json,
     :accept => :json
end
