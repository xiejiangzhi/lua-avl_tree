
```
local Tree = require 'avl_tree'

local lt_func = function(a, b) return a < b end
local eq_func = function(a, b) return a == b end
local t = Tree.new(lt_func, eq_func)

t:empty() -- true
t:add(123)
t:add(12)
t:add(100)
t:empty() -- false
t:size() -- 3

local dir = 1 or -1
t:iter(dir, function(v) end)
t:query(1, 20, dir, function(v) end)

t:peek('left' or 'right')
t:print()

t:pop('left') -- 12
t:pop('right') -- 123
t:del(123)

t:clear()
```