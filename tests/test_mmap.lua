package.path = "../?.lua;"..package.path;

local ffi = require("ffi")

mmap = require("mmap")

local afile = mmap("textfile.txt")


local map = afile:getPointer();
print("FILE")
print(ffi.string(map, #afile))