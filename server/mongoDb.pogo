mongoose = require 'mongoose'
mongoose.set('debug', true)

exports.connect ()! =
  mongoose.connect 'mongodb://localhost/lexeme' ^!
