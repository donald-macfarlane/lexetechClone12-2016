users = require './users.json'

exports.authenticate! (email, password) =
  if (users."#(email):#(password)")
    true
  else
    @throw @new Error("Invalid email/password")

exports.signUp! (email, password) =
  users."#(email):#(password)" = true
