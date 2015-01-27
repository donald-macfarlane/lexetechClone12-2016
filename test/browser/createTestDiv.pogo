module.exports() =
  oldDiv = document.querySelector 'body > div.test'
  if (oldDiv)
    oldDiv.parentNode.removeChild(oldDiv)

  div = document.createElement('div')
  div.className = 'test'
  document.body.appendChild(div)

  div
