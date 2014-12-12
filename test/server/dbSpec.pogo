redisDb = require '../../server/redisDb'

describe 'redisDb'
  describe 'setQueries()'
    it 'accepts an empty array'
      redisDb().setQueries([])!
