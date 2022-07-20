function basicSerialize (o)
  if type(o) == "number" then
    return tostring(o)
  else -- assume it is a string
    return string.format("%q", o)
  end
end

function save (name, value, saved)
  local value_type = type(value)
  if value_type == "function" then
    return
  end
  
  saved = saved or {} -- initial value
  io.write(name, " = ")
  if value_type == "number" or value_type == "string" then
    io.write(basicSerialize(value), "\n")
  elseif value_type == "table" then
    if saved[value] then -- value already saved?
      -- use its previous name
      io.write(saved[value], "\n")
    else
      saved[value] = name -- save name for next time
      io.write("{}\n") -- create a new table
      for k,v in pairs(value) do -- save its fields
        local fieldname = string.format("%s[%s]", name,
        basicSerialize(k))
        save(fieldname, v, saved)
      end
    end
  else
      error("cannot save a " .. type(value) .. ": " .. name)
  end
end

function CopyTable(src, dest)
  if type(src) ~= "table" then 
    return src
  end
  dest = dest or {}
  for k,v in pairs(src) do
    --filted some member of metatable like "__index"...
    if string.find(k,"_") ~= 1
    then
      dest[CopyTable(k)] = CopyTable(v)
    end
  end
  return dest
end

function NewInstance(class_obj, value_object, super_class_obj)
  local instance = {}

  --Process super class
  local proto_obj = {}
  if super_class_obj ~= nil then 
    proto_obj = super_class_obj:New() 
  end
  setmetatable(instance, proto_obj)
  proto_obj.__index = proto_obj

  --Process class instance
  CopyTable(class_obj, instance)
  if value_object ~= nil then
    CopyTable(value_object, instance)
  end
  
  return instance
end

