local Node   = {}
Node.__index = Node

local newLeaf = function(a)
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
	return getHeight(node.right)-getHeight(node.left)
end

-- http://en.wikipedia.org/wiki/Tree_rotation
local rotateNode = function(root,rotation_side,opposite_side)
	local pivot           = root[opposite_side]
	root[opposite_side]   = pivot[rotation_side]
	pivot[rotation_side]  = root
	root,pivot            = pivot,root
	setHeight(pivot);setHeight(root)
	return root
end
-- perform leaf check,height check,& rotation
local updateSubtree = function(root)
	setHeight(root)
	local rotation_side,opposite_side,pivot,rotate_pivot
	local balance = getBalance(root)
	if balance > 1 then
		pivot = root.right
		if getBalance(pivot) < 0 then rotate_pivot = true end
		rotation_side,opposite_side = 'left','right'
	elseif balance < -1 then
		pivot = root.left
		if getBalance(pivot) > 0 then rotate_pivot = true end
		rotation_side,opposite_side = 'right','left'
	end
	if rotation_side then
		if rotate_pivot then
			root[opposite_side] = rotateNode(pivot,opposite_side,rotation_side)
		end
		root = rotateNode(root,rotation_side,opposite_side)
	end
	return root
end

function Node:add(a, lt_fn, eq_fn) -- Insert given element, return it if successful
	if not self or not self.value then
		return a, newLeaf(a)
	else
		if lt_fn(a, self.value) then
			a, self.left   = Node.add(self.left, a, lt_fn, eq_fn)
		elseif eq_fn(a, self.value) then
			self.value = a
			a = nil
		else
			a, self.right  = Node.add(self.right, a, lt_fn, eq_fn)
		end
		return a, updateSubtree(self)
	end
end

-- return new_node, value
function Node.delete(self, a, lt_fn, eq_fn)
	if self then
		local v = self.value
		if eq_fn(a, v) then
			if not self.left or not self.right then
				return self.left or self.right, a
			else
				local sNode = self.right
				while sNode.left do
					sNode	    = sNode.left
				end
				self        = self:delete(sNode.value, lt_fn, eq_fn)
				self.value  = sNode.value
				return self, a
			end
		else
			if lt_fn(a, v) then
				self.left, a = Node.delete(self.left, a, lt_fn, eq_fn)
			else
				self.right, a  = Node.delete(self.right, a, lt_fn, eq_fn)
			end
		end
		return updateSubtree(self), a
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
		if lt_fn(v, skey) then
			Node.query(node[b], skey, ekey, a, b, cb, lt_fn, eq_fn)
		elseif eq_fn(v, skey) then
			Node.query(node[a], skey, ekey, a, b, cb, lt_fn, eq_fn)
			cb(v)
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
Node.print = function(self,depth)
	depth = depth or 1
	if self then
		Node.print(self.right,depth+1)
		print(string.format("%s%d",string.rep("  ", depth), self.value))
		Node.print(self.left,depth+1)
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
  a, self.root = Node.add(self.root, a, self.lt_fn, self.eq_fn)
	if a then
		self.total = self.total + 1
	end
  return a
end

function M:get(a)
	if not self.root then
		return
	end
	return self.root:get(a, self.lt_fn, self.eq_fn)
end

function M:del(a)
  self.root, a = self.root:delete(a, self.lt_fn, self.eq_fn)
	if a then
		self.total = self.total - 1
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

function M:min()
	return self.root:peek('left')
end

function M:max()
	return self.root:peek('right')
end

function M:print()
	self.root:print()
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