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

    expect(db.blockQueries(1)!.length).to.eql 1
    query = db.blockQueries(1)!.(0)

    expect(query.text).to.eql 'query 1'
    expect(query.responses.0.text).to.eql 'response 1'

  it 'can get queries for block'
    db.clear()!
    db.setLexicon(
      lexicon.blocks [
        {
          id = 1
          queries = [
            {
              text 'query 1'

              responses = [
                {
                  text = 'response 1'
                }
              ]
            }
            {
              text 'query 2'

              responses = [
                {
                  text = 'response 1'
                }
              ]
            }
          ]
        }
      ]
    )!
    queries = api.get('/api/blocks/1/queries')!.body
    expect(queries.length).to.eql 2
    expect [q <- queries, q.text].to.eql ['query 1', 'query 2']

  it 'returns empty list for non-extant block'
    db.clear()!
    db.setLexicon(
      lexicon.blocks []
    )!
    queries = api.get('/api/blocks/2/queries')!.body
    expect(queries.length).to.eql 0

  describe 'authoring'
    describe 'predicants'
      it 'can create a predicant'
        api.post '/api/predicants' { name = 'predicant 1' }!
        predicants = api.get '/api/predicants'!.body
        predicantIds = Object.keys(predicants)
        expect(predicantIds.length).to.equal 1
        id = predicantIds.0
        expect(predicants.(id).id).to.equal(id)
        expect(predicants.(id).name).to.equal 'predicant 1'
