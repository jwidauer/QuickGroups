local _, addon = ...

local colors = addon.new_module("colors")

colors.blue = "|cff4287f5";
colors.reset = "|r";

function colors:colorise_string(str, color)
    return self[color] .. tostring(str) .. self.reset;
end
