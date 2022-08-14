local Tree = require 'avl_tree'

local test = function(name, fn)
  local s = os.clock()
  fn()
  local t = os.clock()
  local cost = (t - s) * 1000
  print(string.format('%s cost %.2fms', name, cost))
end

local data = {}
for i = 1, 100000 do
  data[#data + 1] = math.floor(math.random(10000000))
end

local ta = Tree.new()
test('insert '..#data, function()
  for i, v in ipairs(data) do
    ta:add(v)
  end
end)

print('tree total', ta:size())
local counter = {}
local t = 0
for i, v in ipairs(data) do
  if not counter[v] then
    counter[v] = 1
    t = t + 1
  end
end
print('real uniq count', t)

test('get '..#data, function()
  for i, v in ipairs(data) do
    ta:get(v)
  end
end)

test('del '..#data, function()
  for i, v in ipairs(data) do
    ta:del(v)
  end
end)

print('total data', ta:size())