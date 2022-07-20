BornPoint = Room:New({
  title = "出生点",
  desc = "这里是一片空地，周围站着很多刚注册的新手玩家。",
  exits = {
    east = "NewbiePlaza",
    west = "SmallRoad"
  }
})

NewbiePlaza = Room:New({
  title = "新手广场",
  desc = "光秃秃的黄土地上，有几棵小树。",
  exits = {
    west = "BornPoint"
  }
})

SmallRoad = Room:New({
  title = "小路",
  desc = "这条小路荒草蔓延。似乎是通往外界的唯一道路。",
  exits = {
    east = "BornPoint"
  }
})
