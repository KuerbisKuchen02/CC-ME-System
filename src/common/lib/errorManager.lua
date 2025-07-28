---@module "common.lib.log"
local log = require("ccmesystem.lib.log")

local ErrorHandler = {
    isTracebackEnabled = true,
    header = "CCME-System Error"
}

local isErrorHandled = false

--- Throw an error at the given level or at top level if not level is given
--- The errorHandler is transperent for the stack level.
--- @param errMsg string error message with optional parameter
--- @param level? number level of the error
function ErrorHandler.error(errMsg, level)
    level = level and level + 1 or 2
    if isErrorHandled then
        log.fatal("Error handling failed, unexpected state isErrorHandled")
        error("Error handling failed, unexpected state isErrorHandled")
    end
    local stackTrace = debug.traceback("", level)
    log.fatal(errMsg .. stackTrace)

    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    printError(ErrorHandler.header .. ":")
    if not ErrorHandler.isTracebackEnabled then
        local info = debug.getinfo(level, "Sl")
        printError(("Error %s:%s: %s"):format(info.source, info.currentline, errMsg))
        isErrorHandled = true
        term.setTextColor(colors.white)
        error()
    end
    for line in stackTrace:gmatch("[^\r\n]+") do
        if line:match("%[C%]:") then break end
        local fileNameInTraceback, lineNumberInTraceback = line:match("([^:]+):(%d+):")
        if fileNameInTraceback and lineNumberInTraceback then
            term.setTextColor(colors.lightGray)
            term.write(fileNameInTraceback)
            term.setTextColor(colors.gray)
            term.write(":")
            term.setTextColor(colors.lightBlue)
            term.write(lineNumberInTraceback)
            term.setTextColor(colors.gray)
            line = line:gsub(fileNameInTraceback .. ":" .. lineNumberInTraceback, "")
        end
        term.setTextColor(colors.gray)
        print(line)
    end
    printError("Error: " .. errMsg)
    isErrorHandled = true
    term.setTextColor(colors.white)
    error()
end

return ErrorHandler
