users = require './users.json'

exports.authenticate (email, password, done) =
  if (users."#(email):#(password)")
    done()
  else
    done(@new Error("Invalid email/password"))

exports.signUp (email, password, done) =
  users."#(email):#(password)" = true
  done()
