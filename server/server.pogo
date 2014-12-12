app = require './app'
express = require 'express'
morgan = require 'morgan'

server = express()
server.use(morgan('combined'))
server.use(app)

port = process.env.PORT || 8000
server.listen(port, ^)!
console.log "http://localhost:#(port)/"
