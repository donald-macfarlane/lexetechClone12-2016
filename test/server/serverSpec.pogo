httpism = require 'httpism'
app = require '../../server/app'
expect = require 'chai'.expect
memoryDb = require '../../server/memoryDb'
redisDb = require '../../server/redisDb'
lexiconBuilder = require './lexiconBuilder'
traversal = require '../../browser/traversal'
debug = require '../../server/debug'

describeServer(name, createDb) =
  describe "server using #(name)"
    port = 12345
    api = httpism.api "http://localhost:#(port)"
    server = nil
    db = nil
    lexicon = nil

    beforeEach
      db := createDb()
      app.set 'db' (db)
      server := app.listen (port)
      lexicon := lexiconBuilder()

    afterEach
      server.close()

    conversation(graph) =
      currentQuery = traversal(graph)
      {
        asks (query) respondWith (response) =
          expect(currentQuery.text).to.equal (query)
          currentQuery := currentQuery.respond (response)
      }

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
        body = api.get! '/query/1/graph?depth=3'.body
        expect(Object.keys(body.queries).length).to.equal 3

      it 'should return graph at most 2 when specified'
        body = api.get! '/query/1/graph?depth=2'.body
        expect(Object.keys(body.queries).length).to.equal 2

      it 'returns enough information to traverse query / response'
        body = api.get! '/query/1/graph?depth=4'.body

        q1 = traversal(body)
        expect(q1.text).to.equal 'query 1'
        q2 = q1.respond 'response 1'
        expect(q2.text).to.equal 'query 2'
        q3 = q2.respond 'response 1'
        expect(q3.text).to.equal 'query 3'
        q4 = q3.respond 'response 1'
        expect(q4.text).to.equal 'query 4'

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
        graph = api.get! '/query/1/graph?depth=4'.body
        c = conversation(graph)
        c.asks 'query 1' respondWith 'response 1'
        c.asks 'query 2' respondWith 'response 1'
        c.asks 'query 3' respondWith 'response 1'

      it 'can explore the right hand side'
        graph = api.get! '/query/1/graph?depth=4'.body
        c = conversation(graph)
        c.asks 'query 1' respondWith 'response 2'
        c.asks 'query 2' respondWith 'response 1'
        c.asks 'query 4' respondWith 'response 1'

describeServer('memory', @() @{ memoryDb })
describeServer('redis', redisDb)
