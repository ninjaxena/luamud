CommandList.kill = function(cmds)
  local target = nil
  local target_id = cmds[2] -- cmds[1]是指令本身，cmds[2]才是参数
  if target_id == nil then
    Reply("你怒气冲冲的瞪着空气，不知道要攻击谁。")
    return
  else
    if target_id == this_player.id then
      Reply("你狠狠用左脚踢了一下自己的右脚，发现这个行为很傻，于是就停止了。")
      return
    end
    local targets = this_player.environment:Search('id', target_id)
    if #targets == 0 then
      Reply(string.format("没有%s这个东西", target_id))
      return
    elseif targets[1].hp ~= nil and targets[1].hp > 0 then
      target = targets[1]
    else
      Reply("你不能攻击一个死物。")
      return
    end
  end

  if target ~= nil then
    table.insert(this_player.fright_list, target)
    Reply(string.format("你对着%s大喝一声：“納命来！”",target.name))

    --反击
    table.insert(target.fright_list, this_player)
    Reply(string.format("%s对你一瞪眼，一跺脚，狠狠道：“竟敢在太岁头上动土？”", target.name))
    if target.user_id ~= nil then
      target:Reply(string.format("%s向你发起了攻击！", this_player.name))
    end
  end
end