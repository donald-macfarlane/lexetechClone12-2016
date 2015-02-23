express = require 'express'
bodyParser = require 'body-parser'
passport = require 'passport'
flash = require 'connect-flash'
session = require 'cookie-session'
BasicStrategy = require 'passport-http'.BasicStrategy
api = require './api'
_ = require 'underscore'
logger = require 'winston'

users = require './users.pogo'
User = require './models/user'

redisDb = require './redisDb'
require './mongoDb'.connect()

(n) days = n * 60 * 60 * 24 * 1000

app = express()
app.use(bodyParser.json {limit = '1mb'})
app.use(session { name = 'session', secret = 'haha bolshevik', maxAge = 30 days, overwrite = true })
app.use(bodyParser.urlencoded { extended = true })
app.engine('html', require('ejs').renderFile)
app.set 'views' (__dirname + '/views')
app.set('logger', logger)

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
    user = users.signUp(req.params.email, req.param 'password')!
    req.login (user, ^)!
    res.redirect '/'
  catch (e)
    logger.error("could not sign up", e)
    req.flash('error', 'that email address is already used')
    res.redirect '/signup'

app.post '/logout' @(req, res)
  req.logout()
  res.redirect '/'

app.use(express.static(__dirname + '/generated'))
app.use(express.static(__dirname + '/public'))
app.use('/source', express.static(__dirname + '/../browser/style'))

page(req, js) = {
  script = js
  user = if (req.user)
    _.pick(req.user, 'email')

  flash = req.flash('error')
}

authoring (req, res) =
  res.render 'index.html' (page (req, '/authoring.js'))

app.get('/authoring/*', authoring)
app.get('/authoring', authoring)

app.get '*' @(req, res)
  res.render 'index.html' (page (req, '/app.js'))

module.exports = app
