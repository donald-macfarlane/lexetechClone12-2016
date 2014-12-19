redisDb = require '../../server/redisDb'
expect = require '../expect'

describe 'redisDb'
  db = redisDb()

  beforeEach
    db.clear()!

  it 'creates blocks with auto-increment ids'
    expect(db.createBlock({ name = 'Block 1' })!).to.equal 1
    expect(db.createBlock({ name = 'Block 2' })!).to.equal 2
    expect(db.blockById(1)!).to.eql({
      id = 1
      name = 'Block 1'
    })