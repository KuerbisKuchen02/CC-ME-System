#!/usr/bin/env lua

local context = require("ccmesystem")()

-- include custom modules here:
-- e.g. context:require("example.yourmodule")

context.config:save()

context:run()