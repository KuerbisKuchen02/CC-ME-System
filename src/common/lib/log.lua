local log = {}

log.level = "trace"
log.outfile = "ccmesystem.log"
log.usecolor = true

local modes = {
    {name = "trace", color = colors.gray},
    {name = "debug", color = colors.blue},
    {name = "info", color = colors.white},
    {name = "warn", color = colors.yellow},
    {name = "error", color = colors.orange},
    {name = "fatal", color = colors.red}
}

local levels = {}
for i, v in ipairs(modes) do
    levels[v.name] = i
end

for i, x in ipairs(modes) do
    local nameupper = x.name:upper()
    log[x.name] = function(msg, ...)
        if type(msg) == "string" then
            msg = string.format(msg, ...)
        end
        local level = levels[log.level]
        if level == nil then
            level = levels["info"]
        end
        if i < level then
            return
        end
        if log.usecolor then
            term.setTextColor(x.color)
        end
        local info = debug.getinfo(2, "Sl")
        local lineinfo = info.short_src .. ":" .. info.currentline
        msg = string.format("[%-6s%s] %s: %s",
                            nameupper,
                            os.date("%T"),
                            lineinfo,
                            msg)
        if log.outfile then
            if fs.exists(log.outfile) and fs.getSize(log.outfile) > 100000 then
                fs.delete(log.outfile)
            end
            local file = fs.open(log.outfile, "a")
            if file == nil then error("cannot initiate logger!") end
            file.writeLine(msg)
            file.close()
        end
        -- print(msg)
    end
end

return log