local component = require("Component")
local system = require("System")
local event = require("Event")
local gui = require("GUI")
local bigLetters = require("BigLetters")
-------------------------------------------------------------------------------
--Вікно
local workspace, window = system.addWindow(gui.filledWindow(1, 1, 140, 23, 0x061424))
window.actionButtons.maximize:remove() --Розгортати його не потрібно

local localization = system.getCurrentScriptLocalization()

local flux = nil

if component.isAvailable("flux_storage") then
    flux = component.flux_storage
else
    gui.alert(localization.notStorage)
    window:remove()
end

window:addChild(gui.text(10, 3, 0xFFFFFF, localization.allEnergy))
local Energy = window:addChild(gui.object(10, 5, 130, 5))

window:addChild(gui.text(110, 15, 0xFFFFFF, localization.input))
window:addChild(gui.text(110, 19, 0xFFFFFF, localization.output))
local input = window:addChild(gui.text(110, 16, 0xFFFFFF, flux.getEnergyInfo()["energyInput"] .. " " .. flux.getNetworkInfo()["energyType"] .. "/t"))
local output = window:addChild(gui.text(110, 20, 0xFFFFFF, flux.getEnergyInfo()["energyOutput"] .. " " .. flux.getNetworkInfo()["energyType"] .. "/t"))

local pointCount = window:addChild(gui.text(10, 17, 0xFFFFFF, localization.pointCount .. math.floor(flux.getCountInfo()["pointCount"])))
local plugCount = window:addChild(gui.text(10, 19, 0xFFFFFF, localization.plugCount .. math.floor(flux.getCountInfo()["plugCount"])))
local storageCount = window:addChild(gui.text(10, 21, 0xFFFFFF, localization.storageCount .. math.floor(flux.getCountInfo()["storageCount"])))

local loop = event.addHandler(function()
    Energy:remove()

    local Energy = window:addChild(gui.object(10, 5, 130, 5))
    Energy.draw = function(object)
        bigLetters.drawText(object.x, object.y, 0xFFFFFF, math.floor(flux.getEnergyInfo()["totalEnergy"]) .. " " .. string.lower(flux.getNetworkInfo()["energyType"]))
    end

    input.text = flux.getEnergyInfo()["energyInput"] .. " " .. flux.getNetworkInfo()["energyType"] .. "/t"
    output.text = flux.getEnergyInfo()["energyOutput"] .. " " .. flux.getNetworkInfo()["energyType"] .. "/t"

    pointCount.text = localization.pointCount .. math.floor(flux.getCountInfo()["pointCount"])
    plugCount.text = localization.plugCount .. math.floor(flux.getCountInfo()["plugCount"])
    storageCount.text = localization.storageCount .. math.floor(flux.getCountInfo()["storageCount"])
end)
window.actionButtons.close.onTouch = function()
    event.removeHandler(loop)
    window:remove()
end