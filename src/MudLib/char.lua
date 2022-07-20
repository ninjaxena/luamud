Charactor = {
  id = "somebody",
  name = "某人",
  desc = "一个普通的人",
  heart_id = 0,
  hp = 100, -- 角色的HP
  max_hp = 100 --角色的最大HP
}

function Charactor:New(value)
  local instance = NewInstance(self, value, SpaceObject)
  instance.heart_id = HeartOfWorld:Add(instance)  
  return instance
end

function Charactor:Say(msg)
  self.environment.channel:Say(msg)
end

function Charactor:Enter(room)
  local in_msg = "%s走了进来"
  local out_msg = "%s往%s的方向走了出去"
  local old_loc = self.environment
  if old_loc ~= nil then
    self:Say(string.format(out_msg, self.name, room.title))
  end

  self:Put(room)
  self:Say(string.format(in_msg, self.name))
  
end

function Charactor:Desc()
  return self.desc
end

function Charactor:ToStr()
  local desc_str = "-%s(%s)-\n%s\n"
  return string.format(desc_str, self.name, self.id, self:Desc())
end

function Charactor:HeartBeat(now)
  if #(self.fright_list) == 0 then
    return
  end
  
  if self.hp <= 0 then
    self.fright_list = {}
    return
  end
  
  --找到本地的敌人
  local enemies = {}
  local enemies_id = {}
  for i, enemy in ipairs(self.fright_list) do
    if enemy.hp <= 0 then
      table.remove(self.fright_list, i)
    elseif self.environment == enemy.environment then
        table.insert(enemies, enemy)
    end
  end 
  
  --发起攻击
  if #enemies > 0 then
    local random = math.random(1, #enemies)
    local target = enemies[random]
    Combat(self, target)
  end
end

function Charactor:Dispose()
  HeartOfWorld:Del(self.heart_id)
  SpaceObject.Dispose(self)
end


--构建“玩家类"
Player = {
  user_data = {},  --存储的玩家数据
  user_id = -1, --通信用的ID
  fright_list = {} --战斗对象列表
}

function Player:New(user_id, user_data)
  local instance = NewInstance(self, nil, Charactor)
  
  if user_id ~= nil and user_data ~= nil then
    instance.user_data = user_data
    instance.user_id = user_id

    instance.id = user_data.user_name
    instance.name = user_data.user_name --TODO 注册的时候建立一个“昵称”用来显示，区别登录时用的英文Id
    
    -- 替换掉父类注册的对象（原型对象）
    HeartOfWorld.members[instance.heart_id] = instance
  end
  return instance
end

function Player:HeartBeat(now)
  Charactor.HeartBeat(self,now)
end

function Player:Reply(message)
  TcpServer:SendTo(self.user_id,message)
end

function Player:Enter(room)
  if self.hp <= 0 then
    self:Reply("你奄奄一息，倒地不起，不能移动分毫。")
    return false
  end
  
  Charactor.Enter(self, room)
  room.channel:Join(self.user_id, self)
  return true  
end

function Player:Desc()
  local msg = "一个普通的玩家。\n%s" 
  --根据游戏内容设置玩家的详细描述
  local hp_msg = "一动不动，看起来没有生命气息。"
  local hp_rate = self.hp/self.max_hp
  if hp_rate == 1 then
    hp_msg = "看起来非常健康。"
  elseif hp_rate > 0.8 then
    hp_msg = "身上有几处淤青，可以忽略。"
  elseif hp_rate > 0.6 then
    hp_msg = "手脚有点小擦伤，但无大碍。"
  elseif hp_rate > 0.4 then
    hp_msg = "身上有个明细的伤口，正在流行，不过不危及生命。"
  elseif hp_rate > 0.2 then
    hp_msg = "伤痕累累，行动吃力。"
  elseif hp_rate > 0 then
    hp_msg = "就如风中残烛，眼看就要支持不下去了。"
  end
  return string.format(msg, hp_msg)
end

function Player:Say(msg)
  self.environment.channel:Say(msg, self)
end

function Player:Dispose()
  self:Say(self.name .. "下线了")
  self.user_data:Save()
  self.user_data:Dispose()
  self.environment.channel:Leave(self.user_id)
  Charactor.Dispose(self)
end