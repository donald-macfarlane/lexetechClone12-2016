_ = require 'underscore'
createContext = require './context'
cache = require './cache'

cloneContext(c) =
  predicants = {}
  for @(pk) in (c.predicants)
    predicants.(pk) = true

  blockStack = JSON.parse(JSON.stringify(c.blockStack))

  createContext {
    coherenceIndex = c.coherenceIndex
    block = c.block
    blocks = c.blocks.slice 0
    level = c.level
    depth = c.depth
    predicants = predicants
    blockStack = blockStack
  }

actions = {
  none (response, context) = nil
  email (response, context) = nil

  addBlocks (response, context, blocks, ...) =
    context.pushBlockStack()

    context.coherenceIndex = 0
    context.block = blocks.shift()
    context.blocks = blocks

  setBlocks (response, context, blocks, ...) =
    context.blocks = blocks.slice 0

    nextBlock = context.blocks.shift()

    if (nextBlock != context.block)
      context.block = nextBlock
      context.coherenceIndex = 0


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
    query = findNextQueryInCurrentBlock(context)!
    if (@not query)
      if (context.blocks.length > 0)
        context.block = context.blocks.shift()
        context.coherenceIndex = 0
        findNextQuery(context)!
      else if (context.blockStack.length > 0)
        context.popBlockStack()
        findNextQuery(context)!
    else
      query

  findNextQueryInCurrentBlock(context) =
    findNextItem! @(query) in (db.block(context.block)) startingFrom (context.coherenceIndex) matching
      query.level <= context.level \
        @and anyPredicantIn (query.predicants) foundIn (context.predicants)

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
        db.block(1).query(0)!

    context = createContext {
      coherenceIndex =
        if (queryId)
          db.block(query.block)!.coherenceIndexForQueryId(queryId)!
        else
          0

      block = query.block
      blocks = []
      level = startContext.level
      predicants = startContext.predicants
      depth = 0
      blockStack = []
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

findNextItemIn (block) startingFrom (index) matching (predicate) =
  if (index < block.length()!)
    item = block.query(index)!

    if (predicate(item))
      item.index = index
      item
    else
      findNextItemIn (block) startingFrom (index + 1) matching (predicate)!
