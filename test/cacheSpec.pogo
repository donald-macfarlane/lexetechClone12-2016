expect = require 'chai'.expect
cache = require '../common/cache'

describe 'cache'
  it 'should only calculate values once per key'
    computed = 0
    c = cache()

    firstValue = c.cacheBy '1'
      ++computed
      'a'

    expect(firstValue).to.eql 'a'

    secondValue = c.cacheBy '1'
      ++computed
      'b'

    expect(firstValue).to.eql 'a'

    expect(computed).to.eql 1

  it 'should return different values per key'
    c = cache()
    
    c.cacheBy 'a'
      'a'

    c.cacheBy 'b'
      'b'

    expect(c.cacheBy 'a' @{1}).to.eql 'a'
    expect(c.cacheBy 'b' @{1}).to.eql 'b'

  it 'should only do work once'
    computed = 0
    c = cache()
    
    c.onceBy 'a'
      ++computed

    c.onceBy 'a'
      ++computed

    expect(computed).to.eql 1

  it 'should only do work once, even in recursive situations'
    computed = 0
    c = cache()
    
    c.onceBy 'a'
      ++computed

      c.onceBy 'a'
        ++computed

    expect(computed).to.eql 1
