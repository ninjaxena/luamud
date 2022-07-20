function Combat(attacker, target)
  local normal_power = 2
  local double_power = normal_power*2
  local lease_power = normal_power/2

  local damage = normal_power

  local a_skill = attacker.skill
  local d_skill = target.skill
  if a_skill ~= nil then
    -- 有招攻无招
    if d_skill == nil then
      damage = double_power
    else
      --这种复杂判断其实应该用哈系表查询，但是if写法更容易表达内在含义
      --tiger>monkey>crane>tiger
      if a_skill == d_skill then
        damage = normal_power
      elseif a_skill == "tiger" then
        if d_skill == "monkey" then
          damage = double_power
        elseif d_skill == "crane" then
          damage = lease_power
        end
      elseif a_skill == "monkey" then
        if d_skill == "tiger" then
          damage = lease_power
        elseif d_skill == "crane" then
          damage = double_power
        end
      elseif a_skill == "crane" then
        if d_skill == "monkey" then
          damage = lease_power
        elseif d_skill == "tiger" then
          damage = double_power
        end
      end

    end
  end

  attack_msg = {
    "%s狠狠的向%s挥出一拳，正中鼻梁。",
    "%s对准%s的心窝飞起一脚，踹个正着。",
    "%s拼了老命的对准%s一头撞去，碰了个满怀。",
    "%s怪叫一声，对着%s的脑门就是一掌。"
  }

  hurt_msg = {
    "造成%s的伤害如同搔痒一般。\n",
    "造成%s一片擦伤。\n",
    "%s闷哼一声，晃了一下还是站住了。\n",
    "%s身上出现了一个深深的伤口，血流不止。\n",
    "一声巨响，%s被连人击飞。\n"
  }

  --处理战斗逻辑
  local amsg = attack_msg[math.random(1,#attack_msg)]
  local hmsg = hurt_msg[damage]

  if damage < 1 then hmsg = hurt_msg[1] end
  if damage > #hurt_msg then hmsg = hurt_msg[#hurt_msg] end
  target.hp = target.hp - damage
  attacker.environment.channel:Say(
    string.format(amsg,attacker.name, target.name), 
    attacker, target)
  attacker.environment.channel:Say(
    string.format(hmsg, target.name),
    attacker, target)

  if attacker.user_id ~= nil then
    attacker:Reply(string.format(amsg,"你",target.name))
    attacker:Reply(string.format(hmsg, target.name))
  end

  if target.user_id ~= nil then
    target:Reply(string.format(amsg, attacker.name, "你", damage))
    target:Reply(string.format(hmsg, "你"))
  end

  if target.hp<= 0 then
    attacker:Reply(string.format("%s已经奄奄一息，你终于停手了。", target.name))
    target:Reply("你不支倒地，奄奄一息。")
    attacker.environment.channel:Say(
      string.format("%s已经奄奄一息，%s终于停手了。", target.name, attacker.name), target, attacker)
  end
end
