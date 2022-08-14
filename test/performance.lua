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
  data[#data + 1] = math.floor(math.random(1000000))
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

local n = 0
local qn = #data / 100
test('query '..qn, function()
  for i = 1, qn do
    local v = data[i]
    ta:query(v / 3, v / 2, 1, function() n = n + 1 end)
  end
end)
print("query counter", n)

n = 0
local iter_n = #data / 1000
test('iter '..iter_n, function()
  for i = 1, iter_n do
    ta:iter(1, function() n = n + 1 end)
  end
end)
print("iter counter", n)

test('del '..#data, function()
  for i, v in ipairs(data) do
    ta:del(v)
  end
end)

print('total data', ta:size())