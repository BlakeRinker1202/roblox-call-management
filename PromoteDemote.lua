-- PromoteDemote.lua
-- Basic Admin Essentials plugin to handle :promote and :demote commands
-- Sends requests to your external VSC bot

local HttpService = game:GetService("HttpService")

-- === CONFIG ===
local API_URL = "http://localhost:3000" -- Where your Node.js bot will be running
local GROUP_ID = 855648348
local COOLDOWN_TIME = 30

-- Store cooldowns { [player.UserId] = tick() }
local cooldowns = {}

-- Rank rules
local tier135_165 = {135, 145, 155, 165}
local tier175_205 = {175, 185, 195, 205}

-- Helper to check if value exists in table
local function inTable(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

-- Permission checking
local function canManage(userRank, targetRank)
	if userRank >= 135 and userRank <= 165 then
		return false
	elseif userRank >= 175 and userRank <= 205 then
		return inTable(tier135_165, targetRank)
	elseif userRank >= 213 then
		return inTable(tier175_205, targetRank) or inTable(tier135_165, targetRank)
	else
		return false
	end
end

-- Error message
local function errorMessage(plr, msg)
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Error",
		Text = msg
	})
end

-- Success message
local function successMessage(plr, msg)
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Success",
		Text = msg
	})
end

-- Register commands
return {
	["promote"] = {
		Prefix = ":",
		Commands = {"promote"},
		Args = {"username"},
		Description = "Promotes a user.",
		AdminLevel = "Players", -- We'll do manual rank checks
		Function = function(plr, args)
			local now = tick()
			if cooldowns[plr.UserId] and now - cooldowns[plr.UserId] < COOLDOWN_TIME then
				errorMessage(plr, "Please wait 30 seconds before using this command again.")
				return
			end

			if not args[1] then
				errorMessage(plr, "Please provide a username.")
				return
			end

			-- Get sender's group rank
			local senderRank = plr:GetRankInGroup(GROUP_ID)
			if senderRank < 135 then
				errorMessage(plr, "You do not have the correct rank to promote/demote.")
				return
			end

			-- Send request to bot
			local payload = {
				action = "promote",
				senderName = plr.Name,
				senderRank = senderRank,
				targetName = args[1]
			}

			local success, response = pcall(function()
				return HttpService:PostAsync(API_URL.."/promote-demote", HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
			end)

			if success then
				local resData = HttpService:JSONDecode(response)
				if resData.success then
					successMessage(plr, resData.message)
				else
					errorMessage(plr, resData.message)
				end
			else
				errorMessage(plr, "Failed to contact promotion bot.")
			end

			cooldowns[plr.UserId] = now
		end
	},

	["demote"] = {
		Prefix = ":",
		Commands = {"demote"},
		Args = {"username"},
		Description = "Demotes a user.",
		AdminLevel = "Players", -- We'll do manual rank checks
		Function = function(plr, args)
			local now = tick()
			if cooldowns[plr.UserId] and now - cooldowns[plr.UserId] < COOLDOWN_TIME then
				errorMessage(plr, "Please wait 30 seconds before using this command again.")
				return
			end

			if not args[1] then
				errorMessage(plr, "Please provide a username.")
				return
			end

			local senderRank = plr:GetRankInGroup(GROUP_ID)
			if senderRank < 135 then
				errorMessage(plr, "You do not have the correct rank to promote/demote.")
				return
			end

			local payload = {
				action = "demote",
				senderName = plr.Name,
				senderRank = senderRank,
				targetName = args[1]
			}

			local success, response = pcall(function()
				return HttpService:PostAsync(API_URL.."/promote-demote", HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
			end)

			if success then
				local resData = HttpService:JSONDecode(response)
				if resData.success then
					successMessage(plr, resData.message)
				else
					errorMessage(plr, resData.message)
				end
			else
				errorMessage(plr, "Failed to contact promotion bot.")
			end

			cooldowns[plr.UserId] = now
		end
	}
}
