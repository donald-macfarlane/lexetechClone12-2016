express = require 'express'

app = express()

app.post '/blocks' @(req, res)
  db = app.get 'db'
  db.createBlock(req.body)!
  created(res)

app.get '/blocks/:id' @(req, res)
  db = app.get 'db'
  res.send (db.block(req.param 'id').queries()!)

app.post '/lexicon' @(req, res)
  db = app.get 'db'
  db.setLexicon(req.body)!
  created(res)

created(res) =
  res.status(201).send({ status = 'success' })

module.exports = app
