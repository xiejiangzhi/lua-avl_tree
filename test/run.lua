local lust = require 'test.lust'

local describe, it, expect = lust.describe, lust.it, lust.expect
-- local before_each, after_each = lust.before, lust.after
-- local spy = lust.spy

lust.case_filter = function(name)
  -- return name:match("#focus")
  return true
end

describe('rb_tree', function()
  local lib = require 'avl_tree'

  it('add/get/del', function()
    local ss = lib.new(
      function(a, b)
        if a[1] < b[1] then
          return -1
        elseif a[1] > b[1] then
          return 1
        else
          return 0
        end
      end
    )

    expect(ss:peek('left')).to.equal(nil)
    expect(ss:peek('right')).to.equal(nil)
    expect(ss:empty()).to.equal(true)
    expect(ss:get({ 'a' })).to.equal(nil)
    ss:add({ 'a', 123 })
    expect(ss:get({ 'a' })).to.equal({ 'a', 123 })
    expect(ss:empty()).to.equal(false)
    expect(ss.root.height).to.be(0)

    ss:add({ 'b', 321 })
    expect(ss:get({ 'b' })).to.equal({ 'b', 321 })

    ss:add({ 'c', 2 })
    ss:add({ 'd', 3 })
    expect(ss.root.height).to.be(2)

    expect(ss:size()).to.equal(4)

    expect(ss:del({ 'a' })).to.equal({ 'a', 123 })
    expect(ss:size()).to.equal(3)
    expect(ss:get({ 'a' })).to.equal(nil)
    expect(ss:empty()).to.equal(false)
    expect(ss.root.height).to.be(1)

    ss:add({ 'b', 111 })
    expect(ss:get({ 'b' })).to.equal({ 'b', 111 })
    expect(ss:get({ 'c' })).to.equal({ 'c', 2 })
    expect(ss:del({ 'b' })).to.equal({ 'b', 111 })
    expect(ss:get({ 'b' })).to.equal(nil)
    expect(ss:get({ 'c' })).to.equal({ 'c', 2 })
    expect(ss.root.height).to.be(1)

    expect(ss:peek('left')).to.equal({ 'c', 2 })
    expect(ss:peek('right')).to.equal({ 'd', 3 })

    -- del invalid
    expect(ss:del({ 'b' })).to.equal(nil)
  end)

  it('size & height', function()
    local ss = lib.new()
    local ks = { 1, 2, 3, 19, 18, 17, 7, 6, 4, 5, 14, 15, 16, 13 }
    for i, v in ipairs(ks)  do
      ss:add(v)
      expect(ss:size()).to.be(i)
    end
    expect(ss.root.height).to.be(math.ceil(math.log(#ks, 2)))

    local t = #ks
    for i, k in ipairs(ks) do
      ss:del(k)
      expect(ss:size()).to.be(t - i)
    end
  end)

  it('pop', function()
    local ss = lib.new()
    local ks = { 1, 2, 3, 19, 18, 17, 7, 6, 4, 5, 14, 15, 16, 13 }
    for i, v in ipairs(ks)  do
      ss:add(v)
    end

    local t = #ks
    table.sort(ks)
    for i, k in ipairs(ks) do
      expect(ss:pop('left')).to.be(k)
      expect(ss:size()).to.be(t - i)
    end

    for i, v in ipairs(ks)  do
      ss:add(v)
    end

    table.sort(ks, function(a, b) return a > b end)
    for i, k in ipairs(ks) do
      expect(ss:pop('right')).to.be(k)
      expect(ss:size()).to.be(t - i)
    end
  end)


  it('repeat add', function()
    local ss = lib.new()
    expect(ss:add(1)).to.be(1)
    expect(ss:add(1)).to.be(nil)
    expect(ss:add(2)).to.be(2)
    expect(ss:add(2)).to.be(nil)
    expect(ss:add(2)).to.be(nil)
    expect(ss:add(1)).to.be(nil)

    expect(ss:del(1)).to.be(1)
    expect(ss:del(1)).to.be(nil)
    expect(ss:del(2)).to.be(2)
    expect(ss:del(2)).to.be(nil)
    expect(ss:del(2)).to.be(nil)
  end)

  it('iter', function()
    local ss = lib.new()
    ss:add(1)
    ss:add(3)
    ss:add(2)
    ss:add(4)
    ss:add(2.5)
    ss:add(0)
    ss:add(3.5)
    expect(ss:size()).to.be(7)
    expect(ss.root.height).to.be(3)

    local r = {}
    ss:iter(1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 0, 1, 2, 2.5, 3, 3.5, 4 })

    r = {}
    ss:iter(-1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 4, 3.5, 3, 2.5, 2, 1, 0 })

    -- top n
    r = {}
    ss:iter(-1, function(v)
      r[#r + 1] = v
      if #r >= 3 then
        return false
      end
    end)
    expect(r).to.equal({ 4, 3.5, 3 })

    -- top n
    r = {}
    ss:iter(1, function(v)
      r[#r + 1] = v
      if #r >= 4 then
        return false
      end
    end)
    expect(r).to.equal({ 0, 1, 2, 2.5 })
  end)

  it('query', function()
    local ss = lib.new()
    ss:add(1)
    ss:add(3)
    ss:add(2)
    ss:add(4)
    ss:add(2.5)
    ss:add(0)
    ss:add(3.5)
    expect(ss:size()).to.be(7)

    local r = {}
    ss:query(1, 3, 1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 1, 2, 2.5, 3 })

    r = {}
    ss:query(1.1, 3.9, -1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 3.5, 3, 2.5, 2 })

    r = {}
    ss:query(nil, 3.9, -1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 3.5, 3, 2.5, 2, 1, 0 })

    r = {}
    ss:query(1.5, nil, -1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 4, 3.5, 3, 2.5, 2 })

    r = {}
    ss:query(9.5, nil, -1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ })

    r = {}
    ss:query(nil, -9, 1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ })
  end)

  it('query more', function()
    local ss = lib.new()
    for i = 1, 30 do
      ss:add(i)
    end

    local r = {}
    ss:query(5, 15, 1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 })

    r = {}
    ss:query(5, 15, -1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5 })

    r = {}
    ss:query(10, 25, 1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 })

    r = {}
    ss:query(10, 25, -1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({  25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10 })
  end)


  it('clear', function()
    local ss = lib.new()
    ss:add(1)
    ss:add(3)
    ss:add(2)
    ss:add(4)

    ss:clear()
    expect(ss:size()).to.be(0)
    expect(ss:get(1)).to.be(nil)
    expect(ss:get(2)).to.be(nil)

    ss:add(1)
    ss:add(2)
    expect(ss:get(1)).to.be(1)
    expect(ss:get(2)).to.be(2)
  end)

  it('large data test', function()
    local ss = lib.new()
    local n = 10000
    lib.reset_stat()
    for i = 1, n do
      expect(ss:add(i)).to.be(i)
    end
    expect(ss:size()).to.be(n)
    expect(ss.root.height).to.be(13)
    for i = 1, n do
      expect(ss:del(i)).to.be(i)
      expect(ss:size()).to.be(n - i)
    end
    expect(ss:empty()).to.be(true)
  end)

  it('same key', function()
    local ss = lib.new(
      function(a, b)
        if a == b then
          return 0
        end
        if a.v < b.v then
          return -1
        elseif a.v == b.v then
          if a.k < b.k then
            return -1
          else
            return 1
          end
        else
          return 1
        end
      end
    )

    local a = { v = 1, k = 'a' }
    local b = { v = 3, k = 'b' }
    local c = { v = 2, k = 'c' }
    local d = { v = 1, k = 'd' }
    local e = { v = 1, k = 'e' }
    local f = { v = 1, k = 'f' }

    expect(ss:size()).to.be(0)
    ss:add(a)
    ss:add(b)
    ss:add(c)
    ss:add(d)
    ss:add(e)
    ss:add(f)
    expect(ss:size()).to.be(6)
    -- ss:print(function(obj) return string.format('%i-%s', obj.v, obj.k) end)

    expect(ss:get(a)).to.be(a)
    expect(ss:get(b)).to.be(b)
    expect(ss:get(c)).to.be(c)
    expect(ss:get(d)).to.be(d)
    expect(ss:get(e)).to.be(e)
    expect(ss:get(f)).to.be(f)

    expect(ss:peek('left').v).to.be(1)
    expect(ss:peek('right')).to.be(b)
  end)
end)