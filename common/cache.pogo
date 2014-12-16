module.exports () =
  cache = {}

  {
    cacheBy (key, block) =
      value = cache.(key)

      if (@not value)
        cache.(key) = block()
      else
        value

    onceBy (key, block) =
      value = cache.(key)

      if (@not value)
        cache.(key) = true
        block()
    
    clear() =
      cache := {}
  }
