mongoose = require 'mongoose'
mongoose.set('debug', process.env.MONGO_DEBUG == 'true')

connected = false

module.exports.connect() =
  if (@not connected)
    url = process.env.MONGOLAB_URI @or 'mongodb://localhost/lexeme'
    mongoose.connect (url)
    connected := true
