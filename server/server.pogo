app = require './app'
redisDb = require './redisDb'
app.set 'db' (redisDb())

port = process.env.NODE_PORT || 8000
app.listen(port)
console.log "http://localhost:#(port)/"
