#!/usr/bin/env lua

if arg[1] then
    package.path = arg[1] .. "/?.lua;" .. package.path
end

if arg[2] then
    dofile(arg[2])
else
    error("No file to run")
end
