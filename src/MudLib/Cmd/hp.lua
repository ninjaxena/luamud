CommandList.hp = function(cmds)
  local output = "%s+-------------+\n| HP: %d/%d |\n+-------------+";
  Reply(string.format(output, this_player:ToStr(),this_player.hp, this_player.max_hp))
end