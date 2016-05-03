System = {}
System.kernel = {}
System.kernel.driver = {}
System.kernel.info = {id="smart-kernel",name = "Smart Kernel",release="0.0.1-alpha"}
System.user = {}
System.user.boot = "/boot/main.lua"
--
function System.kernel.driver.mountDeviceList(tipe, _exam)
  local obj = {}
  for addr in component.list(tipe,_exam) do
    table.insert(obj,component.proxy(addr))
  end
  if #obj > 0 then
    System.kernel.driver[tipe] = obj
    return obj
  else
    return nil
  end
end

function System.user.launch(address,path)
  local obj = component.proxy(address)
  local file = obj.open(path,"r")
  local temp = obj.read(file,obj.size(path))
  assert(load(temp))()
end
--

local gpu = System.kernel.driver.mountDeviceList("gpu")
local screen = System.kernel.driver.mountDeviceList("screen",1)
local kb = System.kernel.driver.mountDeviceList("keyboard",1)

if #gpu == 0 and #screen == 0 then
  error("Присоедините видеокарту и монитор, затем перезагрузите.")
end

local GPU = gpu[1]
local Screen = screen[1]
GPU.bind(Screen.address)
local x,y = GPU.maxResolution()
GPU.setResolution(x,y)
GPU.setDepth(GPU.maxDepth())
GPU.setBackground(0)
GPU.setForeground(0xffffff)
GPU.fill(1,1,x,y,' ')

local fs = System.kernel.driver.mountDeviceList("filesystem")
local RootFS = nil

for i in pairs(fs) do
  if fs[i].exists(System.user.boot) then
    RootFS = fs[i]
    break
  end
end

System.kernel.driver.root = RootFS

local s = {"Smart Kernel 0.0.1","by MrConstructor303"}

GPU.set(math.floor((x-unicode.len(s[1]))/2),math.floor(y/2)-1,s[1])
GPU.set(math.floor((x-unicode.len(s[2]))/2),math.floor(y/2)+1,s[2])
GPU.fill(1,y,x,1,'.')
for i = 1,x do
  computer.pullSignal(0.05)
  GPU.set(i,y,'|')
end
computer.beep()
GPU.fill(1,1,x,y,' ')
if not RootFS then
  error("Вставьте загрузочный диск!")
end

System.user.launch(RootFS.address,System.user.boot)