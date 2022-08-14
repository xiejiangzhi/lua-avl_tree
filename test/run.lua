local lust = require 'test.lust'

local describe, it, expect = lust.describe, lust.it, lust.expect
-- local before_each, after_each = lust.before, lust.after
-- local spy = lust.spy

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

    ss:add({ 'b', 321 })
    expect(ss:get({ 'b' })).to.equal({ 'b', 321 })

    ss:add({ 'c', 2 })
    ss:add({ 'd', 3 })

    expect(ss:size()).to.equal(4)

    expect(ss:del({ 'a' })).to.equal({ 'a', 123 })
    expect(ss:size()).to.equal(3)
    expect(ss:get({ 'a' })).to.equal(nil)
    expect(ss:empty()).to.equal(false)

    ss:add({ 'b', 111 })
    expect(ss:get({ 'b' })).to.equal({ 'b', 111 })
    expect(ss:get({ 'c' })).to.equal({ 'c', 2 })
    expect(ss:del({ 'b' })).to.equal({ 'b', 111 })
    expect(ss:get({ 'b' })).to.equal(nil)
    expect(ss:get({ 'c' })).to.equal({ 'c', 2 })

    expect(ss:peek('left')).to.equal({ 'c', 2 })
    expect(ss:peek('right')).to.equal({ 'd', 3 })

    -- del invalid
    expect(ss:del({ 'b' })).to.equal(nil)
  end)

  it('size', function()
    local ss = lib.new()
    local ks = { 1, 2, 3, 19, 18, 17, 7, 6, 4, 5, 14, 15, 16, 13 }
    for i, v in ipairs(ks)  do
      ss:add(v)
      expect(ss:size()).to.be(i)
    end

    local t = #ks
    for i, k in ipairs(ks) do
      ss:del(k)
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

    local r = {}
    ss:iter(1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 0, 1, 2, 2.5, 3, 3.5, 4 })

    r = {}
    ss:iter(-1, function(v) r[#r + 1] = v end)
    expect(r).to.equal({ 4, 3.5, 3, 2.5, 2, 1, 0 })
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
    expect(r).to.equal({ 3, 2.5, 2 })
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
    for i = 1, n do
      expect(ss:add(i)).to.be(i)
    end
    expect(ss:size()).to.be(n)
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