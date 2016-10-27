local _G = _G
local table = table
local file = file
local string = string
local package = package
local node = node
local pcall = pcall
local assert = assert
local loadstring = loadstring
local loadfile = loadfile
local collectgarbage = collectgarbage
local setmetatable = setmetatable
local setfenv = setfenv
local unpack = unpack
local pairs = pairs
local ipairs = ipairs
local type = type
local f = f
--for debug purposes
local print = print

module("softmodule")


local function dumpfunction(modulename, funcname)
	local capture = false
	local parseok = false
	local src = nil
	
	file.open(modulename..".lua", "r")
	while true do
		local line = file.readline()
		if line == nil then
			break
		end
		if capture then
			table.insert(src, line)
			local functxt = table.concat(src)
			f = loadstring(functxt)
			functxt = nil
			parseok = pcall(f)
			if parseok then
				break
			end
		else
			local match = string.match(line, "function +([a-zA-Z0-9_%.]+) *%(")
			if match == funcname then
				src = { line }
				capture = true
			end
		end
	end
	file.close()

	if parseok then
		local filename = modulename.."."..funcname..".lua"
		file.open(filename, "w")
		file.writeline("modulename = ...")
		file.writeline("require(modulename)") --don't reload functions already deleted, because cached
		file.writeline("package.seeall(package.loaded[modulename])")
		file.writeline("setfenv(1, package.loaded[modulename])")
		file.writeline("")
		local line1st = true
		for i, line in ipairs(src) do
			if line1st then
				file.write(string.gsub(line, funcname, funcname..".func"))
				line1st = false
			else
				file.write(line)
			end
		end
		file.close()
		node.compile(filename)
		file.remove(filename)
	end
	
	return parseok
end

local function callFlushedFunc(modulename, funcname, ...)
	local modl = package.loaded[modulename]
	modl[funcname].func = nil
	assert(loadfile(modulename.."."..funcname..".lc"))(modulename) --load function stored on file as module.function.func()
	local res = { modl[funcname].func(...) } --call original function
	modl[funcname].func = nil --delete from memory function just executed
	collectgarbage() --assure that gc is called to flush function RAM
	return unpack(res)
end

local function callCachedFunc(modulename, funcname, ...)
	local modl = package.loaded[modulename]
	if modl[funcname].func == nil then
		--cache function once
		assert(loadfile(modulename.."."..funcname..".lc"))(modulename) --load function stored on file as module.function.f()
	end
	local res = { modl[funcname].func(...) }
	return unpack(res)
end

function injectFlushedCall(modulename, funcname, gencode)
	if gencode then
		dumpfunction(modulename, funcname)
	end
	local modl = package.loaded[modulename]
	modl[funcname] = {} --delete function and free RAM
	collectgarbage() --definitively flush function code from RAM
	local mt = {}
	mt.__call = function(t, ...) return callFlushedFunc(modulename, funcname, ...) end
	setmetatable(modl[funcname], mt)
end

function injectCachedCall(modulename, funcname, gencode)
	if gencode then
		dumpfunction(modulename, funcname)
	end
	local modl = package.loaded[modulename]
	modl[funcname] = {} --delete function and free RAM
	collectgarbage() --definitively flush function code from RAM
	local mt = {}
	mt.__call = function(t, ...) return callCachedFunc(modulename, funcname, ...) end
	setmetatable(modl[funcname], mt)
end

-- return a table with function names
function getModuleFunctions(modl)
	local funclist = {}

	for k, v in pairs(modl) do
		if type(v) == "function" then
			table.insert(funclist, k)
		end
	end
	
	return funclist
end

-- unload specified module entirely
function unloadModule(modname)
	package.loaded[modname] = nil
	_G[modname] = nil
end
