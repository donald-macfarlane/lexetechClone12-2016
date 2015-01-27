var queriesInHierarchyByLevel = require('../../browser/routes/authoring/blocks/queriesInHierarchyByLevel')
var expect = require('chai').expect;

describe('queriesInHierarchyByLevel', function () {
  it('returns queries in hierarchy of level', function () {
    function query(number, level, queries) {
      return {
        name: 'query ' + number,
        level: level,
        queries: queries
      };
    }

    var queries = [
      query(1, 1),
      query(2, 1),
      query(3, 2),
      query(4, 2),
      query(5, 3),
      query(6, 3),
      query(7, 1),
      query(8, 2),
      query(9, 1)
    ];

    expect(queriesInHierarchyByLevel(queries)).to.eql([
      query(1, 1),
      query(2, 1, [
        query(3, 2),
        query(4, 2, [
          query(5, 3),
          query(6, 3)
        ]),
      ]),
      query(7, 1, [
        query(8, 2),
      ]),
      query(9, 1)
    ]);
  });
});
