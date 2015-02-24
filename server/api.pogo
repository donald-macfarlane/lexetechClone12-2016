express = require 'express'
_ = require 'underscore'
githubContent = require './githubContent'

app = express()

backup(redisDb, backupHttpism) =
  github = githubContent(backupHttpism)
  try
    github.put!('lexicon.json', JSON.stringify(redisDb.getLexicon()!, nil, 2))
    console.log "backed up lexicon"
  catch (e)
    console.log "could not backup lexicon"
    console.log(e)

delayBackupsByWait = {}

delayBackup(wait) =
  if (delayBackupsByWait.(wait))
    delayBackupsByWait.(wait)
  else
    delayBackupsByWait.(wait) = _.debounce(backup, wait)

app.use @(req, res, next)
  if (req.method == 'PUT' @or req.method == 'POST' @or req.method == 'DELETE')
    backupHttpism = app.get 'backupHttpism'
    if (backupHttpism)
      (delayBackup(app.get 'backupDelay'))(app.get 'db', backupHttpism)

    next()
  else
    next()

app.get '/blocks' @(req, res)
  db = app.get 'db'
  res.send(db.listBlocks()!)

app.post '/blocks' @(req, res)
  db = app.get 'db'
  block = db.createBlock(req.body)!
  res.set 'location' "#(req.baseUrl)/blocks/#(block.id)"
  res.status(201).send(block)

app.get '/blocks/:id' @(req, res)
  db = app.get 'db'
  res.send (db.blockById(req.params.id)!)

app.post '/blocks/:id' @(req, res)
  db = app.get 'db'
  res.send (db.updateBlockById(req.params.id, req.body)!)

app.get '/blocks/:id/queries' @(req, res)
  db = app.get 'db'
  res.send (db.blockQueries(req.params.id)!)

app.get '/blocks/:blockId/queries/:queryId' @(req, res)
  db = app.get 'db'
  query = db.queryById(req.params.queryId)!
  if (query)
    res.send (query)
  else
    res.status(404).send({})

app.post '/blocks/:blockId/queries/:queryId' @(req, res)
  db = app.get 'db'
  query = req.body
  
  if (query.after)
    res.send (db.moveQueryAfter(req.params.blockId, req.params.queryId, query.after)!)
  else if (query.before)
    res.send (db.moveQueryBefore(req.params.blockId, req.params.queryId, query.before)!)
  else
    res.send (db.updateQuery(req.params.queryId, query)!)

app.delete '/blocks/:blockId/queries/:queryId' @(req, res)
  db = app.get 'db'
  db.deleteQuery(req.params.blockId, req.params.queryId)!
  res.send {}

app.post '/blocks/:blockId/queries' @(req, res)
  db = app.get 'db'
  query = req.body

  if (query.before)
    before = query.before
    delete (query.before)
    res.send (db.insertQueryBefore(req.params.blockId, before, query)!)
  else if (query.after)
    after = query.after
    delete (query.after)
    res.send (db.insertQueryAfter(req.params.blockId, after, query)!)
  else
    res.send (db.addQuery(req.params.blockId, query)!)

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
  db.deleteUserQuery(req.user.id, req.params.queryId)!
  res.status(204).send({})

app.post '/user/documents' @(req, res)
  db = app.get 'db'
  document = db.createDocument!(req.user.id, req.body)
  res.set 'location' "#(req.baseUrl)/user/documents/#(document.id)"
  res.send (document)

app.post '/user/documents/:id' @(req, res)
  db = app.get 'db'
  db.writeDocument!(req.user.id, req.params.id, req.body)
  res.send {}

app.get '/user/documents/:id' @(req, res)
  db = app.get 'db'
  doc = db.readDocument!(req.user.id, req.params.id)

  if (doc)
    res.send (doc)
  else
    res.status(404).send { message = 'no such document' }

module.exports = app
