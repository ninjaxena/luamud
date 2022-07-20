Room = {
  title = "虚空",
  desc = "这里一片白茫茫",
  exits = {}, --east="xxx", west="yyy", ...
  channel = World.channel
}

function Room:New(value)
  local ret = NewInstance(self, value, SpaceObject)
  ret:Put(World)
  ret.channel =  Channel:New()
  return ret
end

function Room:ToStr()
  local output = [[
--%s--  
%s
这里的出口：
%s
这里有：
%s]]

  local str_builder = {}
  for dir, exit in pairs(self.exits) do
    if _G[exit] ~= nil and _G[exit].title ~= nil then
      table.insert(str_builder, dir)
      table.insert(str_builder, " 通往 ")
      table.insert(str_builder, _G[exit].title)
      table.insert(str_builder, "\n")
    end
  end
  local exits_str = table.concat(str_builder, "")
  
  str_builder = {}
  for index, content in pairs(self.content) do
    if content.name ~= nil then
      table.insert(str_builder, content.name)
      table.insert(str_builder, " (")
      table.insert(str_builder, content.id)
      table.insert(str_builder, ")")
      table.insert(str_builder, "\n")
    end
  end
  local content_str = table.concat(str_builder, "")
  
  return string.format(output, self.title, self.desc, exits_str, content_str)
end