express = require 'express'
bodyParser = require 'body-parser'
passport = require 'passport'
flash = require 'connect-flash'
session = require 'express-session'
BasicStrategy = require 'passport-http'.BasicStrategy
api = require './api'
_ = require 'underscore'

users = require './users.pogo'
User = require './models/user'

redisDb = require './redisDb'
require './mongoDb'.connect()

app = express()
app.use(bodyParser.json {limit = '1mb'})
app.use(session { name = 'session', secret = 'haha bolshevik', resave = false, saveUninitialized = false })
app.use(bodyParser.urlencoded { extended = true })
app.engine('html', require('ejs').renderFile)
app.set 'views' (__dirname + '/views')

app.use(passport.initialize())
app.use(passport.session())
app.use(flash())

app.set 'db' (redisDb())

passport.serializeUser(User.serializeUser())
passport.deserializeUser(User.deserializeUser())

passport.use (new (BasicStrategy @(username, password, done)
  if (app.get 'apiUsers'."#(username):#(password)")
    done(nil, { id = username, username = username })
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

app.use('/api', api)

app.post '/login' (passport.authenticate 'local' {
  successRedirect = '/'
  failureRedirect = '/login'
  failureFlash = true
})

app.post '/signup' @(req, res)
  try
    user = users.signUp(req.param 'email', req.param 'password')!
    req.login (user, ^)!
    res.redirect '/'
  catch (e)
    res.redirect '/signup'

app.post '/logout' @(req, res)
  req.logout()
  res.redirect '/'

app.use(express.static(__dirname + '/generated'))
app.use(express.static(__dirname + '/public'))
app.use('/source', express.static(__dirname + '/../browser/style'))

authoring (req, res) =
  res.render 'index.html' {
    script = '/authoring.js'
    user = if (req.user)
      _.pick(req.user, 'email')
  }

app.get('/authoring/*', authoring)
app.get('/authoring', authoring)

app.get '*' @(req, res)
  res.render 'index.html' {
    script = '/app.js'
    user = if (req.user)
      _.pick(req.user, 'email')
  }

module.exports = app
