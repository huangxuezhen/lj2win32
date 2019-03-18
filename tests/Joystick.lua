
local ffi = require("ffi")
local C = ffi.C

require("win32.windef") -- to pickup HWND

local joystickapi = require("win32.joystickapi")

local Joystick = {}
setmetatable(Joystick, {
    __call = function(self, ...)
        return self:new(...)
    end
})
local Joystick_mt = {
    __index = Joystick
}

function Joystick.init(self, id)
    local obj = {
        ID = id;
        info = ffi.new("JOYINFOEX")
    }
    obj.info.dwSize = ffi.sizeof("JOYINFOEX")

    setmetatable(obj, Joystick_mt)

    obj.caps = obj:getCapabilities()

    return obj
end

function Joystick.new(self, id)
    return self:init(id)
end

-- An enumeration of attached joysticks
function Joystick:sticks()
    local function enumerator()
        local numDevs = joystickapi.joyGetNumDevs();
        local pji = ffi.new("JOYINFO")

        for i = 0, numDevs-1 do
            -- use getting the position to determine if
            -- the joystick is connected
            local result = joystickapi.joyGetPos(i, pji)


            if result == C.JOYERR_NOERROR then
                local joy = Joystick(i)
                coroutine.yield(joy)
            end
        end
    end

    return coroutine.wrap(enumerator)
end


function Joystick.getCapabilities(self, res)

    local res = res or {}
    local pjc = ffi.new("JOYCAPSA")
    local cbjc = ffi.sizeof("JOYCAPSA")

    local result = joystickapi.joyGetDevCapsA(self.ID, pjc, cbjc);
    if result ~= 0 then
        return false, result
    end

    res.Mid = pjc.wMid;
    res.Pid = pjc.wPid;
    res.name = ffi.string(pjc.szPname)  -- MAXPNAMELEN
    res.xMin = pjc.wXmin;
    res.xMax = pjc.wXmax;
    res.yMin = pjc.wYmin;
    res.yMax = pjc.wYmax;
    res.zMin = pjc.wZmin;
    res.zMax = pjc.wZmax;
    res.numButtons = pjc.wNumButtons;
    res.periodMin = pjc.wPeriodMin;
    res.periodMax = pjc.wPeriodMax;
    res.rMin = pjc.wRmin;
    res.rMax = pjc.wRmax;
    res.uMin = pjc.wUmin;
    res.uMax = pjc.wUmax;
    res.vMin = pjc.wVmin;
    res.vMax = pjc.wVmax;
    res.caps = pjc.wCaps;
    res.maxAxes = pjc.wMaxAxes;
    res.numAxes = pjc.wNumAxes;
    res.maxButtons = pjc.wMaxButtons;
    res.regKey = ffi.string(pjc.szRegKey);
    res.OEMVxD = ffi.string(pjc.szOEMVxD);

    return res
end

function Joystick.getPosition(self, res)
    local res = res or {}

    self.info.dwFlags = C.JOY_RETURNALL

    local result = joystickapi.joyGetPosEx(self.ID, self.info)
    if result ~= 0 then
        return false, result
    end

    res.x = self.info.dwXpos;
    res.y = self.info.dwYpos;
    res.z = self.info.dwZpos;
    res.r = self.info.dwRpos;
    res.u = self.info.dwUpos;
    res.v = self.info.dwVpos;
    
    res.buttons = self.info.dwButtons;

    return res;
end


return Joystick