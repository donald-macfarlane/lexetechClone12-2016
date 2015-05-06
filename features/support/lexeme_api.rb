require 'redis'
require 'mongo'

class LexemeApi
  include Mongo

  def load_lexicon(filename)
    json = File.read(File.expand_path("../#{filename}", __FILE__))
    post_json "/api/lexicon", json
  end

  def sign_up(email, password)
    post_json "/api/users", email: email, password: password, author: true
  rescue RestClient::Found
  end

  def create_block(name)
    post "/api/blocks", name: name
  end

  def clear_db
    mongo_db['users'].remove
    redis_db.flushdb
  end

  private

  def post(path, form_values={})
    RestClient.post(root + path, form_values)
  end

  def post_json(path, body={})
    RestClient.post(root + path, body, :content_type => :json, :accept => :json)
  end

  def root
    'http://api:squidandeels@localhost:8001'
  end

  def mongo_db
    mongo_client = MongoClient.new
    mongo_client['lexeme']
  end

  def redis_db
    @redis_db ||= Redis.new
  end
end

module HasLexemeApi
  def api
    LexemeApi.new
  end
end

World(HasLexemeApi)
