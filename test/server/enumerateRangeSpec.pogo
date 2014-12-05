expect = require 'chai'.expect
enumerateRange = require '../../tools/enumerateRange'

describe 'enumerateRange'
  it 'enumerates numbers separated by commas'
    expect(enumerateRange '1,2,4,10').to.eql [1,2,4,10]

  it 'enumerates numbers separated by commas, and ranges'
    expect(enumerateRange '1,2,4,10-20').to.eql [1,2,4,10..20]
