mongoose = require 'mongoose'

passportPlugin = require 'passport-local-mongoose'
Schema = mongoose.Schema

User = @new Schema {}
User.plugin(passportPlugin, { usernameField = 'email' })

module.exports = mongoose.model('User', User)
