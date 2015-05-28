module.exports() =
  oldDivs = document.querySelectorAll 'body > div.test'
  if (oldDivs.length)
    [
      oldDiv <- oldDivs
      oldDiv.parentNode.removeChild(oldDiv)
    ]

  div = document.createElement('div')
  div.className = 'test'
  document.body.appendChild(div)

  div
