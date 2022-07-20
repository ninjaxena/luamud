CommandList.skill = function(cmds)
  local skill_name = cmds[2]
  if skill_name == nil and this_player.skill == nil then
    Reply("你摆了一个王八拳的姿势，然而并没有什么卵用。")
    return
  end

  if skill_name == "tiger" then
    this_player.skill = "tiger"
    Reply("你收拳挺胸，摆了一个猛虎式。")
    this_player:Say(this_player.name .. "身形一晃，摆出了一个猛虎式。")
  elseif skill_name == "monkey" then
    this_player.skill = "monkey"
    Reply("你缩腰弓背，放了一个灵猴式的架子。")
    this_player:Say(this_player.name .. "身形一晃，摆出了一个灵猴式。")
  elseif skill_name == "crane" then
    this_player.skill = "crane"
    Reply("你伸臂展拳，正是一招白鹤晾翅。。")
    this_player:Say(this_player.name .. "身形一晃，摆出了一个白鹤式。")
  else
    if skill_name == nil then
      this_player.skill = nil
      Reply("你收招吐气，回复了平时的姿势。")
      this_player:Say(this_player.name .. "回复了平时的姿势。")
    else
      Reply("你想使用什么招数？(猛虎式：tiger 白鹤式：crane 灵猴式：monkey)")
    end
    return
  end

end