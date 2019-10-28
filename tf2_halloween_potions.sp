#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION	"1.0"
#define PLUGIN_DESC	"Potion Powerups for more Halloween Chaos."
#define PLUGIN_NAME	"[TF2] Halloween Potions"
#define PLUGIN_AUTH	"Glubbable"
#define PLUGIN_URL	"https://steamcommunity.com/groups/GlubsServers"

public const Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
};

// Index List of Potions
enum
{
	Potion_None = -1,
	Potion_Crits = 0,
	Potion_Speed,
	Potion_Defense,
	Potion_Uber,
	Potion_Heal,
	Potion_PowerPlay,
	Potion_Max
};

// Conditions for Potions
TFCond g_tfPotionConditions[] =
{
	TFCond_HalloweenCritCandy, // 33 (IDs might be wrong! I am bad at counting.)
	TFCond_SpeedBuffAlly, // 32
	TFCond_DefenseBuffed, // 26
	TFCond_UberchargedCanteen, // 52
	TFCond_RegenBuffed // 29
};

// Duration Time for Potion Conditions
float g_tfPotionDurations[] =
{
	4.0,
	8.0,
	6.0,
	4.0,
	6.0,
	4.0
};

// Conditions for Player Play Potion
TFCond g_tfPowerPlayConditions[] =
{
	TFCond_MegaHeal, // 28
	TFCond_CritCanteen, // 34
	TFCond_UberchargedCanteen, // 52
	TFCond_CritOnDamage, // 56
	TFCond_UberBulletResist, // 58
	TFCond_UberBlastResist, // 59
	TFCond_UberFireResist, // 60
	TFCond_BulletImmune, // 67
	TFCond_BlastImmune, // 68
	TFCond_FireImmune // 69
};

// Default Potion Info
#define DEFAULT_POTION_MODEL	"models/props_halloween/hwn_flask_vial.mdl"
#define DEFAULT_POTION_SOUND 	")player/pl_scout_dodge_can_drink.wav"

// Skins for default potion
int g_iDefaultPotionSkins[] =
{
	1,
	2,
	0,
	5,
	3,
	6
};

// Potion Time until Despawn
#define POTION_LIFETIME 24.0

// Storage for Potion Data
char g_sPotionModel[PLATFORM_MAX_PATH];
char g_sPotionSound[PLATFORM_MAX_PATH];
char g_sPotionParticle[PLATFORM_MAX_PATH];
int g_iPotionSkin[Potion_Max];

// Global Settings
bool g_bEnabled = false;
ConVar g_cvEnableOnAllMaps = null;

/* ====================							==================== */
/* ====================			PUBLIC FUNCTIONS		==================== */
/* ====================							==================== */

public void OnPluginStart()
{
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("teamplay_round_start", Event_OnRoundStart);
	
	g_cvEnableOnAllMaps = CreateConVar("sv_halloween_potions_enable", "0", "Enables Halloween Potion Spawns.");
}

public void OnConfigsExecuted()
{
	g_bEnabled = g_cvEnableOnAllMaps.BoolValue;
	
	SetupPotions();
}

public void Event_OnPlayerTouch(const char[] sOutput, int iCaller, int iActivator, float flDelay)
{
	if (MaxClients >= iActivator > 0)
	{
		char sTargetName[64];
		GetEntPropString(iCaller, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
		ReplaceString(sTargetName, sizeof(sTargetName), "tf_potion_", " ", false);
		TrimString(sTargetName);
		
		ApplyPotion(iActivator, StringToInt(sTargetName));
		EmitSoundToAll(g_sPotionSound, iCaller); // no idea why but setting a custom pickup sound breaks the sound???
		CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(iCaller), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_OnPlayerDeath(Event eEvent, const char[] sName, bool bDB)
{
	if (!g_bEnabled)
		return;
	
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	if (iClient <= 0)
		return;
		
	int iAttacker = GetClientOfUserId(eEvent.GetInt("attacker"));
	if (iAttacker <= 0 || iAttacker == iClient || eEvent.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
		return;
	
	int iRandom = GetRandomInt(0, 10);
	if (iRandom >= 5)
	{
		float vecPos[3], vecVel[3];
		GetEntPropVector(iClient, Prop_Data, "m_vecAbsOrigin", vecPos);
		vecPos[2] += 35.0;
		
		vecVel[0] = GetRandomFloat(-128.0, 128.0);
		vecVel[1] = GetRandomFloat(-128.0, 128.0);
		vecVel[2] = GetRandomFloat(64.0, 256.0);
		
		SpawnPotion(vecPos, vecVel);
	}
}

public Action Event_OnRoundStart(Event eEvent, const char[] sName, bool bDB)
{
	if (GameRules_GetRoundState() <= RoundState_Pregame)
		return;
	
	g_bEnabled = g_cvEnableOnAllMaps.BoolValue;
	
	SetupPotions();
}

public Action Timer_RemoveEntity(Handle hTimer, int iRef)
{
	int iEnt = EntRefToEntIndex(iRef);
	if (iEnt > MaxClients)
		RemoveEntity(iEnt);
}

/* ====================	 				==================== */
/* ====================	 	LOCAL FUNCTIONS 	==================== */
/* ==================== 				==================== */

void SetupPotions()
{
	char sTargetName[64];
	int iEnt = INVALID_ENT_REFERENCE;
	while ((iEnt = FindEntityByClassname(iEnt, "info_target")) != INVALID_ENT_REFERENCE)
	{
		GetEntPropString(iEnt, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
		if (strcmp(sTargetName, "tf_halloween_potions_logic", false) == 0)
		{
			g_bEnabled = true;
			break;
		}
	}
	
	g_sPotionModel = DEFAULT_POTION_MODEL;
	PrecacheModel(g_sPotionModel);
	
	g_sPotionSound = DEFAULT_POTION_SOUND;
	PrecacheSound(g_sPotionSound);
	
	g_sPotionParticle = "";
	
	for (int i = 0; i < Potion_Max; i++)
		g_iPotionSkin[i] = g_iDefaultPotionSkins[i];
}

void SpawnPotion(const float vecPos[3], const float vecVel[3])
{
	int iEntity = CreateEntityByName("tf_halloween_pickup");
	if (iEntity == INVALID_ENT_REFERENCE)
		return;
	
	char sTargetName[64];
	int iPotionIndex = GetRandomInt(0, Potion_Max - 1);
	Format(sTargetName, sizeof(sTargetName), "tf_potion_%i", iPotionIndex);
	DispatchKeyValue(iEntity, "targetname", sTargetName);
	DispatchKeyValue(iEntity, "powerup_model", g_sPotionModel);
	DispatchKeyValue(iEntity, "pickup_sound", g_sPotionSound);
	DispatchKeyValue(iEntity, "pickup_particle", g_sPotionParticle);
	
	DispatchKeyValue(iEntity, "AutoMaterialize", "0");
	
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity);
	SetEntityModel(iEntity, g_sPotionModel);
	SetEntityMoveType(iEntity, MOVETYPE_STEP);
	
	SetEntProp(iEntity, Prop_Data, "m_nSkin", g_iPotionSkin[iPotionIndex]);
	TeleportEntity(iEntity, vecPos, NULL_VECTOR, vecVel);
	
	HookSingleEntityOutput(iEntity, "OnPlayerTouch", Event_OnPlayerTouch);
	CreateTimer(POTION_LIFETIME, Timer_RemoveEntity, EntIndexToEntRef(iEntity), TIMER_FLAG_NO_MAPCHANGE);
}

void ApplyPotion(int iClient, int iPotionIndex)
{
	if (iPotionIndex == Potion_PowerPlay)
	{
		for (int i = 0; i < sizeof(g_tfPowerPlayConditions); i++)
			TF2_AddCondition(iClient, g_tfPowerPlayConditions[i], g_tfPotionDurations[iPotionIndex]);
	}
	else
		TF2_AddCondition(iClient, g_tfPotionConditions[iPotionIndex], g_tfPotionDurations[iPotionIndex]);
}

// Hotfix for older sourcemod compilers
#if SOURCEMOD_V_MINOR < 9
stock int RemoveEntity(int iEntity)
{
	AcceptEntityInput(iEntity, "Kill");
}
#endif