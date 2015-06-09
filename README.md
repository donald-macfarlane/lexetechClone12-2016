lexeme
======

# start

Make sure you're running redis and mongodb.

```bash
gulp
```

Then go to [http://localhost:4000/](http://localhost:4000/)

# test

To run all tests:

```bash
qo test
```

Or you can run individual tests for server `qo mocha`, browser `qo karma` and full stack `qo cucumber`.

# get production data

```bash
qo lexicon --env prod > lexicon.json
qo put-lexicon lexicon.json
```

# Semantic UI

You can customise the semantic ui by editing the files in `semantic/src/site` in order to compile the changes you need to run the semantic ui gulp file, do this by running `gulp --gulpfile=semantic/gulpfile.js` in the root directory of this repo.

documentation
-------------

How lexemes are navigated by level and coherence order:
https://docs.google.com/a/featurist.co.uk/drawings/d/1ANk_qYeaZtKDKxkmb_2cLN0BDuT-GA6ZT8R8DcKI948/edit?usp=sharing
