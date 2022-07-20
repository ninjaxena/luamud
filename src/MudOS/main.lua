--[[
LuaMudOS v0.1 by wadehan@tencent.com
It's a simple MUD server for study LUA
]]--

--- A TCP server can be set a recieving handler.
TcpServer = {
  num2client = {},
  client2num = {},
  clients = {},
  conn_count = 0
}

function TcpServer.Start(self, bind_addr, handler)

  setmetatable(self.client2num, {__mode="k"});
  local socket = require("socket")
  bind_addr.host = bind_addr.host or "0.0.0.0"
  bind_addr.port = bind_addr.port or "7777"
  local server = assert(socket.bind(bind_addr.host, bind_addr.port, 1024))
  server:settimeout(0)
  table.insert(self.clients, server)
  print("Bind the TCP server at " .. bind_addr.host .. ":" .. bind_addr.port)

  while true do
    -- Processing network events
    local recvt, sendt, status = socket.select(self.clients, nil ,1)
    if #recvt > 0 then
      for idx, client in ipairs(recvt) do
        if client == server then

          -- Processing accept new connection --
          local conn = server:accept()
          if conn then
            self.conn_count = self.conn_count + 1 --maybe it should be looped to 0 when it is too large?
            local conn_id = tostring(self.conn_count)
            self.num2client[conn_id] = conn
            self.client2num[conn] = conn_id
            table.insert(self.clients, conn)
            print(string.format("A client(#%s) successfully connect! online: %d", conn_id, #(self.client2num)))
            handler(conn_id)  -- The nil recv_data represented that accept
          end
        else

          -- Processing recieving package
          local receive, receive_status = client:receive('*l')
          local conn_num = self.client2num[client]
          if receive_status ~= 'closed' then
            if receive then
              handler(conn_num,receive);
            end
          else
            handler(conn_num, "bye") --Call the close script on upper level
            print(string.format("Client #%d disconnect!", conn_num))
          end
        end
      end
    end

    -- Processing heartbeat timer
    HeartOfWorld:Tick()

  end
end

function TcpServer.SendTo(self, client_id, message, no_ret)
  local client = self.num2client[client_id];
  if client == nil then
    return false, "Can not find the client connection: " .. client_id
  end
  local output = message
  if no_ret ~= true then
    output = output..'\n'
  end
  return client:send(output);
end

function TcpServer.CloseClient(self, client_id)
  local client = self.num2client[client_id];
  if client == nil then
    return
  end
  self.num2client[client_id] = nil

  for i, c in pairs(self.clients) do
    if c == client then
      table.remove(self.clients, i)
      client:close();
      collectgarbage();
      return
    end
  end
end

-- Sessions pool --
SessionPool = {}
PROMPT = "> "
--- A command system which you can set a command to it.
CommandSystem = {
  cmd_tab = {},

  accept = function(user_id)
    TcpServer:SendTo(user_id,"Welcome.")
    return true
  end,

  any_cmd = function(user_id, cmds)
    TcpServer:SendTo(user_id, "Invalid command.")
    return true
  end,

  RegisterCommand = function(self, command_name, command_function)
    command_name = string.lower(command_name)
    self.cmd_tab[command_name] = command_function
  end ,

  ProcessCommand = function(self, user_id, command_line)

    -- Shortcut function replying and sending message to client by closure
    function Reply(message, no_ret)
      TcpServer:SendTo(user_id,message, no_ret)
    end

    function Send(target_user_id, message, no_ret)
      TcpServer:SendTo(target_user_id,message, no_ret)
    end

    if command_line == nil then
      return self.accept(user_id)
    end


    local cmds = {}
    string.gsub(command_line, "[^ ]+", function(w) table.insert(cmds, w) end)
    local cmd = cmds[1]
    if cmd == nil then
      Reply(PROMPT, true)
      return true
    end
    cmd = string.lower(cmd)
    local cmd_fun = self.cmd_tab[cmd]

    -- If client have not logined, use any_cmd() process all the input
    this_player = SessionPool[user_id] -- Shotcut: this_player
    if (this_player == nil) or (cmd_fun == nil)
    then
      if cmds[1] ~= nil and cmds[1] == "bye" then
        TcpServer:CloseClient(user_id)
        return
      end
      return self.any_cmd(user_id, cmds)
    else
      local ret = cmd_fun(cmds)
      Reply(PROMPT, true)
      return ret
    end
  end
}

--- Save/Load user data
require("MudOS/serialize")
local md5 = require("MudOS/md5")
user_data_save_path="/tmp/"
UserData = {
  user_name = nil,
  pass_token = nil,

  New = function(self, value)
    value = value or {}
    setmetatable(value, self)
    self.__index = self
    CopyTable(self, value)
    return value
  end,

  Create = function (user_name, password)
    --Check if the file exist
    local save_path = user_data_save_path..user_name..".lua";
    local file, err = io.open(save_path, "r")
    if err == nil then
      io.close(file)
      return nil, "The save file "..save_path.."had existed!"
    end

    local user_data = nil
    user_data = UserData:New()
    user_data.user_name = user_name
    user_data.pass_token = md5.sumhexa(password)

    file, err = io.open(save_path, "w")
    if err ~= nil  then
      return nil, err
    end
    io.output(file)
    print("Saving file: ".. save_path)
    save('player_'..user_name, user_data)
    io.close(file)

    return user_data
  end,

  IsExits = function(user_name)
    local save_path = user_data_save_path..user_name..".lua";
    local file,err = io.open(save_path,"r")
    if file ~= nil then
      io.close(file)
    end
    if err ~= nil then
      return false
    end
    return true
  end,

  Load = function (user_name, password)
    -- check file exits
    local save_path = user_data_save_path..user_name..".lua";
    local file,err = io.open(save_path,"r")
    if err ~= nil then
      return nil, err
    end
    io.close(file)

    -- load file
    local save_obj_name = 'player_'..user_name
    local user_data = _G[save_obj_name]
    if user_data == nil then
      dofile(save_path)
      local load_obj = _G[save_obj_name]
      user_data = UserData:New(load_obj)
    end


    -- check password
    local check_token = md5.sumhexa(password)
    if check_token ~= user_data.pass_token then
      return nil, "Invalid password!"
    end
    return user_data
  end,

  Save = function(self)
    local save_path = user_data_save_path.. self.user_name ..".lua";
    local file,err = io.open(save_path,"w");
    if(err ~= nil) then
      return false, err
    end
    local save_obj_name = 'player_' .. self.user_name
    io.output(file)
    save(save_obj_name, self)
    io.close(file)
    return true
  end,

  Dispose = function(self)
    local save_obj_name = 'player_'.. self.user_name
    _G[save_obj_name] = nil
  end
}

-- Init the base server and start it
local handler = function(client_id, recv_data)
  local result, err_msg
    = CommandSystem:ProcessCommand(client_id, recv_data)
  if(result == false) then
    TcpServer:SendTo(client_id, err_msg)
  end
end

--- Broadcast system
Channel = {
  members = {}
}

function Channel:New(value)
  return NewInstance(self, value)
end

function Channel:Join(user_id, member)
  if self.members[user_id] == nil then
    self.members[user_id] = member
  end
end

function Channel:Leave(user_id)
  if self.members[user_id] ~= nil then
    self.members[user_id] = nil
  end
end

function Channel:Say(message, ...)
  for user_id, member in pairs(self.members) do
    local ignore = false
    for i, sender in ipairs{...} do
      if member == sender then
        ignore = true
      end
    end
    
    if ignore == false then
      TcpServer:SendTo(user_id, message)
    end
  end
end

--- Timer System
HeartOfWorld = {
  rate = 1, -- beat times per second
  members = {}, -- all hearts in here
  last_beat_time = 0
}

function HeartOfWorld:Add(heart)
  local next_idx = #(self.members) + 1
  self.members[next_idx] = heart
  return next_idx
end

function HeartOfWorld:Del(heart_or_idx)
  local idx = heart_or_idx
  if type(heart_or_idx) ~= 'number' then
    for i, obj in pairs(self.members) do
      if obj == heart_or_idx then
        idx = i
      end
    end
  end
  self.members[idx] = nil
end

function HeartOfWorld:Tick()
  local now = os.time()
  local interval = now - self.last_beat_time
  if interval > self.rate then
    self.last_beat_time = now
    -- Make hearts beating
    for idx, obj in pairs(self.members) do
      if obj.HeartBeat ~= nil and type(obj.HeartBeat) == 'function' then
        obj:HeartBeat(now)
      end
    end
  end
end

-- Load GameLib level code
print("Start to load GameLib ...")
require("MudLib/index")

-- Start up network procedule
if(arg[1] == "dev_mode") then
  print("Ready to dev now.")
else
  print("Starting TCP server ...")
  TcpServer:Start({}, handler)
end
