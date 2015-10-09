mongoDb = require '../../server/mongoDb'
users = require '../../server/users'
expect = require '../expect'
startSmtpServer = require './smtpServer'
retry = require 'trytryagain'

httpism = require 'httpism'
app = require '../../server/app'

describe 'users'
  before
    mongoDb.connect()

  beforeEach
    users.deleteAll()!

  authenticate () = users.authenticate 'dave@home.com' 'pa55word'
  signUp () = users.signUp 'dave@home.com' 'pa55word'

  context 'when the user does not exist'
    it 'fails to authenticate the user'
      expect(authenticate()).to.be.rejectedWith 'Incorrect email'

  context 'when the user exists'
    beforeEach
      signUp()

    it 'authenticates the user'
      expect(authenticate()).to.be.fulfilled

  describe 'api'
    port = 12345
    api = httpism.api "http://user:password@localhost:#(port)"
    server = nil

    beforeEach
      app.set 'apiUsers' { "user:password" = {admin = true} }
      server := app.listen (port)

    afterEach
      server.close()

    it 'can add a user and list it'
      postedUser = api.post! '/api/users' {
        email = 'joe@example.com'
      }.body

      userList = api.get! '/api/users'.body
      user = api.get! (postedUser.href).body

      expect(userList).to.eql [
        postedUser
      ]
      expect(user).to.eql(postedUser)

    context 'when there are users'
      beforeEach
        api.post! '/api/users' {
          email = 'joe@example.com'
          password = 'joey'
        }.body
        api.post! '/api/users' {
          email = 'bob@example.com'
          password = 'bobby'
        }.body

    it "can't create two users with the same email address"
      api.post! '/api/users' {
        firstName = 'Joe'
        familyName = 'Fox'
        email = 'joe@example.com'
      }.body

      response = api.post! '/api/users' {
        firstName = 'Joe'
        familyName = 'Rabbit'
        email = 'joe@example.com'
      } (exceptions: false)
      
      expect(response.statusCode).to.equal 400
      expect(response.body.alreadyExists).to.be.true

      userList = api.get! '/api/users'.body
      expect(userList.length).to.equal 1
      joe = userList.0

      expect(joe.familyName).to.equal 'Fox'

    it "can't update a user to have the same email address as another"
      api.post! '/api/users' {
        firstName = 'Joe'
        familyName = 'Fox'
        email = 'joe@example.com'
      }.body

      joey = api.post! '/api/users' {
        firstName = 'Joey'
        familyName = 'Rabbit'
        email = 'joey@example.com'
      } (exceptions: false).body

      joey.email = 'joe@example.com'
      response = api.put!(joey.href, joey, exceptions = false)
      
      expect(response.statusCode).to.equal 400
      expect(response.body.alreadyExists).to.be.true

      userList = api.get! '/api/users'.body
      expect([u <- userList, u.email]).to.eql [
        'joe@example.com'
        'joey@example.com'
      ]

    it 'lists only max users'
      [
        n <- [1..5]
        api.post! '/api/users' {
          email = "joe#(n)@example.com"
        }
      ]

      userList = api.get!('/api/users', querystring = {max = 3}).body
      expect(userList.length).to.eql 3

    it 'can add a user and authenticate it'
      postedUser = api.post! '/api/users' {
        email = 'joe@example.com'
        password = 'blahblah'
      }.body

      users.authenticate! 'joe@example.com' 'blahblah'

    describe 'passwords'
      it 'can add a user without a password, set the password and authenticate'
        postedUser = api.post! '/api/users' {
          email = 'joe@example.com'
        }.body

        user = api.get!(postedUser.href).body
        expect(user.hasPassword).to.be.false

        token = api.post!(postedUser.resetPasswordTokenHref).body.token
        api.post!(user.resetPasswordHref, { password = 'mypassword1', token = token})

        user := api.get!(postedUser.href).body
        expect(user.hasPassword).to.be.true

        users.authenticate! (user.email, 'mypassword1')

      it 'reuses existing token if there is one'
        postedUser = api.post! '/api/users' {
          email = 'joe@example.com'
        }.body

        originalToken = api.post!(postedUser.resetPasswordTokenHref).body.token
        latestToken = api.post!(postedUser.resetPasswordTokenHref).body.token

        expect(latestToken).to.equal(originalToken)

      it 'cannot reset password with wrong token'
        postedUser = api.post! '/api/users' {
          email = 'joe@example.com'
        }.body

        user = api.get!(postedUser.href).body
        expect(user.hasPassword).to.be.false

        token = api.post!(postedUser.resetPasswordTokenHref).body.token
        response = api.post!(user.resetPasswordHref, { password = 'mypassword1', token = token + 'x'}, exceptions = false)
        expect(response.statusCode).to.equal 400

        user := api.get!(postedUser.href).body
        expect(user.hasPassword).to.be.false

        expect(users.authenticate(user.email, 'mypassword1')).to.be.rejectedWith('Authentication not possible')!

      it 'cannot get a reset token if user has password'
        postedUser = api.post! '/api/users' {
          email = 'joe@example.com'
          password = 'blah'
        }.body

        user = api.get!(postedUser.href).body
        expect(user.hasPassword).to.be.true

        response = api.post!(postedUser.resetPasswordTokenHref, {}, exceptions = false)
        expect(response.statusCode).to.equal 400
        expect(response.body.token).to.be.undefined

      it 'cannot reset password with no token'
        postedUser = api.post! '/api/users' {
          email = 'joe@example.com'
        }.body

        user = api.get!(postedUser.href).body
        expect(user.hasPassword).to.be.false

        response = api.post!(user.resetPasswordHref, { password = 'mypassword1' }, exceptions = false)
        expect(response.statusCode).to.equal 400

        user := api.get!(postedUser.href).body
        expect(user.hasPassword).to.be.false

        expect(users.authenticate(user.email, 'mypassword1')).to.be.rejectedWith('Authentication not possible')!

      it 'cannot reset a password twice'
        user = api.post! '/api/users' {
          email = 'joe@example.com'
        }.body

        token = api.post!(user.resetPasswordTokenHref).body.token
        api.post!(user.resetPasswordHref, { password = 'mypassword1', token = token})
        response = api.post!(user.resetPasswordHref, { password = 'myotherpassword', token = token}, exceptions = false)
        expect(response.statusCode).to.equal 400

      context 'forgetting passwords'
        smtpServer = nil

        beforeEach
          smtpServer := startSmtpServer!()
          app.set 'smtp url' (smtpServer.url)
          app.set 'system email' 'system@lexenotes.com'

        afterEach
          smtpServer.stop()

        it 'sends a reset password email'
          user = api.post! '/api/users' {
            firstName = 'Joe'
            email = 'joe@example.com'
            password = 'joes secret'
          }.body

          api.post!('/forgotpassword', { email = 'joe@example.com' }, form = true)

          email = retry!
            expect(smtpServer.emails.length).to.equal 1
            smtpServer.emails.0

          expect(email.to).to.eql [{address = 'joe@example.com', name = ''}]
          expect(email.from).to.eql [{address = 'system@lexenotes.com', name = ''}]
          linkRegex = r/http:\/\/localhost:12345\/resetpassword\/(\w*)/
          expect(email.text).to.match (linkRegex)
          expect(email.text).to.contain 'Joe'
          expect(email.html).to.match (linkRegex)
          expect(email.html).to.contain 'Joe'

          token = linkRegex.exec(email.text).1
          api.post!('/resetpassword', { password = 'newpassword', token = token }, form = true)
          users.authenticate! 'joe@example.com' 'newpassword'

    context 'given an existing user'
      joe = nil
      jane = nil

      beforeEach
        joe := api.post! '/api/users' {
          email = 'joe@example.com'
          password = 'password1'
        }.body
        jane := api.post! '/api/users' {
          email = 'jane@example.com'
          password = 'password1'
        }.body

      it 'can update an existing user'
        api.put! (joe.href) {
          email = 'jack@example.com'
          password = 'password1'
        }

        user = api.get! (joe.href).body

        expect(user.email).to.eql 'jack@example.com'

      it 'can delete a user'
        userList = api.get! '/api/users'.body

        expect [u <- userList, u.email].to.eql [
          'jane@example.com'
          'joe@example.com'
        ]

        response = api.delete! (joe.href)
        expect(response.statusCode).to.equal 204

        userList := api.get! '/api/users'.body
        expect [u <- userList, u.email].to.eql [
          'jane@example.com'
        ]

    describe 'search'
      joe = nil
      bob = nil
      jane = nil

      beforeEach =>
        self.timeout 5000

        joe := api.post! '/api/users' {
          firstName = 'Joe'
          familyName = 'Heart'
          email = 'joe@example.com'
          password = 'password1'
        }.body

        bob := api.post! '/api/users' {
          firstName = 'Bob'
          familyName = 'Spade'
          email = 'bob@example.com'
          password = 'password1'
        }.body

        jane := api.post! '/api/users' {
          firstName = 'Jane'
          familyName = 'Diamond'
          email = 'jane@example.com'
          password = 'password1'
        }.body
      
      it 'can find just one person'
        results = api.get! '/api/users/search?q=jane'.body

        expect(results).to.eql [
          jane
        ]
      
      it 'can find several people'
        results = api.get! '/api/users/search?q=example'.body

        expect(results).to.eql [
          joe
          bob
          jane
        ]

    describe 'authorisation'
      beforeEach
        app.set 'apiUsers' { "user:password" = { admin = false } }


      it 'refuses access to users without admin role'
        response = api.get!('/api/users', exceptions = false)
        expect(response.statusCode).to.equal 403
