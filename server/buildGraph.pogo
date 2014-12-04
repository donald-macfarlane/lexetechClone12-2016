_ = require 'underscore'
debug = require './debug'
createContext = require './context'
createVisitedQueries = require './visitedQueries'

cloneContext(c) =
  blocks = {}
  for @(bk) in (c.blocks)
    blocks.(bk) = true

  predicants = {}
  for @(pk) in (c.predicants)
    predicants.(pk) = true

  createContext {
    coherenceIndex = c.coherenceIndex
    blocks = blocks
    level = c.level
    depth = c.depth
    predicants = predicants
  }

actions = {
  none (context) = nil
  email (context) = nil

  addBlocks (context, blocks, ...) =
    for each @(block) in (blocks)
      context.blocks.(block) = true

  setBlocks (context, blocks, ...) =
    context.blocks = {}
    for each @(block) in (blocks)
      context.blocks.(block) = true

  setVariable (context, variable, value) = nil

  repeatLexeme (context) =
    --context.coherenceIndex

  loopBack (context) = nil
}

newContextFromResponse (response) context (context) =
  newContext = cloneContext(context)
  newContext.level = response.setLevel
  ++newContext.depth
  ++newContext.coherenceIndex

  action = actions.(response.action.name)
  action(newContext, response.action.arguments, ...)

  for each @(p) in (response.predicants)
    newContext.predicants.(p) = true

  newContext

anyPredicantIn (predicants) foundIn (currentPredicants) =
  if (predicants.length > 0)
    _.any(predicants) @(p)
      currentPredicants.(p)
  else
    true

block (block) inActiveBlocks (blocks) =
  blocks.(block)

createCachedQueryLookups() =
  cache = []

  {
    findQueryByContext (context) or (block) =
      c = cache.(context.coherenceIndex)
      key = context.key()

      if (@not c)
        c := {}
        cache.(context.coherenceIndex) = c
        c.(key) = block()!
      else
        q = c.(key)
        if (q)
          q
        else
          c.(key) = block()!
  }

module.exports(db, graph, queryId, startContext = { blocks = {"1" = true}, level = 1, predicants = {context = true} }, maxDepth = 0) =
  unexploredQueries = []
  visitedQueries = createVisitedQueries()
  cachedQueryLookups = createCachedQueryLookups()

  findNextQuery(context) =
    cachedQueryLookups.findQueryByContext! (context) or
      findNextItem! @(query) in (db) startingFrom (context.coherenceIndex) matching
        query.level <= context.level \
          @and anyPredicantIn (query.predicants) foundIn (context.predicants) \
          @and block (query.block) inActiveBlocks (context.blocks)

  selectResponse (response) forQuery (query, context) =
    graph.response (response, context = context)

    newContext = newContextFromResponse (response) context (context)
    graph.query (query) toResponse (response, parentQueryContext = context, responseContext = newContext)

    if (maxDepth == 0 @or newContext.depth < maxDepth)
      nextQuery = findNextQuery!(newContext)
      graph.response (response) toQuery (nextQuery, responseContext = newContext)

      if (nextQuery)
        newContext.coherenceIndex = nextQuery.index
        if (@not visitedQueries.hasVisitedQuery (nextQuery) context (newContext))
          visitedQueries.visitedQuery (nextQuery) context (newContext)
          unexploredQueries.push {
            query = nextQuery
            context = newContext
          }

  buildGraphForQuery(query, context) =
    graph.query (query, context = context)

    [
      response <- query.responses
      selectResponse! (response) forQuery (query, context)
    ]

  unexploredQueries.push {
    query = db.queryById(queryId)!
    context = createContext {
      coherenceIndex = db.coherenceIndexForQueryId(queryId)!
      blocks = startContext.blocks
      level = startContext.level
      predicants = startContext.predicants
      depth = 0
    }
  }

  every(n) =
    i = -1

    @(block)
      ++i
      if (i >= n)
        block()
        i := 0

  everySoOften = every 1000

  numberOfQueries = 0
  
  graphNextQuery() =
    if(unexploredQueries.length > 0)
      task = unexploredQueries.shift()
      everySoOften
        graph.debug "exploring #(unexploredQueries.length):#(numberOfQueries)"

      buildGraphForQuery!(task.query, task.context)
      ++numberOfQueries
      graphNextQuery!()

  graphNextQuery!()

findNextItemIn (array) startingFrom (index) matching (predicate) =
  if (index < array.length()!)
    item = array.query(index)!

    if (predicate(item))
      item.index = index
      item
    else
      findNextItemIn (array) startingFrom (index + 1) matching (predicate)!
