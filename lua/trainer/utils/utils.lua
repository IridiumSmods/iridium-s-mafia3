----------------------------
-- First Letter Uppercase --
----------------------------
function FirstToUpper(str : string)
    return (str:gsub("^%l", string.upper))
end

local function titleCase( first, rest )
   return first:upper()..rest:lower()
end

function FirstLettersToUpper(str : string)
	return string.gsub(str, "(%a)(%w*)", titleCase)
end