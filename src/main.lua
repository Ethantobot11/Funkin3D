require "modules.overrides"

local baton = require "lib.baton"
Timer = require "lib.timer"
state = require "lib.state"
local nest = require("lib.nest").init({ console = "3ds", scale = 1, mode = "720" })

local desktopOS = { "Windows", "Linux", "OS X" }
IS_DESKTOP = false
__DEBUG__ = false

input = nil
audio = {}
graphics = nil
isErect = false
weekData = {}
spriteTimers = {0, 0, 0}
weeks = nil
font, uiFont, uiFont2 = nil, nil, nil

camera = { zoom = 1, toZoom = 1, x = 0, y = 0, zooming = true, locked = false }
uiScale = { zoom = 1, toZoom = 1, x = 0, y = 0 }

love.graphics.setActiveScreen = love.graphics.setActiveScreen or function(s)
	love._activeScreen = s
end

love.graphics.getActiveScreen = love.graphics.getActiveScreen or function()
	return love._activeScreen or "bottom"
end

local function isDesktop()
	local os = love.system.getOS()
	for _, v in ipairs(desktopOS) do
		if v == os then return true end
	end
	return false
end

local function setupInput(desktop)
	local config = {
		uiLeft     = { "axis:leftx-", "button:dpleft" },
		uiRight    = { "axis:leftx+", "button:dpright" },
		uiUp       = { "axis:lefty-", "button:dpup" },
		uiDown     = { "axis:lefty+", "button:dpdown" },
		uiConfirm  = { "button:a" },
		uiBack     = { "button:b" },
		uiErectButton = { "button:back" },

		-- Gameplay
		gameLeft   = { "axis:leftx-", "axis:rightx-", "button:dpleft",  "button:y" },
		gameDown   = { "axis:lefty+", "axis:righty+", "axis:triggerleft+",  "button:dpdown", "button:b" },
		gameUp     = { "axis:lefty-", "axis:righty-", "axis:triggerright+", "button:dpup",   "button:x" },
		gameRight  = { "axis:leftx+", "axis:rightx+", "button:dpright", "button:a" },
	}

	if desktop then
        table.insert(config.uiLeft, "key:left")
        table.insert(config.uiRight, "key:right")
        table.insert(config.uiUp, "key:up")
        table.insert(config.uiDown, "key:down")
        table.insert(config.uiConfirm, "key:return")
        table.insert(config.uiBack, "key:escape")
        table.insert(config.uiErectButton, "key:tab")

        table.insert(config.gameLeft, "key:a")
        table.insert(config.gameLeft, "key:left")
        table.insert(config.gameDown, "key:s")
        table.insert(config.gameDown, "key:down")
        table.insert(config.gameUp, "key:w")
        table.insert(config.gameUp, "key:up")
        table.insert(config.gameRight, "key:d")
        table.insert(config.gameRight, "key:right")
	end

	input = baton.new({
		controls = config,
		joystick = love.joystick.getJoysticks()[1],
	})
end

function love.load()
	if love.graphics.setDefaultFilter then
		love.graphics.setDefaultFilter("nearest", "nearest")
	end

	IS_DESKTOP = isDesktop()
	setupInput(IS_DESKTOP)

	audio.play = function(sound)
		sound:stop()
		sound:play()
	end

	uiConfirm = love.audio.newSource("assets/sounds/confirmMenu.ogg", "static")
	uiBack    = love.audio.newSource("assets/sounds/cancelMenu.ogg", "static")
	uiScroll  = love.audio.newSource("assets/sounds/scrollMenu.ogg", "static")

	-- Load modules
	graphics = require "modules.graphics"

	-- Load weeks
	weekData = {
		require "states.weeks.tutorial",
		require "states.weeks.week1",
		require "states.weeks.week2",
		require "states.weeks.week3",
		require "states.weeks.week4",
		require "states.weeks.week5",
		require "states.weeks.week6"
	}
	weeks = require "states.weeks"

	title       = require "states.menu.title"
	menuSelect  = require "states.menu.menuSelect"
	storyMode   = require "states.menu.storyMode"
	freeplay    = require "states.menu.freeplay"
	debugOffset = require "states.debug.offsets"

	title.music = love.audio.newSource("assets/music/freakyMenu.ogg", "stream")
	title.music:setLooping(true)
	title.music:setVolume(0.5)
	title.music:play()

	font    = love.graphics.newFont("assets/fonts/vcr.ttf", 12)
	uiFont  = love.graphics.newFont("assets/fonts/vcr.ttf", 24)
	uiFont2 = love.graphics.newFont("assets/fonts/vcr.ttf", 18)
	love.graphics.setFont(uiFont)

	state.switch(title)

	graphics.setFade(0)
	graphics.fadeIn(0.5)
end

function love.update(dt)
	dt = math.min(dt, 1 / 30)
	input:update()
	Timer.update(dt)
	state.update(dt)
end

function love.keypressed(k)
	if k == "7" then
		state.switch(debugOffset)
	end
	state.keypressed(k)
	nest.video.keypressed(k)
end

function love.draw(screen)
	graphics.setActiveScreen(screen)
	love.graphics.push()

	if love._console == "Wii U" then
		if screen == "gamepad" then
			love.graphics.scale(2, 2)
			love.graphics.translate(60, 0)
		else
			love.graphics.scale(3, 3)
			love.graphics.translate(12, 0)
		end
	end

	graphics.setColor(1, 1, 1, 1)

	if screen == "bottom" or screen == "gamepad" then
		state.bottomDraw()

		love.graphics.print(
			("FPS: %d\nMemory: %.2fKB"):format(love.timer.getFPS(), collectgarbage("count")),
			0, 190
		)
	else
		state.topDraw()
	end

	love.graphics.pop()
	love.graphics.setColor(1, 1, 1, 1)
end
