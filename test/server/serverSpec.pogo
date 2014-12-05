httpism = require 'httpism'
app = require '../../server/app'
expect = require 'chai'.expect
memoryDb = require '../../server/memoryDb'
redisDb = require '../../server/redisDb'
lexiconBuilder = require './lexiconBuilder'
conversation = require '../conversation'
debug = require '../../server/debug'
_ = require 'underscore'

describe "server"
  port = 12345
  api = httpism.api "http://localhost:#(port)"
  server = nil
  db = nil
  lexicon = nil

  beforeEach
    db := redisDb()
    app.set 'db' (db)
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

  context 'when there are 4 queries'
    beforeEach
      db.setQueries! [
        lexicon.query {
          name = 'query 1'

          responses = [
            lexicon.response {
              response = 'response 1'
            }
          ]
        }
        lexicon.query {
          name = 'query 2'

          responses = [
            lexicon.response {
              response = 'response 1'
            }
          ]
        }
        lexicon.query {
          name = 'query 3'

          responses = [
            lexicon.response {
              response = 'response 1'
            }
          ]
        }
        lexicon.query {
          name = 'query 4'

          responses = [
            lexicon.response {
              response = 'response 1'
            }
          ]
        }
      ]

    it 'should return graph at most 3 deep by default'
      body = api.get! '/queries/1/graph'.body
      expect(depthOf(body.query)).to.equal 3

    it 'should return graph at most 2 when specified'
      body = api.get! '/queries/1/graph?depth=2'.body
      expect(depthOf(body.query)).to.equal 2

    it 'returns enough information to traverse query / response'
      body = api.get! '/queries/1/graph?depth=4'.body

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
          name = "query #(n)"

          responses = [
            lexicon.response {
              response = 'response 1'
            }
          ]
        }
      ]

    it 'returns a maximum of 10 queries'
      body = api.get! '/queries/1/graph?depth=20'.body
      expect(depthOf(body.query)).to.equal 10

  context 'when two responses have the same query'
    beforeEach
      db.setQueries! [
        lexicon.query {
          name = 'query 1'

          responses = [
            lexicon.response {
              response = 'response 1'
            }
            lexicon.response {
              response = 'response 2'
            }
          ]
        }
        lexicon.query {
          name = 'query 2'

          responses = [
            lexicon.response {
              response = 'response 1'
            }
          ]
        }
        lexicon.query {
          name = 'query 3'

          responses = [
            lexicon.response {
              response = 'response 1'
            }
          ]
        }
      ]

    it 'can choose the first response, and get to the same query'
      body = api.get! '/queries/1/graph?depth=4'.body

      c = conversation(body)
      c.asks 'query 1' respondWith 'response 1'
      c.asks 'query 2' respondWith 'response 1'
      c.asks 'query 3' respondWith 'response 1'

    it 'can choose the second response, and get to the same query'
      body = api.get! '/queries/1/graph?depth=4'.body

      c = conversation(body)
      c.asks 'query 1' respondWith 'response 2'
      c.asks 'query 2' respondWith 'response 1'
      c.asks 'query 3' respondWith 'response 1'

  context 'when a query is dependent on previous response'
    beforeEach
      db.setQueries! [
        lexicon.query {
          name = 'query 1'

          responses = [
            lexicon.response {
              response = 'response 1'
              predicants = ['a']
            }
            lexicon.response {
              response = 'response 2'
              predicants = ['b']
            }
          ]
        }
        lexicon.query {
          name = 'query 2'

          responses = [
            lexicon.response {
              response = 'response 1'
            }
          ]
        }
        lexicon.query {
          name = 'query 3'

          predicants = ['a']

          responses = [
            lexicon.response {
              response = 'response 1'
            }
          ]
        }
        lexicon.query {
          name = 'query 4'

          predicants = ['b']

          responses = [
            lexicon.response {
              response = 'response 1'
            }
          ]
        }
      ]

    it 'can explore the left hand side'
      graph = api.get! '/queries/1/graph?depth=4'.body
      c = conversation(graph)
      c.asks 'query 1' respondWith 'response 1'
      c.asks 'query 2' respondWith 'response 1'
      c.asks 'query 3' respondWith 'response 1'

    it 'can explore the right hand side'
      graph = api.get! '/queries/1/graph?depth=4'.body
      c = conversation(graph)
      c.asks 'query 1' respondWith 'response 2'
      c.asks 'query 2' respondWith 'response 1'
      c.asks 'query 4' respondWith 'response 1'

    describe 'asking for the next part of the graph'
      it 'can explore the left hand side'
        graph = api.get! '/queries/1/graph?depth=2'.body
        c = conversation(graph)
        c.asks 'query 1' respondWith 'response 1'

        q2 = c.query()
        expect(q2.partial).to.be.true

        q2 := api.get (q2.href)!.body
        c := conversation(q2)
        c.asks 'query 2' respondWith 'response 1'
        c.asks 'query 3' respondWith 'response 1'

      it 'can explore the right hand side'
        graph = api.get! '/queries/1/graph?depth=2'.body
        c = conversation(graph)
        c.asks 'query 1' respondWith 'response 2'

        q2 = c.query()
        expect(q2.partial).to.be.true

        q2 := api.get (q2.href)!.body
        c := conversation(q2)
        c.asks 'query 2' respondWith 'response 1'
        c.asks 'query 4' respondWith 'response 1'
