httpism = require 'httpism'
app = require '../../server/app'
expect = require 'chai'.expect
lexiconBuilder = require '../lexiconBuilder'

describe "query api"
  port = 12345
  api = httpism.api "http://api:squidandeels@localhost:#(port)"
  server = nil
  db = nil
  lexicon = nil

  beforeEach
    db := app.get 'db'
    server := app.listen (port)
    lexicon := lexiconBuilder()

  afterEach
    server.close()

  it 'can insert queries'
    db.clear()!
    l = lexicon.queries [
      {
        text 'query 1'

        responses = [
          {
            text = 'response 1'
          }
        ]
      }
    ]
    response = api.post('/api/lexicon', l)!
    expect(response.statusCode).to.eql 201
    expect(response.body.status).to.equal 'success'

    expect(db.block(1).length()!).to.eql 1
    query = db.block(1).query(0)!

    expect(query.text).to.eql 'query 1'
    expect(query.responses.0.text).to.eql 'response 1'
