_ = require 'underscore'
createContext = require './context'
cache = require '../common/cache'
queryGraph = require './queryGraph'
lexemeApi = require '../browser/lexemeApi'

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

module.exports(api = lexemeApi()) =
  {
    firstQueryGraph(maxDepth = 1) =
      query = api.block(1).query(0)!

      context = createContext {
        coherenceIndex = 0
        block = query.block
        blocks = []
        level = 1
        predicants = {context = true}
        blockStack = []
      }

      self.nextQueryGraph(query, context, maxDepth)!

    nextQueryGraph(startingQuery, startingContext, maxDepth) =
      unexploredQueries = []
      queryCache = cache()
      graph = queryGraph(self)
      startingContext.depth = 0

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
        findNextItem! @(query) in (api.block(context.block)) startingFrom (context.coherenceIndex) matching
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

      firstQuery = graph.query (startingQuery, context = startingContext)
      unexploredQueries.push {
        query = startingQuery
        context = startingContext
        generatedQuery = firstQuery
      }

      graphNextQuery() =
        if(unexploredQueries.length > 0)
          task = unexploredQueries.shift()
          buildGraphForQuery!(task.query, task.context, task.generatedQuery)
          graphNextQuery!()

      graphNextQuery!()

      firstQuery
  }

findNextItemIn (block) startingFrom (index) matching (predicate) =
  if (index < block.length()!)
    item = block.query(index)!

    if (predicate(item))
      item.index = index
      item
    else
      findNextItemIn (block) startingFrom (index + 1) matching (predicate)!
