local M = {} -- proxy table for tree
M.__index = M

local Stat = {
	update = 0,
	rotate = 0,
}

local QueryKeyRule = {
	lr = {
		cmp_0 = {
			b_sk = true, a_sk = nil,
		},
		cmp_1_1 = {
			b_sk = true, b_ek = nil,
			a_sk = nil, a_ek = true,
		},
		cmp_10 = {
			b_ek = nil, a_ek = true
		},
	},

	rl = {
		cmp_0 = {
			b_sk = nil, a_sk = true,
		},
		cmp_1_1 = {
			b_sk = nil, b_ek = true,
			a_sk = true, a_ek = nil,
		},
		cmp_10 = {
			b_ek = true, a_ek = nil
		}
	}
}

local NewNode = function(a)
	return {
    value   = a,
    height  = 0,
	}
end

local DefaultCmpFn = function(a, b)
	if a < b then
		return -1
	elseif a > b then
		return 1
	else
		return 0
	end
end


function M.new(cmp_fn)
  return setmetatable({
    root = nil,
		total = 0,
    cmp_fn = cmp_fn or DefaultCmpFn,
  }, M)
end

function M:add(a)
	if not a then
		return
	end
	local added
  added, self.root = M._add(self.root, a, self.cmp_fn)
	if added then
		self.total = self.total + 1
  	return a
	end
end

function M:get(a)
	if not self.root then
		return
	end
	return M._get(self.root, a, self.cmp_fn)
end

function M:del(a)
	if not self.root then
		return
	end

	local v
  v, self.root = M._delete(self.root, a, self.cmp_fn)
	if v then
		self.total = self.total - 1
		return v
	end
end

-- side: left or right
function M:pop(side)
  assert(side,'No side specified!')
	if not self.root then
		return
	end
  a, self.root = M._pop(self.root, side)
	if a then
		self.total = self.total - 1
	end
  return a
end

function M:size()
  return self.total
end

function M:empty()
	return self.total == 0
end

function M:clear()
	self.root = nil
	self.total = 0
end

function M:peek(dir)
	if not self.root then
		return
	end
	return M._peek(self.root, dir)
end

function M:print(to_str_fn)
	if not self.root then
		return
	end

	print('---------')
	M._print(self.root, to_str_fn or tostring)
end

-- dir 1 or -1
function M:iter(dir, cb)
	local a, b
	if dir == 1 or not dir then
		a, b = 'left', 'right'
	elseif dir == -1 then
		a, b = 'right', 'left'
	else
		error("invalid iter dir "..tostring(dir))
	end

	M._iter(self.root, a, b, cb)
end

-- skey: start key, if nil, start from first
-- ekey: end key, if nil, end to last
function M:query(skey, ekey, dir, cb)
	local before_side, after_side, q_rule
	if dir == 1 or not dir then
		before_side, after_side = 'left', 'right'
		q_rule = QueryKeyRule.lr
	elseif dir == -1 then
		before_side, after_side = 'right', 'left'
		q_rule = QueryKeyRule.rl
	else
		error("invalid iter dir "..tostring(dir))
	end

	M._query(self.root, skey, ekey, before_side, after_side, cb, self.cmp_fn, q_rule)
end

function M.print_stat(tree)
	local str = {}
	if tree then
		str[#str + 1] = 'size: '..tree:size()
		str[#str + 1] = 'height: '..(tree.root and tree.root.height or 0)
	end
  for k, v in pairs(Stat) do
    str[#str + 1] = k..': '..v
  end
  print("Stat", table.concat(str, ', '))
end

function M.reset_stat()
	for k, v in pairs(Stat) do
		Stat[k] = 0
	end
end

--------------------------------------------

local setHeight = function(node)
	local lh = node.left and node.left.height or -1
	local rh = node.right and node.right.height or -1
	node.height = math.max(lh, rh) + 1
	return rh - lh
end

local getBalance = function(node)
	local lh = node.left and node.left.height or -1
	local rh = node.right and node.right.height or -1
	return rh - lh
end

-- left rotate: rotate_node(node, 'right', 'left')
-- right rotate: rotate_node(node, 'left', 'right')
local rotateNode = function(root, pivot_side, opt_side)
	Stat.rotate = Stat.rotate + 1
	local pivot = root[pivot_side]
	root[pivot_side] = pivot[opt_side]
	pivot[opt_side] = root
	setHeight(root)
	setHeight(pivot)
	return pivot
end

-- perform leaf check, height check,& rotation
-- return new_root, no_change(true/false)
local updateSubtree = function(root)
	Stat.update = Stat.update + 1
	local h = root.height
	local balance = setHeight(root)

	if balance > 1 then
		if getBalance(root.right) < 0 then
			root.right = rotateNode(root.right, 'left', 'right')
		end
		root = rotateNode(root, 'right', 'left')
	elseif balance < -1 then
		if getBalance(root.left) > 0 then
			root.left = rotateNode(root.left, 'right', 'left')
		end
		root = rotateNode(root, 'left', 'right')
	end

	return root, root.height == h
end

-- return added, node, _current_tree_no_change
function M._add(node, a, cmp_fn)
	if not node then
		return true, NewNode(a)
	end

	local cmp_v = cmp_fn(a, node.value)
	if cmp_v == 0 then
		node.value = a
		return false, node, true
	end

	local r, no_change
	if cmp_v < 0 then
		r, node.left, no_change  = M._add(node.left, a, cmp_fn)
	else
		r, node.right, no_change  = M._add(node.right, a, cmp_fn)
	end

	if no_change then
		return r, node, true
	else
		return r, updateSubtree(node)
	end
end

-- return value, new_node, _current_tree_no_change
-- return nil
function M._delete(node, a, cmp_fn)
	if not node then
		return nil, nil, true
	end

	local v = node.value
	local no_change
	local cmp_v = cmp_fn(a, v)
	if cmp_v == 0 then
		if not node.left then
			return v, node.right
		elseif not node.right then
			return v, node.left
		else
			local r_node = node.right

			if r_node.left then
				local min_node
				r_node.left, min_node = M._delete_min_node(r_node.left)
				node.value = min_node.value
			else
				node.right = r_node.right
				node.value = r_node.value
			end

			return v, updateSubtree(node)
		end
	elseif cmp_v < 0 then
		v, node.left, no_change = M._delete(node.left, a, cmp_fn)
	else
		v, node.right, no_change  = M._delete(node.right, a, cmp_fn)
	end

	if no_change then
		return v, node, true
	else
		return v, updateSubtree(node)
	end
end

-- return new_node, deleted_node
function M._delete_min_node(node)
	if node.left then
		local v
		node.left, v = M._delete_min_node(node.left)
		return updateSubtree(node), v
	elseif node.right then
		return node.right, node
	else
		return nil, node
	end
end

-- side: left or right
function M._pop(node, side)
	local v
	if not node[side] then
		return node.value, node.left or node.right
	else
		v, node[side] = M._pop(node[side], side)
	end
	return v, updateSubtree(node)
end

function M._peek(node, side)
	if not node[side] then
		return node.value
	else
		return M._peek(node[side], side)
	end
end

-- Find given element and return it
function M._get(node, a, cmp_fn)
	if node then
		local v = node.value
		local cmp_v = cmp_fn(a, v)
		if cmp_v == 0 then
			return v
		elseif cmp_v < 0 then
			return M._get(node.left, a, cmp_fn)
		else
			return M._get(node.right, a, cmp_fn)
		end
	end
end

function M._iter(node, before_side, after_side, cb)
	if node then
		if M._iter(node[before_side], before_side, after_side, cb) == false then
			return false
		end
		if cb(node.value) == false then
			return false
		end
		if M._iter(node[after_side], before_side, after_side, cb) == false then
			return false
		end
	end
	return true
end



function M._query(node, skey, ekey, before_side, after_side, cb, cmp_fn, q_rule)
	if not node then
		return
	end

	if skey == nil and ekey == nil then
		M._iter(node, before_side, after_side, cb)
		return
	end

	local v = node.value
	local cmp_sv = skey and cmp_fn(v, skey) or 1
	if cmp_sv == 0 then
		local rule = q_rule.cmp_0
		M._query(node[before_side], rule.b_sk and skey, ekey, before_side, after_side, cb, cmp_fn, q_rule)
		cb(v)
		M._query(node[after_side], rule.a_sk and skey, ekey, before_side, after_side, cb, cmp_fn, q_rule)
	elseif cmp_sv < 0 then
		M._query(node.right, skey, ekey, before_side, after_side, cb, cmp_fn, q_rule)
	else
		local cmp_ev = ekey and cmp_fn(v, ekey) or -1
		if cmp_ev < 0 then
			local rule = q_rule.cmp_1_1
			M._query(
				node[before_side], rule.b_sk and skey, rule.b_ek and ekey, before_side, after_side, cb, cmp_fn, q_rule
			)
			cb(v)
			M._query(
				node[after_side], rule.a_sk and skey, rule.a_ek and ekey, before_side, after_side, cb, cmp_fn, q_rule
			)
		elseif cmp_ev == 0 then
			-- ignore left ekey
			local rule = q_rule.cmp_10
			M._query(node[before_side], skey, rule.b_ek and ekey, before_side, after_side, cb, cmp_fn, q_rule)
			cb(v)
			M._query(node[after_side], skey, rule.a_ek and ekey, before_side, after_side, cb, cmp_fn, q_rule)
		else
			M._query(node.left, skey, ekey, before_side, after_side, cb, cmp_fn, q_rule)
		end
	end
end

M._print = function(node, to_str_fn, depth)
	depth = depth or 1
	if node then
		M._print(node.right, to_str_fn, depth + 1)
		local indent = string.rep("  ", depth)
		print(string.format("%s%s(%i)", indent, to_str_fn(node.value), node.height))
		M._print(node.left, to_str_fn, depth+1)
	end
end

return M