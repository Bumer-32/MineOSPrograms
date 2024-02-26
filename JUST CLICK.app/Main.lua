local GUI = require("GUI")
local system = require("System")
local bigLetters = require("BigLetters")

local internet = nil
if component.isAvailable("internet") then
  internet = component.internet
else
  GUI.alert("For run this program need internet card!")
  return
end

---------------------------------------------------------------------------------
local previous = 0
local number = 0

local serverAddr = "147.185.221.18:45819"

local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 60, 20, 0x4B4B4B))

local text1 = "Just Click Game! You should just to click!"
window:addChild(GUI.text(math.floor((window.width/2)-(unicode.len(text1)/2)), 5, 0xFFFFFF, text1))
local text2 = "Summ of all clicks (off all players) you can see"
window:addChild(GUI.text(math.floor((window.width/2)-(unicode.len(text2)/2)), 6, 0xFFFFFF, text2))

local Num = window:addChild(GUI.object(math.floor((window.width/2)-(unicode.len(number)*7)/2), 8, 130, 5))

local socket = internet.connect(serverAddr)
while true do
    local status, err = socket.finishConnect()

    if status then
        break
    end
    if err then
        GUI.alert("Can't connect to server!")
        GUI.alert("error: " .. error)
        break
    end
end

local status, _ = socket.finishConnect()
if not status then
    return
end

window.eventHandler = function(workspace, window, e1, e2, e3, e4)
    if e1 == "touch" then
        window.backgroundPanel.colors.background = 0xFF9200
        socket.write("click")
    elseif e1 == "drop" then
        window.backgroundPanel.colors.background = 0x4B4B4B
    elseif e1 == "internet_ready" then
        local data = socket.read()
        if data ~= nil then
            previous = number
            number = tonumber(data)
        end
    end
    
    if unicode.len(previous) ~= unicode.len(number) then
        Num.localX = math.floor((window.width/2)-(unicode.len(number)*7)/2)
    end

    Num.draw = function(object)
        bigLetters.drawText(object.x, object.y, 0xFFFFFF, tostring(number))
    end
end

window.actionButtons.close.onTouch = function()
    --workspace:stop()
    socket.write("disconnect")
    socket.close()
    window:remove()
    return
end
---------------------------------------------------------------------------------
workspace:draw()
