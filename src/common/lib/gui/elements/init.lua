local elements = {}

-- get the directory of the current script
local files = fs.list(fs.getDir(select(2,...) or ""))

for _, file in ipairs(files) do
    if file:match("%.lua$") and file ~= "init.lua" then
        local name = file:sub(1, -5)
        elements[name] = require("ccmesystem.lib.gui.elements." .. name)
    end
end

return elements
