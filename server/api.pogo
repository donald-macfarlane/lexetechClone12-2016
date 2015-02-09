express = require 'express'

app = express()

app.get '/blocks' @(req, res)
  db = app.get 'db'
  res.send(db.listBlocks()!)

app.post '/blocks' @(req, res)
  db = app.get 'db'
  block = db.createBlock(req.body)!
  res.status(201).send(block)

app.get '/blocks/:id' @(req, res)
  db = app.get 'db'
  res.send (db.blockById(req.param 'id')!)

app.post '/blocks/:id' @(req, res)
  db = app.get 'db'
  res.send (db.updateBlockById(req.param 'id', { name = req.body.name })!)

app.get '/blocks/:id/queries' @(req, res)
  db = app.get 'db'
  res.send (db.blockQueries(req.param 'id')!)

app.get '/blocks/:blockId/queries/:queryId' @(req, res)
  db = app.get 'db'
  query = db.queryById(req.param 'queryId')!
  if (query)
    res.send (query)
  else
    res.status(404).send({})

app.post '/blocks/:blockId/queries/:queryId' @(req, res)
  db = app.get 'db'
  query = req.body
  
  if (query.after)
    res.send (db.moveQueryAfter(req.param 'blockId', req.param 'queryId', query.after)!)
  else if (query.before)
    res.send (db.moveQueryBefore(req.param 'blockId', req.param 'queryId', query.before)!)
  else
    res.send (db.updateQuery(req.param 'queryId', query)!)

app.delete '/blocks/:blockId/queries/:queryId' @(req, res)
  db = app.get 'db'
  db.deleteQuery(req.param 'blockId', req.param 'queryId')!
  res.send {}

app.post '/blocks/:blockId/queries' @(req, res)
  db = app.get 'db'
  query = req.body

  if (query.before)
    before = query.before
    delete (query.before)
    res.send (db.insertQueryBefore(req.param 'blockId', before, query)!)
  else if (query.after)
    after = query.after
    delete (query.after)
    res.send (db.insertQueryAfter(req.param 'blockId', after, query)!)
  else
    res.send (db.addQuery(req.param 'blockId', query)!)

app.post '/lexicon' @(req, res)
  db = app.get 'db'
  db.setLexicon(req.body)!
  res.status(201).send({})

app.get '/lexicon' @(req, res)
  db = app.get 'db'
  res.send(db.getLexicon(req.body)!)

app.get '/predicants' @(req, res)
  db = app.get 'db'
  predicants = db.predicants()!
  res.send(predicants)

app.post '/predicants' @(req, res)
  db = app.get 'db'
  if (req.body :: Array)
    db.addPredicants(req.body)!
  else
    db.addPredicant(req.body)!

  res.status(201).send({})

app.delete '/predicants' @(req, res)
  db = app.get 'db'
  db.removeAllPredicants()!
  res.status(204).send({})

app.post '/user/queries' @(req, res)
  db = app.get 'db'
  query = req.body
  res.send (db.addQueryToUser(req.user.id, query)!)

app.get '/user/queries' @(req, res)
  db = app.get 'db'
  query = req.body
  res.send (db.userQueries(req.user.id, query)!)

app.delete '/user/queries/:queryId' @(req, res)
  db = app.get 'db'
  query = req.body
  db.deleteUserQuery(req.user.id, req.param 'queryId')!
  res.status(204).send({})

module.exports = app
