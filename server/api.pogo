express = require 'express'

app = express()

app.get '/blocks/:id' @(req, res)
  db = app.get 'db'

  setTimeout ^ 1000!
  res.send (db.block(req.param 'id').queries()!)

app.post '/lexicon' @(req, res)
  db = app.get 'db'
  db.setLexicon(req.body)!
  res.status(201).send({ status = 'success' })

module.exports = app
