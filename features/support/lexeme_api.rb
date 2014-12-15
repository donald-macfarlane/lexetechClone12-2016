require 'mongo'
include Mongo

class LexemeApi
  def load_lexicon(filename)
    json = File.read(File.expand_path("../#{filename}", __FILE__))
    RestClient.post "http://api:squidandeels@localhost:8001/api/lexicon",
      json,
      :content_type => :json,
      :accept => :json
  end

  def sign_up(email, password)
    RestClient.post "http://api:squidandeels@localhost:8001/signup",
      email: email,
      password: password
  rescue RestClient::Found
  end

  def clear_db
    client = MongoClient.new
    db = client['lexeme']
    users = db['users']
    users.remove
  end
end

module HasLexemeApi
  def api
    LexemeApi.new
  end
end

World(HasLexemeApi)
