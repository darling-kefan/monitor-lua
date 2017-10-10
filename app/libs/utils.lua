local type  = type
local pairs = pairs
local s_rep = string.rep
local s_sub = string.sub
local s_byte = string.byte
local s_find = string.find
local s_insert = string.insert
local t_insert = table.insert
local t_concat = table.concat

local _M = {}

function _M.is_empty_table(t)
    if t == nil or _G.next(t) == nil then
        return true
    else
        return false
    end
end

function _M.is_array(t)
    if (type(t) ~= "table") then return false end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

function _M.in_array(d, t)
    if not t then return false end
    for _, v in pairs(t) do
        if v == tonumber(d) then return true end
    end
    return false
end

function _M.explode(d, s)
    local t, i
    t = {}
    i = 0
    if #s == 1 then return {s} end
    while true do
        local m, n = s_find(s, d, i, true)
        if m ~= nil then
            t_insert(t, s_sub(s, i, m - 1))
        else
            t_insert(t, s_sub(s, i))
            break
        end
        i = n + 1
    end
    return t
end

function _M.str_pad(input, pad_length, pad_string, pad_type)
    if (input == nil) then return nil end
    if (#input >= pad_length) then return input end
    if (pad_string == nil or #pad_string < 1) then pad_string = ' ' end

    local string, pad, pad_string_num
    string = input
    pad_string_num = math.floor((pad_length - #input) / #pad_string)
    if (pad_type == nil or tonumber(pad_type) == 0) then -- string pad right
        pad = s_rep(pad_string, pad_string_num)
        string = string .. pad
    elseif (tonumber(pad_type) == 1) then -- string pad left
        pad = s_rep(pad_string, pad_string_num)
        string = pad .. string
    elseif (tonumber(pad_type) == 2) then -- string pad both
        local pieces = {input}
        local i = 0
        while true do
            if (math.modf(i / 2) == 1) then
                t_insert(pieces, 1, pad_string)
            else
                t_insert(pieces, pad_string)
            end
            i = i + 1
            if (i >= pad_string_num) then break end
        end
        string = t_concat(pieces)
    end

    return string
end

function _M.chsize(char)
    if not char then
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end

function _M:utf8mblen(str)
    if not str then return nil end
    if str == '' then return 0 end

    local index = 1
    local count = 0
    while index <= #str do
        local char = s_byte(str, index)
        index = index + self.chsize(char)
        count = count + 1
    end
    return count
end

function _M:utf8sub(str, startChar, numChars)
    if not str and not startChar and not numChars then
        return nil
    end

    local startIndex = 1
    while startChar > 1 do
        local char = s_byte(str, startIndex)
        startIndex = startIndex + self.chsize(char)
        startChar = startChar - 1
    end

    local currentIndex = startIndex

    while numChars > 0 and currentIndex <= #str do
        local char = s_byte(str, currentIndex)
        currentIndex = currentIndex + self.chsize(char)
        numChars = numChars - 1
    end

    return s_sub(str, startIndex, currentIndex - 1)
end

return _M
