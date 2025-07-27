# CCME-System

Description:
- simple and smart applied energistics like storage system
- supports inventory and item_storage api
- server/client architecture (one server/ multiple clients) 
- automatic crafting and processing

![System Context - CCME-System](diagrams/ccmesystem_system_context.svg)

## Server

- modulith architecture
- slim kernel with extensibilty in mind

![Component View - CCME-System Server](diagrams/server_component_view.svg)

### Kernel

#### context.lua
- manage modules (require)
- manage threads (spawn, spawnPeripheral)
- manage global state (Config, Items)

**API**
```lua
config: Config
mediator: Mediator

function require(self, module: string|table): table
function spawn(self, func: function)
function spawnPeripheral(self, func: function)
function run(self)
```

#### items.lua
- manage peripherals
- manage items

**API**
```lua
function getItems(self, hash: string): table
function loadPeriperal(self, peripheralName: string)
function unloadPeripheral(self, peripheralName: string)
function insert(self, from: string, fromSlot: number, item: table|number)
function extract(self, toPeripheral: string, hash: string, count: number)
```

**Item**
```lua
<itemhash> = {
	hash = <string>
	count = <int>, -- default 0
	reserved = <int>, -- default 0
	details = {
		displayName = <string>,
		stackSize = <number>,
		tags = {
			[<tagName> = true,]
			...
		},
		-- optional
		[nbt = <string>,]
		[damage = <number>,]
		[maxDamage = <number>,]
		[enchantments = {
			{
				name = <string>,
				displayName = <string>,
				level = <int>,
			},
			[...]
		},]
	},
	locations = {
		[<peripheralName> = <int>,] -- item count
		...
	} -- default {}
}
```
**Legend:**
> - `<...>`     = Placeholder for data with expected data type
> - `[...]`     = optional part
> - `{...}`     = Object, table
> - `...`       = Placeholder for other similar data
> - `-- ...`    = Comment
> - `...|...`   = OR

**Peripheral**
```lua
```lua
<peripheralName> = {
	name = <string> -- peripheralName
	type = lookup{peripheral.getType()},
	priority = <int> -- default 0
	size = <int>|nil,
	remote = <wrappedPeripheral>,
	modificationSeq = <int>,
	lastScan = <int>,
	content = {
		<slotNumber> = { -- if type == inventory else iteration
			hash = <itemHash>,
			count = <int>,
			reserved = <int>,
		},
		...
	}
	itemTypes = nil|{
		<itemHash> = true,
		...
	} -- default nil
}
```
**Legend:**
> - `<...>`     = Placeholder for data with expected data type
> - `[...]`     = optional part
> - `{...}`     = Object, table
> - `...`       = Placeholder for other similar data
> - `-- ...`    = Comment
> - `...|...`   = OR

## Client

### GUI

#### Components
- Pane
- Button
- Select (Dropdown menu)
- Combobox
- Textfield
- Textarea
- TableView
- ListView
- ScrollPane


#### LayoutEngine