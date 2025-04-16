local expect = require("cc.expect").expect

local tree = {}

--- @enum tree.DepthFirstOrder
tree.DepthFirstOrder = {
    PRE_ORDER = 1,
    IN_ORDER = 2,
    POST_ORDER = 3,
    REVERSE_PRE_ORDER = 4,
    REVERSE_IN_ORDER = 5,
    REVERSE_POST_ORDER = 6,
}

--- Create an iterator to traverse a tree in depth-first order
--- 
------
--- Possible orders:
--- 
--- - PRE_ORDER = 1,
--- - IN_ORDER = 2,
--- - POST_ORDER = 3,
--- - REVERSE_PRE_ORDER = 4,
--- - REVERSE_IN_ORDER = 5,
--- - REVERSE_POST_ORDER = 6,
--- 
------
--- Usage example:
--- ```lua
--- for node in tree.depthFirstIter(root, order, filter) do
---    print(node)
--- end
--- ```
--- 
--- @generic T : table
--- @param root T
--- @param order tree.DepthFirstOrder
--- @param filter? (fun(node: table):boolean)
--- @return fun(): T? Iterator
function tree.depthFirstIter(root, order, filter)
    expect(1, tree, "table")
    expect(2, order, "number")
    expect(3, filter, "function", "nil")

    local stack, isReverse = {}, order > 3
    order = isReverse and order - 3 or order

    local function peek() return stack[#stack] end
    local function pop() return table.remove(stack) end
    local function push(node, state)
        if filter and not filter(node) then
            return
        end
        table.insert(stack, {node = node, state = state or false})
    end

    push(root)

    return function ()
        while (#stack > 0) do
            local frame = peek()
            local node, state = frame.node, frame.state
            local children = node.children or {}

            -- pre order and reverse pre order            
            if order == tree.DepthFirstOrder.PRE_ORDER then
                pop()
                -- if isReverse then i=1, #children else i=#children, 1, -1
                for i = isReverse and 1 or #children, isReverse and #children or 1, isReverse and 1 or -1 do
                    push(children[i])
                end
                return node
            -- in order and reverse in order
            elseif order == tree.DepthFirstOrder.IN_ORDER then
                if state then
                    pop()
                    if #children > 1 then
                        push(children[isReverse and 1 or #children])
                    end
                    return node
                end
                -- change state of current node
                frame.state = true
                if #children == 1 then
                    push(children[1])
                else
                    -- if reversed then i=2, #children else i=#children-1, 1, -1
                    for i = isReverse and 2 or #children - 1, isReverse and #children or 1, isReverse and 1 or -1 do
                        local child = children[i]
                        push(child)
                    end
                end
            -- post order and reverse post order
            elseif order == tree.DepthFirstOrder.POST_ORDER then
                if state then
                    pop()
                    return node
                end
                -- if isReverse then i=1, #children else i=#children, 1, -1
                for i = isReverse and 1 or #children, isReverse and #children or 1, isReverse and 1 or -1  do
                    local child = children[i]
                    push(child)
                end
                frame.state = true
            end
        end
    end
end

return tree