--- @alias gui.Sizing gui.Sizing.FixedSizing | gui.Sizing.FitSizing | gui.Sizing.GrowSizing | gui.Sizing.PercentSizing
local Sizing = {}

--- @enum gui.Sizing.Type
Sizing._Type = {
    FIXED = 1,
    FIT = 2,
    GROW = 3,
    PERCENT = 4,
}

--- @class gui.Sizing.FixedSizing
--- @field type gui.Sizing.Type
--- @field value number

--- Fixed sizing
--- @param n number
--- @return gui.Sizing.FixedSizing
function Sizing.FIXED(n) return {n, type=Sizing._Type.FIXED, min=n} end

--- @class gui.Sizing.FitSizing
--- @field type gui.Sizing.Type
--- @field min number?
--- @field max number?

--- Fit sizing
--- @param min number?
--- @param max number?
--- @return gui.Sizing.FitSizing
function Sizing.FIT(n, min, max) return {n, type=Sizing._Type.FIT, min=min, max=max} end

--- @class gui.Sizing.GrowSizing
--- @field type gui.Sizing.Type
--- @field min number?
--- @field max number?

--- Grow sizing
--- @param min number?
--- @param max number?
--- @return gui.Sizing.GrowSizing
function Sizing.GROW(min, max) return {min, type=Sizing._Type.GROW, min=min, max=max} end

--- @class gui.Sizing.PercentSizing
--- @field type gui.Sizing.Type
--- @field value number

--- Percent sizing
--- @param n number
--- @return gui.Sizing.PercentSizing
function Sizing.PERCENT(n) return {n, type=Sizing._Type.PERCENT} end

return Sizing