_ = require 'underscore'
createContext = require './context'
cache = require '../common/cache'
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

findNextQuery(api, context) =
  query = findNextQueryInCurrentBlock(api, context)!
  if (@not query)
    if (context.blocks.length > 0)
      context.block = context.blocks.shift()
      context.coherenceIndex = 0
      findNextQuery(api, context)!
    else if (context.blockStack.length > 0)
      context.popBlockStack()
      findNextQuery(api, context)!
  else
    query

findNextQueryInCurrentBlock(api, context) =
  findNextItem! @(query) in (api.block(context.block)) startingFrom (context.coherenceIndex) matching
    query.level <= context.level \
      @and anyPredicantIn (query.predicants) foundIn (context.predicants)

preloadQueryGraph(query, depth) =
  if (depth > 0 @and query)
    [
      r <- query.responses
      preloadQueryGraph(r.query(preload = false)!, depth - 1)!
    ]

module.exports(api = lexemeApi()) =
  queryCache = cache()

  queryGraph (query, context) =
    {
      text = query.text

      responses = [
        r <- query.responses
        {
          text = r.text
          notes = r.notes

          query(preload = true) =
            if (@not self._query)
              self._query = nextQueryForResponse(r, context)

            if (preload @and @not self.preloaded)
              @{
                self.preloaded = true
                preloadQueryGraph(self._query!, 4)!
              }()

            self._query
        }
      ]
    }

  nextQueryForResponse (response, context) =
    newContext = newContextFromResponse (response) context (context)

    queryCache.cacheBy "#(newContext.coherenceIndex):#(newContext.key())"!
      nextQuery = findNextQuery!(api, newContext)

      if (nextQuery)
        newContext.coherenceIndex = nextQuery.index
        queryGraph (nextQuery, newContext)

  {
    firstQueryGraph() =
      query = api.block(1).query(0)!

      context = createContext {
        coherenceIndex = 0
        block = query.block
        blocks = []
        level = 1
        predicants = {context = true}
        blockStack = []
      }

      graph = queryGraph (query, context)
      preloadQueryGraph(graph, 4)
      graph
  }

findNextItemIn (block) startingFrom (index) matching (predicate) =
  if (index < block.length()!)
    item = block.query(index)!

    if (predicate(item))
      item.index = index
      item
    else
      findNextItemIn (block) startingFrom (index + 1) matching (predicate)!
