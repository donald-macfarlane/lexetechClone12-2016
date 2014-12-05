app = require './app'
redisDb = require './redisDb'
app.set 'db' (redisDb())

module.exports = app
