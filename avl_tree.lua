local Node   = {}
Node.__index = Node

local new_node = function(a)
	return setmetatable({
    value   = a,
    height  = 0,
	}, Node)
end

local getHeight = function(node)
	return node and node.height or -1
end

local setHeight = function(node)
	node.height = math.max(getHeight(node.left), getHeight(node.right)) + 1
end

local getBalance = function(node)
	return getHeight(node.right) - getHeight(node.left)
end

-- left: rotate_node(node, -1)
-- right: rotate_node(node, 1)
local rotate_node = function(root, dir)
	local a, b
	if dir == 1 then
		a, b = 'right', 'left'
	else
		a, b = 'left', 'right'
	end
	local pivot = root[b]
	root[b] = pivot[a]
	pivot[a] = root
	setHeight(pivot)
	setHeight(root)
	return pivot
end

-- perform leaf check,height check,& rotation
-- return new_root, no_change
local updateSubtree = function(root)
	local h = root.height
	setHeight(root)
	local balance = getBalance(root)
	if balance > 1 then
		if getBalance(root.right) < 0 then
			root.right = rotate_node(root.right, 1)
		end
		root = rotate_node(root, -1)
	elseif balance < -1 then
		if getBalance(root.left) > 0 then
			root.left = rotate_node(root.left, -1)
		end
		root = rotate_node(root, 1)
	end

	return root, root.height == h
end

-- Insert given element, return it if added
-- return node, added, should_stop_check
function Node.add(self, a, cmp_fn)
	if not self then
		return true, new_node(a)
	end

	local cmp_v = cmp_fn(a, self.value)
	if cmp_v == 0 then
		self.value = a
		return false, self, true
	end

	local r, no_change
	if cmp_v < 0 then
		r, self.left, no_change  = Node.add(self.left, a, cmp_fn)
	else
		r, self.right, no_change  = Node.add(self.right, a, cmp_fn)
	end

	if no_change then
		return r, self, true
	else
		return r, updateSubtree(self)
	end
end

-- return value, new_node,
-- return nil
function Node.delete(self, a, cmp_fn)
	if not self then
		return nil, nil, true
	end

	local v = self.value
	local no_change
	local cmp_v = cmp_fn(a, v)
	if cmp_v == 0 then
		if not self.left then
			return v, self.right
		elseif not self.right then
			return v, self.left
		else
			local sNode = self.right

			if sNode.left then
				local min_node
				sNode.left, min_node = Node.delete_min_node(sNode.left)
				self.value = min_node.value
			else
				self.right = sNode.right
				self.value = sNode.value
			end

			return v, updateSubtree(self)
		end
	elseif cmp_v < 0 then
		v, self.left, no_change = Node.delete(self.left, a, cmp_fn)
	else
		v, self.right, no_change  = Node.delete(self.right, a, cmp_fn)
	end

	if no_change then
		return v, self, true
	else
		return v, updateSubtree(self)
	end
end

-- return new_node, deleted_node
function Node.delete_min_node(node)
	if node.left then
		local v
		node.left, v = Node.delete_min_node(node.left)
		return updateSubtree(node), v
	elseif node.right then
		return node.right, node
	else
		return nil, node
	end
end

-- side: left or right
function Node:pop(side)
	local v
	if not self[side] then
		return self.value,self.left or self.right
	else
		v,self[side] = Node.pop(self[side],side)
	end
	return v, updateSubtree(self)
end

function Node:peek(side)
	if not self[side] then
		return self.value
	else
		return Node.peek(self[side],side)
	end
end

-- Find given element and return it
function Node.get(self, a, cmp_fn)
	if self then
		local v = self.value
		local cmp_v = cmp_fn(a, v)
		if cmp_v == 0 then
			return v
		elseif cmp_v < 0 then
			return Node.get(self.left, a, cmp_fn)
		else
			return Node.get(self.right, a, cmp_fn)
		end
	end
end

-- tree traversal is in order by default (left,root,right)
function Node.iter(node, a, b, cb)
	if node then
		Node.iter(node[a], a, b, cb)
		cb(node.value)
		Node.iter(node[b], a, b, cb)
	end
end

function Node.query(node, skey, ekey, a, b, cb, cmp_fn)
	if node then
		local v = node.value
		local cmp_sv = cmp_fn(v, skey)
		if cmp_sv == 0 then
			Node.query(node[a], skey, ekey, a, b, cb, cmp_fn)
			cb(v)
			Node.query(node[b], skey, ekey, a, b, cb, cmp_fn)
		elseif cmp_sv < 0 then
			Node.query(node[b], skey, ekey, a, b, cb, cmp_fn)
		else
			local cmp_ev = cmp_fn(v, ekey)
			if cmp_ev <= 0 then
				Node.query(node[a], skey, ekey, a, b, cb, cmp_fn)
				cb(v)
				Node.query(node[b], skey, ekey, a, b, cb, cmp_fn)
			else
				Node.query(node[a], skey, ekey, a, b, cb, cmp_fn)
			end
		end
	end
end

Node.print = function(self, to_str_fn, depth)
	depth = depth or 1
	if self then
		Node.print(self.right, to_str_fn, depth + 1)
		local indent = string.rep("  ", depth)
		print(string.format("%s%s", indent, to_str_fn(self.value)))
		Node.print(self.left, to_str_fn, depth+1)
	end
end

----------------------------------------

local M = {} -- proxy table for tree
M.__index = M

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
  added, self.root = Node.add(self.root, a, self.cmp_fn)
	if added then
		self.total = self.total + 1
  	return a
	end
end

function M:get(a)
	if not self.root then
		return
	end
	return self.root:get(a, self.cmp_fn)
end

function M:del(a)
	if not self.root then
		return
	end

	local v
  v, self.root = self.root:delete(a, self.cmp_fn)
	if v then
		self.total = self.total - 1
		return v
	end
end

-- side: left or right
function M:pop(side)
  assert(side,'No side specified!')
  a, self.root = self.root:pop(side)
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
	return self.root:peek(dir)
end

function M:print(to_str_fn)
	if not self.root then
		return
	end

	print('------')
	self.root:print(to_str_fn or tostring)
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

	self.root:iter(a, b, cb)
end

function M:query(skey, ekey, dir, cb)
	local a, b
	if dir == 1 or not dir then
		a, b = 'left','right'
	elseif dir == -1 then
		a, b = 'right','left'
	else
		error("invalid iter dir "..tostring(dir))
	end

	self.root:query(skey, ekey, a, b, cb, self.cmp_fn)
end

return M