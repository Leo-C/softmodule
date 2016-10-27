require "modtest"
require "softmodule"


print("## Std func tests ##\n")

r = modtest.printnum(5)
print("Test #1.1 (output std func): ", r, "\n")

print("Test #1.2 (std func type): ", modtest.printnum, "\n")

pu = package.loaded["modtest"]
print("Test #1.3 (func type from package struct): ", pu["printnum"], "\n")

print("Test #1.4 (complete list of functions)\n")
for i, f in ipairs(softmodule.getModuleFunctions(modtest)) do
	print(f, "\n")
end

print("Test #1.5 (std heap use): ", node.heap(), "\n")

softmodule.injectFlushedCall("modtest", "printnum", true)
--softmodule.injectCachedCall("modtest", "printnum", true)


print("## Post injection dynamic func tests ##\n")

print("Test #2.5 (post injection heap use): ", node.heap(), "\n")

print("Test #2.1 (injected func type): ", modtest.printnum, "\n")

print("Test #2.2 (post func struct): ", modtest.printnum["func"], "\n")

r = modtest.printnum(7)
print("Test #2.3 (output post func): ", r, "\n")

print("Test #2.4 (complete list of functions)\n")
for i, f in ipairs(softmodule.getModuleFunctions(modtest)) do
	print(f, "\n")
end

print("Test #2.5 (func type from package struct): ", modtest.printnum["func"], "\n")

print("Test #3.1 (heap use): ", node.heap(), "\n")

softmodule.unloadModule(modtest)

print("Test #3.2 (clean heap use): ", node.heap(), "\n")
