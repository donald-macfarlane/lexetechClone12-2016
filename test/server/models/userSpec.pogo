mongoDb = require '../../../server/mongoDb'
User = require '../../../server/models/user'
expect = require '../../expect'

describe 'User'
  auth = User.authenticate()

  before
    mongoDb.connect()!
    User.remove {} ^!

  after
    mongoDb.disconnect()!

  context 'before registering'
    it 'cannot be authenticated' @(done)
      auth('josh@work.com', 'whatever') @(err, result, otherStuff)
        expect(result).to.be.false
        done()

  context 'after registering'
    it 'can be authenticated' @(done)
      User.register ({email = 'josh@work.com'}, 'whatever')
        auth('josh@work.com', 'whatever') @(err, result, otherStuff)
          expect(result.email).to.equal('josh@work.com')
          done()
