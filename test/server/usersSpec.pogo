mongoDb = require '../../server/mongoDb'
users = require '../../server/users'
expect = require '../expect'

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
