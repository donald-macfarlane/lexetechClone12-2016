httpism = require 'httpism'
app = require '../server/app'
expect = require 'chai'.expect
lexiconBuilder = require './lexiconBuilder'
buildGraph = require '../browser/buildGraph'
lexemeApi = require '../browser/lexemeApi'

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

  withLexicon(l) =
    db.setLexicon(lexicon.lexicon (l))!

  withBlocks(blocks) =
    db.setLexicon(lexicon.blocks(blocks))!

  withQueries(queries) =
    db.setLexicon(lexicon.queries(queries))!

  debug(args, ...) =
    console.log [
      a <- args
      if (a :: Object)
        JSON.stringify(a, nil, 2)
      else
        a
    ] ...
    args.(args.length - 1)

  conversation() =
    query = nil
    response = nil
    qapi = buildGraph (
      api = lexemeApi (
        http = {
          get(url) =
            api.get(url)!.body
        }
      )
    )

    {
      shouldAsk (queryText) thenRespondWith (responseText) =
        if (@not query)
          query := qapi.firstQueryGraph()!
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
      {
        text = 'query 1'

        responses = [
          {
            text = 'response 1'
          }
        ]
      }
      {
        text = 'query 2'

        responses = [
          {
            text = 'response 1'
          }
        ]
      }
      {
        text = 'query 3'

        responses = [
          {
            text = 'response 1'
          }
        ]
      }
      {
        text = 'query 4'

        responses = [
          {
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

  context 'with queries of different levels'
    beforeEach
      withQueries! [
        {
          text = 'query 1'

          responses = [
            {
              text = 'keep level 1'
            }
            {
              text = 'set level 2'
              setLevel = 2
            }
          ]
        }
        {
          text = 'level 2 query'
          level = 2

          responses = [
            {
              text = 'response 1'
            }
          ]
        }
        {
          text = 'query 3'

          responses = [
            {
              text = 'response 1'
            }
          ]
        }
      ]

    it 'skips queries when the level is too high'
      c = conversation()
      c.shouldAsk 'query 1' thenRespondWith 'keep level 1'!
      c.shouldAsk 'query 3' thenRespondWith 'response 1'!
      c.shouldBeFinished()!

    it 'includes queries when the level is increased'
      c = conversation()
      c.shouldAsk 'query 1' thenRespondWith 'set level 2'!
      c.shouldAsk 'level 2 query' thenRespondWith 'response 1'!
      c.shouldAsk 'query 3' thenRespondWith 'response 1'!
      c.shouldBeFinished()!

  context 'when two responses have the same query'
    beforeEach
      withQueries! [
        {
          text = 'query 1'

          responses = [
            {
              text = 'response 1'
            }
            {
              text = 'response 2'
            }
          ]
        }
        {
          text = 'query 2'

          responses = [
            {
              text = 'response 1'
            }
          ]
        }
        {
          text = 'query 3'

          responses = [
            {
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

  context 'when a query requires a predicate set by a previous response'
    beforeEach
      withQueries! [
        {
          text = 'query 1'

          responses = [
            {
              text = 'response 1'
              predicants = ['a']
            }
            {
              text = 'response 2'
              predicants = ['b']
            }
          ]
        }
        {
          text = 'query 2'

          responses = [
            {
              text = 'response 1'
            }
          ]
        }
        {
          text = 'query 3'

          predicants = ['a']

          responses = [
            {
              text = 'response 1'
            }
          ]
        }
        {
          text = 'query 4'

          predicants = ['b']

          responses = [
            {
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

  describe 'repeats'
    context 'when there is a response that repeats the same query'
      beforeEach
        withQueries! [
          {
            text = 'query 1'

            responses = [
              {
                text = 'response 1'
                action = { name = 'repeatLexeme', arguments = [] }
              }
              {
                text = 'response 2'
              }
            ]
          }
          {
            text = 'query 2'

            responses = [
              {
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

  describe 'blocks'
    describe 'set blocks'
      context "when we set blocks that we aren't in"
        beforeEach
          withBlocks! [
            {
              id = 1
              queries = [
                {
                  text = 'block 1, query 1'

                  responses = [
                    {
                      text = 'response 1'
                      action = { name = 'setBlocks', arguments = [3, 4] }
                    }
                  ]
                }
                {
                  text = 'block 1, query 2'

                  responses = [
                    {
                      text = 'response 1'
                      action = { name = 'setBlocks', arguments = [3, 4] }
                    }
                  ]
                }
              ]
            }
            {
              id = 2
              queries = [
                {
                  text = 'block 2, query 1'

                  responses = [
                    {
                      text = 'response 1'
                    }
                  ]
                }
              ]
            }
            {
              id = 3
              queries = [
                {
                  text = 'block 3, query 1'

                  responses = [
                    {
                      text = 'response 1'
                    }
                  ]
                }
              ]
            }
            {
              id = 4
              queries = [
                {
                  text = 'block 4, query 1'

                  responses = [
                    {
                      text = 'response 1'
                    }
                  ]
                }
              ]
            }
          ]

        it 'we skip the current and other blocks'
          c = conversation()
          c.shouldAsk 'block 1, query 1' thenRespondWith 'response 1'!
          c.shouldAsk 'block 3, query 1' thenRespondWith 'response 1'!
          c.shouldAsk 'block 4, query 1' thenRespondWith 'response 1'!
          c.shouldBeFinished()!

      context 'when we set blocks that we are already in'
        beforeEach
          withBlocks! [
            {
              id = 1
              queries = [
                {
                  text = 'block 1, query 1'

                  responses = [
                    {
                      text = 'response 1'
                      action = { name = 'setBlocks', arguments = [1, 3] }
                    }
                  ]
                }
                {
                  text = 'block 1, query 2'

                  responses = [
                    {
                      text = 'response 1'
                    }
                  ]
                }
              ]
            }
            {
              id = 2
              queries = [
                {
                  text = 'block 2, query 1'
                  block 2

                  responses = [
                    {
                      text = 'response 1'
                    }
                  ]
                }
              ]
            }
            {
              id = 3
              queries = [
                {
                  text = 'block 3, query 1'
                  block = 3

                  responses = [
                    {
                      text = 'response 1'
                    }
                  ]
                }
              ]
            }
          ]

        it "we continue with the block we're in, but skip to the remaining blocks"
          c = conversation()
          c.shouldAsk 'block 1, query 1' thenRespondWith 'response 1'!
          c.shouldAsk 'block 1, query 2' thenRespondWith 'response 1'!
          c.shouldAsk 'block 3, query 1' thenRespondWith 'response 1'!
          c.shouldBeFinished()!

    describe 'add blocks'
      context 'when we add blocks within a block'
        beforeEach
          withBlocks! [
            {
              id = 1
              queries = [
                {
                  text = 'block 1, query 1'

                  responses = [
                    {
                      text = 'response 1'
                      action = { name = 'addBlocks', arguments = [4, 3] }
                    }
                  ]
                }
                {
                  text = 'block 1, query 2'

                  responses = [
                    {
                      text = 'response 1'
                    }
                  ]
                }
              ]
            }
            {
              id = 2
              queries = [
                {
                  text = 'block 2, query 1'
                  block 2

                  responses = [
                    {
                      text = 'response 1'
                    }
                  ]
                }
              ]
            }
            {
              id = 3
              queries = [
                {
                  text = 'block 3, query 1'
                  block = 3

                  responses = [
                    {
                      text = 'response 1'
                    }
                  ]
                }
              ]
            }
            {
              id = 4
              queries = [
                {
                  text = 'block 4, query 1'
                  block = 3

                  responses = [
                    {
                      text = 'response 1'
                    }
                  ]
                }
              ]
            }
          ]
        
        it 'goes to those new blocks, then comes back to where we were before'
          c = conversation()
          c.shouldAsk 'block 1, query 1' thenRespondWith 'response 1'!
          c.shouldAsk 'block 4, query 1' thenRespondWith 'response 1'!
          c.shouldAsk 'block 3, query 1' thenRespondWith 'response 1'!
          c.shouldAsk 'block 1, query 2' thenRespondWith 'response 1'!
          c.shouldBeFinished()!
