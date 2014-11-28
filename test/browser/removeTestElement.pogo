module.exports() =
  testDiv = document.querySelector 'body > div.test'
  if (testDiv)
    testDiv.parent.removeChild(testDiv)
