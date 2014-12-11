User = require './models/user'

exports.deleteAll! () =
  User.remove {} ^!

exports.authenticate! (email, password) =
  User.authenticate (email, password) ^!

exports.signUp! (email, password) =
  User.register (@new User({ email = email }), password) ^!
