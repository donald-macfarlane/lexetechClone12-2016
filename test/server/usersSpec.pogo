mongoDb = require '../../server/mongoDb'
users = require '../../server/users'
expect = require '../expect'

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
      app.set 'apiUsers' { "user:password" = true }
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

    context 'given an existing user'
      postedUser = nil

      beforeEach
        postedUser := api.post! '/api/users' {
          email = 'joe@example.com'
        }.body

      it 'can update an existing user'
        api.put! (postedUser.href) {
          email = 'jack@example.com'
        }

        user = api.get! (postedUser.href).body

        expect(user.email).to.eql 'jack@example.com'

    describe 'search'
      beforeEach
        api.post! '/api/users' {
          email = 'joe@example.com'
        }.body

        api.post! '/api/users' {
          email = 'bob@example.com'
        }.body

        api.post! '/api/users' {
          email = 'jane@example.com'
        }.body
      
      it 'can find just one person'
        results = api.get! '/api/users/search?q=jane'.body

        expect(results).to.eql {
          results = [
            { title = 'jane@example.com' }
          ]
        }
      
      it 'can find several people'
        results = api.get! '/api/users/search?q=example'.body

        expect(results).to.eql {
          results = [
            { title = 'joe@example.com' }
            { title = 'bob@example.com' }
            { title = 'jane@example.com' }
          ]
        }
