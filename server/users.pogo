User = require './models/user'
authenticate = User.authenticate()

exports.deleteAll! () =
  User.remove {} ^!

exports.authenticate! (email, password) =
  promise @(success, failure)
    authenticate(email, password) @(err, result, otherStuff)
      if (result)
        success (result)
      else
        failure (otherStuff)

exports.signUp! (email, password) =
  user = User.register (@new User({ email = email }), password) ^!
  user.id = user._id
  delete (user._id)
  user
