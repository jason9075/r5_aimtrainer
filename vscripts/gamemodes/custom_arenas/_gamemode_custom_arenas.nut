
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
	array<LocationSettings> locationSettings
    LocationSettings& selectedLocation
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
	array<LocationSettings> droplocationSettings
    LocationSettings& dropselectedLocation

	bool FallTriggersEnabled = false
	bool mapSkyToggle = false
} arenas

void function _RegisterLocationARENAS(LocationSettings locationSettings)
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

void function SimpleChampionUI(){
{
	printt("Flowstate DEBUG - Game is starting.")
	print(">>>>>>>>>>>>>>Flowstate <<<<<<")
	printl(">>>>>>>>>>>>>>printl <<<<<<")



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

			if(FlowState_RandomGunsEverydie()){
			player.SetPlayerGameStat( PGS_TITAN_KILLS, 0)
			}
		}
	}
ResetAllPlayerStats()
arenas.ringBoundary = CreateRingBoundary(arenas.selectedLocation)
printt("Flowstate DEBUG - Bubble created, executing SimpleChampionUI.")

float endTime = Time() + FlowState_RoundTime()
printt("Flowstate DEBUG - TDM/FFA gameloop Round started.")

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
	printt("Flowstate DEBUG - Tping arenas player to Lobby.", player)

	if(IsValid( player ))
			{
				if(FlowState_ForceCharacter()){CharSelect(player)}
				if(!IsAlive(player)) {DoRespawnPlayer( player, null )}
				
				Survival_SetInventoryEnabled( player, true )
				player.SetPlayerNetBool( "pingEnabled", true )
				player.SetHealth( 100 )
				Inventory_SetPlayerEquipment(player, "armor_pickup_lv2", "armor")
			}
	
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

// bool function returnPropBool(){
// //By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
// 	return arenas.cantUseChangeProp
// }

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
entity function CreateRingBoundary(LocationSettings location)
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
    array<LocPair> spawns = location.spawns

    vector ringCenter
    foreach( spawn in spawns )
    {
        ringCenter += spawn.origin
    }

    ringCenter /= spawns.len()

    float ringRadius = 0

    foreach( LocPair spawn in spawns )
    {
        if( Distance( spawn.origin, ringCenter ) > ringRadius )
            ringRadius = Distance(spawn.origin, ringCenter)
    }

    ringRadius += GetCurrentPlaylistVarFloat("ring_radius_padding", 800)
	//We watch the ring fx with this entity in the threads
	entity circle = CreateEntity( "prop_script" )
	circle.SetValueForModelKey( $"mdl/fx/ar_survival_radius_1x100.rmdl" )
	circle.kv.fadedist = -1
	circle.kv.modelscale = ringRadius
	circle.kv.renderamt = 255
	circle.kv.rendercolor = FlowState_RingColor()
	circle.kv.solid = 0
	circle.kv.VisibilityFlags = ENTITY_VISIBLE_TO_EVERYONE
	circle.SetOrigin( ringCenter )
	circle.SetAngles( <0, 0, 0> )
	circle.NotSolid()
	circle.DisableHibernation()
    circle.Minimap_SetObjectScale( ringRadius / SURVIVAL_MINIMAP_RING_SCALE )
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

	SetDeathFieldParams( ringCenter, ringRadius, ringRadius, 90000, 99999 ) // This function from the API allows client to read ringRadius from server so we can use visual effects in shared function. Colombia

	//Audio thread for ring
	foreach(sPlayer in GetPlayerArray())
		thread AudioThread(circle, sPlayer, ringRadius)

	//Damage thread for ring
	thread RingDamage(circle, ringRadius)

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