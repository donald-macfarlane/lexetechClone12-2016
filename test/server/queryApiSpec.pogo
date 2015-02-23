httpism = require 'httpism'
express = require 'express'
bodyParser = require 'body-parser'
app = require '../../server/app'
expect = require 'chai'.expect
lexiconBuilder = require '../lexiconBuilder'
retry = require 'trytryagain'

describe "query api"
  port = 12345
  api = httpism.api "http://user:password@localhost:#(port)"
  server = nil
  db = nil
  lexicon = nil

  beforeEach
    db := app.get 'db'
    app.set 'apiUsers' { "user:password" = true }
    server := app.listen (port)
    lexicon := lexiconBuilder()
    db.clear()!

  afterEach
    server.close()

  describe 'backups'
    describe 'block ids'
      it 'block ids are maintained'
        lexicon1 = lexicon.blocks [
          {
            id = '10'
            name = 'block 10'
          }
          {
            id = '30'
            name = 'block 30'
          }
          {
            id = '20'
            name = 'block 20'
          }
        ]

        api.post('/api/lexicon', lexicon1)!
        lexicon2 = api.get('/api/lexicon')!.body
        expect([b <- lexicon2.blocks, {id = b.id, name = b.name}]).to.eql([
          {id = '10', name = 'block 10'}
          {id = '20', name = 'block 20'}
          {id = '30', name = 'block 30'}
        ])

      it 'the next block id is one higher than highest from before'
        lexicon1 = lexicon.blocks [
          {
            id = '1'
            name = 'block 1'
          }
          {
            id = '30'
            name = 'block 30'
          }
          {
            id = '20'
            name = 'block 20'
          }
        ]

        api.post('/api/lexicon', lexicon1)!
        api.post!('/api/blocks', {
          name = 'block 31'
          queries = [
            {
              text 'query 4'
            }
          ]
        })

        lexicon2 = api.get('/api/lexicon')!.body
        expect([b <- lexicon2.blocks, {id = b.id, name = b.name}]).to.eql([
          {id = '1', name = 'block 1'}
          {id = '20', name = 'block 20'}
          {id = '30', name = 'block 30'}
          {id = '31', name = 'block 31'}
        ])

      it 'the next query id is one higher than highest from before'
        lexicon1 = lexicon.blocks [
          {
            id = '1'
            name = 'block 1'
            queries = [
              { id = '1', name = 'query 1' }
            ]
          }
          {
            id = '30'
            name = 'block 30'
            queries = [
              { id = '10', name = 'query 10' }
              { id = '20', name = 'query 20' }
            ]
          }
        ]

        api.post('/api/lexicon', lexicon1)!
        api.post!('/api/blocks/1/queries', {
          name = 'query next'
        })

        lexicon2 = api.get('/api/lexicon')!.body
        expect([
          b <- lexicon2.blocks
          {
            id = b.id
            name = b.name
            queries = [
              q <- b.queries
              { id = q.id, name = q.name }
            ]
          }
        ]).to.eql([
          {
            id = '1'
            name = 'block 1'
            queries = [
              { id = '1', name = 'query 1' }
              { id = '21', name = 'query next' }
            ]
          }
          {
            id = '30'
            name = 'block 30'
            queries = [
              { id = '10', name = 'query 10' }
              { id = '20', name = 'query 20' }
            ]
          }
        ])

    it 'can set and get the lexicon'
      lexicon1 = lexicon.blocks [
        {
          id = '1'
          name = 'block 1'
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

                  predicants = [
                    "three"
                    "four"
                  ]
                }
              ]
            }
          ]
        }
        {
          id = '2'
          name = 'block 2'
          queries = [
            {
              text 'query 3'

              predicants = [
                "three"
                "four"
              ]

              responses = [
                {
                  text = 'response 1'
                }
              ]
            }
            {
              text 'query 4'

              responses = [
                {
                  text = 'response 1'
                }
              ]
            }
          ]
        }
      ]

      api.post('/api/lexicon', lexicon1)!
      lexicon2 = api.get('/api/lexicon')!.body
      expect(lexicon2).to.eql(lexicon1)

    context 'given a single query in the lexicon'
      backupApp = nil
      backupServer = nil
      backupAppPort = 23456
      lexiconBackups = []

      beforeEach
        backupApp := express()
        backupApp.use(bodyParser.json {limit = '1mb'})

        backupApp.get '/content/' @(req, res)
          if (lexiconBackups.length > 0)
            res.send [
              {
                name = 'lexicon.json'
                sha = String(lexiconBackups.length)
              }
            ]
          else
            res.send []

        backupApp.put '/content/lexicon.json' @(req, res)
          if (lexiconBackups.length == 0 @or req.body.sha == String(lexiconBackups.length))
            stringContent = @new Buffer(req.body.content, 'base64').toString('ascii')
            lexiconBackups.push(JSON.parse(stringContent))
            res.send()
          else
            res.status(422).send({message = "sha (#(req.body.sha)) not found"})

        backupServer := backupApp.listen(backupAppPort)

        app.set 'backupHttpism' (httpism.api("http://localhost:#(backupAppPort)/content/"))
        app.set 'backupDelay' (100)

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

      afterEach
        backupServer.close()
        app.set('backupHttpism', nil)

      it 'backs up the lexicon on writes'
        query1 = api.get('/api/blocks/1/queries/1')!.body
        query1.text = 'query 1 (updated)'
        api.post('/api/blocks/1/queries/1', query1)!
        api.post('/api/blocks/1/queries/1', query1)!
        api.post('/api/blocks/1/queries/1', query1)!

        retry (timeout = 120)!
          expect(lexiconBackups.length).to.equal(1)
          expect([l <- lexiconBackups, b <- l.blocks, q <- b.queries, q.text]).to.eql(['query 1 (updated)'])

      it 'can update the lexicon backup'
        query1 = api.get('/api/blocks/1/queries/1')!.body
        query1.text = 'query 1 (updated)'
        api.post('/api/blocks/1/queries/1', query1)!
        api.post('/api/blocks/1/queries/1', query1)!
        api.post('/api/blocks/1/queries/1', query1)!

        retry (timeout = 120)!
          expect(lexiconBackups.length).to.equal(1)
          expect([l <- lexiconBackups, b <- l.blocks, q <- b.queries, q.text]).to.eql(['query 1 (updated)'])

        query1.text = 'query 1 (updated, again)'
        api.post('/api/blocks/1/queries/1', query1)!

        retry (timeout = 120)!
          expect(lexiconBackups.length).to.equal(2)
          expect([l <- lexiconBackups, b <- l.blocks, q <- b.queries, q.text]).to.eql(['query 1 (updated)', 'query 1 (updated, again)'])

  it 'can insert queries'
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
    db.setLexicon(
      lexicon.blocks []
    )!
    queries = api.get('/api/blocks/2/queries')!.body
    expect(queries.length).to.eql 0

  describe 'authoring'
    describe 'blocks'
      it 'can create a block'
        response = api.post!('/api/blocks', {
          name = 'a block'
        })
        block = response.body

        blocks = api.get! '/api/blocks'.body
        expect(response.headers.location).to.equal('/api/blocks/1')
        expect(blocks.length).to.equal(1)
        expect(blocks.0.name).to.equal('a block')
        expect(blocks.0.id).to.equal(block.id)

        expect(api.get!('/api/blocks/1').body).to.eql(block)
        expect(api.get!('/api/blocks').body).to.eql [block]

      it 'orders blocks by id numerically'
        lexicon1 = lexicon.blocks [
          { id = '3' }
          { id = '10' }
          { id = '1' }
          { id = '2' }
        ]

        api.post('/api/lexicon', lexicon1)!

        blocks = api.get! '/api/blocks'.body
        expect([b <- blocks, b.id]).to.eql ['1', '2', '3', '10']

      it 'post ignores block id'
        api.post!('/api/blocks', {
          id = "1000"
          name = "block 1000"
        })

        blocks = api.get! '/api/blocks'.body
        expect([b <- blocks, { id = b.id, name = b.name}]).to.eql [{id = '1', name = 'block 1000'}]

      it 'can soft delete a block'
        block1Url = api.post!('/api/blocks', {
          id = "1"
        }).location
        api.post!('/api/blocks', {
          id = "2"
        })

        expect([b <- api.get!('/api/blocks').body, b.id]).to.eql ["1", "2"]

        api.post!('/api/blocks/1', {
          id = "1"
          deleted = true
        })
        expect([b <- api.get!('/api/blocks').body, b.id]).to.eql ["2"]
        expect(api.get!('/api/blocks/1').body).to.eql {
          id = "1"
          deleted = true
        }

    describe 'queries'
      block = nil

      beforeEach
        block := api.post!('/api/blocks', {
          name = 'a block'
        }).body

      it 'can insert a query into a block'
        query = api.post!("/api/blocks/#(block.id)/queries", {
          name = 'a query'
        }).body

        queries = api.get! "/api/blocks/#(block.id)/queries".body

        expect(queries.length).to.equal 1
        expect(queries.0.id).to.equal(query.id)
        expect(queries.0.name).to.equal('a query')

      it 'ignores the query id on creation'
        query = api.post!("/api/blocks/#(block.id)/queries", {
          id = '1000'
          name = 'query 1000'
        }).body

        queries = api.get! "/api/blocks/#(block.id)/queries".body

        expect([q <- queries, { id = q.id, name = q.name }]).to.eql [
          { id = '1', name = 'query 1000' }
        ]

      context 'when a query is added'
        newQuery = nil
        beforeEach
          newQuery := api.post!("/api/blocks/#(block.id)/queries", {
            name = 'a query'
          }).body

        it 'can get the query'
          query = api.get! "/api/blocks/#(block.id)/queries/#(newQuery.id)".body

          expect(query.id).to.equal(newQuery.id)
          expect(query.name).to.equal('a query')

        it 'can update the query'
          api.post! "/api/blocks/#(block.id)/queries/#(newQuery.id)" {
            name = 'a new name'
          }

          query = api.get! "/api/blocks/#(block.id)/queries/#(newQuery.id)".body

          expect(query.id).to.equal(newQuery.id)
          expect(query.name).to.equal('a new name')

        it 'can delete the query'
          api.delete! "/api/blocks/#(block.id)/queries/#(newQuery.id)"

          response = api.get! "/api/blocks/#(block.id)/queries/#(newQuery.id)" (exceptions = false)
          expect(response.statusCode).to.equal 404

          queries = api.get! "/api/blocks/#(block.id)/queries".body
          expect(queries.length).to.equal 0

        it 'can soft delete the query'
          newQuery.deleted = true
          api.post!("/api/blocks/#(block.id)/queries/#(newQuery.id)", newQuery)

          deletedQuery = api.get! "/api/blocks/#(block.id)/queries/#(newQuery.id)".body
          expect(deletedQuery).to.eql(newQuery)

          queries = api.get! "/api/blocks/#(block.id)/queries".body
          expect(queries.length).to.equal 0

        it 'can insert a query into a block before another query'
          query = api.post!("/api/blocks/#(block.id)/queries", {
            before = newQuery.id
            name = 'first query'
          }).body

          queries = api.get! "/api/blocks/#(block.id)/queries".body

          expect(queries.length).to.equal 2
          expect(queries.0.id).to.equal(query.id)
          expect(queries.0.name).to.equal('first query')
          expect(queries.1.id).to.equal(newQuery.id)
          expect(queries.1.name).to.equal('a query')

        it 'can insert a query into a block after another query'
          query = api.post!("/api/blocks/#(block.id)/queries", {
            after = newQuery.id
            name = 'last query'
          }).body

          queries = api.get! "/api/blocks/#(block.id)/queries".body

          expect(queries.length).to.equal 2
          expect(queries.0.id).to.equal(newQuery.id)
          expect(queries.0.name).to.equal('a query')
          expect(queries.1.id).to.equal(query.id)
          expect(queries.1.name).to.equal('last query')

      context 'when there are three queries'
        query1 = nil
        query2 = nil
        query3 = nil

        beforeEach
          query1 := api.post!("/api/blocks/#(block.id)/queries", {
            name = 'query 1'
          }).body
          query2 := api.post!("/api/blocks/#(block.id)/queries", {
            name = 'query 2'
          }).body
          query3 := api.post!("/api/blocks/#(block.id)/queries", {
            name = 'query 3'
          }).body

        it 'can move a query to after another query'
          api.post!("/api/blocks/#(block.id)/queries/#(query1.id)", {
            after = query3.id
          }).body

          queries = api.get! "/api/blocks/#(block.id)/queries".body

          expect([q <- queries, q.name]).to.eql [
            'query 2'
            'query 3'
            'query 1'
          ]

        it 'can move a query to before another query'
          api.post!("/api/blocks/#(block.id)/queries/#(query3.id)", {
            before = query1.id
          }).body

          queries = api.get! "/api/blocks/#(block.id)/queries".body

          expect([q <- queries, q.name]).to.eql [
            'query 3'
            'query 1'
            'query 2'
          ]

    describe 'predicants'
      it 'can create a predicant'
        api.post '/api/predicants' { name = 'predicant 1' }!
        predicants = api.get '/api/predicants'!.body
        predicantIds = Object.keys(predicants)
        expect(predicantIds.length).to.equal 1
        id = predicantIds.0
        expect(predicants.(id).id).to.equal(id)
        expect(predicants.(id).name).to.equal 'predicant 1'

      it 'can create multiple predicants'
        api.post '/api/predicants' { name = 'predicant 1' }!
        api.post! '/api/predicants' [
          { name = 'predicant 2' }
          { name = 'predicant 3' }
        ]
        predicants = api.get '/api/predicants'!.body
        names = [k <- Object.keys(predicants), p = predicants.(k), p.name]
        ids = Object.keys(predicants)
        expect(ids.length).to.equal 3

        for each @(id) in (Object.keys(predicants))
          predicant = predicants.(id)
          expect(predicant.id).to.equal(id)

        expect(names).to.contain('predicant 1')
        expect(names).to.contain('predicant 2')
        expect(names).to.contain('predicant 3')

      it 'can delete all predicants'
        api.post '/api/predicants' { name = 'predicant 1' }!
        api.delete '/api/predicants'!
        predicants = api.get '/api/predicants'!.body
        predicantIds = Object.keys(predicants)
        expect(predicantIds.length).to.equal 0

      it 'can insert a lexicon with predicants identified by id'
        l = lexicon.queries [
          {
            text 'query 1'

            predicants = [
              'pred1'
              'pred3'
            ]

            responses = [
              {
                text = 'response 1'
                predicants = [
                  'pred1'
                  'pred2'
                ]
              }
            ]
          }
        ]
        api.post('/api/lexicon', l)!

        block = api.get('/api/blocks')!.body.0
        query = api.get("/api/blocks/#(block.id)/queries")!.body.0
        predicants = api.get('/api/predicants')!.body

        expect [p <- query.predicants, predicants.(p).name].to.eql [
          'pred1'
          'pred3'
        ]

    describe 'clipboards'
      it 'can store new queries for a given user'
        query = {
          text = 'query 1'
          responses = [
            {
              text = 'reseponse 1'
            }
          ]
        }

        postedQuery = api.post!('/api/user/queries', query).body
        queries = api.get!('/api/user/queries').body

        query.id = postedQuery.id
        expect(queries).to.eql [
          query
        ]

      context 'given some queries in a users clipboard'
        beforeEach
          api.post!('/api/user/queries', {
            text = 'query 1'
            responses = [
              {
                text = 'reseponse 1'
              }
            ]
          })
          
          api.post!('/api/user/queries', {
            text = 'query 2'
            responses = [
              {
                text = 'reseponse 2'
              }
            ]
          })

        it 'can delete one'
          queries = api.get!('/api/user/queries').body
          expect(queries.length).to.equal(2)
          api.delete!("/api/user/queries/#(queries.0.id)")
          newQueries = api.get!('/api/user/queries').body
          expect(newQueries.length).to.equal(1)
          expect(newQueries.0.text).to.equal('query 2')

      context "when there is more than one user"
        user1 = nil
        user2 = nil

        beforeEach
          user1 := api
          user2 := httpism.api "http://different:password@localhost:#(port)"
          users = app.get 'apiUsers'
          users."different:password" = true

        it "one user cannot access another's queries"
          user1.post!('/api/user/queries', {
            text = 'query 1'
            responses = [
              {
                text = 'reseponse 1'
              }
            ]
          })
          
          user2.post!('/api/user/queries', {
            text = 'query 2'
            responses = [
              {
                text = 'reseponse 2'
              }
            ]
          })
        
          user1Queries = user1.get!('/api/user/queries').body
          expect([q <- user1Queries, q.text]).to.eql ['query 1']

          user2Queries = user2.get!('/api/user/queries').body
          expect([q <- user2Queries, q.text]).to.eql ['query 2']
