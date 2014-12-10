_ = require 'underscore'
createContext = require './context'
cache = require './cache'

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
  none (response, context) = nil
  email (response, context) = nil

  addBlocks (response, context, blocks, ...) =
    for each @(block) in (blocks)
      context.blocks.(block) = true

  setBlocks (response, context, blocks, ...) =
    context.blocks = {}
    for each @(block) in (blocks)
      context.blocks.(block) = true

  setVariable (response, context, variable, value) = nil

  repeatLexeme (response, context) =
    --context.coherenceIndex
    response.repeating = true

  loopBack (response, context) = nil
}

newContextFromResponse (response) context (context) =
  newContext = cloneContext(context)
  newContext.level = response.setLevel
  ++newContext.depth
  ++newContext.coherenceIndex

  action = actions.(response.action.name)
  action(response, newContext, response.action.arguments, ...)

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

startingContext = {
  blocks = {"1" = true}
  level = 1
  predicants = {context = true}
}

module.exports(db, graph, queryId, startContext = startingContext, maxDepth = 0) =
  unexploredQueries = []
  queryCache = cache()

  findNextQuery(context) =
    findNextItem! @(query) in (db) startingFrom (context.coherenceIndex) matching
      query.level <= context.level \
        @and anyPredicantIn (query.predicants) foundIn (context.predicants) \
        @and block (query.block) inActiveBlocks (context.blocks)

  selectResponse (response) forQuery (query, context, generatedQuery = nil) =
    newContext = newContextFromResponse (response) context (context)
    generatedResponse = generatedQuery.addResponse (response)

    if (maxDepth == 0 @or newContext.depth < maxDepth)
      generatedSubQuery = queryCache.cacheBy "#(newContext.coherenceIndex):#(newContext.key())"!
        nextQuery = findNextQuery!(newContext)
        subQuery = graph.query (nextQuery, context = newContext)

        if (nextQuery)
          newContext.coherenceIndex = nextQuery.index

          unexploredQueries.push {
            query = nextQuery
            context = newContext
            generatedQuery = subQuery
          }

        subQuery

      generatedResponse.setQuery (generatedSubQuery)

  buildGraphForQuery(query, context, generatedQuery) =
    [
      response <- query.responses
      selectResponse! (response) forQuery (query, context, generatedQuery = generatedQuery)
    ]

  firstTask () =
    query =
      if (queryId)
        db.queryById(queryId)!
      else
        db.query(0)!

    context = createContext {
      coherenceIndex =
        if (queryId)
          db.coherenceIndexForQueryId(queryId)!
        else
          0

      blocks = startContext.blocks
      level = startContext.level
      predicants = startContext.predicants
      depth = 0
    }

    {
      query = query
      context = context
      generatedQuery = graph.query (query, context = context)
    }

  unexploredQueries.push(firstTask()!)

  graphNextQuery() =
    if(unexploredQueries.length > 0)
      task = unexploredQueries.shift()
      buildGraphForQuery!(task.query, task.context, task.generatedQuery)
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
