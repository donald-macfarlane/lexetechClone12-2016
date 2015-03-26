var mongoose = require("mongoose");
var passportPlugin = require("passport-local-mongoose");

var Schema = mongoose.Schema;
var User = new Schema({});

User.plugin(passportPlugin, {
    usernameField: "email"
});

module.exports = mongoose.model("User", User);
