express = require 'express'
morgan = require 'morgan'
bodyParser = require 'body-parser'
passport = require 'passport'
session = require 'express-session'
LocalStrategy = require 'passport-local'.Strategy
BasicStrategy = require 'passport-http'.BasicStrategy

apiUsers = require './apiUsers.json'
users = require './users.json'

app = express()
app.use(morgan('combined'))
app.use(bodyParser.json {limit = '1mb'})
app.use(session { name = 'session', secret = 'haha bolshevik', resave = false, saveUninitialized = false })
app.use(bodyParser.urlencoded { extended = true })
app.engine('html', require('ejs').renderFile)
app.set 'views' (__dirname + '/views')

app.use(passport.initialize())
app.use(passport.session())

passport.serializeUser @(user, done)
  done(nil, user.email)

passport.deserializeUser @(email, done)
  done(nil, { email = email })

buildGraph = require './buildGraph'
queryGraph = require './queryGraph'

passport.use (new (BasicStrategy @(username, password, done)
  if (apiUsers."#(username):#(password)")
    done(nil, { username = username })
  else
    done()
))

basicAuth = passport.authenticate('basic', { session = false })

app.use '/api' @(req, res, next)
  if (req.user)
    next()
  else
    basicAuth(req, res, next)

app.post '/api/queries' @(req, res)
  db = app.get 'db'
  db.setQueries(req.body)!
  res.status(201).send({ status = 'success' })

app.get '/api/queries/first/graph' @(req, res)
  loadGraph(nil, req, res)

app.get '/api/queries/:id/graph' @(req, res)
  loadGraph(req.param 'id', req, res)

passport.use (new (LocalStrategy { usernameField = 'email' } @(email, password, done)
  if (users."#(email):#(password)")
    done(nil, { email = email })
  else
    done()
))

app.post '/login' (passport.authenticate 'local' {
  successRedirect = '/'
  failureRedirect = '/login'
  failureFlash = true
})

app.post '/signup' @(req, res)
  promise! @(success, failure)
    users."#(req.param 'email'):#(req.param 'password')" = true

    req.login { id = 4, email = req.param 'email' } @(err)
      if (err)
        failure(err)
      else
        success()

  res.redirect '/'

app.post '/logout' @(req, res)
  req.logout()
  res.redirect '/'

app.get '/' @(req, res)
  res.render 'index.html' { user = req.user }

loadGraph (queryId, req, res) =
  db = app.get 'db'
  graph = queryGraph()

  maxDepth = Math.min(10, req.param 'depth') @or 3

  startContext =
    if (req.param 'context')
      JSON.parse(req.param 'context')

  buildGraph!(db, graph, queryId, startContext = startContext, maxDepth = maxDepth)
  res.send (graph.toJSON())

app.use(express.static(__dirname + '/public'))

module.exports = app
