local system = require("System")
local filesystem = require("Filesystem")
local GUI = require("GUI")
local component = require("Component")
local computer = require("computer")
local event = require("Event")
local json = require("JSON")

local localization = system.getCurrentScriptLocalization()

local internet = nil
if component.isAvailable("internet") then
  internet = component.internet
else
  GUI.alert(localization.notInternet)
  return
end

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 39, 23, 0x662480))

local progress = window:addChild(GUI.progressIndicator(window.width - 5, 2, 0x1E1E1E, 0x1E1E1E, 0xA5A5A5))

local user = window:addChild(GUI.input(5, 5, 30, 3, 0x1E1E1E, 0xA5A5A5, 0xA5A5A5, 0x1E1E1E, 0xFFFFFF, "", localization.nick, false))
local repo = window:addChild(GUI.input(5, 9, 30, 3, 0x1E1E1E, 0xA5A5A5, 0xA5A5A5, 0x1E1E1E, 0xFFFFFF, "", localization.repository, false))
local path = window:addChild(GUI.filesystemChooser(5, 13, 30, 3, 0x1E1E1E, 0xA5A5A5, 0x1E1E1E, 0xA5A5A5, localization.choosePath, localization.choose, localization.cancel, localization.choosePath, "/"))
path:setMode(GUI.IO_MODE_DIRECTORY)
local downloadButton = window:addChild(GUI.button(5, 17, 30, 3, 0x1E1E1E, 0xA5A5A5, 0xA5A5A5, 0x1E1E1E, localization.download))

window:addChild(GUI.text(1, window.height, 0xA5A5A5, "GitHub Dowloader V-1.0"))

local function request(url, body, headers, timeout)
  local newUrl = url:gsub("%s", "%%20")
  local handle, error = internet.request(newUrl, body, headers)
  
  if not handle then
    return nil, (localization.requestFailed):format(error or localization.unknownError)
  end

  local start = computer.uptime()
  
  while true do
    local status, error = handle.finishConnect()
    
    if status then
      break
    end
    
    if status == nil then
      return nil, (localization.requestFailed):format(error or localization.unknownError)
    end
    
    if computer.uptime() >= start + timeout then
      handle.close()

      return nil, localization.timeout
    end
    
    event.sleep(0.05)
  end

  return handle
end

local function ReadUrl(url)
  local handle, error = request(url, nil, nil, 10)
  local data = ""
  progress.active = true

  if not error then
    while true do
      local chunk, error = handle.read()
      if chunk then
        data = data .. chunk
        progress:roll()
        workspace:draw()
      else
        break
      end
    end
  else
    GUI.alert(error)
    progress.active = false
    return
  end
  progress.active = false
  handle.close()

  return data
end

local function downloader(url)
  local data = ReadUrl(url)
  if data then
    local content = json.decode(data)
    for i, content in ipairs(content) do
      if content.type == "file" then
        filesystem.write(path.path .. repo.text .. "/" .. content.path, ReadUrl(content.download_url))
      end
      if content.type == "dir" then
        filesystem.makeDirectory(path.path .. repo.text .. "/" .. content.path)
        downloader(url .. content.name .. "/")
      end
    end
    computer.pushSignal("system", "updateFileList")
  end
end

downloadButton.onTouch = function()
    if user.text == "" then
        GUI.alert(localization.noNick)
        return
    end
    if repo.text == "" then
        GUI.alert(localization.noRepository)
        return
    end
	if string.sub(path.path, 1, 1) ~= "/" then
        GUI.alert(localization.noPath)
        return
    end
    downloader("https://api.github.com/repos/" .. user.text .. "/" .. repo.text .. "/contents/") 
    filesystem.makeDirectory(path.path .. repo.text)
    workspace:draw()
end