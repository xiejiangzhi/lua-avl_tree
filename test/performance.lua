local Tree = require 'avl_tree'

local test = function(name, fn)
  local s = os.clock()
  fn()
  local t = os.clock()
  local cost = (t - s) * 1000
  print(string.format('%s cost %.2fms', name, cost))
end

local times = 100000
local sizes = { 10000, 50000, 100000 }
for _, size in ipairs(sizes) do
  local data = {}
  for i = 1, size do
    data[#data + 1] = i
  end
  for i = 1, size do
    local n = math.random(size)
    data[i], data[n] = data[n], data[i]
  end

  local name = times..' in '..size
  print('======== '..name..'===========')

  local ta = Tree.new()
  Tree.reset_stat()
  test('insert '..name, function()
    for i, v in ipairs(data) do
      ta:add(v)
    end
  end)
  ta:print_stat()
  Tree.reset_stat()

  test('get '..name, function()
    for i = 1, times do
      local n = (i - 1) % #data + 1
      ta:get(data[n])
    end
  end)

  local n = 0
  local qn = 500
  test('query '..qn, function()
    for i = 1, qn do
      local v = data[i]
      ta:query(v / 3, v / 2, 1, function() n = n + 1 end)
    end
  end)
  print("query counter", n)

  n = 0
  local iter_n = 100
  test('iter '..iter_n, function()
    for i = 1, iter_n do
      ta:iter(1, function() n = n + 1 end)
    end
  end)
  print("iter counter", n)

  test('del '..name, function()
    for i, v in ipairs(data) do
      ta:del(v)
    end
  end)
  ta:print_stat()
  Tree.reset_stat()
end