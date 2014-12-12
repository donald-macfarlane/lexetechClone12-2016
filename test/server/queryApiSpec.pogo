httpism = require 'httpism'
app = require '../../server/app'
expect = require 'chai'.expect
memoryDb = require '../../server/memoryDb'
redisDb = require '../../server/redisDb'
lexiconBuilder = require '../lexiconBuilder'
conversation = require '../conversation'
debug = require '../../server/debug'
_ = require 'underscore'
uritemplate = require 'uritemplate'

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

  depthOf (query) =
    if (query.responses.length > 0)
      1 + _.max [
        r <- query.responses
        if (r.query)
          depthOf(r.query)
        else
          0
      ]
    else
      1

  it 'can insert queries'
    db.clear()!
    fixture = require '../../features/support/lexicon.json'
    response = api.post('/api/queries', fixture)!
    expect(response.statusCode).to.eql 201
    expect(response.body.status).to.equal 'success'
    expect(db.query(0)!.responses.0.text).to.eql 'right arm'

  context 'when there are 4 queries'
    beforeEach
      db.setQueries! [
        lexicon.query {
          text = 'query 1'

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
        lexicon.query {
          text = 'query 2'

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
        lexicon.query {
          text = 'query 3'

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
        lexicon.query {
          text = 'query 4'

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
      ]

    it 'should return graph at most 3 deep by default'
      body = api.get! '/api/queries/1/graph'.body
      expect(depthOf(body.query)).to.equal 3

    it 'should return graph at most 2 when specified'
      body = api.get! '/api/queries/1/graph?depth=2'.body
      expect(depthOf(body.query)).to.equal 2

    it 'returns enough information to traverse query / response'
      body = api.get! '/api/queries/1/graph?depth=4'.body

      c = conversation(body)
      c.asks 'query 1' respondWith 'response 1'
      c.asks 'query 2' respondWith 'response 1'
      c.asks 'query 3' respondWith 'response 1'
      c.asks 'query 4' respondWith 'response 1'

  describe 'max depth'
    beforeEach
      db.setQueries! [
        n <- [1..20]

        lexicon.query {
          text = "query #(n)"

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
      ]

    it 'returns a maximum of 10 queries'
      body = api.get! '/api/queries/1/graph?depth=20'.body
      expect(depthOf(body.query)).to.equal 10

  context 'when two responses have the same query'
    beforeEach
      db.setQueries! [
        lexicon.query {
          text = 'query 1'

          responses = [
            lexicon.response {
              text = 'response 1'
            }
            lexicon.response {
              text = 'response 2'
            }
          ]
        }
        lexicon.query {
          text = 'query 2'

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
        lexicon.query {
          text = 'query 3'

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
      ]

    it 'can choose the first response, and get to the same query'
      body = api.get! '/api/queries/1/graph?depth=4'.body

      c = conversation(body)
      c.asks 'query 1' respondWith 'response 1'
      c.asks 'query 2' respondWith 'response 1'
      c.asks 'query 3' respondWith 'response 1'

    it 'can choose the second response, and get to the same query'
      body = api.get! '/api/queries/1/graph?depth=4'.body

      c = conversation(body)
      c.asks 'query 1' respondWith 'response 2'
      c.asks 'query 2' respondWith 'response 1'
      c.asks 'query 3' respondWith 'response 1'

  context 'when a query is dependent on previous response'
    beforeEach
      db.setQueries! [
        lexicon.query {
          text = 'query 1'

          responses = [
            lexicon.response {
              text = 'response 1'
              predicants = ['a']
            }
            lexicon.response {
              text = 'response 2'
              predicants = ['b']
            }
          ]
        }
        lexicon.query {
          text = 'query 2'

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
        lexicon.query {
          text = 'query 3'

          predicants = ['a']

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
        lexicon.query {
          text = 'query 4'

          predicants = ['b']

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
      ]

    it 'can explore the left hand side'
      graph = api.get! '/api/queries/1/graph?depth=4'.body
      c = conversation(graph)
      c.asks 'query 1' respondWith 'response 1'
      c.asks 'query 2' respondWith 'response 1'
      c.asks 'query 3' respondWith 'response 1'

    it 'can explore the right hand side'
      graph = api.get! '/api/queries/1/graph?depth=4'.body
      c = conversation(graph)
      c.asks 'query 1' respondWith 'response 2'
      c.asks 'query 2' respondWith 'response 1'
      c.asks 'query 4' respondWith 'response 1'

    describe 'asking for the next part of the graph'
      expand (href, obj) =
        t = uritemplate.parse(href)
        t.expand(obj)

      it 'can explore the left hand side'
        graph = api.get! '/api/queries/1/graph?depth=2'.body
        c = conversation(graph)
        c.asks 'query 1' respondWith 'response 1'

        q2 = c.query()
        expect(q2.partial).to.be.true

        q2 := api.get (expand(q2.hrefTemplate, depth = 2))!.body
        c := conversation(q2)
        c.asks 'query 2' respondWith 'response 1'
        c.asks 'query 3' respondWith 'response 1'

      it 'can explore the right hand side'
        graph = api.get! '/api/queries/1/graph?depth=2'.body
        c = conversation(graph)
        c.asks 'query 1' respondWith 'response 2'

        q2 = c.query()
        expect(q2.partial).to.be.true

        q2 := api.get (expand(q2.hrefTemplate, depth = 2))!.body
        c := conversation(q2)
        c.asks 'query 2' respondWith 'response 1'
        c.asks 'query 4' respondWith 'response 1'

  context 'when there is a response that repeats the same query'
    beforeEach
      db.setQueries! [
        lexicon.query {
          text = 'query 1'

          responses = [
            lexicon.response {
              text = 'response 1'
              action = { name = 'repeatLexeme', arguments = [] }
            }
            lexicon.response {
              text = 'response 2'
            }
          ]
        }
        lexicon.query {
          text = 'query 2'

          responses = [
            lexicon.response {
              text = 'response 1'
            }
          ]
        }
      ]

    it 'can navigate back to the same query'
      graph = api.get! '/api/queries/first/graph'.body

      query = graph.query
      expect(query.text).to.eql 'query 1'
      response = query.responses.0
      expect(response.text).to.eql 'response 1'
      expect(response.queryHrefTemplate).to.eql (query.hrefTemplate)

      response := query.responses.1
      expect(response.text).to.eql 'response 2'

      query := response.query
      expect(query.text).to.eql 'query 2'
      response := query.responses.0
      expect(response.text).to.eql 'response 1'
      expect(response.queryHrefTemplate).to.be.undefined
  
