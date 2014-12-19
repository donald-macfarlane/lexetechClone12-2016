express = require 'express'

app = express()

app.get '/blocks' @(req, res)
  db = app.get 'db'
  res.send(db.listBlocks()!)

app.post '/blocks' @(req, res)
  db = app.get 'db'
  id = db.createBlock(req.body)!
  res.status(201).send({ status = 'success', block = { id = id } })

app.get '/blocks/:id' @(req, res)
  db = app.get 'db'
  res.send (db.blockById(req.param 'id')!)

app.post '/blocks/:id' @(req, res)
  db = app.get 'db'
  res.send (db.updateBlockById(req.param 'id', { name = req.body.name })!)

app.get '/blocks/:id/queries' @(req, res)
  db = app.get 'db'
  res.send (db.blockQueries(req.param 'id')!)

app.post '/lexicon' @(req, res)
  db = app.get 'db'
  db.setLexicon(req.body)!
  res.status(201).send({ status = 'success' })

module.exports = app
