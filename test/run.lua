local lust = require 'test.lust'

local describe, it, expect = lust.describe, lust.it, lust.expect
-- local before_each, after_each = lust.before, lust.after
-- local spy = lust.spy

describe('rb_tree', function()
  local lib = require 'avl_tree'

  it('add/get/del', function()
    local ss = lib.new(
      function(a, b) return a[1] < b[1] end,
      function(a, b) return a[1] == b[1] end
    )

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

    ss:del({ 'a' })
    expect(ss:size()).to.equal(3)
    expect(ss:get({ 'a' })).to.equal(nil)
    expect(ss:empty()).to.equal(false)

    ss:add({ 'b', 111 })
    expect(ss:get({ 'b' })).to.equal({ 'b', 111 })
    expect(ss:get({ 'c' })).to.equal({ 'c', 2 })
    ss:del({ 'b' })
    expect(ss:get({ 'b' })).to.equal(nil)
    expect(ss:get({ 'c' })).to.equal({ 'c', 2 })

    expect(ss:min()).to.equal({ 'c', 2 })
    expect(ss:max()).to.equal({ 'd', 3 })
  end)

  it('size', function()
    local ss = lib.new()
    ss:add(1)
    expect(ss:size()).to.be(1)
    ss:add(2)
    expect(ss:size()).to.be(2)
    ss:add(3)
    expect(ss:size()).to.be(3)
    ss:add(4)
    expect(ss:size()).to.be(4)

    ss:add(5)
    expect(ss:size()).to.be(5)
    ss:add(6)
    expect(ss:size()).to.be(6)
    ss:add(7)
    expect(ss:size()).to.be(7)

    ss:add(19)
    expect(ss:size()).to.be(8)
    ss:add(18)
    expect(ss:size()).to.be(9)
    ss:add(17)
    expect(ss:size()).to.be(10)
    ss:add(16)
    expect(ss:size()).to.be(11)
    ss:add(15)
    expect(ss:size()).to.be(12)
    ss:add(14)
    expect(ss:size()).to.be(13)
    ss:add(13)
    expect(ss:size()).to.be(14)

    local t = 14
    local ks = { 1, 2, 3, 19, 18, 17, 7, 6, 4, 5, 14, 15, 16, 13 }
    for i, k in ipairs(ks) do
      ss:del(k)
      -- ss:print()
      expect(ss:size()).to.be(t - i)
    end

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

  it('same key', function()
    local ss = lib.new(
      function(a, b)
        if a.v < b.v then
          return true
        elseif a == b then
          return a.k < b.k
        end
      end,
      function(a, b) return a == b end
    )

    local a = { v = 1, k = 'a' }
    local b = { v = 3, k = 'b' }
    local c = { v = 2, k = 'c' }
    local d = { v = 1, k = 'd' }

    expect(ss:size()).to.be(0)
    ss:add(a)
    ss:add(b)
    ss:add(c)
    ss:add(d)
    expect(ss:size()).to.be(4)

    expect(ss:get(a)).to.be(a)
    expect(ss:get(b)).to.be(b)
    expect(ss:get(c)).to.be(c)
    expect(ss:get(d)).to.be(d)

    expect(ss:min().v).to.be(1)
    expect(ss:max()).to.be(b)
  end)
end)