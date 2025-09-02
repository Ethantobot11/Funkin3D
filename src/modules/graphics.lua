--[[----------------------------------------------------------------------------
This file is part of Friday Night Funkin' Rewritten

Refactored for better readability and structure.
------------------------------------------------------------------------------]]

local graphics = {}

local imageType = "png"
local fade = {1}
local isFading = false
local fadeTimer

local screenWidth, screenHeight

function graphics.screenBase(width, height)
	screenWidth, screenHeight = width, height
end

function graphics.getWidth()
	return screenWidth
end

function graphics.getHeight()
	return screenHeight
end

function graphics.imagePath(path)
	return "assets/images/" .. path .. "." .. imageType
end

function graphics.setImageType(type)
	imageType = type
end

function graphics.getImageType()
	return imageType
end

function graphics.getActiveScreen()
	return graphics.activeScreen
end

function graphics.setActiveScreen(s)
	graphics.activeScreen = s
end

function graphics.screenDepth(screen)
	local depth = screen ~= "bottom" and -love.graphics.getDepth() or 0
	if screen == "right" then
		depth = -depth
	end
	return depth
end

function graphics.setFade(value)
	if fadeTimer then Timer.cancel(fadeTimer) end
	isFading = false
	fade[1] = value
end

function graphics.getFade()
	return fade[1]
end

function graphics.fadeOut(duration, func)
	if fadeTimer then Timer.cancel(fadeTimer) end
	isFading = true
	fadeTimer = Timer.tween(duration, fade, {0}, "linear", function()
		isFading = false
		if func then func() end
	end)
end

function graphics.fadeIn(duration, func)
	if fadeTimer then Timer.cancel(fadeTimer) end
	isFading = true
	fadeTimer = Timer.tween(duration, fade, {1}, "linear", function()
		isFading = false
		if func then func() end
	end)
end

function graphics.isFading()
	return isFading
end

function graphics.clear(r, g, b, a, s, d)
	local f = fade[1]
	love.graphics.clear(f * r, f * g, f * b, a, s, d)
end

function graphics.setColor(r, g, b, a)
	local f = fade[1]
	love.graphics.setColor(f * r, f * g, f * b, a)
end

function graphics.setBackgroundColor(r, g, b, a)
	local f = fade[1]
	love.graphics.setBackgroundColor(f * r, f * g, f * b, a)
end

function graphics.getColor()
	local r, g, b, a = love.graphics.getColor()
	local f = fade[1]
	return r / f, g / f, b / f, a
end

function graphics.newImage(imageData, optionsTable)
	local image, width, height

	local object = {
		x = 0, y = 0,
		orientation = 0,
		sizeX = 1, sizeY = 1,
		offsetX = 0, offsetY = 0,
		shearX = 0, shearY = 0,
		alpha = 1,
		color = {1, 1, 1},
		depth = 0,

		setImage = function(self, img)
			image = type(img) == "string" and love.graphics.newImage(img) or img
			width, height = image:getWidth(), image:getHeight()
		end,

		getImage = function() return image end,

		draw = function(self)
			local x, y = self.x, self.y
			local color = {love.graphics.getColor()}
			if optionsTable and optionsTable.floored then
				x, y = math.floor(x), math.floor(y)
			end
			love.graphics.setColor(
				self.color[1] * color[1],
				self.color[2] * color[2],
				self.color[3] * color[3],
				self.alpha * color[4]
			)
			love.graphics.draw(
				image,
				self.x - (graphics.screenDepth(graphics.getActiveScreen()) * self.depth),
				self.y,
				self.orientation,
				self.sizeX,
				self.sizeY,
				math.floor(width / 2) + self.offsetX,
				math.floor(height / 2) + self.offsetY,
				self.shearX,
				self.shearY
			)
			love.graphics.setColor(color)
		end,

		release = function(self)
			image:release()
		end
	}

	object:setImage(imageData)
	return object
end

function graphics.newSprite(imageData, frameData, animData, animName, loopAnim, optionsTable)
	local sheet, sheetWidth, sheetHeight
	local frames = {}
	local anim = {}
	local frame, isAnimated, isLooped
	local options = optionsTable

	local object = {
		x = 0, y = 0,
		orientation = 0,
		sizeX = 1, sizeY = 1,
		offsetX = 0, offsetY = 0,
		shearX = 0, shearY = 0,
		alpha = 1,
		color = {1, 1, 1},
		secondary = optionsTable and optionsTable.secondary or nil,
		depth = 0,

		setSheet = function(self, data)
			sheet = data
			--if sheet.setWrap then sheet:setWrap("clampzero", "clampzero") end
			sheetWidth, sheetHeight = sheet:getWidth(), sheet:getHeight()
		end,

		getSheet = function() return sheet end,

		animate = function(self, name, loop)
			if not animData[name] then
				local fallback = name:gsub(" alt", "")
				if not animData[fallback] then
					print("Animation " .. name .. " does not exist!")
					return
				end
				name = fallback
			end
			anim = animData[name]
			anim.name = name
			frame = anim.start
			isLooped = loop
			isAnimated = true
		end,

		getAnims = function() return animData end,
		getAnimName = function() return anim.name end,
		setAnimSpeed = function(_, speed) anim.speed = speed end,
		isAnimated = function() return isAnimated end,
		isLooped = function() return isLooped end,
		setOptions = function(_, opts) options = opts end,
		getOptions = function() return options end,

		update = function(self, dt)
			if isAnimated then
				frame = frame + anim.speed * dt
				if frame > anim.stop then
					if isLooped then frame = anim.start else isAnimated = false end
				end
			end
			if self.secondary then
				self.secondary.x = self.x
				self.secondary.y = self.y + 60
				self.secondary:update(dt)
			end
		end,

		draw = function(self)
			local flooredFrame = math.floor(frame)
			if flooredFrame > anim.stop then return end

			local f = frameData[flooredFrame]
			local width, height
			local x, y = self.x, self.y
			local color = {love.graphics.getColor()}

			if options and options.floored then
				x, y = math.floor(x), math.floor(y)
			end

			if options and options.noOffset then
				width = f.offsetWidth ~= 0 and f.offsetX or 0
				height = f.offsetHeight ~= 0 and f.offsetY or 0
			else
				width = f.offsetWidth == 0 and math.floor(f.width / 2) or math.floor(f.offsetWidth / 2) + f.offsetX
				height = f.offsetHeight == 0 and math.floor(f.height / 2) or math.floor(f.offsetHeight / 2) + f.offsetY
			end

			love.graphics.setColor(
				self.color[1] * color[1],
				self.color[2] * color[2],
				self.color[3] * color[3],
				self.alpha * color[4]
			)

			if self.secondary then self.secondary:draw() end

			love.graphics.draw(
				sheet,
				frames[flooredFrame],
				x - (graphics.screenDepth(graphics.getActiveScreen()) * self.depth),
				y,
				self.orientation,
				self.sizeX,
				self.sizeY,
				width + anim.offsetX + self.offsetX,
				height + anim.offsetY + self.offsetY,
				self.shearX,
				self.shearY
			)

			love.graphics.setColor(color)
		end,

		release = function(self)
			sheet:release()
		end
	}

	object:setSheet(imageData)

	for _, f in ipairs(frameData) do
		table.insert(frames, love.graphics.newQuad(f.x, f.y, f.width, f.height, sheetWidth, sheetHeight))
	end

	object:animate(animName, loopAnim)
	return object
end

return graphics
