
```
local Tree = require 'avl_tree'

local lt_func = function(a, b) return a < b end
local eq_func = function(a, b) return a == b end
local t = Tree.new(lt_func, eq_func)

t:add(123)
t:add(12)

t:del(123)
t:iter(1, function(v) end)
t:query(1, 20, 1, function(v) end)
```