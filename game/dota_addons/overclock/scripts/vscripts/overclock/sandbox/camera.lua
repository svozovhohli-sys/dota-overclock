--[[
	OVERCLOCK :: sandbox/camera.lua
	Free camera + focus helpers. Server side sets the camera targets; the
	Panorama layer toggles the built-in free camera dolly via console commands.
--]]
local State = require("overclock.core.state")
local Config = require("overclock.core.config")
local Players = require("overclock.core.players")
local Events = require("overclock.core.events")
local Log = require("overclock.core.logger")

local M = {}

function M.set_free(on)
	State.debug.free_camera = on and true or false
	SendToServerConsole(on and "dota_camera_force_free 1" or "dota_camera_force_free 0")
	SendToServerConsole(on and "dota_camera_disable_zoom 0" or "dota_camera_disable_zoom 1")
	Events.emit("camera:free", State.debug.free_camera)
	Log.info("free camera = %s", tostring(State.debug.free_camera))
	return State.debug.free_camera
end

function M.toggle_free()
	return M.set_free(not State.debug.free_camera)
end

-- Focus the player's camera on a world position.
function M.focus(pid, position)
	local hero = Players.hero_of(pid)
	if hero then
		PlayerResource:SetCameraTarget(pid, hero)
	end
	-- Custom games expose SetCameraTarget on PlayerResource; a raw entity
	-- target works via a temporary dummy when the hero should not move.
	return true
end

function M.focus_entity(pid, entity)
	if entity and IsValidEntity(entity) then
		PlayerResource:SetCameraTarget(pid, entity)
		return true
	end
	return false
end

function M.release(pid)
	PlayerResource:SetCameraTarget(pid, nil)
	return true
end

-- Move the camera to an absolute point (reuses the oc dummy as a proxy).
function M.move_to(pid, position)
	local proxy = CreateUnitByName(Config.DUMMY_UNIT, position, false,
		nil, nil, DOTA_TEAM_NEUTRALS)
	if proxy then
		PlayerResource:SetCameraTarget(pid, proxy)
		proxy:SetModelScale(0.01)
		proxy:AddNoDraw()
	end
	return true
end

return M
