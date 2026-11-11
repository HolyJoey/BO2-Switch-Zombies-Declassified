-- Modified by Fr0sty for DLC5 (No Man's Land start, Kino Grief/Turned menus). Original: Zombies Declassified (Logo2K).
require("T6.CoDBase")
require("T6.Lobby")
require("T6.EdgeShadow")
require("T6.Menus.Playercard")
require("T6.JoinableList")
require("T6.Error")
require("T6.Menus.CODTv")
require("T6.Menus.SignOutPopup")
require("T6.Menus.RejoinSessionPopup")
require("T6.Mods")
require("T6.Menus.ServerBrowserPopup")
if CoD.isWIIU then
	require("T6.WiiUControllerSettings")
end
if CoD.isZombie == false and (CoD.isXBOX or CoD.isPS3) then
	require("T6.Menus.EliteAppPopup")
end
CoD.MainLobby = {}
CoD.MainLobby.ShouldPreventCreateLobby = function ()
	if UIExpression.AcceptingInvite() == 1 or Engine.IsJoiningAnotherParty() == 1 or UIExpression.PrivatePartyHost() == 0 or Engine.IsGameLobbyRunning() then
		return true
	else
		return false
	end
end

CoD.MainLobby.OnlinePlayAvailable = function (MainLobbyWidget, ClientInstance, Boolean)
	if Boolean == nil then
		Boolean = false
	end
	if CoD.isPC and Engine.IsVacBanned() then
		local ErrorPopup = MainLobbyWidget:openPopup("Error", ClientInstance.controller)
		ErrorPopup:setMessage(Engine.Localize("PLATFORM_VACBANNED"))
		ErrorPopup.anyControllerAllowed = true
		ErrorPopup.callingMenu = MainLobbyWidget
		return 0
	elseif CoD.isWIIU and Engine.IsSignedInToDemonware(ClientInstance.controller) == false then
		if UIExpression.IsPrimaryLocalClient(ClientInstance.controller) == 1 then
			Engine.Exec(ClientInstance.controller, "xsigninlive")
		end
		return 0
	elseif UIExpression.IsGuest(ClientInstance.controller) == 1 then
		local ErrorPopup = MainLobbyWidget:openPopup("Error", ClientInstance.controller)
		ErrorPopup:setMessage(Engine.Localize("XBOXLIVE_NOGUESTACCOUNTS"))
		ErrorPopup.anyControllerAllowed = true
	elseif UIExpression.DvarBool(ClientInstance.controller, "live_betaexpired") == 1 then
		local ErrorPopup = MainLobbyWidget:openPopup("Error", ClientInstance.controller)
		ErrorPopup:setMessage(Engine.Localize("MP_BETACLOSED"))
	elseif UIExpression.IsSignedInToLive(ClientInstance.controller) == 0 then
		if CoD.isPS3 or CoD.isWIIU then
			if UIExpression.IsPrimaryLocalClient(ClientInstance.controller) == 1 then
				Engine.Exec(ClientInstance.controller, "xsigninlive")
			else
				Engine.Exec(ClientInstance.controller, "signclientin")
			end
		elseif CoD.isPC then
			if 0 == UIExpression.GetUsedControllerCount() then
				Engine.Exec(ClientInstance.controller, "xsigninlivenoguests")
			else
				Engine.Exec(ClientInstance.controller, "xsigninlive")
			end
		elseif 0 == UIExpression.GetUsedControllerCount() then
			Engine.Exec(ClientInstance.controller, "xsigninlivenoguests")
		elseif UIExpression.IsSignedIn(ClientInstance.controller) == 1 then
			MainLobbyWidget:openPopup("popup_signintolive", ClientInstance.controller)
		else
			Engine.Exec(ClientInstance.controller, "xsigninlive")
		end
	elseif (UIExpression.IsContentRatingAllowed(ClientInstance.controller) == 0 or UIExpression.IsAnyControllerMPRestricted() == 1) and not Boolean then
		local ErrorPopup = MainLobbyWidget:openPopup("Error", ClientInstance.controller)
		ErrorPopup:setMessage(Engine.Localize("XBOXLIVE_MPNOTALLOWED"))
		ErrorPopup.anyControllerAllowed = true
	elseif UIExpression.IsDemonwareFetchingDone(ClientInstance.controller) == 1 then
		local PlayerStatTable1 = Engine.GetPlayerStats(ClientInstance.controller)
		local PlayerStatTable2 = Engine.GetPlayerStats(ClientInstance.controller)
		if PlayerStatTable1.cacLoadouts.resetWarningDisplayed:get() == 0 then
			PlayerStatTable1.cacLoadouts.resetWarningDisplayed:set(1)
			if PlayerStatTable2.cacLoadouts.classWarningDisplayed ~= nil then
				PlayerStatTable2.cacLoadouts.classWarningDisplayed:set(1)
			end
			local ErrorPopup = MainLobbyWidget:openPopup("Error", ClientInstance.controller)
			ErrorPopup:setMessage(Engine.Localize("MENU_STATS_RESET"))
			ErrorPopup.anyControllerAllowed = true
		elseif CoD.isZombie == false and PlayerStatTable2.cacLoadouts.classWarningDisplayed:get() == 0 then
			PlayerStatTable2.cacLoadouts.classWarningDisplayed:set(1)
			local ErrorPopup = MainLobbyWidget:openPopup("Error", ClientInstance.controller)
			ErrorPopup:setMessage(Engine.Localize("MENU_RESETCUSTOMCLASSES"))
			ErrorPopup.anyControllerAllowed = true
		else
			return 1
		end
	else
		Engine.ExecNow(nil, "initiatedemonwareconnect")
		local ConnectingDemonwarePopup = MainLobbyWidget:openPopup("popup_connectingdw", ClientInstance.controller)
		ConnectingDemonwarePopup.openingStore = Boolean
		ConnectingDemonwarePopup.callingMenu = MainLobbyWidget
	end
	return 0
end

CoD.MainLobby.IsControllerCountValid = function (MainLobbyWidget, LocalClientIndex, MaxLocalPlayers)
	if MaxLocalPlayers < UIExpression.GetUsedControllerCount() then
		local ErrorPopup = MainLobbyWidget:openPopup("Error", LocalClientIndex)
		ErrorPopup:setMessage(Engine.Localize("XBOXLIVE_TOOMANYCONTROLLERS"))
		ErrorPopup.anyControllerAllowed = true
		return 0
	else
		return 1
	end
end

CoD.MainLobby.OpenPlayerMatchPartyLobby = function (MainLobbyWidget, ClientInstance)
	if CoD.MainLobby.ShouldPreventCreateLobby() then
		return 
	elseif CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance) == 1 then
		Engine.ProbationCheckForDashboardWarning(CoD.GAMEMODE_PUBLIC_MATCH)
		local InProbation, LocalClientIndexInProbation = Engine.ProbationCheckInProbation(CoD.GAMEMODE_PUBLIC_MATCH)
		if InProbation == true then
			MainLobbyWidget:openPopup("popup_public_inprobation", LocalClientIndexInProbation)
			return 
		end
		local GivenProbation, LocalClientIndexGivenProbation = Engine.ProbationCheckForProbation(CoD.GAMEMODE_PUBLIC_MATCH)
		if GivenProbation == true then
			MainLobbyWidget:openPopup("popup_public_givenprobation", LocalClientIndexGivenProbation)
			return 
		elseif Engine.ProbationCheckParty(CoD.GAMEMODE_PUBLIC_MATCH, ClientInstance.controller) == true then
			MainLobbyWidget:openPopup("popup_public_partyprobation", ClientInstance.controller)
			return 
		end
		local MaxLocalPlayers = UIExpression.DvarInt(LocalClientIndexGivenProbation, "party_maxlocalplayers_playermatch")
		if CoD.MainLobby.IsControllerCountValid(MainLobbyWidget, ClientInstance.controller, MaxLocalPlayers) == 1 then
			MainLobbyWidget.lobbyPane.body.lobbyList.maxLocalPlayers = MaxLocalPlayers
			CoD.SwitchToPlayerMatchLobby(ClientInstance.controller)
			if CoD.isZombie == true then
				Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_SELECTING_PLAYLIST)
				CoD.PlaylistCategoryFilter = "playermatch"
				MainLobbyWidget:openMenu("SelectMapZM", ClientInstance.controller)
				CoD.GameGlobeZombie.MoveToCenter(ClientInstance.controller)
			else
				MainLobbyWidget:openMenu("PlayerMatchPartyLobby", ClientInstance.controller)
			end
			MainLobbyWidget:close()
		end
	end
end

CoD.MainLobby.OpenLeagueSelectionPopup = function (MainLobbyWidget, ClientInstance)
	if CoD.MainLobby.ShouldPreventCreateLobby() then
		return 
	elseif CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance) == 1 then
		Engine.ProbationCheckForDashboardWarning(CoD.GAMEMODE_PUBLIC_MATCH)
		local InProbation, LocalClientIndexInProbation = Engine.ProbationCheckInProbation(CoD.GAMEMODE_LEAGUE_MATCH)
		if InProbation == true then
			MainLobbyWidget:openPopup("popup_league_inprobation", LocalClientIndexInProbation)
			return 
		end
		local GivenProbation, LocalClientIndexGivenProbation = Engine.ProbationCheckForProbation(CoD.GAMEMODE_LEAGUE_MATCH)
		if GivenProbation == true then
			MainLobbyWidget:openPopup("popup_league_givenprobation", LocalClientIndexGivenProbation)
			return 
		elseif Engine.ProbationCheckParty(CoD.GAMEMODE_LEAGUE_MATCH, ClientInstance.controller) == true then
			MainLobbyWidget:openPopup("popup_league_partyprobation", ClientInstance.controller)
			return 
		end
		Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_SELECTING_PLAYLIST)
		CoD.PlaylistCategoryFilter = "leaguematch"
		PlaylistPopup = MainLobbyWidget:openPopup("PlaylistSelection", ClientInstance.controller)
		PlaylistPopup:addCategoryButtons(ClientInstance.controller)
		Engine.PlaySound("cac_screen_fade")
	end
end

CoD.MainLobby.OpenLeaguePlayPartyLobby = function (MainLobbyWidget, ClientInstance)
	if CoD.MainLobby.ShouldPreventCreateLobby() then
		return 
	elseif CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance) == 1 then
		local MaxLocalPlayers = UIExpression.DvarInt(ClientInstance.controller, "party_maxlocalplayers_playermatch")
		if CoD.MainLobby.IsControllerCountValid(MainLobbyWidget, ClientInstance.controller, MaxLocalPlayers) == 1 then
			MainLobbyWidget.lobbyPane.body.lobbyList.maxLocalPlayers = MaxLocalPlayers
			CoD.SwitchToLeagueMatchLobby(ClientInstance.controller)
			MainLobbyWidget:openMenu("LeaguePlayPartyLobby", ClientInstance.controller)
			MainLobbyWidget:close()
		end
	end
end

CoD.MainLobby.OpenCustomGamesLobby = function (MainLobbyWidget, ClientInstance)
	if CoD.MainLobby.ShouldPreventCreateLobby() then
		return 
	elseif CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance) == 1 and CoD.MainLobby.IsControllerCountValid(MainLobbyWidget, ClientInstance.controller, UIExpression.DvarInt(ClientInstance.controller, "party_maxlocalplayers_privatematch")) == 1 then
		CoD.SwitchToPrivateLobby(ClientInstance.controller)
		if CoD.isZombie == true then
			Engine.SetDvar("ui_zm_mapstartlocation", "")
			MainLobbyWidget:openMenu("SelectMapZM", ClientInstance.controller)
			CoD.GameGlobeZombie.MoveToCenter(ClientInstance.controller)
		else
			local PrivateOnlineLobbyMenu = MainLobbyWidget:openMenu("PrivateOnlineGameLobby", ClientInstance.controller)
		end
		MainLobbyWidget:close()
	end
end

CoD.MainLobby.OpenSoloLobby_Zombie = function (MainLobbyWidget, ClientInstance)
	if CoD.MainLobby.ShouldPreventCreateLobby() then
		return 
	elseif CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance) == 1 then
		if CoD.MainLobby.IsControllerCountValid(MainLobbyWidget, ClientInstance.controller, 1) == 1 then
			MainLobbyWidget.lobbyPane.body.lobbyList.maxLocalPlayers = 1
			if UIExpression.DvarString(nil, "fs_game") == "mods/dlc5" then
				Engine.SetDvar("ui_dlc5_lobby", "1")
				CoD.SwitchToPrivateLobby(ClientInstance.controller)
				Dvar.party_maxplayers:set(1)
				Engine.SetDvar("ui_zm_mapstartlocation", "")
			else
				Engine.SetDvar("ui_dlc5_lobby", "0")
				CoD.SwitchToPlayerMatchLobby(ClientInstance.controller)
				Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_SELECTING_PLAYLIST)
				Dvar.party_maxplayers:set(1)
				CoD.PlaylistCategoryFilter = CoD.Zombie.PLAYLIST_CATEGORY_FILTER_SOLOMATCH
			end
			MainLobbyWidget:openMenu("SelectMapZM", ClientInstance.controller)
			CoD.GameGlobeZombie.MoveToCenter(ClientInstance.controller)
			MainLobbyWidget:close()
		end
	end
end

CoD.MainLobby.OpenTheaterLobby = function (MainLobbyWidget, ClientInstance)
	if CoD.MainLobby.ShouldPreventCreateLobby() then
		return 
	elseif UIExpression.CanSwitchToLobby(ClientInstance.controller, Dvar.party_maxplayers_theater:get(), Dvar.party_maxlocalplayers_theater:get()) == 0 then
		Dvar.ui_errorTitle:set(Engine.Localize("MENU_NOTICE_CAPS"))
		Dvar.ui_errorMessage:set(Engine.Localize("MENU_FILESHARE_MAX_LOCAL_PLAYERS"))
		CoD.Menu.OpenErrorPopup(MainLobbyWidget, {
			controller = ClientInstance.controller
		})
		return 
	elseif Engine.CanViewContent() == false then
		MainLobbyWidget:openPopup("popup_contentrestricted", ClientInstance.controller)
		return 
	elseif CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance) == 1 and CoD.MainLobby.IsControllerCountValid(MainLobbyWidget, ClientInstance.controller, UIExpression.DvarInt(ClientInstance.controller, "party_maxlocalplayers_theater")) == 1 then
		CoD.SwitchToTheaterLobby(ClientInstance.controller)
		local TheaterLobbyMenu = MainLobbyWidget:openMenu("TheaterLobby", ClientInstance.controller, {
			parent = "MainLobby"
		})
		MainLobbyWidget:close()
	end
end

CoD.MainLobby.OpenCODTV = function (MainLobbyWidget, ClientInstance)
	if Engine.CanViewContent() == false then
		MainLobbyWidget:openPopup("popup_contentrestricted", ClientInstance.controller)
		return 
	elseif Engine.IsLivestreamEnabled() then
		MainLobbyWidget:openPopup("CODTv_Error", ClientInstance.controller)
		return 
	elseif CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance) == 1 and Engine.IsCodtvContentLoaded() == true then
		CoD.perController[ClientInstance.controller].codtvRoot = "community"
		MainLobbyWidget:openPopup("CODTv", ClientInstance.controller)
	end
end

CoD.MainLobby.OpenBarracks = function (MainLobbyWidget, ClientInstance)
	if UIExpression.IsGuest(ClientInstance.controller) == 1 then
		MainLobbyWidget:openPopup("popup_guest_contentrestricted", ClientInstance.controller)
		return 
	elseif CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance) == 1 then
		if CoD.isZombie == true then
			Engine.Exec(ClientInstance.controller, "party_setHostUIString ZMUI_VIEWING_LEADERBOARD")
			MainLobbyWidget:openPopup("LeaderboardCarouselZM", ClientInstance.controller)
		else
			Engine.Exec(ClientInstance.controller, "party_setHostUIString MENU_VIEWING_PLAYERCARD")
			MainLobbyWidget:openPopup("Barracks", ClientInstance.controller)
		end
	end
end

CoD.MainLobby.OpenStore = function (MainLobbyWidget, ClientInstance)
	if MainLobbyWidget.occludedBy then
		return 
	end
	Engine.SetDvar("ui_openStoreForMTX", 0)
	if Engine.CheckNetConnection() == false then
		local NetConnectionCheckPopup = MainLobbyWidget:openPopup("popup_net_connection_store", ClientInstance.controller)
		NetConnectionCheckPopup.callingMenu = MainLobbyWidget
		return 
	end
	Engine.Exec(ClientInstance.controller, "setclientbeingusedandprimary")
	if CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance, true) == 1 then
		if not CoD.isPS3 or UIExpression.IsSubUser(ClientInstance.controller) ~= 1 then
			Dvar.ui_storeButtonPressed:set(true)
			CoD.perController[ClientInstance.controller].codtvRoot = "ingamestore"
			if CoD.isPC then
				Engine.ShowMarketplaceUI(ClientInstance.controller)
			else
				MainLobbyWidget:openPopup("CODTv", ClientInstance.controller)
			end
		else
			local ErrorPopup = MainLobbyWidget:openPopup("Error", ClientInstance.controller)
			ErrorPopup:setMessage(Engine.Localize("MENU_SUBUSERS_NOTALLOWED"))
			ErrorPopup.anyControllerAllowed = true
		end
	end
end

CoD.MainLobby.OpenControlsMenu = function (MainLobbyWidget, ClientInstance)
	MainLobbyWidget:openPopup("WiiUControllerSettings", ClientInstance.controller, true)
end

CoD.MainLobby.OpenOptionsMenu = function (MainLobbyWidget, ClientInstance)
	MainLobbyWidget:openPopup("OptionsMenu", ClientInstance.controller)
end

CoD.MainLobby.UpdateButtonPaneButtonVisibilty_Multiplayer = function (MainLobbyButtonPane)
	if CoD.isPartyHost() then
		MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.matchmakingButton)
		--MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.leaguePlayButton)
		if not Engine.IsBetaBuild() then
			MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.customGamesButton)
		end
		MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.theaterButton)
		MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.postTheaterSpacer)
		MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.modsButton)
	else
		MainLobbyButtonPane.body.matchmakingButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		--MainLobbyButtonPane.body.leaguePlayButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		if not Engine.IsBetaBuild() then
			MainLobbyButtonPane.body.customGamesButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		end
		MainLobbyButtonPane.body.theaterButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		MainLobbyButtonPane.body.postTheaterSpacer:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		MainLobbyButtonPane.body.modsButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
	end
end

CoD.MainLobby.UpdateButtonPaneButtonVisibilty_Zombie = function (MainLobbyButtonPane)
	if CoD.isPartyHost() then
		MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.serverBrowserButton)
		-- MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.matchmakingButton)
		MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.customSpacer)
		if UIExpression.DvarInt(nil, "party_playerCount") <= 1 then
			MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.soloPlayButton)
		else
			MainLobbyButtonPane.body.soloPlayButton:closeAndRefocus(MainLobbyButtonPane.body.theaterButton)
		end
		MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.customGamesButton)
		MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.theaterSpacer)
		MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.theaterButton)
		MainLobbyButtonPane.body.buttonList:addElement(MainLobbyButtonPane.body.modsButton)
	else
		MainLobbyButtonPane.body.serverBrowserButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		-- MainLobbyButtonPane.body.matchmakingButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		MainLobbyButtonPane.body.customSpacer:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		MainLobbyButtonPane.body.soloPlayButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		MainLobbyButtonPane.body.customGamesButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		MainLobbyButtonPane.body.theaterSpacer:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		MainLobbyButtonPane.body.theaterButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
		MainLobbyButtonPane.body.modsButton:closeAndRefocus(MainLobbyButtonPane.body.optionsButton)
	end
end

CoD.MainLobby.UpdateButtonPaneButtonVisibilty = function (MainLobbyButtonPane)
	if MainLobbyButtonPane == nil or MainLobbyButtonPane.body == nil then
		return 
	elseif CoD.isZombie == true then
		CoD.MainLobby.UpdateButtonPaneButtonVisibilty_Zombie(MainLobbyButtonPane)
	else
		CoD.MainLobby.UpdateButtonPaneButtonVisibilty_Multiplayer(MainLobbyButtonPane)
	end
	MainLobbyButtonPane:setLayoutCached(false)
end

CoD.MainLobby.UpdateButtonPromptVisibility = function (MainLobbyWidget)
	if MainLobbyWidget == nil then
		return 
	end
	MainLobbyWidget:removeBackButton()
	local ShouldAddJoinButton = false
	if MainLobbyWidget.joinButton ~= nil then
		MainLobbyWidget.joinButton:close()
		ShouldAddJoinButton = true
	end
	MainLobbyWidget.friendsButton:close()
	if MainLobbyWidget.partyPrivacyButton ~= nil then
		MainLobbyWidget.partyPrivacyButton:close()
	end
	MainLobbyWidget:addBackButton()
	MainLobbyWidget:addFriendsButton()
	if ShouldAddJoinButton then
		MainLobbyWidget:addJoinButton()
	end
	if MainLobbyWidget.panelManager.slidingEnabled ~= true then
		MainLobbyWidget.friendsButton:disable()
	end
	if MainLobbyWidget.panelManager:isPanelOnscreen("buttonPane") then
		MainLobbyWidget:addPartyPrivacyButton()
	end
	MainLobbyWidget:addNATType()
end

CoD.MainLobby.PopulateButtons_Multiplayer = function (MainLobbyButtonPane)
	if Engine.IsBetaBuild() then
		MainLobbyButtonPane.body.matchmakingButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_MATCHMAKING_CAPS"), nil, 3)
		--MainLobbyButtonPane.body.leaguePlayButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_LEAGUE_PLAY_CAPS"), nil, 2)
	else
		MainLobbyButtonPane.body.matchmakingButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_MATCHMAKING_CAPS"), nil, 1)
		--MainLobbyButtonPane.body.leaguePlayButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_LEAGUE_PLAY_CAPS"), nil, 3)
	end
	MainLobbyButtonPane.body.matchmakingButton.hintText = Engine.Localize(CoD.MPZM("MPUI_PLAYER_MATCH_DESC", "ZMUI_PLAYER_MATCH_DESC"))
	MainLobbyButtonPane.body.matchmakingButton:setActionEventName("open_player_match_party_lobby")
	--CoD.SetupMatchmakingLock(MainLobbyButtonPane.body.matchmakingButton)
	--MainLobbyButtonPane.body.leaguePlayButton.hintText = Engine.Localize("MPUI_LEAGUE_PLAY_DESC")
	--MainLobbyButtonPane.body.leaguePlayButton:setActionEventName("open_league_play_party_lobby")
	if not Engine.IsBetaBuild() then
		MainLobbyButtonPane.body.customGamesButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_CUSTOMGAMES_CAPS"), nil, 4)
		MainLobbyButtonPane.body.customGamesButton.hintText = Engine.Localize(CoD.MPZM("MPUI_CUSTOM_MATCH_DESC", "ZMUI_CUSTOM_MATCH_DESC"))
		MainLobbyButtonPane.body.customGamesButton:setActionEventName("open_custom_games_lobby")
		CoD.SetupCustomGamesLock(MainLobbyButtonPane.body.customGamesButton)
	end
	MainLobbyButtonPane.body.theaterButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_THEATER_CAPS"), nil, 5)
	MainLobbyButtonPane.body.theaterButton:setActionEventName("open_theater_lobby")
	MainLobbyButtonPane.body.theaterButton.hintText = Engine.Localize(CoD.MPZM("MPUI_THEATER_DESC", "ZMUI_THEATER_DESC"))
	MainLobbyButtonPane.body.postTheaterSpacer = MainLobbyButtonPane.body.buttonList:addSpacer(CoD.CoD9Button.Height / 2, 6)
	if not Engine.IsBetaBuild() then
		MainLobbyButtonPane.body.barracksButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_BARRACKS_CAPS"), nil, 7)
		MainLobbyButtonPane.body.barracksButton.id = "CoD9Button" .. "." .. "MainLobby" .. "." .. Engine.Localize("MENU_BARRACKS_CAPS")
		CoD.SetupBarracksLock(MainLobbyButtonPane.body.barracksButton)
		CoD.SetupBarracksNew(MainLobbyButtonPane.body.barracksButton)
		MainLobbyButtonPane.body.barracksButton:setActionEventName("open_barracks")
	end
	if CoD.isZombie == false and not Engine.IsBetaBuild() and (CoD.isXBOX or CoD.isPS3) and Engine.IsEliteAvailable() and Engine.IsEliteButtonAvailable() then
		MainLobbyButtonPane.body.eliteAppButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_ELITE_CAPS"), nil, 8)
		MainLobbyButtonPane.body.eliteAppButton.hintText = Engine.Localize("MENU_ELITE_DESC")
		MainLobbyButtonPane.body.eliteAppButton:setActionEventName("open_eliteapp_popup")
	end
	MainLobbyButtonPane.body.buttonList:addSpacer(CoD.CoD9Button.Height / 2, 9)
	MainLobbyButtonPane.body.optionsButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_OPTIONS_CAPS"), nil, 11)
	MainLobbyButtonPane.body.optionsButton.hintText = Engine.Localize("MPUI_OPTIONS_DESC")
	MainLobbyButtonPane.body.optionsButton:setActionEventName("open_options_menu")
	MainLobbyButtonPane.body.modsButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_MODS_CAPS"), nil, 12)
	MainLobbyButtonPane.body.modsButton.hintText = Engine.Localize("MENU_SELECT_MOD_NAME_TO_LAUNCH")
	MainLobbyButtonPane.body.modsButton:setActionEventName("open_mods_menu")
end

CoD.MainLobby.PopulateButtons_Zombie = function (MainLobbyButtonPane)
	MainLobbyButtonPane.body.serverBrowserButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_SERVER_BROWSER_CAPS"), nil, 1)
	MainLobbyButtonPane.body.serverBrowserButton.hintText = Engine.Localize("MENU_SERVER_BROWSER_DESC")
	MainLobbyButtonPane.body.serverBrowserButton:setActionEventName("open_server_browser_mainlobby")
	--CoD.SetupMatchmakingLock(MainLobbyButtonPane.body.serverBrowserButton)
	-- MainLobbyButtonPane.body.matchmakingButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_MATCHMAKING_CAPS"), nil, 2)
	-- MainLobbyButtonPane.body.matchmakingButton.hintText = Engine.Localize(CoD.MPZM("MPUI_PLAYER_MATCH_DESC", "ZMUI_PLAYER_MATCH_DESC"))
	-- MainLobbyButtonPane.body.matchmakingButton:setActionEventName("open_player_match_party_lobby")
	-- CoD.SetupMatchmakingLock(MainLobbyButtonPane.body.matchmakingButton)
	MainLobbyButtonPane.body.customSpacer = MainLobbyButtonPane.body.buttonList:addSpacer(CoD.CoD9Button.Height / 2, 3)
	MainLobbyButtonPane.body.soloPlayButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("ZMUI_SOLO_PLAY_CAPS"), nil, 3)
	MainLobbyButtonPane.body.soloPlayButton.hintText = Engine.Localize("ZMUI_SOLO_PLAY_DESC")
	MainLobbyButtonPane.body.soloPlayButton:setActionEventName("open_solo_lobby_zombie")
	MainLobbyButtonPane.body.customGamesButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_CUSTOMGAMES_CAPS"), nil, 4)
	MainLobbyButtonPane.body.customGamesButton.hintText = Engine.Localize(CoD.MPZM("MPUI_CUSTOM_MATCH_DESC", "ZMUI_CUSTOM_MATCH_DESC"))
	MainLobbyButtonPane.body.customGamesButton:setActionEventName("open_custom_games_lobby")
	CoD.SetupCustomGamesLock(MainLobbyButtonPane.body.customGamesButton)
	MainLobbyButtonPane.body.theaterButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_THEATER_CAPS"), nil, 5)
	MainLobbyButtonPane.body.theaterButton:setActionEventName("open_theater_lobby")
	MainLobbyButtonPane.body.theaterButton.hintText = Engine.Localize(CoD.MPZM("MPUI_THEATER_DESC", "ZMUI_THEATER_DESC"))
	MainLobbyButtonPane.body.theaterSpacer = MainLobbyButtonPane.body.buttonList:addSpacer(CoD.CoD9Button.Height / 2, 6)
	MainLobbyButtonPane.body.barracksButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MPUI_LEADERBOARDS_CAPS"), nil, 7)
	CoD.SetupBarracksLock(MainLobbyButtonPane.body.barracksButton)
	MainLobbyButtonPane.body.barracksButton:setActionEventName("open_barracks")
	MainLobbyButtonPane.body.optionSpacer = MainLobbyButtonPane.body.buttonList:addSpacer(CoD.CoD9Button.Height / 2, 8)
	MainLobbyButtonPane.body.optionsButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_OPTIONS_CAPS"), nil, 9)
	MainLobbyButtonPane.body.optionsButton.hintText = Engine.Localize("MPUI_OPTIONS_DESC")
	MainLobbyButtonPane.body.optionsButton:setActionEventName("open_options_menu")
	MainLobbyButtonPane.body.modsButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_MODS_CAPS"), nil, 10)
	MainLobbyButtonPane.body.modsButton.hintText = Engine.Localize("MENU_SELECT_MOD_NAME_TO_LAUNCH")
	MainLobbyButtonPane.body.modsButton:setActionEventName("open_mods_menu")
end

CoD.MainLobby.PopulateButtons = function (MainLobbyButtonPane)
	if CoD.isZombie == true then
		CoD.MainLobby.PopulateButtons_Zombie(MainLobbyButtonPane)
	else
		CoD.MainLobby.PopulateButtons_Multiplayer(MainLobbyButtonPane)
	end
	if CoD.isWIIU then
		MainLobbyButtonPane.body.controlsButton = MainLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_CONTROLLER_SETTINGS_CAPS"), nil, 9)
		MainLobbyButtonPane.body.controlsButton.hintText = Engine.Localize("MENU_CONTROLLER_SETTINGS_DESC")
		MainLobbyButtonPane.body.controlsButton:setActionEventName("open_controls_menu")
	end
	if CoD.isOnlineGame() then
		if MainLobbyButtonPane.playerCountLabel == nil then
			MainLobbyButtonPane.playerCountLabel = LUI.UIText.new()
			MainLobbyButtonPane:addElement(MainLobbyButtonPane.playerCountLabel)
		end
		MainLobbyButtonPane.playerCountLabel:setLeftRight(true, false, 0, 0)
		MainLobbyButtonPane.playerCountLabel:setTopBottom(false, true, -30 - CoD.textSize.Big, -30)
		MainLobbyButtonPane.playerCountLabel:setFont(CoD.fonts.Big)
		MainLobbyButtonPane.playerCountLabel:setRGB(CoD.offWhite.r, CoD.offWhite.g, CoD.offWhite.b)
		local PlayerCountText = CoD.Menu.GetOnlinePlayerCountText()
		local PlayerCountUpdateTimer = nil
		if PlayerCountText ~= "" then
			MainLobbyButtonPane.playerCountLabel:setText(PlayerCountText)
			PlayerCountUpdateTimer = LUI.UITimer.new(60000, "update_online_player_count", false, MainLobbyButtonPane.playerCountLabel)
		else
			PlayerCountUpdateTimer = LUI.UITimer.new(1000, "update_online_player_count", false, MainLobbyButtonPane.playerCountLabel)
		end
		MainLobbyButtonPane.playerCountLabel:registerEventHandler("update_online_player_count", CoD.MainLobby.UpdateOnlinePlayerCount)
		MainLobbyButtonPane.playerCountLabel.timer = PlayerCountUpdateTimer
		MainLobbyButtonPane:addElement(PlayerCountUpdateTimer)
	end
end

CoD.MainLobby.UpdateOnlinePlayerCount = function (PlayerCountLabel)
	if CoD.isOnlineGame() then
		local PlayerCountText = CoD.Menu.GetOnlinePlayerCountText()
		if PlayerCountText ~= "" then
			PlayerCountLabel:setText(PlayerCountText)
			PlayerCountLabel.timer.interval = 60000
			PlayerCountLabel.timer:reset()
		end
	end
end

CoD.MainLobby.FirstSignedInToLive = function (MainLobbyWidget)
	if MainLobbyWidget ~= nil then
		if CoD.isXBOX then
			MainLobbyWidget.anyControllerAllowed = false
		end
		if MainLobbyWidget.friendsButton == nil then
			MainLobbyWidget:addFriendsButton()
		end
	end
end

CoD.MainLobby.LastSignedOutOfLive = function (MainLobbyWidget)
	if MainLobbyWidget ~= nil and CoD.isXBOX then
		MainLobbyWidget.anyControllerAllowed = true
	end
end

CoD.MainLobby.PlayerSelected = function (MainLobbyWidget, PlayerSelectedEvent)
	if MainLobbyWidget.joinable ~= nil and CoD.canJoinSession(UIExpression.GetPrimaryController(), PlayerSelectedEvent.playerXuid) then
		if MainLobbyWidget.joinButton == nil and not MainLobbyWidget.m_blockJoinButton then
			MainLobbyWidget:addJoinButton()
			MainLobbyWidget:addNATType()
		end
	elseif MainLobbyWidget.joinButton ~= nil then
		MainLobbyWidget.joinButton:close()
		MainLobbyWidget.joinButton = nil
	end
	MainLobbyWidget:dispatchEventToChildren(PlayerSelectedEvent)
end

CoD.MainLobby.PlayerDeselected = function (MainLobbyWidget, PlayerDeselectedEvent)
	if MainLobbyWidget.joinButton ~= nil then
		MainLobbyWidget.joinButton:close()
		MainLobbyWidget.joinButton = nil
	end
	MainLobbyWidget:dispatchEventToChildren(PlayerDeselectedEvent)
end

CoD.MainLobby.CurrentPanelChanged = function (MainLobbyWidget, f27_arg1)
	if CoD.isPC then
		MainLobbyWidget.m_blockJoinButton = f27_arg1.id ~= "PanelManager.lobbyPane"
	end
end

--Unused skipped
CoD.MainLobby.BusyList_Update = function (f28_arg0, f28_arg1, f28_arg2, f28_arg3, f28_arg4)
	CoD.PlayerList.Update(f28_arg0, Engine.GetBusyFriendsOfAllLocalPlayers(f28_arg0.maxRows - f28_arg2), f28_arg2, f28_arg3, f28_arg4)
end

CoD.MainLobby.Update = function (MainLobbyWidget, ClientInstance)
	if MainLobbyWidget == nil then
		return 
	elseif UIExpression.IsDemonwareFetchingDone(ClientInstance.controller) == 1 == true then
		MainLobbyWidget.panelManager:processEvent({
			name = "fetching_done"
		})
	end
	CoD.MainLobby.UpdateButtonPaneButtonVisibilty(MainLobbyWidget.buttonPane)
	CoD.MainLobby.UpdateButtonPromptVisibility(MainLobbyWidget)
	MainLobbyWidget:dispatchEventToChildren(ClientInstance)
end

CoD.MainLobby.ClientLeave = function (MainLobbyWidget, ClientInstance)
	Engine.ExecNow(ClientInstance.controller, "leaveAllParties")
	Engine.PartyHostClearUIState()
	CoD.StartMainLobby(ClientInstance.controller)
	CoD.MainLobby.UpdateButtonPaneButtonVisibilty(MainLobbyWidget.buttonPane)
	CoD.MainLobby.UpdateButtonPromptVisibility()
end

CoD.MainLobby.GoBack = function (MainLobbyWidget, ClientInstance)
	Engine.SessionModeResetModes()
	Engine.Exec(ClientInstance.controller, "xstopprivateparty")
	if CoD.isPS3 then
		Engine.Exec(ClientInstance.controller, "signoutSubUsers")
	end
	MainLobbyWidget:setPreviousMenu("MainMenu")
	CoD.Menu.goBack(MainLobbyWidget, ClientInstance.controller)
end

CoD.MainLobby.Back = function (MainLobbyWidget, ClientInstance)
	if CoD.Lobby.OpenSignOutPopup(MainLobbyWidget, ClientInstance) == true then
		return 
	elseif UIExpression.IsPrimaryLocalClient(ClientInstance.controller) == 0 then
		Engine.Exec(ClientInstance.controller, "signclientout")
		MainLobbyWidget:processEvent({
			name = "controller_backed_out"
		})
		return 
	elseif UIExpression.AloneInPartyIgnoreSplitscreen(ClientInstance.controller, 1) == 0 then
		local CustomLeaveMessage = {
			params = {}
		}
		if not CoD.isPartyHost() then
			CustomLeaveMessage.titleText = Engine.Localize("MENU_LEAVE_LOBBY_TITLE")
			CustomLeaveMessage.messageText = Engine.Localize("MENU_LEAVE_LOBBY_CLIENT_WARNING")
			table.insert(CustomLeaveMessage.params, {
				leaveHandler = CoD.MainLobby.ClientLeave,
				leaveEvent = "client_leave",
				leaveText = Engine.Localize("MENU_LEAVE_LOBBY_AND_PARTY"),
				debugHelper = "You're a client of a private party, remove you from the party"
			})
		else
			CustomLeaveMessage.titleText = Engine.Localize("MENU_DISBAND_PARTY_TITLE")
			CustomLeaveMessage.messageText = Engine.Localize("MENU_DISBAND_PARTY_HOST_WARNING")
			table.insert(CustomLeaveMessage.params, {
				leaveHandler = CoD.MainLobby.GoBack,
				leaveEvent = "host_leave",
				leaveText = Engine.Localize("MENU_LEAVE_AND_DISBAND_PARTY"),
				debugHelper = "You're the leader of a private party, choosing this will disband your party"
			})
		end
		CoD.Lobby.ConfirmLeave(MainLobbyWidget, ClientInstance.controller, nil, nil, CustomLeaveMessage)
	else
		CoD.MainLobby.GoBack(MainLobbyWidget, ClientInstance)
	end
end

CoD.MainLobby.AddLobbyPaneElements = function (LobbyPane, MenuParty)
	CoD.LobbyPanes.addLobbyPaneElements(LobbyPane, MenuParty, UIExpression.DvarInt(nil, "party_maxlocalplayers_mainlobby"))
	LobbyPane.body.lobbyList.joinableList = CoD.JoinableList.New({
		leftAnchor = true,
		rightAnchor = true,
		left = 0,
		right = 0,
		topAnchor = true,
		bottomAnchor = false,
		top = 0,
		bottom = 0
	}, false, "", "joinableList", LobbyPane.id)
	LobbyPane.body.lobbyList.joinableList.pane = LobbyPane
	LobbyPane.body.lobbyList.joinableList.maxRows = CoD.MaxPlayerListRows - 2
	LobbyPane.body.lobbyList.joinableList.statusText = Engine.Localize("MENU_PLAYERLIST_FRIENDS_PLAYING")
	LobbyPane.body.lobbyList:addElement(LobbyPane.body.lobbyList.joinableList)
end

CoD.MainLobby.ButtonListButtonGainFocus = function (f34_arg0, ClientInstance)
	f34_arg0:dispatchEventToParent({
		name = "add_party_privacy_button"
	})
	CoD.Lobby.ButtonListButtonGainFocus(f34_arg0, ClientInstance)
end

CoD.MainLobby.ButtonListAddButton = function (f35_arg0, f35_arg1, f35_arg2, f35_arg3)
	local f35_local0 = CoD.Lobby.ButtonListAddButton(f35_arg0, f35_arg1, f35_arg2, f35_arg3)
	f35_local0:registerEventHandler("gain_focus", CoD.MainLobby.ButtonListButtonGainFocus)
	return f35_local0
end

CoD.MainLobby.AddButtonPaneElements = function (f36_arg0)
	CoD.LobbyPanes.addButtonPaneElements(f36_arg0)
	f36_arg0.body.buttonList.addButton = CoD.MainLobby.ButtonListAddButton
end

CoD.MainLobby.PopulateButtonPaneElements = function (MainLobbyButtonPane)
	CoD.MainLobby.PopulateButtons(MainLobbyButtonPane)
	CoD.MainLobby.UpdateButtonPaneButtonVisibilty(MainLobbyButtonPane)
end

CoD.MainLobby.GoToFindingGames_Zombie = function (MainLobbyWidget, ClientInstance)
	Engine.Exec(ClientInstance.controller, "xstartparty")
	Engine.Exec(ClientInstance.controller, "updategamerprofile")
	local PublicGameLobbyMenu = MainLobbyWidget:openMenu("PublicGameLobby", ClientInstance.controller)
	PublicGameLobbyMenu:setPreviousMenu("MainLobby")
	PublicGameLobbyMenu:registerAnimationState("hide", {
		alpha = 0
	})
	PublicGameLobbyMenu:animateToState("hide")
	PublicGameLobbyMenu:registerAnimationState("show", {
		alpha = 1
	})
	PublicGameLobbyMenu:animateToState("show", 500)
	MainLobbyWidget:close()
end

CoD.MainLobby.ButtonPromptJoin = function (MainLobbyWidget, ClientInstance)
	if UIExpression.IsGuest(ClientInstance.controller) == 1 then
		local f39_local0 = MainLobbyWidget:openPopup("Error", ClientInstance.controller)
		f39_local0:setMessage(Engine.Localize("XBOXLIVE_NOGUESTACCOUNTS"))
		f39_local0.anyControllerAllowed = true
		return 
	end 
	if MainLobbyWidget.lobbyPane.body.lobbyList.selectedPlayerXuid ~= nil then
		Engine.SetDvar("selectedPlayerXuid", MainLobbyWidget.lobbyPane.body.lobbyList.selectedPlayerXuid)
		CoD.joinPlayer(ClientInstance.controller, MainLobbyWidget.lobbyPane.body.lobbyList.selectedPlayerXuid)
	end
end

LUI.createMenu.MainLobby = function (LocalClientIndex)
	local MainLobbyName = Engine.Localize(CoD.MPZM("MENU_MULTIPLAYER_CAPS", "MENU_ZOMBIES_CAPS"))
	local MainLobbyWidget = CoD.Lobby.New("MainLobby", LocalClientIndex, nil, MainLobbyName)
	MainLobbyWidget.controller = LocalClientIndex
	MainLobbyWidget.anyControllerAllowed = true
	MainLobbyWidget:setPreviousMenu("MainMenu")
	if CoD.isPC then
		MainLobbyWidget.m_blockJoinButton = true
	end
	if CoD.isZombie == true then
		Engine.Exec(LocalClientIndex, "xsessionupdate")
		MainLobbyWidget:registerEventHandler("open_solo_lobby_zombie", CoD.MainLobby.OpenSoloLobby_Zombie)
		MainLobbyWidget:registerEventHandler("restartMatchmaking", CoD.MainLobby.GoToFindingGames_Zombie)
		Engine.SetDvar("party_readyPercentRequired", 0)
	elseif (CoD.isXBOX or CoD.isPS3) and Engine.IsEliteAvailable() and Engine.IsEliteButtonAvailable() then
		MainLobbyWidget:registerEventHandler("open_eliteapp_popup", CoD.MainLobby.OpenEliteAppPopup)
		MainLobbyWidget:registerEventHandler("elite_registration_ended", CoD.MainLobby.elite_registration_ended)
	end
	MainLobbyWidget:addTitle(MainLobbyName)
	MainLobbyWidget.addButtonPaneElements = CoD.MainLobby.AddButtonPaneElements
	MainLobbyWidget.populateButtonPaneElements = CoD.MainLobby.PopulateButtonPaneElements
	MainLobbyWidget.addLobbyPaneElements = CoD.MainLobby.AddLobbyPaneElements
	MainLobbyWidget:updatePanelFunctions()
	MainLobbyWidget:registerEventHandler("partylobby_update", CoD.MainLobby.Update)
	MainLobbyWidget:registerEventHandler("button_prompt_back", CoD.MainLobby.Back)
	MainLobbyWidget:registerEventHandler("first_signed_in", CoD.MainLobby.FirstSignedInToLive)
	MainLobbyWidget:registerEventHandler("last_signed_out", CoD.MainLobby.LastSignedOutOfLive)
	MainLobbyWidget:registerEventHandler("player_selected", CoD.MainLobby.PlayerSelected)
	MainLobbyWidget:registerEventHandler("player_deselected", CoD.MainLobby.PlayerDeselected)
	MainLobbyWidget:registerEventHandler("current_panel_changed", CoD.MainLobby.CurrentPanelChanged)
	MainLobbyWidget:registerEventHandler("open_player_match_party_lobby", CoD.MainLobby.OpenPlayerMatchPartyLobby)
	MainLobbyWidget:registerEventHandler("open_league_play_party_lobby", CoD.MainLobby.OpenLeagueSelectionPopup)
	MainLobbyWidget:registerEventHandler("playlist_selected", CoD.MainLobby.OpenLeaguePlayPartyLobby)
	MainLobbyWidget:registerEventHandler("open_custom_games_lobby", CoD.MainLobby.OpenCustomGamesLobby)
	MainLobbyWidget:registerEventHandler("open_theater_lobby", CoD.MainLobby.OpenTheaterLobby)
	MainLobbyWidget:registerEventHandler("open_cod_tv", CoD.MainLobby.OpenCODTV)
	MainLobbyWidget:registerEventHandler("open_barracks", CoD.MainLobby.OpenBarracks)
	if CoD.isWIIU then
		MainLobbyWidget:registerEventHandler("open_controls_menu", CoD.MainLobby.OpenControlsMenu)
	end
	MainLobbyWidget:registerEventHandler("open_options_menu", CoD.MainLobby.OpenOptionsMenu)
	MainLobbyWidget:registerEventHandler("open_session_rejoin_popup", CoD.MainLobby.OpenSessionRejoinPopup)
	MainLobbyWidget:registerEventHandler("button_prompt_join", CoD.MainLobby.ButtonPromptJoin)
	MainLobbyWidget:registerEventHandler("open_store", CoD.MainLobby.OpenStore)
	MainLobbyWidget:registerEventHandler("open_server_browser_mainlobby", CoD.MainLobby.OpenIMGUIServerBrowser)
	MainLobbyWidget:registerEventHandler("open_mods_menu", CoD.MainLobby.OpenModsList)
	MainLobbyWidget.lobbyPane.body.lobbyList:setSplitscreenSignInAllowed(true)
	CoD.MainLobby.PopulateButtons(MainLobbyWidget.buttonPane)
	CoD.MainLobby.UpdateButtonPaneButtonVisibilty(MainLobbyWidget.buttonPane)
	CoD.MainLobby.UpdateButtonPromptVisibility(MainLobbyWidget)
	if CoD.useController then
		if CoD.isZombie then
			MainLobbyWidget.buttonPane.body.buttonList:selectElementIndex(1)
		elseif not MainLobbyWidget.buttonPane.body.buttonList:restoreState() then
			if CoD.isPartyHost() then
				if Engine.IsBetaBuild() then
					-- MainLobbyWidget.buttonPane.body.leaguePlayButton:processEvent({
					-- 	name = "gain_focus"
					-- })
				else
					MainLobbyWidget.buttonPane.body.matchmakingButton:processEvent({
						name = "gain_focus"
					})
				end
			else
				MainLobbyWidget.buttonPane.body.optionsButton:processEvent({
					name = "gain_focus"
				})
			end
		end
	end
	MainLobbyWidget.categoryInfo = CoD.Lobby.CreateInfoPane()
	MainLobbyWidget.playlistInfo = CoD.Lobby.CreateInfoPane()
	MainLobbyWidget.lobbyPane.body:close()
	MainLobbyWidget.lobbyPane.body = nil
	CoD.MainLobby.AddLobbyPaneElements(MainLobbyWidget.lobbyPane, Engine.Localize("MENU_PARTY_CAPS"))
	if UIExpression.AnySignedInToLive() == 1 then
		CoD.MainLobby.FirstSignedInToLive(MainLobbyWidget)
	else
		CoD.MainLobby.LastSignedOutOfLive(MainLobbyWidget)
	end
	Engine.SystemNeedsUpdate(nil, "party")
	if CoD.isPS3 then
		MainLobbyWidget.anyControllerAllowed = false
	end
	if not CoD.isZombie then
		CoD.CheckClasses.CheckClasses()
	end
	Engine.SessionModeSetOnlineGame(true)
	return MainLobbyWidget
end

CoD.MainLobby.OpenSessionRejoinPopup = function (MainLobbyWidget, ClientInstance)
	MainLobbyWidget:openPopup("RejoinSessionPopup", ClientInstance.controller)
end

CoD.MainLobby.elite_registration_ended = function (MainLobbyWidget, ClientInstance)
	if UIExpression.IsGuest(ClientInstance.controller) == 1 then
		MainLobbyWidget:openPopup("popup_guest_contentrestricted", ClientInstance.controller)
		return 
	elseif Engine.IsPlayerEliteRegistered(ClientInstance.controller) then
		if Engine.ELaunchAppSearch(ClientInstance.controller) then
			local f42_local0 = MainLobbyWidget:openPopup("EliteAppLaunchExecPopup", ClientInstance.controller)
		else
			local f42_local0 = MainLobbyWidget:openPopup("EliteAppDownloadPopup", ClientInstance.controller)
		end
	end
end

CoD.MainLobby.OpenEliteAppPopup = function (MainLobbyWidget, ClientInstance)
	if UIExpression.IsGuest(ClientInstance.controller) == 1 then
		MainLobbyWidget:openPopup("popup_guest_contentrestricted", ClientInstance.controller)
		return 
	elseif Engine.IsPlayerEliteRegistered(ClientInstance.controller) then
		if Engine.ELaunchAppSearch(ClientInstance.controller) then
			local f43_local0 = MainLobbyWidget:openPopup("EliteAppLaunchExecPopup", ClientInstance.controller)
		else
			local f43_local0 = MainLobbyWidget:openPopup("EliteAppDownloadPopup", ClientInstance.controller)
		end
	else
		local f43_local0 = MainLobbyWidget:openPopup("EliteRegistrationPopup", ClientInstance.controller)
	end
end

CoD.MainLobby.OpenIMGUIServerBrowser = function(MainLobbyWidget, ClientInstance)
	Engine.Exec(ClientInstance.controller, "plutoniumServers")

	if true then
		return
	end

	if CoD.MainMenu.IsGuestRestricted( MainLobbyWidget, ClientInstance ) == true then
		return 
	else
		Engine.Exec( ClientInstance.controller, "loadcommonff" )
		if Engine.CheckNetConnection() == false then
			local f33_local0 = MainLobbyWidget:openPopup( "popup_net_connection", ClientInstance.controller )
			f33_local0.callingMenu = MainLobbyWidget
			return 
		elseif CoD.MainMenu.OfflinePlayAvailable( MainLobbyWidget, ClientInstance ) == 0 then
			return 
		else
			local parentObj = {
				parent = "PartyLobby"
			}

			if CoD.isZombie then
				parentObj.parent = "MainLobby"
			end

			MainLobbyWidget:openMenu( "ServerBrowser", ClientInstance.controller, parentObj )
			MainLobbyWidget:close()
		end
	end
end

CoD.MainLobby.OpenModsList = function(MainLobbyWidget, ClientInstance)
	MainLobbyWidget:openMenu("Mods", ClientInstance.controller, {
		parent = "MainLobby"
	})
	MainLobbyWidget:close()
end

-- DLC5 map-select element size (Kino only)
-- selectstartloczombie.lua hardcodes the start-loc element per map and Kino hits
-- the 400x200 "else". That file is defined AFTER this one, so we intercept the
-- moment LUI.createMenu.SelectStartLocZM is assigned, then hook PopulateStartLocs
-- (called inside createMenu, after the size branch, before the elements are built).
-- Every stage is pcall-guarded and reports via the dlc5_luahook dvar.
pcall( function()
	Engine.SetDvar( "dlc5_luahook", "loaded" )
end )
pcall( function()
	if LUI == nil or LUI.createMenu == nil then
		return
	end

	local dlc5_HookPopulate = function()
		if CoD == nil or CoD.SelectStartLocZombie == nil then
			return
		end
		if CoD.SelectStartLocZombie.dlc5_hooked == true then
			return
		end
		local dlc5_origPopulate = CoD.SelectStartLocZombie.PopulateStartLocs
		if dlc5_origPopulate == nil then
			return
		end
		CoD.SelectStartLocZombie.PopulateStartLocs = function( ... )
			pcall( function()
				local dlc5_map = CoD.Zombie.GetUIMapName()
				Engine.SetDvar( "dlc5_luamap", tostring( dlc5_map ) )
				-- Kino, Moon, Five, Ascension and Shangri-La use full-screen (16:9) start-loc art instead of the stock 400x200 box.
				-- [local fix] full-screen start-loc art only exists in mod_patch.ff; only resize when it is loaded
				local dlc5_patchActive = tonumber( UIExpression.TableLookup( nil, CoD.gametypesTable, 0, 5, 3, "stage", 8 ) ) ~= nil
				if ( dlc5_patchActive or ( DLC5_NEWART ~= nil and DLC5_NEWART[dlc5_map] == true ) ) and ( dlc5_map == "zm_theater" or dlc5_map == "zm_moon" or dlc5_map == "zm_pentagon" or dlc5_map == "zm_cosmodrome" or dlc5_map == "zm_temple" ) then
					CoD.SelectStartLocZombie.StartLocInfoWidth = 1280
					CoD.SelectStartLocZombie.StartLocInfoHeight = 720
					Engine.SetDvar( "dlc5_luahook", "resized" )
				end
			end )
			-- Solo testing: "set dlc5_solotest 1" before opening the map screen lowers the
			-- Grief/Turned lobby minimum to 1 player. Anything else restores the originals.
			pcall( function()
				local dlc5_groups = CoD.Zombie.GameTypeGroups
				if dlc5_groups == nil then
					return
				end
				if CoD.SelectStartLocZombie.dlc5_origMin == nil then
					CoD.SelectStartLocZombie.dlc5_origMin = {}
				end
				local dlc5_orig = CoD.SelectStartLocZombie.dlc5_origMin
				local dlc5_solo = UIExpression.DvarString( nil, "dlc5_solotest" ) == "1"
				local dlc5_report = ""
				for dlc5_i, dlc5_gt in ipairs( { "zgrief", "zcleansed" } ) do
					local dlc5_g = dlc5_groups[dlc5_gt]
					if dlc5_g ~= nil and dlc5_g.minPlayers ~= nil then
						if dlc5_orig[dlc5_gt] == nil then
							dlc5_orig[dlc5_gt] = dlc5_g.minPlayers
						end
						if dlc5_solo then
							dlc5_g.minPlayers = 1
						else
							dlc5_g.minPlayers = dlc5_orig[dlc5_gt]
						end
						dlc5_report = dlc5_report .. dlc5_gt .. "=" .. tostring( dlc5_g.minPlayers ) .. " "
					end
				end
				Engine.SetDvar( "dlc5_luasolo", dlc5_report )
			end )
			local dlc5_args = { ... }
			local dlc5_ret = dlc5_origPopulate( ... )
			-- diagnostics for the Kino "stage" spot: what the engine and the table report
			pcall( function()
				local dlc5_dmap = CoD.Zombie.GetUIMapName()
				if dlc5_dmap ~= "zm_theater" and dlc5_dmap ~= "zm_moon" then
					return
				end
				local dlc5_s = tostring( dlc5_dmap ) .. " engine:"
				local dlc5_locs = Engine.GetStartLocsZombie( dlc5_dmap )
				if dlc5_locs ~= nil then
					for dlc5_k, dlc5_v in pairs( dlc5_locs ) do
						dlc5_s = dlc5_s .. " " .. tostring( dlc5_v.ref )
						local dlc5_modes = Engine.GetGamemodesZombie( dlc5_dmap, dlc5_v.ref )
						if dlc5_modes ~= nil then
							for dlc5_mk, dlc5_mv in pairs( dlc5_modes ) do
								dlc5_s = dlc5_s .. "/" .. tostring( dlc5_mv.ref )
							end
						end
					end
				end
				local dlc5_probeRef = "stage"
				if dlc5_dmap == "zm_moon" then
					dlc5_probeRef = "nomansland"
				end
				dlc5_s = dlc5_s .. " | table:" .. tostring( UIExpression.TableLookup( nil, CoD.gametypesTable, 0, 5, 3, dlc5_probeRef, 6 ) )
				local dlc5_menu = dlc5_args[1]
				if dlc5_menu ~= nil and dlc5_menu.startLocCount ~= nil then
					dlc5_s = dlc5_s .. " | built:" .. tostring( dlc5_menu.startLocCount )
				end
				Engine.SetDvar( "dlc5_lualocs", dlc5_s )
			end )
			return dlc5_ret
		end
		-- Extra start locations. CoD.SelectStartLocZombie.GetStartLocs asks the engine first and, when the
		-- engine knows nothing about the map (all the BO1 ports), falls back to ONE entry built from
		-- gametypestable section 5. So the second spot has to be appended here, not via the engine call.
		local dlc5_origGetStartLocs = CoD.SelectStartLocZombie.GetStartLocs
		if dlc5_origGetStartLocs ~= nil and CoD.SelectStartLocZombie.dlc5_locs_hooked ~= true then
			CoD.SelectStartLocZombie.dlc5_locs_hooked = true
			local dlc5_secondSpot = {
				zm_theater = "stage",
				zm_moon = "nomansland"
			}
			CoD.SelectStartLocZombie.GetStartLocs = function( ... )
				local dlc5_list = dlc5_origGetStartLocs( ... )
				pcall( function()
					local dlc5_map = CoD.Zombie.GetUIMapName()
					local dlc5_ref = dlc5_secondSpot[dlc5_map]
					if dlc5_ref == nil or dlc5_list == nil then
						return
					end
					local dlc5_count = 0
					for dlc5_k, dlc5_v in pairs( dlc5_list ) do
						dlc5_count = dlc5_count + 1
						if dlc5_v.ref == dlc5_ref then
							return
						end
					end
					if dlc5_count == 0 then
						return
					end
					-- [local fix] Only add the spot when the active gametypesTable has its position row; without
					-- it PopulateStartLocs does "number + nil" and Requiem ends the game (UI Error 80076).
					local dlc5_x = UIExpression.TableLookup( nil, CoD.gametypesTable, 0, 5, 3, dlc5_ref, 8 )
					local dlc5_y = UIExpression.TableLookup( nil, CoD.gametypesTable, 0, 5, 3, dlc5_ref, 9 )
					if tonumber( dlc5_x ) == nil or tonumber( dlc5_y ) == nil then
						Engine.SetDvar( "dlc5_luaextraloc", dlc5_map .. ":" .. dlc5_ref .. " skipped (no table row)" )
						return
					end
					local dlc5_name = UIExpression.TableLookup( nil, CoD.gametypesTable, 0, 5, 3, dlc5_ref, 4 )
					if dlc5_name == nil or dlc5_name == "" then
						dlc5_name = dlc5_ref
					end
					dlc5_list[dlc5_count + 1] = {
						ref = dlc5_ref,
						name = dlc5_name
					}
					Engine.SetDvar( "dlc5_luaextraloc", dlc5_map .. ":" .. dlc5_ref .. " added" )
				end )
				-- [local fix] Safety net for every map: drop start locations the menu's table has no position for.
				local dlc5_a = { ... }
				pcall( function()
					if dlc5_list == nil or ( dlc5_a[1] ~= nil and dlc5_a[1].isPublicMatch == true ) then
						return
					end
					for dlc5_k, dlc5_v in pairs( dlc5_list ) do
						local dlc5_r = dlc5_v ~= nil and dlc5_v.ref or nil
						if dlc5_r ~= nil then
							for dlc5_ci, dlc5_col in ipairs( { 8, 9, 17, 18 } ) do
								if tonumber( UIExpression.TableLookup( nil, CoD.gametypesTable, 0, 5, 3, dlc5_r, dlc5_col ) ) == nil then
									dlc5_list[dlc5_k] = nil
									break
								end
							end
						end
					end
				end )
				return dlc5_list
			end
		end
		-- Kino: move the title/description flyout next to the teleporter.
		-- Its position is gametypestable section 5 cols 10/11 (180,-50), read when it opens.
		local dlc5_origShowOptions = CoD.SelectStartLocZombie.ShowStartLocOptionList
		if dlc5_origShowOptions ~= nil then
			-- Mode descriptions for Kino's "stage" spot. The list builds them as
			-- Localize( <mode desc key> .. "_" .. <startloc ref> ), and these keys don't exist.
			local dlc5_stageText = {
				ZMUI_GRIEF_DESC_stage = "Two teams of survivors, one theater. Outlast the undead and the other team - last crew standing wins.",
				ZMUI_CLEANSED_DESC_stage = "One human against the horde of the Turned. Kill the survivor to take their place, and hold out as long as you can."
			}
			-- Moon's second spot: start in Area 51 with the teleporter shut down.
			local dlc5_nmlText = {
				ZMUI_NOMANSLAND_CAPS = "NO MAN'S LAND",
				-- the mode button label: ShowStartLocOptionList builds "ZMUI_<gametype>_<map>_CAPS" for Classic,
				-- which on Moon reads "MOON". Case matters here, so both spellings are listed.
				ZMUI_zclassic_zm_moon_CAPS = "NO MAN'S LAND",
				ZMUI_ZCLASSIC_ZM_MOON_CAPS = "NO MAN'S LAND",
				ZMUI_NOMANSLAND_LOC = "NO MAN'S LAND",
				ZMUI_NOMANSLAND_DESC = "Area 51 with the teleporter shut down. No escape to the moon - survive the base as long as you can.",
				ZMUI_CLASSIC_DESC_nomansland = "Area 51 with the teleporter shut down. No escape to the moon - survive the base as long as you can.",
				ZMUI_ZCLASSIC_DESC_nomansland = "Area 51 with the teleporter shut down. No escape to the moon - survive the base as long as you can."
			}
			CoD.SelectStartLocZombie.ShowStartLocOptionList = function( dlc5_menu, dlc5_index, ... )
				local dlc5_ref = nil
				local dlc5_uimap = nil
				pcall( function()
					dlc5_uimap = CoD.Zombie.GetUIMapName()
					if dlc5_uimap == "zm_theater" or dlc5_uimap == "zm_moon" then
						local dlc5_info = dlc5_menu.startLocInfos[dlc5_index]
						dlc5_ref = dlc5_info.ref
						if dlc5_ref == "theater" then
							dlc5_info.startLocOptionX = -45
							dlc5_info.startLocOptionY = 25
							Engine.SetDvar( "dlc5_luahook", "textmoved" )
						end
					end
				end )
				local dlc5_text = nil
				if dlc5_uimap == "zm_theater" and dlc5_ref == "stage" then
					dlc5_text = dlc5_stageText
				elseif dlc5_uimap == "zm_moon" and dlc5_ref == "nomansland" then
					dlc5_text = dlc5_nmlText
				end
				if dlc5_text == nil then
					return dlc5_origShowOptions( dlc5_menu, dlc5_index, ... )
				end
				local dlc5_origLocalize = Engine.Localize
				Engine.Localize = function( dlc5_key, ... )
					if dlc5_text[dlc5_key] ~= nil then
						return dlc5_text[dlc5_key]
					end
					return dlc5_origLocalize( dlc5_key, ... )
				end
				local dlc5_ok, dlc5_err = pcall( dlc5_origShowOptions, dlc5_menu, dlc5_index, ... )
				Engine.Localize = dlc5_origLocalize
				if not dlc5_ok then
					Engine.SetDvar( "dlc5_luastage", "error: " .. tostring( dlc5_err ) )
				else
					Engine.SetDvar( "dlc5_luastage", "shown " .. tostring( dlc5_ref ) )
				end
			end
		end
		-- Kino, Five, Ascension and Shangri-La: no menu fog layer. selectstartloczombie calls CoD.Fog.SetGameMap on open and
		-- CoD.Fog.Show/Hide when navigating, so force it hidden whenever Kino is the UI map.
		if CoD.Fog ~= nil then
			local dlc5_isKino = function()
				local dlc5_ok, dlc5_name = pcall( CoD.Zombie.GetUIMapName )
				return dlc5_ok and ( dlc5_name == "zm_theater" or dlc5_name == "zm_pentagon" or dlc5_name == "zm_cosmodrome" or dlc5_name == "zm_temple" )
			end
			local dlc5_origFogSetMap = CoD.Fog.SetGameMap
			if dlc5_origFogSetMap ~= nil then
				CoD.Fog.SetGameMap = function( ... )
					local dlc5_ret = dlc5_origFogSetMap( ... )
					if dlc5_isKino() and CoD.Fog.Hide ~= nil then
						pcall( CoD.Fog.Hide, 0 )
						Engine.SetDvar( "dlc5_luafog", "hidden" )
					end
					return dlc5_ret
				end
			end
			local dlc5_origFogShow = CoD.Fog.Show
			if dlc5_origFogShow ~= nil then
				CoD.Fog.Show = function( ... )
					if dlc5_isKino() then
						Engine.SetDvar( "dlc5_luafog", "blocked_show" )
						return
					end
					return dlc5_origFogShow( ... )
				end
			end
		end
		CoD.SelectStartLocZombie.dlc5_hooked = true
		Engine.SetDvar( "dlc5_luahook", "hooked" )
	end

	-- Kino "stage" spot (Grief/Turned). The engine's start-location and gamemode lists come from
	-- its own copy of gametypestable, which doesn't see the rows mod_patch adds, so append them here.
	-- Entries are shallow copies of the engine's own theater/zclassic entries with ref/name changed.
	local dlc5_copy = function( dlc5_src )
		local dlc5_t = {}
		for dlc5_k, dlc5_v in pairs( dlc5_src ) do
			dlc5_t[dlc5_k] = dlc5_v
		end
		return dlc5_t
	end
	local dlc5_firstEntry = function( dlc5_list )
		if dlc5_list == nil then
			return nil
		end
		for dlc5_k, dlc5_v in pairs( dlc5_list ) do
			return dlc5_v
		end
		return nil
	end
	local dlc5_describe = function( dlc5_e )
		local dlc5_s = ""
		if dlc5_e ~= nil then
			for dlc5_k, dlc5_v in pairs( dlc5_e ) do
				dlc5_s = dlc5_s .. tostring( dlc5_k ) .. "=" .. tostring( dlc5_v ) .. ";"
			end
		end
		return dlc5_s
	end
	-- While Moon's "No Man's Land" spot is the chosen start location, show its name instead of "MOON"
	-- everywhere the map name is drawn (lobby map frame, headers, ...).
	pcall( function()
		if Engine == nil or Engine.Localize == nil or dlc5_moonNameHooked == true then
			return
		end
		dlc5_moonNameHooked = true
		local dlc5_moonNameKeys = {
			ZMUI_CLASSIC_ZM_MOON = true, ZMUI_CLASSIC_ZM_MOON_CAPS = true,
			ZMUI_ZCLASSIC_ZM_MOON = true, ZMUI_ZCLASSIC_ZM_MOON_CAPS = true
		}
		local dlc5_origLocalizeGlobal = Engine.Localize
		Engine.Localize = function( dlc5_key, ... )
			if type( dlc5_key ) == "string" and dlc5_moonNameKeys[string.upper( dlc5_key )] == true then
				local dlc5_ok, dlc5_loc = pcall( function()
					return UIExpression.DvarString( nil, "ui_zm_mapstartlocation" )
				end )
				if dlc5_ok and dlc5_loc == "nomansland" then
					if string.find( dlc5_key, "CAPS" ) ~= nil then
						return "NO MAN'S LAND"
					end
					return "No Man's Land"
				end
			end
			return dlc5_origLocalizeGlobal( dlc5_key, ... )
		end
	end )

	-- Extra start locations this mod adds: <map> = { src = <existing spot to copy>, ref = <new spot> }
	local dlc5_extraLocs = {
		zm_theater = { src = "theater", ref = "stage" },
		zm_moon = { src = "moon", ref = "nomansland" }
	}
	if Engine ~= nil and Engine.GetStartLocsZombie ~= nil and Engine.GetGamemodesZombie ~= nil then
		local dlc5_origGetLocs = Engine.GetStartLocsZombie
		local dlc5_origGetModes = Engine.GetGamemodesZombie
		Engine.GetStartLocsZombie = function( dlc5_map, ... )
			local dlc5_list = dlc5_origGetLocs( dlc5_map, ... )
			local dlc5_extra = dlc5_extraLocs[dlc5_map]
			if dlc5_extra == nil or dlc5_list == nil then
				return dlc5_list
			end
			pcall( function()
				local dlc5_source = nil
				local dlc5_count = 0
				for dlc5_k, dlc5_v in pairs( dlc5_list ) do
					dlc5_count = dlc5_count + 1
					if dlc5_v.ref == dlc5_extra.ref then
						return
					end
					if dlc5_v.ref == dlc5_extra.src then
						dlc5_source = dlc5_v
					end
				end
				if dlc5_source == nil then
					return
				end
				-- [local fix] The new spot's row lives in mod_patch.ff, which Requiem 0.3.x does not load in the
				-- frontend (only mod_load.ff). Without the row the start-loc screen crashes (UI Error 80076).
				if tonumber( UIExpression.TableLookup( nil, CoD.gametypesTable, 0, 5, 3, dlc5_extra.ref, 8 ) ) == nil or tonumber( UIExpression.TableLookup( nil, CoD.gametypesTable, 0, 5, 3, dlc5_extra.ref, 9 ) ) == nil then
					Engine.SetDvar( "dlc5_luaextraloc", tostring( dlc5_map ) .. ":" .. dlc5_extra.ref .. " skipped (no table row)" )
					return
				end
				Engine.SetDvar( "dlc5_luafields_loc", dlc5_describe( dlc5_source ) )
				local dlc5_new = dlc5_copy( dlc5_source )
				dlc5_new.ref = dlc5_extra.ref
				dlc5_list[dlc5_count + 1] = dlc5_new
			end )
			return dlc5_list
		end
		Engine.GetGamemodesZombie = function( dlc5_map, dlc5_loc, ... )
			if dlc5_map == "zm_moon" and dlc5_loc == "nomansland" then
				local dlc5_out = {}
				pcall( function()
					local dlc5_classic = dlc5_firstEntry( dlc5_origGetModes( "zm_moon", "moon" ) )
					if dlc5_classic == nil then
						return
					end
					dlc5_out[1] = dlc5_copy( dlc5_classic )
				end )
				return dlc5_out
			end
			if dlc5_map == "zm_theater" and dlc5_loc == "stage" then
				local dlc5_out = {}
				pcall( function()
					local dlc5_classic = dlc5_firstEntry( dlc5_origGetModes( "zm_theater", "theater" ) )
					if dlc5_classic == nil then
						return
					end
					Engine.SetDvar( "dlc5_luafields_mode", dlc5_describe( dlc5_classic ) )
					local dlc5_grief = dlc5_copy( dlc5_classic )
					dlc5_grief.ref = "zgrief"
					dlc5_grief.name = "ZMUI_GRIEF_CAPS"
					local dlc5_turned = dlc5_copy( dlc5_classic )
					dlc5_turned.ref = "zcleansed"
					dlc5_turned.name = "ZMUI_CLEANSED_CAPS"
					dlc5_out[1] = dlc5_grief
					dlc5_out[2] = dlc5_turned
				end )
				return dlc5_out
			end
			return dlc5_origGetModes( dlc5_map, dlc5_loc, ... )
		end
		Engine.SetDvar( "dlc5_luaengine", tostring( Engine.GetStartLocsZombie ~= dlc5_origGetLocs ) )
	end

	local dlc5_oldmt = getmetatable( LUI.createMenu )
	local dlc5_mt = {}
	if dlc5_oldmt ~= nil then
		for dlc5_k, dlc5_v in pairs( dlc5_oldmt ) do
			dlc5_mt[dlc5_k] = dlc5_v
		end
	end
	local dlc5_oldnewindex = dlc5_mt.__newindex
	dlc5_mt.__newindex = function( dlc5_t, dlc5_k, dlc5_v )
		pcall( function()
			if CoD ~= nil and CoD.dlc5_HookGameMap ~= nil then
				CoD.dlc5_HookGameMap()
			end
			if CoD ~= nil and CoD.dlc5_HookSelectMap ~= nil then
				CoD.dlc5_HookSelectMap()
			end
		end )
		if dlc5_k == "SelectStartLocZM" and type( dlc5_v ) == "function" then
			rawset( dlc5_t, dlc5_k, function( ... )
				pcall( dlc5_HookPopulate )
				return dlc5_v( ... )
			end )
			pcall( function()
				Engine.SetDvar( "dlc5_luahook", "wrapped" )
			end )
		elseif dlc5_oldnewindex ~= nil then
			dlc5_oldnewindex( dlc5_t, dlc5_k, dlc5_v )
		else
			rawset( dlc5_t, dlc5_k, dlc5_v )
		end
	end
	setmetatable( LUI.createMenu, dlc5_mt )
	Engine.SetDvar( "dlc5_luahook", "mt_installed" )
end )

-- DLC5 Five, Ascension, Shangri-La, Moon (+ No Man's Land): full-screen, full-detail map art.
-- gamemapzombie.lua draws the map picture on a full-screen element and zooms it to scale 2 on the start-location
-- screen, so only the centre quarter of the 2048 texture is ever seen (~1024 px stretched across the screen). For Five
-- every scale the picture gets is halved (2 -> 1 on the start-loc screen, 1 -> 0.5 at the start of the zoom-in), so the
-- whole texture is shown; Five's art fills its whole texture. Other maps keep their scale-2 box art.
pcall( function()
	if CoD == nil then
		return
	end
	CoD.dlc5_HookGameMap = function()
		if CoD.GameMapZombie == nil or CoD.GameMapZombie.dlc5_hooked == true then
			return
		end
		local dlc5_origSwitch = CoD.GameMapZombie.SwitchToMapDirect
		local dlc5_origDefault = CoD.GameMapZombie.DefaultAnim
		if dlc5_origSwitch == nil or dlc5_origDefault == nil then
			return
		end
		CoD.GameMapZombie.dlc5_hooked = true
		CoD.GameMapZombie.SwitchToMapDirect = function( ... )
			local dlc5_ok, dlc5_name = pcall( CoD.Zombie.GetUIMapName )
			-- [local fix] the half-scale map art is the new art in mod_patch.ff; only halve when it is loaded
			local dlc5_patchActive = false
			pcall( function()
				dlc5_patchActive = tonumber( UIExpression.TableLookup( nil, CoD.gametypesTable, 0, 5, 3, "stage", 8 ) ) ~= nil
			end )
			CoD.GameMapZombie.dlc5_full = dlc5_ok and ( dlc5_patchActive or ( DLC5_NEWART ~= nil and DLC5_NEWART[dlc5_name] == true ) ) and ( dlc5_name == "zm_pentagon" or dlc5_name == "zm_cosmodrome" or dlc5_name == "zm_temple" or dlc5_name == "zm_moon" )
			pcall( function()
				local dlc5_gm = CoD.GameMapZombie.gameMap
				if dlc5_gm ~= nil and dlc5_gm.dlc5_scaleWrapped ~= true then
					local dlc5_origScale = dlc5_gm.setScale
					dlc5_gm.setScale = function( dlc5_self, dlc5_s, ... )
						if CoD.GameMapZombie.dlc5_full == true and type( dlc5_s ) == "number" then
							dlc5_s = dlc5_s * 0.5
						end
						return dlc5_origScale( dlc5_self, dlc5_s, ... )
					end
					dlc5_gm.dlc5_scaleWrapped = true
					Engine.SetDvar( "dlc5_luagamemap", "scale_wrapped" )
				end
			end )
			return dlc5_origSwitch( ... )
		end
		CoD.GameMapZombie.DefaultAnim = function( ... )
			CoD.GameMapZombie.dlc5_full = false
			return dlc5_origDefault( ... )
		end
		Engine.SetDvar( "dlc5_luagamemap", "hooked" )
	end
	CoD.dlc5_HookGameMap()
end )

-- Map-select crash fix (reported 2026-09-25): hover a map on the globe for a few seconds, back out while the globe is
-- still moving, and its "move down finished" / "rotation finished" events arrive after the map list is gone. Stock
-- then runs GoToFirstMap / MapRotatingFinish on whatever menu is current (no mapCount) -> "number expected for loop
-- variables" -> Lua panic. Those late events are now ignored unless the current menu really is the map list.
pcall( function()
	if CoD == nil then
		return
	end
	local function dlc5_isMapList( dlc5_menu )
		return dlc5_menu ~= nil and type( dlc5_menu.mapCount ) == "number" and dlc5_menu.mapInfos ~= nil
	end
	local function dlc5_releaseInput()
		pcall( function()
			CoD.SelectMapZombie.MapRotationInput = {}
			local dlc5_cur = CoD.GameGlobeZombie.gameGlobe.currentMenu
			if dlc5_cur ~= nil and dlc5_cur.occludedBy == nil then
				dlc5_cur.m_inputDisabled = false
			end
		end )
	end
	CoD.dlc5_HookSelectMap = function()
		local dlc5_smz = CoD.SelectMapZombie
		if dlc5_smz == nil or dlc5_smz.dlc5_guarded == true or dlc5_smz.GoToFirstMap == nil then
			return
		end
		dlc5_smz.dlc5_guarded = true
		local dlc5_origFirst = dlc5_smz.GoToFirstMap
		dlc5_smz.GoToFirstMap = function( dlc5_globe, ... )
			if dlc5_globe == nil or not dlc5_isMapList( dlc5_globe.currentMenu ) then
				dlc5_releaseInput()
				return
			end
			return dlc5_origFirst( dlc5_globe, ... )
		end
		local dlc5_origRot = dlc5_smz.MapRotatingFinish
		if dlc5_origRot ~= nil then
			dlc5_smz.MapRotatingFinish = function( dlc5_globe, ... )
				if dlc5_globe == nil or not dlc5_isMapList( dlc5_globe.currentMenu ) then
					dlc5_releaseInput()
					return
				end
				return dlc5_origRot( dlc5_globe, ... )
			end
		end
		local dlc5_origIntern = dlc5_smz.NextMapInternFinish
		if dlc5_origIntern ~= nil then
			dlc5_smz.NextMapInternFinish = function( dlc5_globe, ... )
				if dlc5_globe == nil or not dlc5_isMapList( dlc5_globe.currentMenu ) then
					return
				end
				return dlc5_origIntern( dlc5_globe, ... )
			end
		end
		local dlc5_fns = { "GetMapIndexFromMapLoadName", "GetMapIndexFromPlaylistSuperCategoryID" }
		for dlc5_i = 1, #dlc5_fns do
			local dlc5_fn = dlc5_fns[dlc5_i]
			local dlc5_orig = dlc5_smz[dlc5_fn]
			if dlc5_orig ~= nil then
				dlc5_smz[dlc5_fn] = function( dlc5_menu, ... )
					if not dlc5_isMapList( dlc5_menu ) then
						return 1
					end
					return dlc5_orig( dlc5_menu, ... )
				end
			end
		end
		Engine.SetDvar( "dlc5_luaselectmap", "guarded" )
	end
	CoD.dlc5_HookSelectMap()
end )

-- [local fix] Moon (No Man's Land), Kino (stage) and the 2.0.5 map art for Moon, Kino, Five, Ascension and Shangri-La. Both live in mod_patch.ff, which Requiem does not load in the
-- menu. (1) The menu's table lookups get the mod_patch rows for moon / nomansland; (2) the Moon map-screen art is asked
-- for under names that do not exist, so Requiem builds it right away from t6game/images/<name>.iwi; (3) DLC5_NEWART
-- turns on dlc5's full-screen start-loc layout for Moon only.
pcall( function()
	if DLC5_MOON_HOOKED == true or UIExpression == nil or UIExpression.TableLookup == nil then
		return
	end
	DLC5_MOON_HOOKED = true
	DLC5_NEWART = DLC5_NEWART or {}
	DLC5_NEWART.zm_moon = true
	DLC5_NEWART.zm_theater = true
	DLC5_NEWART.zm_pentagon = true
	DLC5_NEWART.zm_cosmodrome = true
	DLC5_NEWART.zm_temple = true
	local dlc5_rowText = {
		"5,18,zm_moon,moon,ZMUI_MOON_CAPS,ZMUI_MOON_DESC,menu_zm_map_moon_blit,1,0,0,180,-50,nomansland,nomansland,nomansland,nomansland,ZMUI_MOON_LOC,50,-132,-150,-105,280,170",
		"5,21,zm_moon,nomansland,ZMUI_NOMANSLAND_CAPS,ZMUI_NOMANSLAND_DESC,menu_zm_map_moon_blit_nml,1,0,0,140,-60,moon,moon,moon,moon,ZMUI_NOMANSLAND_LOC,150,-120,74,-113,152,94",
		"6,28,zm_moon,nomansland,zclassic,0,right,NO",
		"5,0,zm_theater,theater,ZMUI_THEATER_CAPS,ZMUI_THEATER_DESC,menu_zm_map_theater_blit,1,-35,-9,180,-50,stage,stage,stage,stage,ZMUI_THEATER_LOC,65,-100,-113,-26,243,329",
		"5,20,zm_theater,stage,ZMUI_THEATER_CAPS,ZMUI_THEATER_DESC,menu_zm_map_theater_blit_stage,1,0,0,27,40,theater,theater,theater,theater,ZMUI_THEATER_LOC,380,-207,187,-107,433,253",
		"6,26,zm_theater,stage,zgrief,0,right,NO",
		"6,27,zm_theater,stage,zcleansed,0,right,NO",
		"5,16,zm_cosmodrome,cosmodrome,ZMUI_COSMODROME_CAPS,ZMUI_COSMODROME_DESC,menu_zm_map_cosmodrome_blit,1,0,0,180,-50,,,,,ZMUI_COSMODROME_LOC,-72,-188,,,,",
		"5,17,zm_pentagon,pentagon,ZMUI_PENTAGON_CAPS,ZMUI_PENTAGON_DESC,menu_zm_map_pentagon_blit,1,0,0,180,-50,,,,,ZMUI_PENTAGON_LOC,140,-51,,,,",
		"5,19,zm_temple,temple,ZMUI_TEMPLE_CAPS,ZMUI_TEMPLE_DESC,menu_zm_map_temple_blit,1,0,0,180,-50,,,,,ZMUI_TEMPLE_LOC,304,-81,,,,"
	}
	local dlc5_rows = {}
	for dlc5_ri, dlc5_line in ipairs( dlc5_rowText ) do
		local dlc5_row = {}
		for dlc5_field in string.gmatch( dlc5_line .. ",", "([^,]*)," ) do
			dlc5_row[#dlc5_row + 1] = dlc5_field
		end
		dlc5_rows[#dlc5_rows + 1] = dlc5_row
	end
	local dlc5_origTableLookup = UIExpression.TableLookup
	UIExpression.TableLookup = function( dlc5_ctrl, dlc5_tbl, ... )
		if type( dlc5_tbl ) == "string" and CoD ~= nil and type( CoD.gametypesTable ) == "string" and string.lower( dlc5_tbl ) == string.lower( CoD.gametypesTable ) then
			local dlc5_n = select( "#", ... )
			if dlc5_n >= 3 and dlc5_n % 2 == 1 then
				local dlc5_a = { ... }
				local dlc5_ret = tonumber( dlc5_a[dlc5_n] )
				if dlc5_ret ~= nil then
					for dlc5_ri, dlc5_row in ipairs( dlc5_rows ) do
						local dlc5_match = true
						for dlc5_i = 1, dlc5_n - 1, 2 do
							local dlc5_col = tonumber( dlc5_a[dlc5_i] )
							if dlc5_col == nil or dlc5_row[dlc5_col + 1] ~= tostring( dlc5_a[dlc5_i + 1] ) then
								dlc5_match = false
								break
							end
						end
						if dlc5_match then
							return dlc5_row[dlc5_ret + 1] or ""
						end
					end
				end
			end
		end
		return dlc5_origTableLookup( dlc5_ctrl, dlc5_tbl, ... )
	end
	if RegisterMaterial ~= nil then
		local dlc5_moonArt = {
			menu_zm_moon_map = "menu_dlc5_moon_map",
			menu_zm_moon_map_blur = "menu_dlc5_moon_map_blur",
			menu_zm_map_moon_blit = "menu_dlc5_moon_select",
			menu_zm_map_moon_blit_nml = "menu_dlc5_moon_select_nml",
			menu_zm_moon_zclassic_nomansland = "menu_dlc5_moon_card_nml",
			menu_zm_theater_map = "menu_dlc5_theater_map",
			menu_zm_theater_map_blur = "menu_dlc5_theater_map_blur",
			menu_zm_map_theater_blit = "menu_dlc5_theater_select",
			menu_zm_map_theater_blit_stage = "menu_dlc5_theater_select_stage",
			menu_zm_theater_zencounter_stage = "menu_dlc5_theater_card_stage",
			menu_zm_pentagon_map = "menu_dlc5_pentagon_map",
			menu_zm_pentagon_map_blur = "menu_dlc5_pentagon_map_blur",
			menu_zm_map_pentagon_blit = "menu_dlc5_pentagon_select",
			menu_zm_cosmodrome_map = "menu_dlc5_cosmodrome_map",
			menu_zm_cosmodrome_map_blur = "menu_dlc5_cosmodrome_map_blur",
			menu_zm_map_cosmodrome_blit = "menu_dlc5_cosmodrome_select",
			menu_zm_temple_map = "menu_dlc5_temple_map",
			menu_zm_temple_map_blur = "menu_dlc5_temple_map_blur",
			menu_zm_map_temple_blit = "menu_dlc5_temple_select"
		}
		local dlc5_origRegisterMaterialMoon = RegisterMaterial
		RegisterMaterial = function( dlc5_name, ... )
			if type( dlc5_name ) == "string" and dlc5_moonArt[dlc5_name] ~= nil then
				return dlc5_origRegisterMaterialMoon( dlc5_moonArt[dlc5_name], ... )
			end
			return dlc5_origRegisterMaterialMoon( dlc5_name, ... )
		end
	end
end )
