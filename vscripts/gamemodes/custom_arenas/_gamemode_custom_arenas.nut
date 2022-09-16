
///////////////////////////////////////////////////////
// ███████ ██       ██████  ██     ██     ███████ ████████  █████  ████████ ███████ 
// ██      ██      ██    ██ ██     ██     ██         ██    ██   ██    ██    ██      
// █████   ██      ██    ██ ██  █  ██     ███████    ██    ███████    ██    █████   
// ██      ██      ██    ██ ██ ███ ██          ██    ██    ██   ██    ██    ██      
// ██      ███████  ██████   ███ ███      ███████    ██    ██   ██    ██    ███████
///////////////////////////////////////////////////////
//APEX CUSTOM ARENAS GAMEMODE                                                                   
//Credits: 
//CaféDeColombiaFPS (Retículo Endoplasmático#5955) -- owner/main dev
//Capillary_J(jason9075) -- custom arenas mode
//everyone else -- advice

global function _CustomARENAS_Init
global function _RegisterLocationARENAS
global function RunARENAS

enum eTDMState
{
	IN_PROGRESS = 0
	NEXT_ROUND_NOW = 1
}

struct {
	string scriptversion = "v0.1"
    int tdmState = eTDMState.IN_PROGRESS
    int nextMapIndex = 0
	bool mapIndexChanged = true
	array<entity> playerSpawnedProps
	array<ItemFlavor> characters
	float lastTimeChatUsage
	float lastKillTimer
	entity lastKiller
	int SameKillerStoredKills=0
	array<ArenasLocSettings> locationSettings
    ArenasLocSettings& selectedLocation
	array<vector> thisroundDroppodSpawns
    entity ringBoundary
	entity previousChampion
	entity previousChallenger
	int deathPlayersCounter=0
	int maxPlayers
	int maxTeams

	array<string> mAdmins
	array<string> mChatBanned

    entity supercooldropship
	bool isshipalive = false
	array<ArenasLocSettings> droplocationSettings
    ArenasLocSettings& dropselectedLocation

	bool FallTriggersEnabled = false
	bool mapSkyToggle = false
} arenas

void function _CustomARENAS_Init()
{
	printt("[Flowstate] -> _CustomARENAS_Init")
	SurvivalFreefall_Init() //Enables freefall/skydive
	PrecacheCustomMapsProps()

    __InitAdmins()

    AddCallback_EntitiesDidLoad( __OnEntitiesDidLoad )

    AddCallback_OnClientConnected( void function(entity player) {
        thread _OnPlayerConnected(player)
        UpdatePlayerCounts()
    })

    AddSpawnCallback( "prop_survival", DissolveItem )

    AddCallback_OnPlayerKilled(void function(entity victim, entity attacker, var damageInfo) {
		thread _OnPlayerDied(victim, attacker, damageInfo)
    })

	AddClientCommandCallback("circlenow", ClientCommand_CircleNow)
	AddClientCommandCallback("god", ClientCommand_God)
	AddClientCommandCallback("ungod", ClientCommand_UnGod)
	AddClientCommandCallback("next_round", ClientCommand_NextRound)
	AddClientCommandCallback("tgive", ClientCommand_GiveWeapon)
	AddClientCommandCallback("switch_team", ClientCommand_SwitchTeam)


	thread RunARENAS()

}

void function _RegisterLocationARENAS(ArenasLocSettings locationSettings)
{
    arenas.locationSettings.append(locationSettings)
	arenas.droplocationSettings.append(locationSettings)

}

void function _OnPropDynamicSpawnedARENAS(entity prop)
{
    arenas.playerSpawnedProps.append(prop)
}

//arenas start. CapillaryJ
///////////////////////////////////////////////////////

void function RunARENAS()
//Capillary_J (jason9075)//
{
    WaitForGameState(eGameState.Playing)
    AddSpawnCallback("prop_dynamic", _OnPropDynamicSpawnedARENAS)
	
	if(!Flowstate_DoorsEnabled()){
		array<entity> doors = GetAllPropDoors()

		foreach(entity door in doors)
			if(IsValid(door))
				door.Destroy()
	}

    while(true)
	{
		SimpleChampionUI()
		WaitFrame()
	}
    WaitForever()
}

void function SimpleChampionUI()
{
	printt("Flowstate DEBUG - Game is starting.")

	foreach(player in GetPlayerArray())
		if(IsValid(player)) ScreenFade( player, 0, 0, 0, 255, 1.5, 1.5, FFADE_IN | FFADE_PURGE ) //let's do this before destroy player props so it looks good in custom maps

	DestroyPlayerPropsARENAS()
	isBrightWaterByZer0 = false

	SetGameState(eGameState.Playing)
	arenas.tdmState = eTDMState.IN_PROGRESS
	arenas.FallTriggersEnabled = true

	foreach(player in GetPlayerArray())
	{
			if(IsValid(player))
			{
				_HandleRespawnARENAS(player)
				player.UnforceStand()
				player.UnfreezeControlsOnServer()
				HolsterAndDisableWeapons( player )
			}
	}

	if (!arenas.mapIndexChanged)
	{
		arenas.nextMapIndex = (arenas.nextMapIndex + 1 ) % arenas.locationSettings.len()
	}

	if (FlowState_LockPOI()) {
		arenas.nextMapIndex = FlowState_LockedPOI()
	}

	int choice = arenas.nextMapIndex
	arenas.mapIndexChanged = false
	arenas.selectedLocation = arenas.locationSettings[choice]
	arenas.thisroundDroppodSpawns = GetNewFFADropShipLocations(arenas.selectedLocation.name, GetMapName())
	printt("Flowstate DEBUG - Next round location is: " + arenas.selectedLocation.name)

	if(GetMapName() == "mp_rr_desertlands_64k_x_64k" || GetMapName() == "mp_rr_desertlands_64k_x_64k_nx" || GetMapName() == "mp_rr_canyonlands_mu1" || GetMapName() == "mp_rr_canyonlands_mu1_night" || GetMapName() == "mp_rr_canyonlands_64k_x_64k")
	{
		thread CreateShipRoomFallTriggers()
	}

	if(arenas.selectedLocation.name == "TTV Building" && FlowState_ExtrashieldsEnabled()){
		DestroyPlayerPropsARENAS()
		CreateGroundMedKit(<10725, 5913,-4225>)
	} else if(arenas.selectedLocation.name == "Skill trainer By Colombia" && FlowState_ExtrashieldsEnabled()){
		DestroyPlayerPropsARENAS()
		CreateGroundMedKit(<17247,31823,-310>)
		thread SkillTrainerLoad()
	} else if(arenas.selectedLocation.name == "Skill trainer By Colombia" )
	{
		printt("Flowstate DEBUG - creating props for Skill Trainer.")
		DestroyPlayerPropsARENAS()
		thread SkillTrainerLoad()
	} else if(arenas.selectedLocation.name == "Brightwater By Zer0bytes" )
	{
		printt("Flowstate DEBUG - creating props for Brightwater.")
		isBrightWaterByZer0 = true
		DestroyPlayerPropsARENAS()
		thread WorldEntities()
		wait 1
		thread BrightwaterLoad()
		wait 1.5
		thread BrightwaterLoad2()
		wait 1.5
		thread BrightwaterLoad3()
	} else if(arenas.selectedLocation.name == "Cave By BlessedSeal" ){
		printt("Flowstate DEBUG - creating props for Cave.")
		DestroyPlayerPropsARENAS()
		thread SpawnEditorPropsSeal()
	} else if(arenas.selectedLocation.name == "Gaunlet" && FlowState_ExtrashieldsEnabled()){
		DestroyPlayerPropsARENAS()
		printt("Flowstate DEBUG - creating Gaunlet Extrashield.")
		CreateGroundMedKit(<-21289, -12030, 3060>)
	} else if (arenas.selectedLocation.name == "White Forest By Zer0Bytes"){
		DestroyPlayerPropsARENAS()
		printt("Flowstate DEBUG - creating props for White Forest.")
		thread SpawnWhiteForestProps()
	} else if (arenas.selectedLocation.name == "Custom map by Biscutz"){
		DestroyPlayerPropsARENAS()
		printt("Flowstate DEBUG - creating props for Map by Biscutz.")
		thread LoadMapByBiscutz1()
		thread LoadMapByBiscutz2()
	}
	foreach(player in GetPlayerArray())
	{
		try {
			if(IsValid(player))
			{
				RemoveCinematicFlag(player, CE_FLAG_HIDE_MAIN_HUD | CE_FLAG_EXECUTION)
				player.SetThirdPersonShoulderModeOff()
				_HandleRespawnARENAS(player)
				ClearInvincible(player)
				DeployAndEnableWeapons(player)
				EnableOffhandWeapons( player )

				entity primary = player.GetNormalWeapon( WEAPON_INVENTORY_SLOT_PRIMARY_0 )
				entity secondary = player.GetNormalWeapon( WEAPON_INVENTORY_SLOT_PRIMARY_1 )
				entity tactical = player.GetOffhandWeapon( OFFHAND_INVENTORY )
				entity ultimate = player.GetOffhandWeapon( OFFHAND_LEFT )

				if(IsValid(primary) && primary.UsesClipsForAmmo())
					primary.SetWeaponPrimaryClipCount(primary.GetWeaponPrimaryClipCountMax())
				if(IsValid(secondary) && secondary.UsesClipsForAmmo())
					secondary.SetWeaponPrimaryClipCount( secondary.GetWeaponPrimaryClipCountMax())
				if(IsValid(tactical) && tactical.UsesClipsForAmmo())
					tactical.SetWeaponPrimaryClipCount( tactical.GetWeaponPrimaryClipCountMax() )
				if(IsValid(ultimate) && ultimate.UsesClipsForAmmo())
					ultimate.SetWeaponPrimaryClipCount( ultimate.GetWeaponPrimaryClipCountMax() )
			}
		} catch(e3){}
	}

	printt("Flowstate DEBUG - Clearing last round stats.")
	foreach(player in GetPlayerArray())
		{
			if(IsValidPlayer(player))
			{
				player.p.playerDamageDealt = 0.0
				if (FlowState_ResetKillsEachRound() && IsValidPlayer(player))
				{
					player.SetPlayerNetInt("kills", 0) //Reset for kills
					player.SetPlayerNetInt("assists", 0) //Reset for deaths
				}
			}
		}
	ResetAllPlayerStats()
	arenas.ringBoundary = CreateRingBoundary(arenas.selectedLocation)
	printt("Flowstate DEBUG - Bubble created, executing SimpleChampionUI.")

	float endTime = Time() + FlowState_RoundTime()
	printt("Flowstate DEBUG - Arenas gameloop Round started.")

	foreach(player in GetPlayerArray())
		{
		thread WpnPulloutOnRespawn(player)
		}

	if(GetCurrentPlaylistVarBool("flowstateEndlessFFAorTDM", false ))
	{
		while(true)
		{
			WaitFrame()
		}
	} else if(Flowstate_EnableAutoChangeLevel())
		thread AutoChangeLevelThread(endTime)

	if (FlowState_Timer()){
	while( Time() <= endTime )
		{
			if(Time() == endTime-900)
			{
					foreach(player in GetPlayerArray())
					{
						if(IsValid(player))
						{
							Message(player,"15 MINUTES REMAINING!","", 5)
						}
					}
				}
				if(Time() == endTime-600)
				{
					foreach(player in GetPlayerArray())
					{
						if(IsValid(player))
						{
							Message(player,"10 MINUTES REMAINING!","", 5)
						}
					}
				}
				if(Time() == endTime-300)
				{
					foreach(player in GetPlayerArray())
					{
						if(IsValid(player))
						{
							Message(player,"5 MINUTES REMAINING!","", 5)
						}
					}
				}
				if(Time() == endTime-120)
				{
					foreach(player in GetPlayerArray())
					{
						if(IsValid(player))
						{
							Message(player,"2 MINUTES REMAINING!","", 5)
						}
					}
				}
				if(Time() == endTime-60)
				{
					foreach(player in GetPlayerArray())
					{
						if(IsValid(player))
						{
							Message(player,"1 MINUTE REMAINING!","", 5, "diag_ap_aiNotify_circleMoves60sec")
						}
					}
				}
				if(Time() == endTime-30)
				{
					foreach(player in GetPlayerArray())
					{
						if(IsValid(player))
						{
							Message(player,"30 SECONDS REMAINING!","", 5, "diag_ap_aiNotify_circleMoves30sec")
						}
					}
				}
				if(Time() == endTime-10)
				{
					foreach(player in GetPlayerArray())
					{
						if(IsValid(player))
						{
							Message(player,"10 SECONDS REMAINING!", "\n The battle is over.", 8, "diag_ap_aiNotify_circleMoves10sec")
						}
					}
				}
				if(arenas.tdmState == eTDMState.NEXT_ROUND_NOW){
					printt("Flowstate DEBUG - tdmState is eTDMState.NEXT_ROUND_NOW Loop ended.")
					break}
				WaitFrame()
			}
	}
	else if (!FlowState_Timer() ){
		while( Time() <= endTime )
			{
			if(arenas.tdmState == eTDMState.NEXT_ROUND_NOW) {
				printt("Flowstate DEBUG - tdmState is eTDMState.NEXT_ROUND_NOW Loop ended.")
				break}
				WaitFrame()
			}
	}

	foreach(player in GetPlayerArray())
		{
			if(IsValid(player) && !IsAlive(player)){
					_HandleRespawnARENAS(player)
					ClearInvincible(player)
					player.SetThirdPersonShoulderModeOn()
					HolsterAndDisableWeapons( player )
			}else if(IsValid(player) && IsAlive(player))
				{
					PlayerRestoreHP(player, 100, Equipment_GetDefaultShieldHP())
					player.SetThirdPersonShoulderModeOn()
					HolsterAndDisableWeapons( player )
			}
		}

	wait 1
	foreach(entity champion in GetPlayerArray())
		{
			array<ItemFlavor> characterSkinsA = GetValidItemFlavorsForLoadoutSlot( ToEHI( champion ), Loadout_CharacterSkin( LoadoutSlot_GetItemFlavor( ToEHI( champion ), Loadout_CharacterClass() ) ) )
			CharacterSkin_Apply( champion, characterSkinsA[0])
		}
	foreach(player in GetPlayerArray())
		{

		if(IsValid(player)){
		AddCinematicFlag(player, CE_FLAG_HIDE_MAIN_HUD | CE_FLAG_EXECUTION)
		}
		wait 0.1
		}

	wait 7

	foreach(player in GetPlayerArray())
		{
			if(IsValid(player)){
			ClearInvincible(player)
			RemoveCinematicFlag(player, CE_FLAG_HIDE_MAIN_HUD | CE_FLAG_EXECUTION)
			player.SetThirdPersonShoulderModeOff()
			}
		}
	arenas.ringBoundary.Destroy()
}

void function _HandleRespawnARENAS(entity player)
//By Capillary_J (jason9075)//
{
	if(!IsValid(player)) return

	if( player.IsObserver())
    {
		player.StopObserverMode()
        Remote_CallFunction_NonReplay(player, "ServerCallback_KillReplayHud_Deactivate")
    }

	printt("Flowstate DEBUG - Tping arenas player to Lobby.", player)

	// CharSelect(player)todo???
	arenas.characters = clone GetAllCharacters()
	ItemFlavor character = arenas.characters[0]
	CharacterSelect_AssignCharacter( ToEHI( player ), character )
    ItemFlavor ultiamteAbility = CharacterClass_GetUltimateAbility( character )
    ItemFlavor tacticalAbility = CharacterClass_GetTacticalAbility( character )
    player.GiveOffhandWeapon(CharacterAbility_GetWeaponClassname(tacticalAbility), OFFHAND_TACTICAL, [] )
    player.GiveOffhandWeapon( CharacterAbility_GetWeaponClassname(ultiamteAbility), OFFHAND_ULTIMATE, [] )


	if(!IsAlive(player)) {DoRespawnPlayer( player, null )}

	Survival_SetInventoryEnabled( player, true )
	player.SetPlayerNetBool( "pingEnabled", true )
	player.SetHealth(100)
	Inventory_SetPlayerEquipment(player, "armor_pickup_lv2", "armor")
	player.SetShieldHealth(75)
	TpPlayerToSpawnPoint(player)
	player.UnforceStand()
	player.UnfreezeControlsOnServer()
	HolsterAndDisableWeapons( player )
}

void function WpnPulloutOnRespawn(entity player)
{
	// if(IsValid( player ) && IsAlive(player) && IsValid( player.GetNormalWeapon( WEAPON_INVENTORY_SLOT_PRIMARY_1 )))
	// {
	// 	player.SetActiveWeaponBySlot(eActiveInventorySlot.mainHand, WEAPON_INVENTORY_SLOT_PRIMARY_1)
	// 	player.GetNormalWeapon( WEAPON_INVENTORY_SLOT_PRIMARY_1 ).SetWeaponCharm( $"mdl/props/charm/charm_nessy.rmdl", "CHARM")
	// }
	// wait 0.7
	// if(IsValid( player ) && IsAlive(player) && IsValid( player.GetNormalWeapon( WEAPON_INVENTORY_SLOT_PRIMARY_0 )))
	// {
	// 	player.SetActiveWeaponBySlot(eActiveInventorySlot.mainHand, WEAPON_INVENTORY_SLOT_PRIMARY_0)
	// 	player.GetNormalWeapon( WEAPON_INVENTORY_SLOT_PRIMARY_0 ).SetWeaponCharm( $"mdl/props/charm/charm_nessy.rmdl", "CHARM")
	// }
}

void function ResetAllPlayerStats()
{
    foreach(player in GetPlayerArray()) {
        if(!IsValid(player)) continue
        ResetPlayerStats(player)
    }
}

void function ResetPlayerStats(entity player)
{
    player.SetPlayerGameStat( PGS_SCORE, 0 )
    player.SetPlayerGameStat( PGS_DEATHS, 0)
    player.SetPlayerGameStat( PGS_TITAN_KILLS, 0)
    player.SetPlayerGameStat( PGS_KILLS, 0)
    player.SetPlayerGameStat( PGS_PILOT_KILLS, 0)
    player.SetPlayerGameStat( PGS_ASSISTS, 0)
    player.SetPlayerGameStat( PGS_ASSAULT_SCORE, 0)
    player.SetPlayerGameStat( PGS_DEFENSE_SCORE, 0)
    player.SetPlayerGameStat( PGS_ELIMINATED, 0)
}

void function DestroyPlayerPropsARENAS()
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
    foreach(prop in arenas.playerSpawnedProps)
    {
        if(IsValid(prop))
            prop.Destroy()
    }
    arenas.playerSpawnedProps.clear()
	WaitFrame()
}

//       ██ ██████  ██ ███    ██  ██████  ██
//      ██  ██   ██ ██ ████   ██ ██        ██
//      ██  ██████  ██ ██ ██  ██ ██   ███  ██
//      ██  ██   ██ ██ ██  ██ ██ ██    ██  ██
//       ██ ██   ██ ██ ██   ████  ██████  ██
// Purpose: Create The RingBoundary
entity function CreateRingBoundary(ArenasLocSettings location)
{
	//We watch the ring fx with this entity in the threads
	entity circle = CreateEntity( "prop_script" )
	circle.SetValueForModelKey( $"mdl/fx/ar_survival_radius_1x100.rmdl" )
	circle.kv.fadedist = -1
	circle.kv.modelscale = location.radius
	circle.kv.renderamt = 255
	circle.kv.rendercolor = FlowState_RingColor()
	circle.kv.solid = 0
	circle.kv.VisibilityFlags = ENTITY_VISIBLE_TO_EVERYONE
	circle.SetOrigin( location.center )
	circle.SetAngles( <0, 0, 0> )
	circle.NotSolid()
	circle.DisableHibernation()
    circle.Minimap_SetObjectScale( location.radius / SURVIVAL_MINIMAP_RING_SCALE )
    circle.Minimap_SetAlignUpright( true )
    circle.Minimap_SetZOrder( 2 )
    circle.Minimap_SetClampToEdge( true )
    circle.Minimap_SetCustomState( eMinimapObject_prop_script.OBJECTIVE_AREA )
	SetTargetName( circle, "hotZone" )
	DispatchSpawn(circle)

    foreach ( player in GetPlayerArray() )
    {
        circle.Minimap_AlwaysShow( 0, player )
    }

	SetDeathFieldParams( location.center, location.radius, location.radius, 90000, 99999 ) // This function from the API allows client to read ringRadius from server so we can use visual effects in shared function. Colombia

	//Audio thread for ring
	foreach(sPlayer in GetPlayerArray())
		thread AudioThread(circle, sPlayer, location.radius)

	//Damage thread for ring
	thread RingDamage(circle, location.radius)

    return circle
}

void function AudioThread(entity circle, entity player, float radius)
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
	EndSignal(player, "OnDestroy")
	entity audio
	string soundToPlay = "Survival_Circle_Edge_Small"
	OnThreadEnd(
		function() : ( soundToPlay, audio)
		{

			if(IsValid(audio)) audio.Destroy()
		}
	)
	audio = CreateScriptMover()
	audio.SetOrigin( circle.GetOrigin() )
	audio.SetAngles( <0, 0, 0> )
	EmitSoundOnEntity( audio, soundToPlay )

	while(IsValid(circle)){
			if(!IsValid(player)) continue
			vector fwdToPlayer   = Normalize( <player.GetOrigin().x, player.GetOrigin().y, 0> - <circle.GetOrigin().x, circle.GetOrigin().y, 0> )
			vector circleEdgePos = circle.GetOrigin() + (fwdToPlayer * radius)
			circleEdgePos.z = player.EyePosition().z
			if ( fabs( circleEdgePos.x ) < 61000 && fabs( circleEdgePos.y ) < 61000 && fabs( circleEdgePos.z ) < 61000 )
			{
				audio.SetOrigin( circleEdgePos )
			}
		WaitFrame()
	}

	StopSoundOnEntity(audio, soundToPlay)
}

void function RingDamage( entity circle, float currentRadius)
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
	WaitFrame()
	const float DAMAGE_CHECK_STEP_TIME = 1.5

	while ( IsValid(circle) )
	{
		foreach ( dummy in GetNPCArray() )
		{
			if ( dummy.IsPhaseShifted() )
				continue

			float playerDist = Distance2D( dummy.GetOrigin(), circle.GetOrigin() )
			if ( playerDist > currentRadius )
			{
				dummy.TakeDamage( int( Deathmatch_GetOOBDamagePercent() / 100 * float( dummy.GetMaxHealth() ) ), null, null, { scriptType = DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, damageSourceId = eDamageSourceId.deathField } )
			}
		}

		foreach ( player in GetPlayerArray_Alive() )
		{
			if ( player.IsPhaseShifted() )
				continue

			float playerDist = Distance2D( player.GetOrigin(), circle.GetOrigin() )
			if ( playerDist > currentRadius )
			{
				Remote_CallFunction_Replay( player, "ServerCallback_PlayerTookDamage", 0, 0, 0, 0, DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, eDamageSourceId.deathField, null )
				player.TakeDamage( int( Deathmatch_GetOOBDamagePercent() / 100 * float( player.GetMaxHealth() ) ), null, null, { scriptType = DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, damageSourceId = eDamageSourceId.deathField } )
			}
		}
		wait DAMAGE_CHECK_STEP_TIME
	}
}

void function PlayerRestoreHP(entity player, float health, float shields)
{
	if(!IsValid(player)) return
	if(!IsAlive( player)) return

	player.SetHealth( health )
	Inventory_SetPlayerEquipment(player, "helmet_pickup_lv3", "helmet")
	if(shields == 0) return
	else if(shields <= 50)
		Inventory_SetPlayerEquipment(player, "armor_pickup_lv1", "armor")
	else if(shields <= 75)
		Inventory_SetPlayerEquipment(player, "armor_pickup_lv2", "armor")
	else if(shields <= 100)
		Inventory_SetPlayerEquipment(player, "armor_pickup_lv3", "armor")
	player.SetShieldHealth( shields )
}

void function _OnPlayerConnected(entity player){
    if(!IsValid(player)) return

	arenas.characters = clone GetAllCharacters()
	ItemFlavor character = arenas.characters[0]
	CharacterSelect_AssignCharacter( ToEHI( player ), character )
    ItemFlavor ultiamteAbility = CharacterClass_GetUltimateAbility( character )
    ItemFlavor tacticalAbility = CharacterClass_GetTacticalAbility( character )
    player.GiveOffhandWeapon(CharacterAbility_GetWeaponClassname(tacticalAbility), OFFHAND_TACTICAL, [] )
    player.GiveOffhandWeapon( CharacterAbility_GetWeaponClassname(ultiamteAbility), OFFHAND_ULTIMATE, [] )

	if(GetMapName() == "mp_rr_aqueduct")
	    if(IsValid(player)) {
	    	CreatePanelText( player, "Flowstate", "", <3705.10547, -4487.96484, 470.03302>, <0, 190, 0>, false, 2 )
	    	CreatePanelText( player, "Flowstate", "", <1111.36584, -5447.26221, 655.479858>, <0, -90, 0>, false, 2 )
	    }

	Message(player, "FLOWSTATE: Arenas", "Type 'commands' in console to see the available console commands. ", 10)

	if(IsValid(player))
	{
		switch(GetGameState())
		{
			case eGameState.MapVoting:
			    {
			    	if(!IsAlive(player))
			    	{
			    		_HandleRespawnARENAS(player)
			    		ClearInvincible(player)
			    	}

			    	player.SetThirdPersonShoulderModeOn()
			    	player.UnforceStand()
			    	player.FreezeControlsOnServer()
			    }
			break
			case eGameState.WaitingForPlayers:
				{
					_HandleRespawnARENAS(player)
					ClearInvincible(player)
					player.UnfreezeControlsOnServer()
				}
			break
			case eGameState.Playing:
				{
					player.UnfreezeControlsOnServer()

					_HandleRespawnARENAS(player)

                    array<string> InValidMaps = [
						"mp_rr_canyonlands_staging",
						"Skill trainer By Colombia",
						"Custom map by Biscutz",
						"White Forest By Zer0Bytes",
						"Brightwater By Zer0bytes",
						"Overflow",
						"Drop-Off"
					]

					bool DropPodOnSpawn = GetCurrentPlaylistVarBool("flowstateDroppodsOnPlayerConnected", false )
					bool IsStaging = InValidMaps.find( GetMapName() ) != -1
					bool IsMapValid = InValidMaps.find(arenas.selectedLocation.name) != -1
					if(arenas.tdmState == eTDMState.NEXT_ROUND_NOW || !DropPodOnSpawn || IsStaging || IsMapValid )
						_HandleRespawnARENAS(player)
					else
					{
						if(arenas.thisroundDroppodSpawns.len() > 0){
							player.p.isPlayerSpawningInDroppod = true
							thread AirDropFireteam( arenas.thisroundDroppodSpawns[RandomIntRangeInclusive(0, arenas.thisroundDroppodSpawns.len()-1)] + <0,0,15000>, <0,180,0>, "idle", 0, "droppod_fireteam", player )
							_HandleRespawnARENAS(player)
							player.SetAngles( <0,180,0> )
						}
						else
							_HandleRespawnARENAS(player)
					}

					ClearInvincible(player)

				}
				break
			default:
				break
		}
	}

	thread __HighPingCheck( player )
}

void function __HighPingCheck(entity player)
{
	wait 12
    if(!IsValid(player)) return

	if ( FlowState_KickHighPingPlayer() && (int(player.GetLatency()* 1000) - 40) > FlowState_MaxPingAllowed() )
	{
		player.FreezeControlsOnServer()
		player.ForceStand()
		HolsterAndDisableWeapons( player )

		Message(player, "FLOWSTATE KICK", "Admin has enabled a ping limit: " + FlowState_MaxPingAllowed() + " ms. \n Your ping is too high: " + (int(player.GetLatency()* 1000) - 40) + " ms.", 3)

		wait 3
		
		if(!IsValid(player)) return
		printl("[Flowstate] -> Kicking " + player.GetPlayerName() + " -> [High Ping]")
		ServerCommand( "sv_kick " + player.GetPlayerName() )
		UpdatePlayerCounts()
	} else if(GameRules_GetGameMode() == "custom_arenas"){
		Message(player, "FLOWSTATE", "Your latency: " + (int(player.GetLatency()* 1000) - 40) + " ms."
		, 5)
	}
}

void function _OnPlayerDied(entity victim, entity attacker, var damageInfo)
{
	CreateFlowStateDeathBoxForPlayer(victim, attacker, damageInfo)

	switch(GetGameState())
    {
        case eGameState.Playing:
            // Víctim
            void functionref() victimHandleFunc = void function() : (victim, attacker, damageInfo) {
	    		wait 1
	    		if(!IsValid(victim)) return

	    		if(arenas.tdmState != eTDMState.NEXT_ROUND_NOW && IsValid(victim) && IsValid(attacker) && Spectator_GetReplayIsEnabled() && ShouldSetObserverTarget( attacker )){
	    			victim.SetObserverTarget( attacker )
	    			victim.SetSpecReplayDelay( 4 )
	    			victim.StartObserverMode( OBS_MODE_IN_EYE )
	    			Remote_CallFunction_NonReplay(victim, "ServerCallback_KillReplayHud_Activate")
	    		}

	    		int invscore = victim.GetPlayerGameStat( PGS_DEATHS )
	    		invscore++
	    		victim.SetPlayerGameStat( PGS_DEATHS, invscore)

	    		//Add a death to the victim
	    		int invscore2 = victim.GetPlayerNetInt( "assists" )
	    		invscore2++
	    		victim.SetPlayerNetInt( "assists", invscore2 )

	    		if(arenas.tdmState != eTDMState.NEXT_ROUND_NOW)
	    		    wait Deathmatch_GetRespawnDelay()

				
				if(IsValid(victim)) {
					// victim.SetObserverTarget( attacker )
					// victim.SetSpecReplayDelay( 2 )
                	// victim.StartObserverMode( OBS_MODE_IN_EYE )
					// Remote_CallFunction_NonReplay(victim, "ServerCallback_KillReplayHud_Activate")
					_HandleRespawnARENAS(victim)
				}
	    	}

            // Attacker
            void functionref() attackerHandleFunc = void function() : (victim, attacker, damageInfo)
	    	{
	    		if(IsValid(attacker) && attacker.IsPlayer() && IsAlive(attacker) && attacker != victim)
                {
	    			if(FlowState_KillshotEnabled())
					{
	    			    DamageInfo_AddCustomDamageType( damageInfo, DF_KILLSHOT )
	    			    thread EmitSoundOnEntityOnlyToPlayer( attacker, attacker, "flesh_bulletimpact_downedshot_1p_vs_3p" )
	    			}

	    			GameRules_SetTeamScore(attacker.GetTeam(), GameRules_GetTeamScore(attacker.GetTeam()) + 1)
	    			if(attacker.IsPlayer()) attacker.p.lastKillTimer = Time()
	    		}
            }
	    	thread victimHandleFunc()
            thread attackerHandleFunc()
        break
        default:
	    break
    }

	arenas.deathPlayersCounter++
	if(arenas.deathPlayersCounter == 1 )
	{
		foreach (player in GetPlayerArray())
			if(IsValid(player))
				thread EmitSoundOnEntityExceptToPlayer( player, player, "diag_ap_aiNotify_diedFirst" )
	}

	if(attacker.IsPlayer())
	    arenas.lastKiller = attacker
	UpdatePlayerCounts()
}

void function __InitAdmins()
{
	array<string> Split = split( GetCurrentPlaylistVarString("Admins", "" ) , " ")

	foreach(string data in Split)
	{
		string username = strip(data)
		if(username != " " && arenas.mAdmins.find(username) == -1)
		arenas.mAdmins.append(username)
	}
}

void function __OnEntitiesDidLoad()
{
	switch(GetMapName())
    {
    	case "mp_rr_canyonlands_staging": SpawnMapPropsFR(); break
    	case "mp_rr_arena_composite":
		{
			array<entity> badMovers = GetEntArrayByClass_Expensive( "script_mover" )
			foreach(mover in badMovers)
				if( IsValid(mover) ) mover.Destroy()
			break
		}
    }
}

void function DissolveItem(entity prop)
{
	thread (void function( entity prop) {
		wait 4
	    if(prop == null || !IsValid(prop))
	    	return

	    entity par = prop.GetParent()
	    if(par && par.GetClassName() == "prop_physics" && IsValid(prop))
	    	prop.Dissolve(ENTITY_DISSOLVE_CORE, <0,0,0>, 200)
	}) ( prop )
}

bool function ClientCommand_CircleNow(entity player, array<string> args)
{
	if( IsValid(player) && !IsAdmin( player)) return false

	SummonPlayersInACircle(player)

	return true
}

bool function ClientCommand_God(entity player, array<string> args)
{
	if( !IsValid(player) || IsValid(player) && !IsAdmin(player) ) return false

	player.MakeInvisible()
	MakeInvincible(player)
	HolsterAndDisableWeapons(player)

	return true
}


bool function ClientCommand_UnGod(entity player, array<string> args)
{
	if( !IsValid(player) || IsValid(player) && !IsAdmin(player) ) return false

	player.MakeVisible()
	ClearInvincible(player)
	EnableOffhandWeapons( player )
	DeployAndEnableWeapons(player)

	return true
}

bool function ClientCommand_GiveWeapon(entity player, array<string> args)
{
    if ( FlowState_AdminTgive() && !IsAdmin(player) )
		return false

	if(args.len() < 2) return false

	entity weapon

    switch(args[0])
    {
        case "p":
        case "primary":
            entity primary = player.GetNormalWeapon( WEAPON_INVENTORY_SLOT_PRIMARY_0 )
            if( IsValid( primary ) ){
				player.TakeWeaponByEntNow( primary )
				weapon = player.GiveWeapon(args[1], WEAPON_INVENTORY_SLOT_PRIMARY_0)
			}
        break
        case "s":
        case "secondary":
            entity secondary = player.GetNormalWeapon( WEAPON_INVENTORY_SLOT_PRIMARY_1 )
            if( IsValid( secondary ) ) {
				player.TakeWeaponByEntNow( secondary )
				weapon = player.GiveWeapon(args[1], WEAPON_INVENTORY_SLOT_PRIMARY_1)
			}
        break
        case "t":
        case "tactical":
            entity tactical = player.GetOffhandWeapon( OFFHAND_TACTICAL )
			if( IsValid( tactical ) ) {
				float oldTacticalChargePercent = float( tactical.GetWeaponPrimaryClipCount()) / float(tactical.GetWeaponPrimaryClipCountMax() )
				player.TakeOffhandWeapon( OFFHAND_TACTICAL )

				weapon = player.GiveOffhandWeapon(args[1], OFFHAND_TACTICAL)
				entity newTactical = player.GetOffhandWeapon( OFFHAND_TACTICAL )
				newTactical.SetWeaponPrimaryClipCount( int( newTactical.GetWeaponPrimaryClipCountMax() * oldTacticalChargePercent ) )
			}
        break
        case "u":
        case "ultimate":
            entity ultimate = player.GetOffhandWeapon( OFFHAND_ULTIMATE )
            if( IsValid( ultimate ) )
			{
				player.TakeOffhandWeapon( OFFHAND_ULTIMATE )
				weapon = player.GiveOffhandWeapon(args[1], OFFHAND_ULTIMATE)
			}
        break
    }

    if( args.len() > 2 )
    {
        try {
            weapon.SetMods(args.slice(2, args.len()))
        }
        catch( e2 ) {
            print("invalid mod")
        }
    }
    if( IsValid(weapon) && !weapon.IsWeaponOffhand() )
		player.SetActiveWeaponBySlot(eActiveInventorySlot.mainHand, GetSlotForWeapon(player, weapon))

    return true
}

bool function ClientCommand_NextRound(entity player, array<string> args)
{
    if(IsAdmin( player) && args.len()) {
        if (args[0] == "now")
        {
           arenas.tdmState = eTDMState.NEXT_ROUND_NOW ; arenas.mapIndexChanged = false
	       return true
        }

        int mapIndex = int(args[0])
        arenas.nextMapIndex = (((mapIndex >= 0 ) && (mapIndex < arenas.locationSettings.len())) ? mapIndex : RandomIntRangeInclusive(0, arenas.locationSettings.len() - 1))
        arenas.mapIndexChanged = true

	    if(args.len() > 1){
	    	if (args[1] == "now")
	    	   arenas.tdmState = eTDMState.NEXT_ROUND_NOW
	    }
	} else 
		return false

	return true
}

bool function ClientCommand_SwitchTeam(entity player, array<string> args)
{
	int team = player.GetTeam()
	if(team==TEAM_MILITIA){
		SetTeam(player, TEAM_IMC)	
	}else{
		SetTeam(player, TEAM_MILITIA)	
	}
	return true
}

void function CreateFlowStateDeathBoxForPlayer( entity victim, entity attacker, var damageInfo )
{
	entity deathBox = FlowState_CreateDeathBox( victim, true )

	foreach ( invItem in FlowStateGetAllDroppableItems( victim ) )
	{
		//Message(victim,"DEBUG", invItem.type.tostring(), 10)
		if( invItem.type == 44 || invItem.type == 45 || invItem.type == 46 || invItem.type == 47 || invItem.type == 48 || invItem.type == 53 || invItem.type == 54 || invItem.type == 55 || invItem.type == 56 )
		    continue
		else{
		    LootData data = SURVIVAL_Loot_GetLootDataByIndex( invItem.type )
		    entity loot = SpawnGenericLoot( data.ref, deathBox.GetOrigin(), deathBox.GetAngles(), invItem.count )
		    AddToDeathBox( loot, deathBox )
		}
	}

	UpdateDeathBoxHighlight( deathBox )

	foreach ( func in svGlobal.onDeathBoxSpawnedCallbacks )
		func( deathBox, attacker, damageInfo != null ? DamageInfo_GetDamageSourceIdentifier( damageInfo ) : 0 )
}

bool function IsAdmin( entity player )
{
    return arenas.mAdmins.find(player.GetPlayerName()) != -1
}

void function SummonPlayersInACircle(entity player0)
{
	vector pos = player0.GetOrigin()
	pos.z += 5
	Message(player0,"CIRCLE FIGHT NOW!", "", 5)
    for(int i = 0 ; i < GetPlayerArray().len() ; i++)
	{
		entity p = GetPlayerArray()[i]
		if(!IsValid( p ) || p == player0)
		    continue

		float r = float(i) / float( GetPlayerArray().len() ) * 2 * PI
		TeleportFRPlayer(p, pos + 150.0 * <sin( r ), cos( r ), 0.0>, <0, 0, 0>)
		Message(p,"CIRCLE FIGHT NOW!", "", 5)
	}
}

entity function FlowState_CreateDeathBox( entity player, bool hasCard )
{
	entity box = CreatePropDeathBox_NoDispatchSpawn( DEATH_BOX, player.GetOrigin(), <0, 45, 0>, 6 )
	box.kv.fadedist = 10000
	if ( hasCard )
		SetTargetName( box, DEATH_BOX_TARGETNAME )

	DispatchSpawn( box )

	box.RemoveFromAllRealms()
	box.AddToOtherEntitysRealms( player )
	box.Solid()
	box.SetUsable()
	box.SetUsableValue( USABLE_BY_ALL | USABLE_CUSTOM_HINTS )
	box.SetOwner( player )
	box.SetNetInt( "ownerEHI", player.GetEncodedEHandle() )

	if ( hasCard )
	{
		box.SetNetBool( "overrideRUI", false )
		box.SetCustomOwnerName( player.GetPlayerName() )
		box.SetNetInt( "characterIndex", ConvertItemFlavorToLoadoutSlotContentsIndex( Loadout_CharacterClass() , LoadoutSlot_GetItemFlavor( ToEHI( player ) , Loadout_CharacterClass() ) ) )
	}

	if ( hasCard )
	{
		Highlight_SetNeutralHighlight( box, "sp_objective_entity" )
		Highlight_ClearNeutralHighlight( box )

		vector restPos = box.GetOrigin()
		vector fallPos = restPos + < 0, 0, 54 >

		thread (void function( entity box , vector restPos , vector fallPos) {
			entity mover = CreateScriptMover( restPos, box.GetAngles(), 0 )
			if ( IsValid( box ) )
				{
				box.SetParent( mover, "", true )
				mover.NonPhysicsMoveTo( fallPos, 0.5, 0.0, 0.5 )
				}
			wait 0.5
			if ( IsValid( box ) )
				mover.NonPhysicsMoveTo( restPos, 0.5, 0.5, 0.0 )
			wait 0.5
			if ( IsValid( box ) )
				box.ClearParent()
			if ( IsValid( mover ) )
				mover.Destroy()

		}) ( box , restPos , fallPos)

		thread (void function( entity box) {
			wait 120
			if(IsValid(box))
				box.Destroy()
		}) ( box )
	}

	return box
}

array<ConsumableInventoryItem> function FlowStateGetAllDroppableItems( entity player )
{
	array<ConsumableInventoryItem> final = []

	// Consumable inventory
	final.extend( SURVIVAL_GetPlayerInventory( player ) )

	// Weapon related items
	foreach ( weapon in SURVIVAL_GetPrimaryWeapons( player ) )
	{
		LootData data = SURVIVAL_GetLootDataFromWeapon( weapon )
		if ( data.ref == "" )
			continue

		// Add the weapon
		ConsumableInventoryItem item

		item.type = data.index
		item.count = weapon.GetWeaponPrimaryClipCount()

		final.append( item )

		foreach ( esRef, mod in GetAllWeaponAttachments( weapon ) )
		{
			if ( !SURVIVAL_Loot_IsRefValid( mod ) )
				continue

			if ( data.baseMods.contains( mod ) )
				continue

			LootData attachmentData = SURVIVAL_Loot_GetLootDataByRef( mod )

			// Add the attachment
			ConsumableInventoryItem attachmentItem

			attachmentItem.type = attachmentData.index
			attachmentItem.count = 1

			final.append( attachmentItem )
		}
	}

	// Non-weapon equipment slots
	foreach ( string ref, EquipmentSlot es in EquipmentSlot_GetAllEquipmentSlots() )
	{
		if ( EquipmentSlot_IsMainWeaponSlot( ref ) || EquipmentSlot_IsAttachmentSlot( ref ) )
			continue

		LootData data = EquipmentSlot_GetEquippedLootDataForSlot( player, ref )
		if ( data.ref == "" )
			continue

		// Add the equipped loot
		ConsumableInventoryItem equippedItem

		equippedItem.type = data.index
		equippedItem.count = 1

		final.append( equippedItem )
	}

	return final
}

void function TpPlayerToSpawnPoint(entity player)
{
    LocPair loc;

	switch(GetGameState())
    {
        case eGameState.MapVoting: 
			loc = _GetVotingLocation()
			break
        case eGameState.Playing:
			loc = _findLocIndex(player)
        	break
    }
	player.SetOrigin(loc.origin) ; player.SetAngles(loc.angles)

}

LocPair function _findLocIndex(entity player)
{
	// workaround
	if(arenas.selectedLocation.team_1_spawns.len() == 0){return _GetVotingLocation()}
	int teamIndex = player.GetTeam()
	array<entity> teamPlayers = GetPlayerArrayOfTeam(teamIndex)
	for(int i = 0 ; i < teamPlayers.len() ; i++){
		entity teamPlayer = teamPlayers[i]
		if(teamPlayer != player){continue}
		if(!IsAlive(player)) {DoRespawnPlayer(player, null)}
		if(teamIndex==TEAM_IMC)
			return arenas.selectedLocation.team_1_spawns[i]
		else
			return arenas.selectedLocation.team_2_spawns[i]
	}
	return _GetVotingLocation()
}

LocPair function _GetVotingLocation()
{
    switch(GetMapName())
    {
		case "mp_rr_aqueduct_night":
        case "mp_rr_aqueduct":
             return NewLocPair(<4885, -4076, 400>, <0, -157, 0>)
        case "mp_rr_canyonlands_staging":
             return NewLocPair(<26794, -6241, -27479>, <0, 0, 0>)
        case "mp_rr_canyonlands_64k_x_64k":
			return NewLocPair(<-19459, 2127, 18404>, <0, 180, 0>)
		case "mp_rr_ashs_redemption":
            return NewLocPair(<-20917, 5852, -26741>, <0, -90, 0>)
        case "mp_rr_canyonlands_mu1":
        case "mp_rr_canyonlands_mu1_night":
		    return NewLocPair(<-19459, 2127, 18404>, <0, 180, 0>)
        case "mp_rr_desertlands_64k_x_64k":
        case "mp_rr_desertlands_64k_x_64k_nx":
			return NewLocPair(<-19459, 2127, 6404>, <0, 180, 0>)
        case "mp_rr_arena_composite":
                return NewLocPair(<0, 4780, 220>, <0, -90, 0>)
        default:
            Assert(false, "No voting location for the map!")
    }
    unreachable
}
