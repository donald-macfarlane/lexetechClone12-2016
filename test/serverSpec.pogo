httpism = require 'httpism'
app = require '../server/app'
expect = require 'chai'.expect
openDb = require '../server/db'

describe 'server'
  port = 12345
  api = httpism.api "http://localhost:#(port)"
  server = nil
  db = nil

  beforeEach
    server := app.listen (port)
    db := openDb()

  afterEach
    server.close()

  it 'should return graph at most 3 deep'
    expect(api.get! '/query/1/graph?depth=3'.body).to.eql {}
