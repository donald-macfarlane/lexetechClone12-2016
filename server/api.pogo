express = require 'express'

app = express()

app.get '/blocks/:id' @(req, res)
  db = app.get 'db'

  res.send (db.block(req.param 'id').queryIds()!)

app.get '/queries/:id' @(req, res)
  db = app.get 'db'

  res.send (db.queryById(req.param 'id')!)

app.post '/lexicon' @(req, res)
  db = app.get 'db'
  db.setLexicon(req.body)!
  res.status(201).send({ status = 'success' })

module.exports = app
