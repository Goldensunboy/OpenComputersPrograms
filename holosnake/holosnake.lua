--[[
  Holographic snake
  This is a demo for the holographic projector, no controls
  Known issue: too small a timer interval causes a race condition that
  messes up the snake tick calculations
--]]

local event = require("event")
local component = require("component")
local holo = component.hologram

local snake
local target
local length
local direction

local tickID
local running = true
local oldColors

function initSnake()
  holo.clear()
  oldColors = {holo.getPaletteColor(1), holo.getPaletteColor(2), holo.getPaletteColor(3)}
  holo.setPaletteColor(1, 0x00FF00)
  holo.setPaletteColor(2, 0xFF0000)
  snake = {}
  length = 6
  for i = 1, length do snake[i] = {i, 1, 1} end
  newTarget()
  direction = pickDirection()
  for _, n in pairs(snake) do holo.set(n[1], n[2], n[3], 1) end
end

function newTarget()
  repeat
    invalid = false
    target = {math.random(48), math.random(32), math.random(48)}
    for _, n in pairs(snake) do
      if n[1] == target[1] and n[2] == target[2] and n[3] == target[3] then
        invalid = true
      end
    end
  until invalid == false
  holo.set(target[1], target[2], target[3], 2)
end

function sortPairs(t, order)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  if order then
    table.sort(keys, function(a, b) return order(t, a, b) end)
  else
    table.sort(keys)
  end
  local i = 0
  return function()
    i = i + 1
    if keys[i] then return keys[i], t[keys[i]] end
  end
end

function pickDirection()
  t = target
  s = snake[length]
  valid = {PX = true, NX = true, PY = true, NY = true, PZ = true, NZ = true}
  if s[1] == 48 or holo.get(s[1] + 1, s[2], s[3]) == 1 then valid["PX"] = false end
  if s[1] == 1 or holo.get(s[1] - 1, s[2], s[3]) == 1 then valid["NX"] = false end
  if s[2] == 32 or holo.get(s[1], s[2] + 1, s[3]) == 1 then valid["PY"] = false end
  if s[2] == 1 or holo.get(s[1], s[2] - 1, s[3]) == 1 then valid["NY"] = false end
  if s[3] == 48 or holo.get(s[1], s[2], s[3] + 1) == 1 then valid["PZ"] = false end
  if s[3] == 1 or holo.get(s[1], s[2], s[3] - 1) == 1 then valid["NZ"] = false end
  dist = {}
  dist["PX"] = t[1] - s[1]
  dist["NX"] = s[1] - t[1]
  dist["PY"] = t[2] - s[2]
  dist["NY"] = s[2] - t[2]
  dist["PZ"] = t[3] - s[3]
  dist["NZ"] = s[3] - t[3]
  for key, _ in sortPairs(dist, function(t, a, b) return t[b] < t[a] end) do
    if valid[key] then print("Dir:", key) return key end
  end
  return "FALSE"
end

function doSnakeTick()
  s = snake[length]
  if direction == "PX" then
    next = {s[1] + 1, s[2], s[3]}
    if holo.get(next[1], next[2], next[3]) == 1 then
      direction = pickDirection()
      doSnakeTick()
      return
    elseif next[1] == target[1] then direction = pickDirection() end
  elseif direction == "NX" then
    next = {s[1] - 1, s[2], s[3]}
    if holo.get(next[1], next[2], next[3]) == 1 then
      direction = pickDirection()
      doSnakeTick()
      return
    elseif next[1] == target[1] then direction = pickDirection() end
  elseif direction == "PY" then
    next = {s[1], s[2] + 1, s[3]}
    if holo.get(next[1], next[2], next[3]) == 1 then
      direction = pickDirection()
      doSnakeTick()
      return
    elseif next[2] == target[2] then direction = pickDirection() end
  elseif direction == "NY" then
    next = {s[1], s[2] - 1, s[3]}
    if holo.get(next[1], next[2], next[3]) == 1 then
      direction = pickDirection()
      doSnakeTick()
      return
    elseif next[2] == target[2] then direction = pickDirection() end
  elseif direction == "PZ" then
    next = {s[1], s[2], s[3] + 1}
    if holo.get(next[1], next[2], next[3]) == 1 then
      direction = pickDirection()
      doSnakeTick()
      return
    elseif next[3] == target[3] then direction = pickDirection() end
  elseif direction == "NZ" then
    next = {s[1], s[2], s[3] - 1}
    if holo.get(next[1], next[2], next[3]) == 1 then
      direction = pickDirection()
      doSnakeTick()
      return
    elseif next[3] == target[3] then direction = pickDirection() end
  else
    print("Collision at: ["..s[1]..", "..s[2]..", "..s[3].."]")
    initSnake()
  end
  if next[1] < 1 or next[1] > 48 or next[2] < 1 or next[2] > 32 or next[3] < 1 or next[3] > 48 then
    print("Warning: Invalid destination!")
    print("Direction:", direction)
    print("Next:", next[0], next[1], next[2])
  end
  if next[1] == target[1] and next[2] == target[2] and next[3] == target[3] then
    length = length + 1
    snake[length] = next
    newTarget()
    direction = pickDirection()
  else
    s = snake[1]
    holo.set(s[1], s[2], s[3], 0)
    for i = 1, length - 1 do snake[i] = snake[i + 1] end
    snake[length] = next
  end
  holo.set(next[1], next[2], next[3], 1)
end

function stopSnake()
  print("Stopping snake")
  event.cancel(tickID)
  event.ignore("key_down", stopSnake)
  running = false
  holo.clear()
  for i = 1, 3 do holo.setPaletteColor(i, oldColors[i]) end
end

initSnake()
tickID = event.timer(0.15, doSnakeTick, math.huge)
event.listen("key_down", stopSnake)

repeat os.sleep(1) until not running

