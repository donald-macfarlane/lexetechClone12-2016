expect = require 'chai'.expect
enumerateRange = require '../../tools/enumerateRange'

describe 'enumerateRange'
  it 'enumerates numbers separated by commas'
    expect(enumerateRange '1,2,4,10').to.eql [n <- [1,2,4,10], String(n)]

  it 'enumerates numbers separated by commas, and ranges'
    expect(enumerateRange '1,2,4,10-20').to.eql [n <- [1,2,4,10..20], String(n)]
