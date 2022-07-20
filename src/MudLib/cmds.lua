-- All the commands defined here, then register it
local greeting_fun = function(user_id)
  local greeting_msg =
    [[
    
      欢迎光临《我的游戏》！
      当前在线%d人。
      由LuaMudOS v0.1开发。
      
请输入的用户名：]];
  local online_number = 0
  for k,v in pairs(SessionPool) do
    online_number = online_number + 1
  end
  Reply(string.format(greeting_msg, online_number), true)
  return true;
end
CommandSystem.accept = greeting_fun

login_progress = {}

local any_fun = function(user_id, cmds)
  local user_name = nil
  local password = nil


  local function UnknowCmd(user_id, cmds)
    Reply("不知道您想做什么？")
    Reply(PROMPT, true)
    return true
  end

  local function FindOnlineUser(user_name)
    for k,v in pairs(SessionPool) do
      if v.id == user_name then
        return v
      end
    end
  end

  local function Login(login_user)
    -- 踢掉之前在线的用户
    local now_player = FindOnlineUser(login_user.user_name)
    if now_player ~= nil then
      Send(now_player.user_id, "你的帐号在另外一个地方登录了。")
      CommandSystem:ProcessCommand(now_player.user_id, "bye")
    end

    now_player = Player:New(user_id, login_user)
    SessionPool[user_id] = now_player
    login_progress[user_id] = UnknowCmd
    World.channel:Say(now_player.name .. "进入了这个世界！")
    World.channel:Join(user_id, now_player)
    Reply("登录成功！你可以输入help来获得命令帮助。")

    -- 进入上次下线的场景
    local last_room = login_user.cur_room
    if last_room ~= nil and _G[last_room] ~= nil then
      now_player:Enter(_G[last_room])
    else
      now_player:Enter(BornPoint)
    end
    CommandSystem:ProcessCommand(now_player.user_id, "look")
  end

  local function EnterPassword(user_id, cmds)
    password = cmds[1]
    if password then
      -- 读取存档文件
      local login_user,err = UserData.Load(user_name, password)
      if login_user == nil then
        --验证失败
        print(user_name, err);
        Reply("错误的用户名或密码，请重新输入用户名：", true)
        login_progress[user_id] = EnterUserName
        return true
      end

      Login(login_user)
      return true
    else
      Reply("空密码，请重新输入：", true)
    end
    return true
  end

  local new_password = nil;
  local function CreateNewUser(user_id, cmds)
    if new_password == nil then
      new_password = cmds[1]
      login_progress[user_id] = CreateNewUser
      Reply("请再次输入密码：", true)
      return true
    elseif new_password == cmds[1] then
      local new_user = UserData.Create(user_name,new_password)
      Reply(string.format("用户%s创建成功！", user_name))
      Login(new_user)
      return true
    else
      new_password = nil
      Reply("两次密码不一致，请重新输入密码：", true)
    end

  end

  local function EnterUserName()
    user_name = cmds[1]
    if user_name then
      if UserData.IsExits(user_name) then
        login_progress[user_id] = EnterPassword
        Reply("请输入密码：", true)
      else
        login_progress[user_id] = CreateNewUser
        Reply("新建用户，请输入密码：", true)
      end
    else
      login_progress[user_id] = EnterUserName
    end
    return true
  end

  -- 从状态函数表login_progeress{}里面获得行为做操作
  local progress_fun = login_progress[user_id];
  if progress_fun then
    local ret = progress_fun(user_id, cmds)
    return ret
  else
    return EnterUserName();
  end
end
CommandSystem.any_cmd = any_fun

-- All command register in here --
CommandList = {}

--TODO 增加help命令的详细内容
CommandList.help = function(cmds)
  local target = cmds[2]
  if target == nil then
    for k,v in pairs(CommandList) do
      Reply(k,v)
    end
    return
  end
end

CommandList.bye = function(cmds)
  local user_id = this_player.user_id
  print("Closing client #"..user_id)
  Reply("再见")
  TcpServer:CloseClient(user_id)
  SessionPool[user_id] = nil
  World.channel[user_id] = nil
  this_player:Dispose()
  return true;
end

CommandList.look = function(cmds)
  local target = nil
  local target_id = cmds[2] -- cmds[1]是指令本身，cmds[2]才是参数
  if target_id == nil then
    target = this_player.environment
  else
    local targets = this_player.environment:Search('id', target_id)
    if #targets == 0 then
      Reply(string.format("没有%s这个东西", target_id))
      return
    else
      target = targets[1]
    end
  end
  Reply(target:ToStr())
end

CommandList.go = function(cmds)
  local direction = cmds[2]
  if direction == nil then
    Reply("你要去什么地方？")
    return
  end

  local target = this_player.environment.exits[direction]
  if target == nil or _G[target] == nil then
    Reply("往"..direction.."方向的路走不通。")
    return
  end

  if this_player:Enter(_G[target]) == true then
    this_player.user_data.cur_room = target --记录当前房间用来重新上线用
    CommandList.look({"look"})
  end
end

CommandList.say = function(cmds)
  table.remove(cmds, 1)
  if #cmds == 0 then
    Reply("你在喃喃自语，没人能听见。")
    return
  end
  local msg = table.concat(cmds, " ")
  this_player:Say(string.format("%s说道：\"%s\"",this_player.name,msg))
  Reply(string.format("你说道：\"%s\"", msg))
end

CommandList.dofile = function(cmds)
  table.remove(cmds,1)
  if #cmds == 0 then
    Reply("你凌空一指，啥都没发生。")
    return
  end
  
  local msg = table.concat(cmds, " ")
  local load_rs  = SaveDoFile(MUD_LIB_PATH..msg)
  Reply("你凌空一指，天空中显示出几个大字：\n"..load_rs)
end

CommandList.loadcmd = function(cmds)
  if cmds[2] == nil then
    Reply("你要重载什么命令？")
    return
  end
  
  local ret_msg = ReloadCmds(CommandList, cmds[2])
  Reply("重载结果：\n"..ret_msg)
end

function SaveDoFile(file)
  local fun, err = loadfile(file)
  local ret = err
  if fun~= nil then
    local is_succ, result = pcall(fun)
    ret = tostring(result)
  end
  return ret
end

function ReloadCmds(self, cmd)
  --Search Cmd path
  local ret_msg = {}
  if cmd == nil then
    local handle = io.popen("ls "..MUD_LIB_PATH.."Cmd/*.lua")
    local result = handle:read("*a")
    handle:close()
    local cmd_files = {}
    string.gsub(result,'[^\n \t]+', function(w) table.insert(cmd_files,w) end)
    print("正在装载命令文件: ")
    for i, v in pairs(cmd_files) do
      print(v)
      table.insert(ret_msg,SaveDoFile(v))
    end
  else
    table.insert(ret_msg,SaveDoFile(MUD_LIB_PATH.."Cmd/"..cmd..".lua"))
  end

  for cmd,fun in pairs(self) do
    CommandSystem:RegisterCommand(cmd, fun)
  end
  
  return table.concat(ret_msg,"\n")
end

-- Register all the commands in CommandList to system --
ReloadCmds(CommandList)








