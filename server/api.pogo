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
  res.send (db.updateQuery(req.param 'queryId', req.body)!)

app.delete '/blocks/:blockId/queries/:queryId' @(req, res)
  db = app.get 'db'
  db.deleteQuery(req.param 'blockId', req.param 'queryId')!
  res.send {}

app.post '/blocks/:id/queries' @(req, res)
  db = app.get 'db'
  query = req.body

  if (query.before)
    before = query.before
    delete (query.before)
    res.send (db.insertQueryBefore(req.param 'id', before, query)!)
  else if (query.after)
    after = query.after
    delete (query.after)
    res.send (db.insertQueryAfter(req.param 'id', after, query)!)
  else
    res.send (db.addQuery(req.param 'id', query)!)

app.post '/lexicon' @(req, res)
  db = app.get 'db'
  db.setLexicon(req.body)!
  res.status(201).send({})

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

module.exports = app
