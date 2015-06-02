var queriesInHierarchyByLevel = require('../../browser/routes/authoring/blocks/queriesInHierarchyByLevel')
var expect = require('chai').expect;

describe('queriesInHierarchyByLevel', function () {
  function query(number, level, queries) {
    return {
      name: 'query ' + number,
      level: level
    };
  }

  function hquery(number, level, queries) {
    var q = {
      query: {
        name: 'query ' + number,
        level: level,
      }
    };

    if (queries) {
      q.queries = queries;
    }

    return q;
  }

  function hqueries(qs) {
    return {
      queries: qs
    };
  }

  it('returns queries in hierarchy of level', function () {
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
      hquery(1, 1),
      hquery(2, 1, [
        hquery(3, 2),
        hquery(4, 2, [
          hquery(5, 3),
          hquery(6, 3)
        ]),
      ]),
      hquery(7, 1, [
        hquery(8, 2),
      ]),
      hquery(9, 1)
    ]);
  });

  it('simple', function () {
    var queries = [
      query(1, 1),
      query(2, 2),
      query(3, 3)
    ];

    expect(queriesInHierarchyByLevel(queries)).to.eql([
      hquery(1, 1, [
        hquery(2, 2, [
          hquery(3, 3)
        ])
      ])
    ]);
  });

  it('simple up down', function () {
    var queries = [
      query(1, 1),
      query(2, 2),
      query(3, 3),
      query(4, 2),
      query(5, 1)
    ];

    expect(queriesInHierarchyByLevel(queries)).to.eql([
      hquery(1, 1, [
        hquery(2, 2, [
          hquery(3, 3)
        ]),
        hquery(4, 2)
      ]),
      hquery(5, 1)
    ]);
  });

  it('returns normal hierarchy when first query is higher than rest', function () {
    var queries = [
      query(1, 2),
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
      hqueries([
        hquery(1, 2)
      ]),
      hquery(2, 1, [
        hquery(3, 2),
        hquery(4, 2, [
          hquery(5, 3),
          hquery(6, 3)
        ]),
      ]),
      hquery(7, 1, [
        hquery(8, 2),
      ]),
      hquery(9, 1)
    ]);
  });

  it('hierarchy that starts by jumping', function () {
    var queries = [
      query(1, 1),
      query(2, 3),
      query(3, 2),
      query(4, 3)
    ];

    expect(queriesInHierarchyByLevel(queries)).to.eql([
      hquery(1, 1, [
        hqueries([
          hquery(2, 3)
        ]),
        hquery(3, 2, [
          hquery(4, 3)
        ])
      ]),
    ]);
  });
});
