local print = print
local tostring = tostring
module("modtest")

GLOB = -1

function printnum(num)
    print("num = ", num ,"\n")
    return "printed "..tostring(num)
end

function printhello()
	print("Hello!\n")
	return true
end
