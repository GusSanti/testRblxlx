local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Variables = require(ServerScriptService.Main.Round.Variables)
local info = workspace.Info
local ChallengeModule = require(ReplicatedStorage.Modules.ChallengeModule)
local ReceiveRewardsEvent = ReplicatedStorage.Events.Client.ReceiveRewards
local FriendBonus = require(script.Parent.FriendBonus)

return function(player)
	local challengeData = ChallengeModule.Data[Variables.challenge]
	local playerExpBefore = player.PlayerExp.Value
	local gemsBefore = player.Gems.Value
	local republicCredits = player:FindFirstChild("RepublicCredits")
	local republicCreditsBefore = republicCredits and republicCredits.Value or 0
	local receiveRewards = ChallengeModule.Rewards[challengeData.Difficulty].Give(player)

	if type(receiveRewards) == "table" then
		if typeof(receiveRewards.PlayerExp) == "number" and player.PlayerExp.Value == playerExpBefore then
			player.PlayerExp.Value += receiveRewards.PlayerExp
		end
		if typeof(receiveRewards.Gems) == "number" and player.Gems.Value == gemsBefore then
			player.Gems.Value += receiveRewards.Gems
		end
		if republicCredits and typeof(receiveRewards.RepublicCredits) == "number" and republicCredits.Value == republicCreditsBefore then
			republicCredits.Value += receiveRewards.RepublicCredits
		end
	end

	FriendBonus.Apply(player, receiveRewards, true)
	player.LastChallengeCompletedUniqueId.Value = info.ChallengeUniqueId.Value
	ReceiveRewardsEvent:FireClient(player,receiveRewards)
end
