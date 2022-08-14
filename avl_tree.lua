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
	node.height = math.max(getHeight(node.left),getHeight(node.right))+1
end

local getBalance = function(node)
	return getHeight(node.right) - getHeight(node.left)
end

local rotate_left = function(root)
	local pivot = root.right
	root.right = pivot.left
	pivot.left = root
	setHeight(pivot)
	setHeight(root)
	return pivot
end

local rotate_right = function(root)
	local pivot = root.left
	root.left = pivot.right
	pivot.right = root
	setHeight(pivot)
	setHeight(root)
	return pivot
end

-- perform leaf check,height check,& rotation
local updateSubtree = function(root)
	setHeight(root)
	local balance = getBalance(root)
	if balance > 1 then
		if getBalance(root.right) < 0 then
			root.right = rotate_right(root.right)
		end
		root = rotate_left(root)
	elseif balance < -1 then
		if getBalance(root.left) > 0 then
			root.left = rotate_left(root.left)
		end
		root = rotate_right(root)
	end

	return root
end

-- Insert given element, return it if added
-- return node, added
function Node.add(self, a, lt_fn, eq_fn)
	if not self then
		return new_node(a), true
	else
		if eq_fn(a, self.value) then
			self.value = a
			return self, false
		end

		local r
		if lt_fn(a, self.value) then
			self.left, r   = Node.add(self.left, a, lt_fn, eq_fn)
		else
			self.right, r  = Node.add(self.right, a, lt_fn, eq_fn)
		end
		return updateSubtree(self), r
	end
end

-- return new_node, value
-- return nil
function Node.delete(self, a, lt_fn, eq_fn)
	if not self then
		return
	end

	local v = self.value
	if eq_fn(a, v) then
		if not self.left then
			return self.right, v
		elseif not self.right then
			return self.left, v
		else
			local sNode = self.right

			local node
			if sNode.left then
				local min_node
				sNode.left, min_node = Node.delete_min_node(sNode.left)
				self.value = min_node.value
			else
				self.right = sNode.right
				self.value = sNode.value
			end

			return updateSubtree(self), v
		end
	else
		if lt_fn(a, v) then
			self.left, v = Node.delete(self.left, a, lt_fn, eq_fn)
		else
			self.right, v  = Node.delete(self.right, a, lt_fn, eq_fn)
		end
	end
	return updateSubtree(self), v
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
	return v,updateSubtree(self)
end

function Node:peek(side)
	if not self[side] then
		return self.value
	else
		return Node.peek(self[side],side)
	end
end

-- Find given element and return it
function Node.get(self, a, lt_fn, eq_fn)
	if self then
		local v = self.value
		if eq_fn(a, v) then
			return v
		elseif lt_fn(a, v) then
			return Node.get(self.left, a, lt_fn, eq_fn)
		else
			return Node.get(self.right, a, lt_fn, eq_fn)
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

function Node.query(node, skey, ekey, a, b, cb, lt_fn, eq_fn)
	if node then
		local v = node.value
		if eq_fn(v, skey) then
			Node.query(node[a], skey, ekey, a, b, cb, lt_fn, eq_fn)
			cb(v)
			Node.query(node[b], skey, ekey, a, b, cb, lt_fn, eq_fn)
		elseif lt_fn(v, skey) then
			Node.query(node[b], skey, ekey, a, b, cb, lt_fn, eq_fn)
		else
			if lt_fn(v, ekey) or eq_fn(v, ekey) then
				Node.query(node[a], skey, ekey, a, b, cb, lt_fn, eq_fn)
				cb(v)
				Node.query(node[b], skey, ekey, a, b, cb, lt_fn, eq_fn)
			else
				Node.query(node[a], skey, ekey, a, b, cb, lt_fn, eq_fn)
			end
		end
	end
end

-- http://stackoverflow.com/questions/1733311/pretty-print-a-tree
Node.print = function(self, to_str_fn, depth)
	depth = depth or 1
	if self then
		Node.print(self.right, to_str_fn, depth+1)
		local indent = string.rep("  ", depth)
		print(string.format("%s%s", indent, to_str_fn(self.value)))
		Node.print(self.left, to_str_fn, depth+1)
	end
end

------------------------

local M = {} -- proxy table for tree
M.__index = M

local DefaultLtFn = function(a, b) return a < b end
local DefaultEqFn = function(a, b) return a == b end

function M.new(lt_fn, eq_fn)
  return setmetatable({
    root = nil,
		total = 0,
    lt_fn = lt_fn or DefaultLtFn,
    eq_fn = eq_fn or DefaultEqFn,
  }, M)
  -- return setmetatable(t,{__index = function(t,k) return t.root[k] end})
end

function M:add(a)
	if not a then
		return
	end
	local added
  self.root, added = Node.add(self.root, a, self.lt_fn, self.eq_fn)
	if added then
		self.total = self.total + 1
  	return a
	end
end

function M:get(a)
	if not self.root then
		return
	end
	return self.root:get(a, self.lt_fn, self.eq_fn)
end

function M:del(a)
	if not self.root then
		return
	end

  self.root, a = self.root:delete(a, self.lt_fn, self.eq_fn)
	if a then
		self.total = self.total - 1
		return a
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
		a, b = 'left','right'
	elseif dir == -1 then
		a, b = 'right','left'
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

	self.root:query(skey, ekey, a, b, cb, self.lt_fn, self.eq_fn)
end

return M