/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#pragma semicolon 1

new String:explosionSound1[]="war3source/particle_suck1.wav";


#define MAXWARDS 64*4 //on map LOL
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0

new BeamSprite;
new HaloSprite;

new ExplosionModel;
new SuicidedAsTeam[MAXPLAYERSCUSTOM];
new Float:SuicideLocation[MAXPLAYERSCUSTOM][3];
new bool:SuicideEffects[MAXPLAYERSCUSTOM];
new SuicideTeam[MAXPLAYERSCUSTOM];
new Float:SuicideRadius[MAXPLAYERSCUSTOM];
new SuicideSkillID[MAXPLAYERSCUSTOM];
new Float:SuicideDamage[MAXPLAYERSCUSTOM];

/*
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERSCUSTOM][3];
new Float:teleportpos[MAXPLAYERSCUSTOM][3];
new bool:inteleportcheck[MAXPLAYERSCUSTOM];


new String:teleportSound[]="war3source/blinkarrival.wav";
*/
public Plugin:myinfo = 
{
	name = "WCX - Skills Engine",
	author = "necavi, Anthony Iacono",
	description = "Provides natives for use with War3 mod",
	version = "0.1",
	url = "http://0xf.org"
}

public OnPluginStart()
{
	LoadTranslations("w3s.race.human.phrases");
	LoadTranslations("w3s.race.undead.phrases");
}

public OnMapStart()
{
	if(War3_GetGame()==Game_TF)
	{
		ExplosionModel=PrecacheModel("materials/particles/explosion/explosionfiresmoke.vmt",false);
		PrecacheSound("weapons/explode1.wav",false);
	}
	else
	{
		ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
		PrecacheSound("weapons/explode5.wav",false);
	}
	
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	War3_PrecacheSound(explosionSound1);
	
//	War3_PrecacheSound(teleportSound);
}
public OnWar3EventSpawn(client)
{
	SuicidedAsTeam[client] = GetClientTeam(client);
}

public bool:InitNativesForwards()
{
	CreateNative("War3_SuicideBomber",Native_War3_SuicideBomber);
	//CreateNative("War3_Teleport",Native_War3_Teleport);
	return true;
}


//Suicide Bomber

public Native_War3_SuicideBomber(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	if(SuicidedAsTeam[client]!=GetClientTeam(client))
		return;
	
	SuicideTeam[client] = GetClientTeam(client);
	GetNativeArray(2,SuicideLocation[client],3);
	SuicideDamage[client] = Float:GetNativeCell(3);
	SuicideSkillID[client] = GetNativeCell(4);
	SuicideRadius[client] = Float:GetNativeCell(5);
	SuicideEffects[client] = bool:GetNativeCell(6);
	
	CreateTimer(0.10,SuicideAction,client);
}

public Action:SuicideAction(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		new Float:radius = SuicideRadius[client];
		new our_team = SuicideTeam[client];
		if(SuicideEffects[client])
		{
			TE_SetupExplosion(SuicideLocation[client],ExplosionModel,10.0,1,0,RoundToFloor(radius),160);
			TE_SendToAll();
			if(War3_GetGame()==Game_TF){
				
				
				ThrowAwayParticle("ExplosionCore_buildings", SuicideLocation[client],  5.0);
				ThrowAwayParticle("ExplosionCore_MidAir", SuicideLocation[client],  5.0);
				ThrowAwayParticle("ExplosionCore_MidAir_underwater", SuicideLocation[client],  5.0);
				ThrowAwayParticle("ExplosionCore_sapperdestroyed", SuicideLocation[client],  5.0);
				ThrowAwayParticle("ExplosionCore_Wall", SuicideLocation[client],  5.0);
				ThrowAwayParticle("ExplosionCore_Wall_underwater", SuicideLocation[client],  5.0);
			}
			else{
				SuicideLocation[client][2]-=40.0;
			}
			
			TE_SetupBeamRingPoint(SuicideLocation[client], 10.0, radius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,33}, 120, 0);
			TE_SendToAll();
			
			new beamcolor[]={0,200,255,255}; //blue //secondary ring
			if(our_team==2)
			{ //TERRORISTS/RED in TF?
				beamcolor[0]=255;
				beamcolor[1]=0;
				beamcolor[2]=0;
				
			} //secondary ring
			TE_SetupBeamRingPoint(SuicideLocation[client], 20.0, radius+10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
			TE_SendToAll();
			
			if(War3_GetGame()==Game_TF){
				SuicideLocation[client][2]-=30.0;
			}
			else{
				SuicideLocation[client][2]+=40.0;
			}
			
			EmitSoundToAll(explosionSound1,client);
			
			if(War3_GetGame()==Game_TF){
				EmitSoundToAll("weapons/explode1.wav",client);
			}
			else{
				EmitSoundToAll("weapons/explode5.wav",client);
			}
		}
		new bool:friendlyfire = GetConVarBool(FindConVar("mp_friendlyfire"));
		new Float:location_check[3];
		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x,true)&&client!=x)
			{
				new team=GetClientTeam(x);
				if(team==our_team&&!friendlyfire)
					continue;
				
				GetClientAbsOrigin(x,location_check);
				new Float:distance=GetVectorDistance(SuicideLocation[client],location_check);
				if(distance>radius)
					continue;
				
				if(!W3HasImmunity(x,Immunity_Ultimates))
				{
					new Float:factor=(radius-distance)/radius;
					new damage;
					damage=RoundFloat(SuicideDamage[client]*factor);
					War3_DealDamage(x,damage,client,_,"suicidebomber",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);	
				
					War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
					W3FlashScreen(x,RGBA_COLOR_RED);
				}
				else
				{
					PrintToConsole(client,"%T","Could not damage player {player} due to immunity",client,x);
				}
				
			}
		}
	}
}




