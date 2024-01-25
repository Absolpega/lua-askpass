#!/usr/bin/env lua

local function color(str, n)
	return string.format("\027[%dm%s\027[0m", n, str)
end

local prompt = "\027[93mEnter password < $ > \027[0m"

-- https://github.com/sindresorhus/cli-spinners/blob/main/spinners.json
local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

spinner[0] = "⠿"

-- makes all spinner frames cyan
for i = 0, #spinner do
	spinner[i] = color(spinner[i], 96)
end

--[[
Copyright (c) 2024 Absolpega

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- https://stackoverflow.com/a/29857160
local function read_utf8_char(file)
	local c1 = file:read(1)
	local ctr, c = -1, math.max(c1:byte(), 128)
	repeat
		ctr = ctr + 1
		c = (c - 128) * 2
	until c < 128

	-- file:read(0) will still wait for input
	if ctr == 0 then
		return c1
	end

	return c1 .. file:read(ctr)
end

local function strip_ansi_codes(str)
	-- https://stackoverflow.com/a/49209650
	return string.gsub(str, "[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", "")
end

local function ewrite(...)
	io.stderr:write(...)
end

local function ewriteln(...)
	io.stderr:write(... or "", "\n")
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
	ewrite("\027[s", "\r", move_right, frame, "\027[u")
end

local READALL = (_VERSION < "Lua 5.3") and "*a" or "a"

local saved_term = io.popen("stty -g"):read(READALL)

os.execute("stty -isig -icanon -echo")

ewrite(prompt)

local password = {}
-- draw spinner before waiting for input
spin(0)
while true do
	local char = read_utf8_char(io.input())
	if char == "\n" or char == string.char(3) then
		break
	elseif char == "\127" then
		if table.remove(password) then
			ewrite("\b \b")
			spin(-1)
		end
		if #password == 0 then
			spin(0)
		end
	else
		table.insert(password, char)
		ewrite("*")
		spin(1)
	end
end

spin(0)
ewriteln()

print(table.concat(password))

os.execute("stty " .. saved_term)
