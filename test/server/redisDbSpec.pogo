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

  it 'iterates all blocks in alphabetical order'
    db.createBlock({ name = 'Z' })!
    db.createBlock({ name = 'A' })!
    db.createBlock({ name = 'B' })!
    expect(db.listBlocks()!).to.eql [
      { id = 2, name = 'A' }
      { id = 3, name = 'B' }
      { id = 1, name = 'Z' }
    ]

  it 'updates blocks'
    id = db.createBlock({ name = 'Block X' })!
    db.updateBlock(id, { name = 'Block Y' })!
    expect(db.listBlocks()!).to.eql [
      { id = 1, name = 'Block Y' }
    ]
