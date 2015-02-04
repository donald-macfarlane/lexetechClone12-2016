module.exports = moveItemIn (list) from (from) to (to) =
  list.splice(to, 0, list.splice(from, 1).0)
