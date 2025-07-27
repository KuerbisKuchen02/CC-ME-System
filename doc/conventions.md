---
title: Programming conventions
---

> [!NOTE]
> This Conventions took heavy inspiration from the [LuaRocks style guide](https://github.com/luarocks/lua-style-guide?tab=readme-ov-file)

# Naming Conventions

- Functions and methods: `camelCase`
- Variables and attributes: `camelCase`
  - string of letters, digit and underscores, not beginning with a digit
  - use an underscore at the beginning to mark private fields in a class that should not be modified externally
- Events: `snake_case`
- Classes: `PascalCase`
- Module file names: `camelCase`
  - short and best a single word
- Class file names: `PascalCase`
  - same name as class

## Indentation and formatting

- Let's address the elephant in the room first. Indented with 4 spaces.

```lua
for i, pkg in ipairs(packages) do
    for name, version in pairs(pkg) do
        if name == searched then
            print(version)
        end
    end
end
```

- One should not use tabs for indentation, or mix it with spaces.
- Use LF (Unix) line endings.

## Documentation

- Document function signatures using [Lua Language Server](https://luals.github.io/). Specifying typing information after each parameter or return value is a nice plus.

```lua
--- Load a local or remote manifest describing a repository.
-- All functions that use manifest tables assume they were obtained
-- through either this function or load_local_manifest.
-- @param repoUrl string URL or pathname for the repository.
-- @param luaVersion string Lua version in "5.x" format, defaults to installed version.
-- @return table|nil #  A table representing the manifest, or nil
function manif.loadManifest(repoUrl, luaVersion)
   -- code
end
```

- Use `TODO` and `FIXME` tags in comments. `TODO` indicates a missing feature to be implemented later. `FIXME` indicates a problem in the existing code (inefficient implementation, bug, unnecessary code, etc).

```lua
-- TODO: implement method
local function something()
   -- FIXME: check conditions
end
```

- Prefer comments over the function that explain _what_ the function does than inline comments inside the function that explain _how_ it does it. Ideally, the implementation should be simple enough so that comments aren't needed. If the function grows complex, split it into multiple functions so that their names explain what each part does.

## Variable names

- Variable names with larger scope should be more descriptive than those with smaller scope. One-letter variable names should be avoided except for very small scopes (less than ten lines) or for iterators.

- `i` should be used only as a counter variable in for loops (either numeric for or `ipairs`).

- Prefer more descriptive names than `k` and `v` when iterating with `pairs`, unless you are writing a function that operates on generic tables.

- Use `_` for ignored variables (e.g. in for loops):

```lua
for _, item in ipairs(items) do
   doSomethingWithItem(item)
end
```

- Variables and function names should use `camelCase`.

```lua
-- bad
local OBJEcttsssss = {}
local this_is_my_object = {}
local c = function()
   -- ...stuff...
end

-- good
local thisIsMyObject = {}

local function doThatThing()
   -- ...stuff...
end
```

> **Rationale:** The standard library uses lowercase APIs, with `joinedlowercase` names, but this does not scale too well for more complex APIs. The ComputerCraft API uses `camelCase` so stick to that.

- When doing OOP, classes should use `PascalCase`. Acronyms (e.g. XML) should only uppercase the first letter (`XmlDocument`). Methods use `camelCase` too.

- Prefer using `is...` when naming boolean functions:

```lua
-- bad
local function evil(alignment)
   return alignment < 100
end

-- good
local function isEvil(alignment)
   return alignment < 100
end
```

- `UPPER_CASE` is to be used sparingly, with "constants" only.

> **Rationale:** "Sparingly", since Lua does not have real constants. This notation is most useful in libraries that bind C libraries, when bringing over constants from C.

- Do not use uppercase names starting with `_`, they are reserved by Lua.

## Tables

- When creating a table, prefer populating its fields all at once, if possible:

```lua
local player = {
   name = "Jack",
   class = "Rogue",
}
```

- You can add a trailing comma to all fields, including the last one.

> **Rationale:** This makes the structure of your tables more evident at a glance. Trailing commas make it quicker to add new fields and produces shorter diffs.

- Use plain `key` syntax whenever possible, use `["key"]` syntax when using names that can't be represented as identifiers and avoid mixing representations in a declaration:

```lua
table = {
   ["1394-E"] = val1,
   ["UTF-8"] = val2,
   ["and"] = val2,
}
```

## Strings

- Use `"double quotes"` for strings; use `'single quotes'` when writing strings that contain double quotes.

```lua
local name = "LuaRocks"
local sentence = 'The name of the program is "LuaRocks"'
```

> **Rationale:** Double quotes are used as string delimiters in a larger number of programming languages. Single quotes are useful for avoiding escaping when using double quotes in literals.

## Line lengths

- There are no hard or soft limits on line lengths. Line lengths are naturally limited by using one statement per line. If that still produces lines that are too long (e.g. an expression that produces a line over 256-characters long, for example), this means the expression is too complex and would do better split into subexpressions with reasonable names.

> **Rationale:** No one works on VT100 terminals anymore. If line lengths are a proxy for code complexity, we should address code complexity instead of using line breaks to fit mind-bending statements over multiple lines.

## Function declaration syntax

- Prefer function syntax over variable syntax. This helps differentiate between named and anonymous functions.

```lua
-- bad
local nope = function (name, options)
   -- ...stuff...
end

-- good
local function yup(name, options)
   -- ...stuff...
end
```

- Perform validation early and return as early as possible.

```lua
-- bad
local function isGoodName(name, options, arg)
   local isGood = #name > 3
   isGood = isGood and #name < 30

   -- ...stuff...

   return isGood
end

-- good
local function isGoodName(name, options, args)
   if #name < 3 or #name > 30 then
      return false
   end

   -- ...stuff...

   return true
end
```

## Function calls

- Even though Lua allows it, do not omit parenthesis for functions that take a unique string literal argument.

```lua
-- bad
local data = getData"KRP"..tostring(areaNumber)
-- good
local data = getData("KRP"..tostring(areaNumber))
local data = getData("KRP")..tostring(areaNumber)
```

> **Rationale:** It is not obvious at a glace what the precedence rules are when omitting the parentheses in a function call. Can you quickly tell which of the two "good" examples in equivalent to the "bad" one? (It's the second one).

- You should not omit parenthesis for functions that take a unique table argument on a single line. You may do so for table arguments that span several lines.

```lua
local anInstance = aModule.new {
   aParameter = 42,
   anotherParameter = "yay",
}
```

> **Rationale:** The use as in `aModule.new` above occurs alone in a statement, so there are no precedence issues.

## Table attributes

- Use dot notation when accessing known properties.

```lua
local luke = {
   jedi = true,
   age = 28,
}

-- bad
local isJedi = luke["jedi"]

-- good
local isJedi = luke.jedi
```

- Use subscript notation `[]` when accessing properties with a variable or if using a table as a list.

```lua
local vehicles = loadVehiclesFromDisk("vehicles.dat")

if vehicles["Porsche"] then
   porscheHandler(vehicles["Porsche"])
   vehicles["Porsche"] = nil
end
for name, cars in pairs(vehicles) do
   regularHandler(cars)
end
```

> **Rationale:** Using dot notation makes it clearer that the given key is meant to be used as a record/object field.

## Functions in tables

- When declaring modules and classes, declare functions external to the table definition:

```lua
local myModule = {}

function myModule.aFunction(x)
   -- code
end
```

- When declaring metatables, declare function internal to the table definition.

```lua
local versionMt = {
   __eq = function (a, b)
      -- code
   end,
   __lt = function (a, b)
      -- code
   end,
}
```

> **Rationale:** Metatables contain special behavior that affect the tables they're assigned (and are used implicitly at the call site), so it's good to be able to get a view of the complete behavior of the metatable at a glance.

This is not as important for objects and modules, which usually have way more code, and which don't fit in a single screen anyway, so nesting them inside the table does not gain much: when scrolling a longer file, it is more evident that `checkVersion` is a method of `Api` if it says `function Api:checkVersion()` than if it says `checkVersion = function()` under some indentation level.

## Variable declaration

- Always use `local` to declare variables.

```lua
-- bad
superpower = get_superpower()

-- good
local superpower = get_superpower()
```

> **Rationale:** Not doing so will result in global variables to avoid polluting the global namespace.

## Variable scope

- Assign variables with the smallest possible scope.

```lua
-- bad
local function good()
   local name = getName()

   test()
   print("doing stuff..")

   --...other stuff...

   if name == "test" then
      return false
   end

   return name
end

-- good
local bad = function ()
   test()
   print("doing stuff..")

   --...other stuff...

   local name = getName()

   if name == "test" then
      return false
   end

   return name
end
```

> **Rationale:** Lua has proper lexical scoping. Declaring the function later means that its scope is smaller, so this makes it easier to check for the effects of a variable.

## Conditional expressions

- False and nil are falsy in conditional expressions. Use shortcuts when you can, unless you need to know the difference between false and nil.

```lua
-- bad
if name ~= nil then
   -- ...stuff...
end

-- good
if name then
   -- ...stuff...
end
```

- Avoid designing APIs which depend on the difference between `nil` and `false`.

- Use the `and`/`or` idiom for the pseudo-ternary operator when it results in more straightforward code. When nesting expressions, use parentheses to make it easier to scan visually:

```lua
local function defaultName(name)
   -- return the default "Waldo" if name is nil
   return name or "Waldo"
end

local function brewCoffee(machine)
   return (machine and machine.isLoaded) and "coffee brewing" or "fill your water"
end
```

> [!NOTE]
`x and y or z`  as a substitute for `x ? y : z` does not work if `y` may be `nil` or `false` so avoid it altogether for returning booleans or values which may be nil.

## Blocks

- Use single-line blocks only for `then return`, `then break` and `function return` (a.k.a "lambda") constructs:

```lua
-- good
if test then break end

-- good
if not ok then return nil, "this failed for this reason: " .. reason end

-- good
useCallback(x, function (k) return k.last end)

-- good
if test then
  return false
end

-- bad
if test < 1 and doComplicatedFunction(test) == false or seven == 8 and nine == 10 then doOtherComplicatedFunction() end

-- good
if test < 1 and doComplicatedFunction(test) == false or seven == 8 and nine == 10 then
   doOtherComplicatedFunction() 
   return false 
end
```

- Separate statements onto multiple lines. Do not use semicolons as statement terminators.

```lua
-- bad
local whatever = "sure";
a = 1; b = 2

-- good
local whatever = "sure"
a = 1
b = 2
```

## Spacing

- Use a space after `--`.

```lua
--bad
-- good
```

- Always put a space after commas and between operators and assignment signs:

```lua
-- bad
local x = y*9
local numbers={1,2,3}
numbers={1 , 2 , 3}
numbers={1 ,2 ,3}
local strings = { "hello"
                , "Lua"
                , "world"
                }
dog.set( "attr",{
  age="1 year",
  breed="Bernese Mountain Dog"
})

-- good
local x = y * 9
local numbers = {1, 2, 3}
local strings = {
   "hello",
   "Lua",
   "world",
}
dog.set("attr", {
   age = "1 year",
   breed = "Bernese Mountain Dog",
})
```

- Indent tables and functions according to the start of the line, not the construct:

```lua
-- bad
local myTable = {
                    "hello",
                    "world",
                 }
usingACallback(x, function (...)
                       print("hello")
                    end)

-- good
local myTable = {
   "hello",
   "world",
}
usingACallback(x, function (...)
   print("hello")
end)
```

> **Rationale:** This keep indentation levels aligned at predictable places. You don't need to realign the entire block if something in the first line changes (such as replacing `x` with `xy` in the `usingACallback` example above).

- The concatenation operator gets a pass for avoiding spaces:

```lua
-- okay
local message = "Hello, "..user.."! This is your day # "..day.." in our platform!"
```

> **Rationale:** Being at the baseline, the dots already provide some visual spacing.

- No spaces after the name of a function in a declaration or in its arguments.
- Space after the inline function declaration, but not in its arguments:

```lua
-- bad
local function hello ( name, language )
   -- code
end

local test = function( name, language ) 
    -- code
end

-- good
local function hello(name, language)
   -- code
end

local test = function (name, language)
    -- code
end
```

- Add two blank lines between functions and one blank line between methods

```lua
-- bad
local function foo()
   -- code
end
local function bar()
   -- code
end
local function MyClass:foo()
   -- code
end
local function MyClass:bar()
   -- code
end

-- good
local function foo()
   -- code
end


local function bar()
   -- code
end


local function MyClass:foo()
   -- code
end

local function MyClass:bar()
   -- code
end
```

- Avoid aligning variable declarations:

```lua
-- bad
local a               = 1
local longIdentifier = 2

-- good
local a = 1
local longIdentifier = 2
```

> **Rationale:** This produces extra diffs which add noise to `git blame`.

- Alignment is occasionally useful when logical correspondence is to be highlighted:

```lua
-- okay
sysCommand(form, UI_FORM_UPDATE_NODE, "a",      FORM_NODE_HIDDEN,  false)
sysCommand(form, UI_FORM_UPDATE_NODE, "sample", FORM_NODE_VISIBLE, false)
```

## Typing

- In non-performance critical code, it can be useful to add type-checking assertions for function arguments:
- use the `cc.expect` module for that

```lua
-- bad
function manif.loadManifest(repoUrl, luaVersion)
   assert(type(repoUrl) == "string")
   assert(type(luaVersion) == "string" or not luaVersion)

   -- ...
end

-- good
function manif.loadManifest(repoUrl, luaVersion)
    expect(1, repoUrl, "string")
    expect(2, luaVersion, "string", "nil")
end

```

> **Rationale:** This is a practice adopted early on in the development that has shown to be beneficial in many occasions.

- Use the standard functions for type conversion, avoid relying on coercion:

```lua
-- bad
local totalScore = reviewScore .. ""

-- good
local totalScore = tostring(reviewScore)
```

## Errors

- Functions that can fail for reasons that are expected (e.g. I/O) should return `false` and a (string) error message on error, possibly followed by other return values such as an error code.
  
- On errors such as API misuse, an error should be thrown, either with `error()` or `assert()`.

## Modules

- every dependency should be required at the top of the file
- if the file has a module description the require statements should be directly under the description

> [!NOTE] Best-Practice
> Also define depended default modules or functions from default modules at the top of the file:
> e.g.
> `local os = os`
> `local write = fs.write`

- Always require a module into a local variable named after the last component of the module’s full name.

```lua
local bar = require("foo.bar") -- requiring the module

bar.say("hello") -- using the module
```

- Don’t rename modules arbitrarily:

```lua
-- bad
local skt = require("socket")
```

> **Rationale:** Code is much harder to read if we have to keep going back to the top to check how you chose to call a module.

- Try to use names that won't clash with your local variables. For instance, don't name your module something like “size”.

- Public functions are declared in the module table and returned at the end

```lua
return {
    bar = bar
}
```

> **Rationale:** Visibility rules are made explicit through syntax.

- Do not set any globals in your module and always return a table in the end.

- If you would like your module to be used as a function, you may set the `__call` metamethod on the module table instead.

> **Rationale:** Modules should return tables in order to be amenable to have their contents inspected via the Lua interactive interpreter or other tools.

- Requiring a module should cause no side-effect other than loading other modules and returning the module table.

- A module should not have state. If a module needs configuration, turn it into a class. For example, do not make something like this:

```lua
-- bad
local mp = require "MessagePack"
mp.setInteger("unsigned")
```

and do something like this instead:

```lua
-- good
local messagepack = require("messagepack")
local mpack = messagepack.new({integer = "unsigned"})
```

- The invocation of require should look like a regular Lua function call, because it is.

```lua
-- bad
local bla = require "bla"

-- good
local bla = require("bla")
```

> **Rationale:** This makes it explicit that require is a function call and not a keyword. Many other languages employ keywords for this purpose, so having a "special syntax" for require would trip up Lua newcomers.

## OOP

- use the `class.lua` library to create classes and objects

```lua
local c = require "libs/class"


--- Create classes ---

-- Create a new class
local MyClass = c.class()

-- Create a child class MyClass2 that inherits from MyClass
local MyClass2 = c.class(MyClass)


--- Special Methods and Attributes ---

--- 0..n parameters
function MyClass:constructor (...)

    -- private Attribute
    -- Note: There is no real protection for private attriubtes, 
    -- except the convention
    self._myAttribute = ...
    -- public Attriubte
    self.myAttribute = ...
end

-- no parameters
function MyClass:destructor () end


--- Methods ---

-- Create a private method
local function privateFunction (self, ...) end

-- Create a public method
--- Note: Omit the self parameter when using the colon notation
function MyClass:publicFunction (...) end -- prefered style
-- or
function MyClass.publicFunction (self, ...)


--- Objects ---

-- Create a new object from MyClass
local obj = MyClass(...) -- prefered style
-- or
local obj = MyClass:new(...)


--- Calling parent methods ---
-- Note: The call to the parent constructor should always be after the parameter validation and before the actual content

self.super("<methodName>", [parameter...])

--- Special case: When calling the parent constructor without parameters
--- the method name can be obmitted
self.super()


--- Check if object is an instance of a class ---

c.instanceOf(obj, class)

```

- Use the method notation when invoking methods:

```lua
-- bad 
myObject.myMethod(myObject)
-- good
myObject:myMethod()
```

> **Rationale:** This makes it explicit that the intent is to use the function as an OOP method.

- Do not rely on the `__gc` metamethod to release resources other than memory. If your object manage resources such as files, add a `close` method to their APIs and do not auto-close via `__gc`. Auto-closing via `__gc` would entice users of your module to not close resources as soon as possible. (Note that the standard `io` library does not follow this recommendation, and users often forget that not closing files immediately can lead to "too many open files" errors when the program runs for a while.)

> **Rationale:** The garbage collector performs automatic _memory_ management, dealing with memory only. There is no guarantees as to when the garbage collector will be invoked, and memory pressure does not correlate to pressure on other resources.

## File structure

- Lua files should be named in all lowercase.

- Lua files should be in a top-level `src` directory. The main library file should be called `modulename.lua`.

- Tests should be in a top-level `test` directory.

- Executables are in `src/bin` directory.
