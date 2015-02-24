var Promise = require("bluebird");

var express = require("express");
var bodyParser = require("body-parser");
var passport = require("passport");
var flash = require("connect-flash");
var session = require("cookie-session");
var BasicStrategy = require("passport-http").BasicStrategy;
var api = require("./api");
var _ = require("underscore");
var logger = require("winston");
var users = require("./users");
var User = require("./models/user");
var redisDb = require("./redisDb");
var promisify = require('./promisify');

require("./mongoDb").connect();

function days(n) {
  return n * 60 * 60 * 24 * 1e3;
};

var app = express();
app.use(bodyParser.json({limit: "1mb"}));

app.use(session({
  name: "session",
  secret: "haha bolshevik",
  maxAge: days(30),
  overwrite: true
}));

app.use(bodyParser.urlencoded({extended: true}));
app.engine("html", require("ejs").renderFile);
app.set("views", __dirname + "/views");
app.set("logger", logger);
app.use(passport.initialize());
app.use(passport.session());
app.use(flash());
app.set("db", redisDb());

passport.serializeUser(User.serializeUser());
passport.deserializeUser(User.deserializeUser());

passport.use(new BasicStrategy(function(username, password, done) {
  if (app.get("apiUsers")[username + ":" + password]) {
    done(undefined, {
      id: username,
      username: username
    });
  } else {
    done();
  }
}));

passport.use(User.createStrategy());

var basicAuth = passport.authenticate("basic", {
  session: false
});

app.use("/api", function(req, res, next) {
  if (req.user) {
    next();
  } else {
    basicAuth(req, res, next);
  }
});

app.use("/api", api);

app.post("/login", passport.authenticate("local", {
  successRedirect: "/",
  failureRedirect: "/login",
  failureFlash: true
}));

app.post("/signup", function(req, res) {
  var user;

  users.signUp(req.body.email, req.body.password).then(function(user) {
    return promisify(function (cb) {
      req.login(user, cb);
    });
  }).then(function() {
    res.redirect("/");
  }, function(e) {
    logger.error("could not sign up", e);
    req.flash("error", "that email address is already used");
    res.redirect("/signup");
  });
});

app.post("/logout", function(req, res) {
  req.logout();
  res.redirect("/");
});

app.use(express.static(__dirname + "/generated"));
app.use(express.static(__dirname + "/public"));
app.use("/source", express.static(__dirname + "/../browser/style"));

function page(req, js) {
  return {
    script: js,
    user: function() {
      if (req.user) {
        return _.pick(req.user, "email");
      }
    }(),
    flash: req.flash("error")
  };
};

function authoring(req, res) {
  res.render("index.html", page(req, "/authoring.js"));
};

app.get("/authoring/*", authoring);
app.get("/authoring", authoring);

app.get("*", function(req, res) {
  res.render("index.html", page(req, "/app.js"));
});

module.exports = app;
