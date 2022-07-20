---代表一个物理空间物体
--@param environment 所处环境
--@param content 内容
SpaceObject = {
  environment = nil, 
  content = {}, 

  New = function(self, value)
    return NewInstance(self, value)
  end,

  --查找本身包含的内容物
  --@param #table key 内容物的属性名,如果是nil则对比整个内容物体
  --@param #table value 要查找的属性值或者内容物本身
  --@param #function fun是找到后的处理函数，形式fun(pos, con_obj)
  --@return #table 返回fun()的返回值（仅限第一个返回值）数值，或者是找到的对象数组
  Search = function(self, key, value, fun)
    local result = {}
    for pos, con_obj in ipairs(self.content) do
      local compare_obj = con_obj
      if key ~= nil then
        compare_obj = con_obj[key]
      end
      if compare_obj == value then
        if fun == nil then
          table.insert(result,#result + 1,con_obj)
        else
          table.insert(result,#result + 1,(fun(pos, con_obj)))
        end
      end
    end
    return result
  end,

  Leave = function(self)
    local old_env = self.environment
    local fun = function(my_idx, my_obj)
      return table.remove(old_env.content, my_idx)
    end
    if old_env ~= nil then
      old_env:Search(nil, self, fun)
    end
  end,

  Put = function(self, env)
    --不能放到自己身上
    if self == env then return end
    self:Leave()
    self.environment = env
    table.insert(env.content, #(env.content) + 1, self)
  end,

  Dispose = function(self)
    --删除自己的内容物
    for pos, con in ipairs(self.content) do
      assert(con:Dispose())
    end
    
    --把自己从空间系统中删除
    self:Leave()
    
    self.content = nil
    self.environment = nil
  end
}

World = SpaceObject:New()  -- 所有物理空间存放的位置
World.channel = Channel:New() -- 构建一个世界频道
