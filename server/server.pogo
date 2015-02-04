app = require './app'
express = require 'express'
morgan = require 'morgan'
apiUsers = require './apiUsers.json'

server = express()
server.use(morgan('combined'))
server.use(app)
server.set('apiUsers', apiUsers)

port = process.env.PORT || 8000
server.listen(port, ^)!
console.log "http://localhost:#(port)/"
