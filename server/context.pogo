module.exports = prototype {
  key() =
    if (self._key)
      self._key
    else
      self._key = "#(self.level):#(Object.keys(self.blocks).join ','):#(Object.keys(self.predicants).join ',')"
}
