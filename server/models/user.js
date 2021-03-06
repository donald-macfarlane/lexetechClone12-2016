var mongoose = require("mongoose");
var passportPlugin = require("passport-local-mongoose");

var Schema = mongoose.Schema;
var User = new Schema({
  username: String,
  firstName: String,
  familyName: String,
  author: Boolean,
  admin: Boolean,
  officePhoneNumber: String,
  cellPhoneNumber: String,
  address: String,
  created: Date,
  resetPasswordToken: String
});

User.plugin(passportPlugin, {
  usernameField: "email"
});

User.index({firstName: 'text', familyName: 'text', email: 'text'});

module.exports = mongoose.model("User", User);
