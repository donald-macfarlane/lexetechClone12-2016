httpism = require 'httpism'
app = require '../../server/app'
expect = require 'chai'.expect

describe "query api"
  port = 12345
  api = httpism.api "http://api:squidandeels@localhost:#(port)"
  server = nil
  db = nil
  lexicon = nil

  beforeEach
    db := app.get 'db'
    server := app.listen (port)

  afterEach
    server.close()

  it 'can insert blocks'
    db.clear()!
    response = api.post('/api/blocks', { id = 'xyz' })!
    expect(response.statusCode).to.equal(201)
    block = db.block('xyz')!
    expect(block).to.exist
