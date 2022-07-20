 MUD_LIB_PATH = MUD_LIB_PATH or "/home/wade/workspace/StudyLua/src/MudLib/"

print("正在构建空间系统 ...")
require("MudLib/space")

print("正在构建房间系统 ...")
require("MudLib/room")
require("MudLib/map")

print("正在构建角色系统 ...")
require("MudLib/char")

-- TODO 构建“道具系统”

print("正在构建战斗系统 ...")
require("MudLib/combat")

print("正在构建命令系统 ...")
dofile(MUD_LIB_PATH .. "cmds.lua")