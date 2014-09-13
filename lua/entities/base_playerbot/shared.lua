AddCSLuaFile()

ENT.Base 			= "base_entity"
ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.RenderGroup		= RENDERGROUP_OPAQUE

function ENT:SetupDataTables()

	self:InstallDataTable();
	self:NetworkVar( "Vector", 1, "PlayerColor" );
	
end

if ( SERVER ) then

	--
	-- All of the AI logic is serverside - so we derive it from a 
	-- specialized class on the server.
	--
	ENT.Type = "nextbot"
	include( "sv_nextbot.lua" )
util.AddNetworkString( "Test1" )
util.AddNetworkString( "Test2" )
else
	
	ENT.Type = "anim"
	//include( "playerfunctions.lua" )
	function ENT:Initialize()
		MsgN(tostring(self:GetPlayerColor()))
	end 

	BotInfo = {}
	net.Receive( "DrawBotInfo", function( length, client )
//		MsgN( "TEST 2: Received message of ", length, " bits..." )
           
		   
		local name	= net.ReadString()
		local pos	= net.ReadVector()
		local ang	= net.ReadAngle()
		local health	= net.ReadFloat()
		local armor	= net.ReadFloat()
		local weapon	= net.ReadEntity()
		local clip1	= net.ReadFloat()
--[[		Msg( "Name: " )
		MsgN( name )
		Msg( "Pos: " )
		MsgN( pos )
		Msg( "Health: " )
		MsgN( health )
		Msg( "Armor: " )
		MsgN( armor )
		Msg( "Weapon: " )
		MsgN( tostring(weapon) )]]--
		BotInfo[name] = {}
		BotInfo[name].pos = pos
		BotInfo[name].ang = ang
		BotInfo[name].health = health
		BotInfo[name].armor = armor
		BotInfo[name].weapon = weapon
		BotInfo[name].clip1 = clip1 or -1
		BotInfo[name].kill = CurTime() + 1
           
	end )
	
	
	hook.Add("PostDrawOpaqueRenderables", "DrawBotInfo", function()
		for k,v in pairs( BotInfo ) do
			//MsgN(k,"-------------------",v)
			ang = LocalPlayer():EyeAngles()
			ang:RotateAroundAxis( ang:Forward(), 90 )
			ang:RotateAroundAxis( ang:Right(), 90 )
			cam.Start3D2D(v.pos, Angle( 0, ang.y, 90 ), 0.2 )
				draw.DrawText( "Name: "..k, "TargetID", -80, 0, Color( 255,255,255,255 ), TEXT_ALIGN_LEFT )
				draw.DrawText( "Health: "..v.health, "TargetID", -80, 20, Color( 255,255,255,255 ), TEXT_ALIGN_LEFT )
				draw.DrawText( "Armor: "..v.armor, "TargetID", -80, 40, Color( 255,255,255,255 ), TEXT_ALIGN_LEFT )
				if v.weapon and v.weapon:IsValid() and v.weapon:IsWeapon() then
					draw.DrawText( "Weapon: "..v.weapon:GetClass(), "TargetID", -80, 60, Color( 255,255,255,255 ), TEXT_ALIGN_LEFT )
					draw.DrawText( "clip1: "..v.clip1, "TargetID", -80, 80, Color( 255,255,255,255 ), TEXT_ALIGN_LEFT )
				end
			cam.End3D2D( )
			if v.kill < CurTime() then
				BotInfo[k] = nil
			end
		end
	end)
	
end
