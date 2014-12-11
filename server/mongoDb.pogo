mongoose = require 'mongoose'
mongoose.set('debug', true)

exports.connect()! =
  url = process.env.MONGOLAB_URI @or 'mongodb://localhost/lexeme'
  mongoose.connect (url) ^!

exports.disconnect()! =
  mongoose.disconnect() ^!
