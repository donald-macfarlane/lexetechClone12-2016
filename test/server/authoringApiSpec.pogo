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
    response = api.post('/api/blocks', { })!
    expect(response.statusCode).to.equal(201)
    blockId = response.body.block.id
    expect(db.blockById(blockId)!).to.exist
