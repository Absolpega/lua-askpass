#!/usr/bin/env lua

local function color(str, n)
    return string.format("\027[%dm%s\027[0m", n, str)
end

local prompt = "\027[93mEnter password < $ > \027[0m"

-- https://github.com/sindresorhus/cli-spinners/blob/main/spinners.json
local spinner =
    { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

spinner[0] = "⠿"

-- makes all spinner frames cyan
-- including 0
for i = 0, #spinner do
    spinner[i] = color(spinner[i], 96)
end

--[[
Copyright (c) 2024 Absolpega

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]

local stty = "stty "

local input = io.open("/dev/tty", "w+")
local output
if input then
    output = input
    stty = stty .. "-F /dev/tty "
else
    input = io.stdin
    output = io.stderr
end

-- https://stackoverflow.com/a/29857160
local function read_utf8_char()
    local c1 = input:read(1)
    local ctr, c = -1, math.max(c1:byte(), 128)
    repeat
        ctr = ctr + 1
        c = (c - 128) * 2
    until c < 128

    -- file:read(0) will still wait for input
    if ctr == 0 then
        return c1
    end

    return c1 .. input:read(ctr)
end

local function strip_ansi_codes(str)
    -- https://stackoverflow.com/a/49209650
    return string.gsub(str, "[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", "")
end

local function write(...)
    output:write(...)
end

local prompt_spinner_position = strip_ansi_codes(prompt):find("[$]")
local idx = 1

local function spin(inc)
    idx = ((idx - 1 + inc) % #spinner) + 1
    local frame = spinner[idx]
    if inc == 0 then
        frame = spinner[0]
    end
    local move_right = string.format("\027[%dC", prompt_spinner_position - 1)
    write("\027[s", "\r", move_right, frame, "\027[u")
end

local READALL = (_VERSION < "Lua 5.3") and "*a" or "a"

local saved_term = io.popen(stty .. "-g"):read(READALL)

os.execute(stty .. "-isig -icanon -echo")

write(prompt)

local password = {}
-- draw spinner before waiting for input
spin(0)
while true do
    local char = read_utf8_char()
    if char == "\n" or char == "\003" then
        break
    elseif char == "\127" then
        if table.remove(password) then
            write("\b \b")
            spin(-1)
        end
        if #password == 0 then
            spin(0)
        end
    else
        table.insert(password, char)
        write("*")
        spin(1)
    end
end

spin(0)
write("\n")

print(table.concat(password))

os.execute(stty .. saved_term)
