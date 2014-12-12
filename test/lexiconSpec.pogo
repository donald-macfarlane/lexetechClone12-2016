httpism = require 'httpism'
app = require '../server/app'
expect = require 'chai'.expect
memoryDb = require '../server/memoryDb'
redisDb = require '../server/redisDb'
lexiconBuilder = require './lexiconBuilder'
debug = require '../server/debug'
_ = require 'underscore'
uritemplate = require 'uritemplate'
queryApi = require '../browser/queryApi'

describe "lexicon"
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

  withQueries(queries) =
    db.setQueries(queries)!

  conversation() =
    query = nil
    response = nil
    qapi = queryApi {
      http = {
        get(url) = api.get (url)!.body
      }
    }
    
    {
      shouldAsk (queryText) thenRespondWith (responseText) =
        if (@not query)
          query := qapi.firstQuery()!
        else
          query := response.query()!

        expect(query.text).to.equal (queryText)

        response := [r <- query.responses, r.text == responseText, r].0
        expect(response, "response '#(responseText)' not one of #([r <- query.responses, "'#(r.text)'"].join ', ')").to.exist

      shouldBeFinished() =
        expect(response.query()!).to.be.undefined
    }

  it 'queries are asked in coherence order'
    withQueries! [
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

    c = conversation()
    c.shouldAsk 'query 1' thenRespondWith 'response 1'!
    c.shouldAsk 'query 2' thenRespondWith 'response 1'!
    c.shouldAsk 'query 3' thenRespondWith 'response 1'!
    c.shouldAsk 'query 4' thenRespondWith 'response 1'!
    c.shouldBeFinished()!

  context 'when two responses have the same query'
    beforeEach
      withQueries! [
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
      c = conversation()
      c.shouldAsk 'query 1' thenRespondWith 'response 1'!
      c.shouldAsk 'query 2' thenRespondWith 'response 1'!
      c.shouldAsk 'query 3' thenRespondWith 'response 1'!
      c.shouldBeFinished()!

    it 'can choose the second response, and get to the same query'
      c = conversation()
      c.shouldAsk 'query 1' thenRespondWith 'response 2'!
      c.shouldAsk 'query 2' thenRespondWith 'response 1'!
      c.shouldAsk 'query 3' thenRespondWith 'response 1'!
      c.shouldBeFinished()!

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
      c = conversation()
      c.shouldAsk 'query 1' thenRespondWith 'response 1'!
      c.shouldAsk 'query 2' thenRespondWith 'response 1'!
      c.shouldAsk 'query 3' thenRespondWith 'response 1'!
      c.shouldBeFinished()!

    it 'can explore the right hand side'
      c = conversation()
      c.shouldAsk 'query 1' thenRespondWith 'response 2'!
      c.shouldAsk 'query 2' thenRespondWith 'response 1'!
      c.shouldAsk 'query 4' thenRespondWith 'response 1'!
      c.shouldBeFinished()!

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

    it 'can ask the same question repeatedly'
      c = conversation()
      c.shouldAsk 'query 1' thenRespondWith 'response 1'!
      c.shouldAsk 'query 1' thenRespondWith 'response 1'!
      c.shouldAsk 'query 1' thenRespondWith 'response 2'!
      c.shouldAsk 'query 2' thenRespondWith 'response 1'!
      c.shouldBeFinished()!
