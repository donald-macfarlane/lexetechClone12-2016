module.exports (s) =
  [
    range <- s.split ','
    rangeMatch = r/(\d+)-(\d+)/.exec(range)
    n <- if (rangeMatch)
      [parseInt(rangeMatch.1)..parseInt(rangeMatch.2)]
    else
      [parseInt(range)]

    n
  ]
