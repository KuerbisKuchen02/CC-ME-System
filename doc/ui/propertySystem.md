# Property System

> The system is inspired by the property system from the [basalt library](https://github.com/Pyroxenium/Basalt2)

The property system allows classes to define properties.
A property is a simple value field that can hava a custom setter and getter.
The property system also provides type safety with build in validation and type checks.
All properties can also be observed using a callback function.

## Properties

To mange properties the system provides a set of methods:

- `defineProperty(name, config)`
- `removeProperty(name)`
- `combinePropery(name, ...)`
- `set(name, value)`
- `get(name)`

With the define Methode a new property is created.
The name is the key used to access the property.
When you only provide a name the property just behaves like a normal table field.
The config parameter is used to configure advanced features. For detailed inforamtion see the [Config chapter](#config).

### Combined Properties

A combined property is an easy way to access or manipulate multiple properties using a single function call.
To combine multiple properties use the `combineProperty()` function.
Which takes a name for the combined property and the names of the individual properties which should be combined.

> [!NOTE]
> Internally the combined properties are just handled as a simple property with a getter and setter that invokes the getters and setters from all individual properties and returning all values.

**Example**:

```lua
clazz:defineProperty("x", {type=PropertyClass.Type.NUMBER})
clazz:defineProperty("y", {type=PropertyClass.Type.NUMBER})
clazz:combineProperties("position", "x", "y")
```

### Config

With the config parameter you can configure all additional features.
The config consists of following optional fields:

- `type`
- `default`
- `canTriggerRender`
- `allowNil`
- `getter`
- `setter`
- `observers`

#### Type

**Type**: `PropertyClass.Type` <br>
**Default value**: `nil` (type checks deactivated)

If the `type` parameter is set, the type safety system is activated.
The type field can be easily set using the `PropertyClass.Type` enum.

Following options are supported:

- STRING
- NUMBER
- BOOLEAN
- NIL
- TABLE
- FUNCTION

> [!IMPORTANT]
> The value `PropertyClass.Type.NIL` is not equivalent to `nil`<br>
> While `nil` deactivates the system, `PropertyClass.Type.NIL` checks if the value is set to `nil` and only nil.

#### Default

**Type**: `any` (must match type parameter) <br>
**Default value**: `nil` (no inital value)

The `default` field can be used to set a default value for a property.
This value is used to initialize this property if no other value is provided.

> [!IMPORTANT]
> If the `type` parameter is set, the default value MUST also follow the type rules

#### CanTriggerRender

**Type**: `boolean` <br>
**Default value**: `false` (no automatic rerender)

If the `canTriggerRender` field is set to `true`, a value change autmatically triggers a rerender of the layout to reflect the changes in the UI.

#### AllowNil

**Type**: `true` <br>
**Default value**: `false` (no nil safety)

If set to `true`, a value can only be set to an actual value that satisfies the `type` parameter.

#### Getter

**Type**: `fun(self: gui.properties.PropertyClass, value: any, ...): ...` <br>
**Default value**: `nil` (no custom getter)

The `getter` is invoked whenever a value is read in any way. The getter function is invoked with a reference to the calling object and the value of the property. The getter MAY manipulate the value in any way or do other things. The function MUST return the final value.

> IMPORTANT
> The `getter` MUST return a value that matches the specified `type`.

#### Setter

**Type**: `fun(self: gui.properties.PropertyClass, value: any, ...): ...` <br>
**Default value**: `nil` (no custom setter)

The `setter` is invoked whenever a value is set in any way.
The setter function is invoked with a reference to the calling object and the new value of the property.
The setter MAY manipulate the value in any way or do other things. The function MUSt return the final value.

> IMPORTANT
> The `setter` MUST return a value that matches the specified `type`.

#### Observers

**Type**: `fun(self: gui.properties.PropertyClass, newValue: T, oldValue: T)[]` <br>
**Default value**: `{}` (no observer)

The `observer` paramter MAY be used to set up observers on initalization.
An observer is just a callback function that is called whenever the value of the property changes.
Observers can also be set and removed later using the observer functions (see chapter [observer](#observer) for more detail).

## Access

A property can be a accessed using one of two way:

1. Using the access functions `set()` and `get()`
2. Using the "normal" field access clazz.myProperty

The access functions ensure type and nil safety, calls observers and hooks.

> [!NOTE]
> Both methods provide the same functionallity since the second option calls the `set()` and `get()` functions internally

## Observer

A observer is a callback function that is invoked when the value of the property changes.

To manage observers the system provides a few functions:

- `addObserver(name, callback)`
- `removeObserver(name, callback)`
- `removeAllObservers(name)`

Multiple observers MAY watch a single property.
The callback function is invoked with a reference of the calling object, the new value and the old value of the property.
The function SHOULD NOT return anything because this value would be discarded anyway.
The observers are called after the hook calls and safety checks. If a check fails the observer are not invoked.

## Setter Hooks

A `setterHook` is a special setter function that is invoked for every property.

**Type**: `fun(self: gui.properties.PropertyClass, property: string, value: T): T`

The function is invoked with a reference to the calling object, the property name and the new value.
The setterHook MUST return a value that matches the specified `type`.

> [!IMPORTANT]
> The setterHooks are invoked BEFORE the actual setters and BEFORE the type and nil checks. So the value passed to a setter hook MAY have a different type than configured.<br>
> Hooks MUST always be called, even if the set later fails.

## Functions as values

The property system has a special feature that allows to set a producer function as the value of a property with a type other than function. If the property is read, the producer function will be invoked and the return value is returned. This allows to dynamically set values.

> [!IMPORTANT]
> The return type of the producer function MUST match the configured type of the property

**Example:**

```lua
element.bgColor = function () return element.status and color.green or color.red end
```

## Usage

```lua
local PropertyClass = require("ccmesystem.lib.gui.properties")

-- Class that inherits the property system class
local MyClass = class.class(PropertyClass)

-- Define a new property
MyClass:defineProperty("myProperty", {
    type = PropertyClass.Type.STRING,
    default = "default value",
    canTriggerRender = true,
    allowNil = false,
    getter = function(self, value)
        return value:upper() -- custom getter that returns the value in uppercase
    end,
    setter = function(self, value)
        return value:lower() -- custom setter that converts the value to lowercase
    end,
    observers = {
        function(self, oldValue, newValue)
            log.info("Property myProperty changed from %s to %s", oldValue, newValue)
        end
    }
})

-- Accessing the property
local myObject = MyClass()
myObject.myProperty = "Hello World" -- This will trigger the setter and observer
local value = myObject.myProperty -- This will trigger the getter
log.info("Value of myProperty: %s", value) -- This will print "Value of myProperty: HELLO WORLD"
```
