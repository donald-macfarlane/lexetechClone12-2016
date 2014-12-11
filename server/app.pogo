express = require 'express'
morgan = require 'morgan'
bodyParser = require 'body-parser'
passport = require 'passport'
session = require 'express-session'
BasicStrategy = require 'passport-http'.BasicStrategy

apiUsers = require './apiUsers.json'
users = require './users.pogo'
User = require './models/user'

app = express()
app.use(morgan('combined'))
app.use(bodyParser.json {limit = '1mb'})
app.use(session { name = 'session', secret = 'haha bolshevik', resave = false, saveUninitialized = false })
app.use(bodyParser.urlencoded { extended = true })
app.engine('html', require('ejs').renderFile)
app.set 'views' (__dirname + '/views')

app.use(passport.initialize())
app.use(passport.session())

passport.serializeUser(User.serializeUser())
passport.deserializeUser(User.deserializeUser())

buildGraph = require './buildGraph'
queryGraph = require './queryGraph'

passport.use (new (BasicStrategy @(username, password, done)
  if (apiUsers."#(username):#(password)")
    done(nil, { username = username })
  else
    done()
))

passport.use(User.createStrategy())

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

app.post '/login' (passport.authenticate 'local' {
  successRedirect = '/'
  failureRedirect = '/login'
  failureFlash = true
})

app.post '/signup' @(req, res)
  promise! @(success, failure)
    users.signUp(req.param 'email', req.param 'password').then
      req.login { id = 4, email = req.param 'email' } @(err)
        if (err)
          failure(err)
        else
          success()
    (failure)

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
app.use('/source', express.static(__dirname + '/../browser/style'))

module.exports = app
