
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
// global function PROPHUNT_GiveAndManageRandomProp
// global function returnPropBool
global function RunARENAS
// global function ClientCommand_NextRoundPROPHUNT

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

	int randomprimary
    int randomsecondary
    int randomult
    int randomtac

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
/////////////Retículo Endoplasmático#5955 CaféDeColombiaFPS///////////////////
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
	if (FlowState_RandomGuns() )
    {
        arenas.randomprimary = RandomIntRangeInclusive( 0, 15 )
        arenas.randomsecondary = RandomIntRangeInclusive( 0, 6 )
    } else if (FlowState_RandomGunsMetagame())
	{
		arenas.randomprimary = RandomIntRangeInclusive( 0, 2 )
        arenas.randomsecondary = RandomIntRangeInclusive( 0, 4 )
	} else if (FlowState_RandomGunsEverydie())
	{
		arenas.randomprimary = RandomIntRangeInclusive( 0, 23 )
        arenas.randomsecondary = RandomIntRangeInclusive( 0, 18 )
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
				
				player.SetThirdPersonShoulderModeOn()
				Survival_SetInventoryEnabled( player, true )
				player.SetPlayerNetInt( "respawnStatus", eRespawnStatus.NONE )
				player.SetPlayerNetBool( "pingEnabled", true )
				player.SetHealth( 100 )
				TakeAllWeapons(player)
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

void function GiveTeamToProphuntPlayer(entity player)
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
	array<entity> IMCplayers = GetPlayerArrayOfTeam(TEAM_IMC)
	array<entity> MILITIAplayers = GetPlayerArrayOfTeam(TEAM_MILITIA)
	

	
	if(IMCplayers.len() > MILITIAplayers.len())
	{
	SetTeam(player, TEAM_MILITIA )
	} else if (MILITIAplayers.len() > IMCplayers.len())
	{
	SetTeam(player, TEAM_IMC )
	} else {
		switch(RandomIntRangeInclusive(0,1))
		{
			case 0:
				SetTeam(player, TEAM_IMC )
				break;
			case 1:
				SetTeam(player, TEAM_MILITIA )
				break;
		}
	}
	printt("Flowstate DEBUG - Giving team to player.", player, player.GetTeam())
}


void function EmitSoundOnSprintingProp()
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
		while(arenas.tdmState==eTDMState.IN_PROGRESS)
		{
		array<entity> MILITIAplayers = GetPlayerArrayOfTeam(TEAM_MILITIA)
			foreach(player in MILITIAplayers)
			{
				if(player.IsSprinting() && IsValid(player))
				{
				EmitSoundOnEntity( player, "husaria_sprint_default_3p" )
				} 
			}
		wait 0.2
		}
}


void function EmitWhistleOnProp()
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
		while(arenas.tdmState==eTDMState.IN_PROGRESS)
		{
		wait 30 //40 s COD original value: 20.
		array<entity> MILITIAplayers = GetPlayerArrayOfTeam(TEAM_MILITIA)
			foreach(player in MILITIAplayers)
			{
				if(IsValid(player))
				{
				EmitSoundOnEntity( player, "husaria_sprint_default_3p" )
				EmitSoundOnEntity( player, "concrete_bulletimpact_1p_vs_3p" )
				EmitSoundOnEntity( player, "husaria_sprint_default_3p" )
				} 
			}
		}
}

void function CheckForPlayersPlaying()
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
	
	while(arenas.tdmState==eTDMState.IN_PROGRESS)
	{
			if(GetPlayerArray().len() == 1)
			{
				SetTdmStateToNextRound()
				foreach(player in GetPlayerArray()){
					Message(player, "ATTENTION", "Not enough players. Round is ending.", 5)
				}
			}
	WaitFrame()	
	}
	printt("Flowstate DEBUG - Ending round cuz not enough players midround")
}

void function PropWatcher(entity prop, entity player)
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
	while(arenas.tdmState==eTDMState.IN_PROGRESS && !player.p.PROPHUNT_DestroyProp) 
	{
	WaitFrame()}
	
	if(IsValid(prop))
		prop.Destroy()
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


// void function PROPHUNT_GiveAndManageRandomProp(entity player, bool anglesornah = false)
// //By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
// {
// 			// Using gamestat as boolean Destroy prop y otras cosas más
// 			//  player.SetPlayerGameStat( PGS_DEFENSE_SCORE, 20)    true 
// 			//  player.SetPlayerGameStat( PGS_DEFENSE_SCORE, 10)    false
// 			player.p.PROPHUNT_DestroyProp = true
// 			if(!anglesornah && IsValid(player)){
// 					WaitFrame()
// 					asset selectedModel = prophuntAssetsWE[RandomIntRangeInclusive(0,(prophuntAssetsWE.len()-1))]
// 					player.p.PROPHUNT_LastModel = selectedModel
// 					player.kv.solid = 6
// 					player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
// 					entity prop = CreatePropDynamic(selectedModel, player.GetOrigin(), player.GetAngles(), 6, -1)
// 					prop.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
// 					prop.kv.solid = 6
// 					prop.SetDamageNotifications( true )
// 					prop.SetTakeDamageType( DAMAGE_YES )
// 					prop.AllowMantle()
// 					prop.SetCanBeMeleed( true )
// 					prop.SetBoundingBox( < -150, -75, 0 >, <150, 75, 100 >  )
// 					prop.SetMaxHealth( 100 )
// 					prop.SetHealth( 100 )
// 					prop.SetParent(player)
// 					AddEntityCallback_OnDamaged(prop, NotifyDamageOnProp)
// 					player.p.PROPHUNT_DestroyProp = false
// 					WaitFrame()
// 					thread PropWatcher(prop, player) 
// 			} else if(anglesornah && IsValid(player)){
// 					player.p.PROPHUNT_DestroyProp = true
// 					player.Show()
// 					player.SetBodyModelOverride( player.p.PROPHUNT_LastModel )
// 					player.SetArmsModelOverride( player.p.PROPHUNT_LastModel )
// 					Message(player, "prophunt", "Angles locked.", 1)
// 					player.kv.solid = SOLID_BBOX
// 					player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
// 					player.AllowMantle()
// 					player.SetDamageNotifications( true )
// 					player.SetTakeDamageType( DAMAGE_YES )
// 			}
// }


void function PlayerwithLockedAngles_OnDamaged(entity ent, var damageInfo)
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
	entity attacker = DamageInfo_GetAttacker(damageInfo)
	float damage = DamageInfo_GetDamage( damageInfo )
	attacker.NotifyDidDamage
	(
		ent,
		DamageInfo_GetHitBox( damageInfo ),
		DamageInfo_GetDamagePosition( damageInfo ), 
		DamageInfo_GetCustomDamageType( damageInfo ),
		DamageInfo_GetDamage( damageInfo ),
		DamageInfo_GetDamageFlags( damageInfo ), 
		DamageInfo_GetHitGroup( damageInfo ),
		DamageInfo_GetWeapon( damageInfo ), 
		DamageInfo_GetDistFromAttackOrigin( damageInfo )
	)
	float NextHealth = ent.GetHealth() - DamageInfo_GetDamage( damageInfo )
	if (NextHealth > 0 && IsValid(ent)){
		ent.SetHealth(NextHealth)
	} else if (IsValid(ent)){
	ent.SetTakeDamageType( DAMAGE_NO )
	ent.SetHealth(0)
	ent.kv.solid = 0
	// ent.SetOwner( attacker )
	// ent.kv.teamnumber = attacker.GetTeam()
	}
}

void function NotifyDamageOnProp(entity ent, var damageInfo)
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
//props health bleedthrough
	entity attacker = DamageInfo_GetAttacker(damageInfo)
	entity victim = ent.GetParent()
	float damage = DamageInfo_GetDamage( damageInfo )
	
	attacker.NotifyDidDamage
	(
		ent,
		DamageInfo_GetHitBox( damageInfo ),
		DamageInfo_GetDamagePosition( damageInfo ), 
		DamageInfo_GetCustomDamageType( damageInfo ),
		DamageInfo_GetDamage( damageInfo ),
		DamageInfo_GetDamageFlags( damageInfo ), 
		DamageInfo_GetHitGroup( damageInfo ),
		DamageInfo_GetWeapon( damageInfo ), 
		DamageInfo_GetDistFromAttackOrigin( damageInfo )
	)
	
	float playerNextHealth = ent.GetHealth() - DamageInfo_GetDamage( damageInfo )
	
	if (playerNextHealth > 0 && IsValid(victim) && IsAlive(victim)){
	victim.SetHealth(playerNextHealth)} else {
	ent.ClearParent()
	victim.SetHealth(0)
	ent.Destroy()}
}

entity function CreateBubbleBoundaryPROPHUNT(LocationSettings location)
{
    array<LocPair> spawns = location.spawns
    vector bubbleCenter
    foreach(spawn in spawns)
    {
        bubbleCenter += spawn.origin
    }
    bubbleCenter /= spawns.len()
    float bubbleRadius = 0
    foreach(LocPair spawn in spawns)
    {
        if(Distance(spawn.origin, bubbleCenter) > bubbleRadius)
        bubbleRadius = Distance(spawn.origin, bubbleCenter)
    }
    bubbleRadius += 200
    entity bubbleShield = CreateEntity( "prop_dynamic" )
	bubbleShield.SetValueForModelKey( BUBBLE_BUNKER_SHIELD_COLLISION_MODEL )
    bubbleShield.SetOrigin(bubbleCenter)
    bubbleShield.SetModelScale(bubbleRadius / 235)
    bubbleShield.kv.CollisionGroup = 0
    bubbleShield.kv.rendercolor = FlowState_BubbleColor()
    DispatchSpawn( bubbleShield )
    thread MonitorBubbleBoundaryPROPHUNT(bubbleShield, bubbleCenter, bubbleRadius)
    return bubbleShield
}

void function MonitorBubbleBoundaryPROPHUNT(entity bubbleShield, vector bubbleCenter, float bubbleRadius)
{
	wait 31
    while(IsValid(bubbleShield))
    {
        foreach(player in GetPlayerArray_Alive())
        {
            if(!IsValid(player)) continue
            if(Distance(player.GetOrigin(), bubbleCenter) > bubbleRadius)
            {
				Remote_CallFunction_Replay( player, "ServerCallback_PlayerTookDamage", 0, 0, 0, 0, DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, eDamageSourceId.deathField, null )
                player.TakeDamage( int( Deathmatch_GetOOBDamagePercent() / 100 * float( player.GetMaxHealth() ) ), null, null, { scriptType = DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, damageSourceId = eDamageSourceId.deathField } )
            }
        }
        wait 1
    }
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

// bool function ClientCommand_NextRoundPROPHUNT(entity player, array<string> args)
// {
// 	if(player.GetPlayerName() == FlowState_Hoster() || player.GetPlayerName() == FlowState_Admin1() || player.GetPlayerName() == FlowState_Admin2() || player.GetPlayerName() == FlowState_Admin3() || player.GetPlayerName() == FlowState_Admin4()) {
		
// 		if (args.len()) {
// 				int mapIndex = int(args[0])
// 				arenas.nextMapIndex = (((mapIndex >= 0 ) && (mapIndex < arenas.locationSettings.len())) ? mapIndex : RandomIntRangeInclusive(0, arenas.locationSettings.len() - 1))
// 				arenas.mapIndexChanged = true

// 				string now = args[0]
// 				if (now == "now")
// 				{
// 				   SetTdmStateToNextRound()
// 				   arenas.mapIndexChanged = false
// 				   arenas.InProgress = false
// 				   SetGameState(eGameState.MapVoting)
// 				}
				
// 				if(args.len() > 1){
// 					now = args[1]
// 					if (now == "now")
// 					{
// 					   SetTdmStateToNextRound()
// 					   arenas.InProgress = false
// 					}
// 				}
// 		}
// 	}
// 	else {
// 	return false
// 	}
// 	return true
// }
