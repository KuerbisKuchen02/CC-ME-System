local enum = {}

--- @enum gui.LayoutDirection 
enum.LayoutDirection = {
    LEFT_TO_RIGHT = 1,
    TOP_TO_BOTTOM = 2,
}

--- @enum gui.XAlignment
enum.XAlignment = {
    LEFT = 1,
    CENTER = 2,
    RIGHT = 3,
}

--- @enum gui.YAlignment
enum.YAlignment = {
    TOP = 1,
    CENTER = 2,
    BOTTOM = 3,
}

--- @enum gui.Overflow
enum.Overflow = {
    HIDDEN = 1, -- No overflow, content is clipped
    VISIBLE = 2, -- Content is visible outside the element bounds
    SCROLL = 3, -- Content can be scrolled if it overflows
    WRAP = 4, -- Content wraps to the next line if it overflows
}

--- @enum gui.events.EventType
enum.EventType = {
    ALARM = "alarm",
    CHAR = "char",
    COMPUTER_COMMAND = "computer_command",
    DISK = "disk",
    DISK_EJECT = "disk_eject",
    FILE_TRANSFER = "file_transfer",
    HTTP_CHECK = "http_check",
    HTTP_FAILURE = "http_failure",
    HTTP_SUCCESS = "http_success",
    KEY = "key",
    KEY_UP = "key_up",
    MODEM_MESSAGE = "modem_message",
    MOUSE_CLICK = "mouse_click",
    MOUSE_DRAG = "mouse_drag",
    MOUSE_SCROLL = "mouse_scroll",
    MOUSE_UP = "mouse_up",
    PASTE = "paste",
    PERIPHERAL = "peripheral",
    PERIPHERAL_DETACH = "peripheral_detach",
    REDNET_MESSAGE = "rednet_message",
    REDSTONE = "redstone",
    SPEAKER_AUDIO_EMPTY = "speaker_audio_empty",
    TASK_COMPLETE = "task_complete",
    TERM_RESIZE = "term_resize",
    TERMINATE = "terminate",
    TIMER = "timer",
    TURTLE_INVENTORY = "turtle_inventory",
    WEBSOCKET_CLOSED = "websocket_closed",
    WEBSOCKET_FAILURE = "websocket_failure",
    WEBSOCKET_MESSAGE = "websocket_message",
    WEBSOCKET_SUCCESS = "websocket_success",
}

return enum