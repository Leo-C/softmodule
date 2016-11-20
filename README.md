## Softmodule


### Introduction

**Softmodule** module in Lua is designed to overcome RAM limits on ESP8266 with [NodeMCU firmware](https://nodemcu.readthedocs.io/en/master/en/build/) (about 45 kB for [ESP-12E](http://www.esp8266.com/wiki/doku.php?id=esp8266-module-family#esp-12) after at start after Lua interpreter load)

In Lua all module's functions are objects retained in memory that consume RAM; various tecniques are available to discard a function code after use, e.g.:

  * [how-do-i-minimise-the-footprint-of-running-application](https://nodemcu.readthedocs.io/en/dev/en/lua-developer-faq/#how-do-i-minimise-the-footprint-of-running-application)
  * [flashmodule](http://www.esp8266.com/viewtopic.php?f=19&t=1940)
  * [volatile modules](http://www.esp8266.com/viewtopic.php?f=24&t=3311&start=10)

Some tecnique (like load a function from a file and execute it *on-the-fly* causing unload after return) are useful for a single exposed function in a file;
others (like *volatile modules*) are applicable to *all* function for a module, loading or unloading entire module:
none of these are applicable to *each* function of a module.

The drawback of all this tecniques is that are not transparent for end-user, if he want simply write a standard module but optimize RAM during it's use.


### Then: **Softmodule**!

*Softmodule* offer a simple tecnique to *inject* a small stub that load (and optionally unload) function code only when needed.  
**This is done transparently on module's functions.**  

Two modes are disposable:

  1. **load-and-discard**: in this case function code is loaded from a .lc file and flushed away after use  
  2. **load-and-retain**: this is a caching tecnique that loads code at 1st use and cache it, with a small overhead from 2nd call

2nd mode is similar to static linking of libraries in  of object files to produce executable file , saving space on executable file (and RAM when executable is loaded)


### API

5 functions permit to optimize RAM used by module's functions:

  * `dumpfunction(modulename, funcname)`  
  -- *modulename* is string name of a module  
  -- *funcname* is string name of a function of module *modulename*  
Extract function *funcname* from file *`modulename`*`.lua` to store it (precompiled) on file *`modulename`*.*`funcname`*`.lc` for subsequent use
  ---
  * `injectFlushedCall(modulename, funcname, gencode)`:  
  -- *modulename* is string name of a module  
  -- *funcname* is string name of a function of module *modulename*  
  -- if *gencode* is specified and is true, then `dumpfunction()` is called with specified *modulename* and *funcname*  
After this call function *funcname* of module *modulename* is loaded from file *`modulename`*.*`funcname`*`.lc` before execution and flushed away after execution.  
BTW execution is slow than before cause loading of code.
  ---
  * `injectCachedCall(modulename, funcname, gencode)`  
  -- *modulename* is string name of a module  
  -- *funcname* is string name of a function of module *modulename*  
  -- if *gencode* is is specified and is true, then `dumpfunction()` is called with specified *modulename* and *funcname*  
After this call function *funcname* of module *modulename* is loaded from file *`modulename`*.*`funcname`*`.lc` before 1st execution and retained; in subsequent call function is reloaded from cache.  
BTW 1st execution is slow than before, but from 2nd call, execution time is fast than before; a little overhead of memory is required for added code that handle code cache.  
The advantage is significant if this function is applied to many function of a module and few of them are recalled (caching few function over total).
  ---
  * `getModuleFunctions(modl)`  
  -- *modl* is a module symbol  
Return a list with all functions contained in module *modl*. Are returned only function that are not already *injected* calling `injectFlushedCall()` or `injectCachedCall()`.  
Useful to apply `injectFlushedCall()` or `injectCachedCall()` to all functions of a module.
  ---
  * `unloadModule(modulename)`  
  -- *modulename* is string name of a module  
Unload entire module *modulename*: all functions and all root module objects (variables, constants, etc.) 


### Internals

Main steps to handle dynamic call are:  

  * extract code for function *f* from original source  
    * `dumpfunction(f)` -> `module.f.lc`
  * substitute a module function with an empty table  
    * `f = nil`
    * `f = {}`
  * registering a metatable with method `__call()` to intercept call of original function and handle load of `.lc` file
    * `mt = { __call = function()` *< load-and-call code >* `end }`
    * `setmetatable(f, mt}`
  * Optionally (calling `injectCachedCall()`) function is cached into `.func` field of table substituted to original function  
    * `f.func = function() original_function() end`
