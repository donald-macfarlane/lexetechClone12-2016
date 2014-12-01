express = require 'express'
openDb = require './db'

db = openDb()
app = express()

app.get '/' @(req, res)
  res.send {}

app.get '/query/:id/graph' @(req, res)
  res.send {}

module.exports = app
