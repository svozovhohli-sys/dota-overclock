--[[
	OVERCLOCK :: core/events.lua
	Central event bus.

	Two kinds of subscriptions:
	  * game events  -> engine `ListenToGameEvent`
	  * custom events -> internal OC.Events.emit("foo", payload)  (server side)

	Modules talk to each other through the internal bus so they never depend on
	each other directly.
--]]
local M = {}

M.game_subs = {}    -- event_name -> { fn, ... }
M.custom_subs = {}  -- topic -> { fn, ... }
M.registered = {}   -- event_name -> true (already ListenToGameEvent'd)

local function dispatch_game(event_name, data)
	local subs = M.game_subs[event_name]
	if not subs then return end
	for _, fn in ipairs(subs) do
		local ok, err = pcall(fn, data)
		if not ok then
			print(string.format("[OVERCLOCK][ERROR] game event '%s' handler: %s",
				event_name, tostring(err)))
		end
	end
end

-- Subscribe to an engine game event. Calls ListenToGameEvent lazily/once.
function M.on(game_event, fn)
	M.game_subs[game_event] = M.game_subs[game_event] or {}
	table.insert(M.game_subs[game_event], fn)
	if not M.registered[game_event] then
		ListenToGameEvent(game_event, function(data)
			dispatch_game(game_event, data)
		end, nil)
		M.registered[game_event] = true
	end
	return fn
end

-- Subscribe to an internal topic.
function M.subscribe(topic, fn)
	M.custom_subs[topic] = M.custom_subs[topic] or {}
	table.insert(M.custom_subs[topic], fn)
	return fn
end

-- Publish an internal topic (server-side only).
function M.emit(topic, payload)
	local subs = M.custom_subs[topic]
	if not subs then return end
	for _, fn in ipairs(subs) do
		local ok, err = pcall(fn, payload)
		if not ok then
			print(string.format("[OVERCLOCK][ERROR] topic '%s' handler: %s",
				topic, tostring(err)))
		end
	end
end

function M.clear()
	M.game_subs = {}
	M.custom_subs = {}
end

return M
