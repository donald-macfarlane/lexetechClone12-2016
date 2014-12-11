users = require '../../server/users.pogo'
expect = require '../expect'

describe 'users'

  authenticate () = users.authenticate 'dave@home.com' 'pa55word'
  signUp () = users.signUp 'dave@home.com' 'pa55word'

  context 'when the user does not exist'
    it 'fails to authenticate the user'
      expect(authenticate()).to.be.rejectedWith 'Invalid email/password'

  context 'when the user exists'
    beforeEach
      signUp()

    it 'authenticates the user'
      expect(authenticate()).to.be.fulfilled
