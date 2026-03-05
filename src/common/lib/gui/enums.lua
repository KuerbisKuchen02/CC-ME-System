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

return enum