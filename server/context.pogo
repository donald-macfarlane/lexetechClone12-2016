module.exports = prototype {
  key() =
    if (self._key)
      self._key
    else
      self._key = "#(self.level):#(Object.keys(self.blocks).join ','):#(Object.keys(self.predicants).join ',')"

  pushBlockStack() =
    self.blockStack.unshift {
      coherenceIndex = self.coherenceIndex
      block = self.block
      blocks = self.blocks
    }

  popBlockStack() =
    b = self.blockStack.shift()
    self.coherenceIndex = b.coherenceIndex
    self.block = b.block
    self.blocks = b.blocks
}
