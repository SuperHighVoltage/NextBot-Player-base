include( "animations.lua" )
include( "playerfunctions.lua" )
--
-- Name: NEXTBOT:BehaveStart
-- Desc: Called to initialize the behaviour.\n\n You shouldn't override this - it's used to kick off the coroutine that runs the bot's behaviour. \n\nThis is called automatically when the NPC is created, there should be no need to call it manually.
-- Arg1: 
-- Ret1:
--
function ENT:BehaveStart()

	local s = self
	self.BehaveThread = coroutine.create( function() self:RunBehaviour() end )
	
end

--
-- Name: NEXTBOT:BehaveUpdate
-- Desc: Called to update the bot's behaviour
-- Arg1: number|interval|How long since the last update
-- Ret1:
--
function ENT:BehaveUpdate( fInterval )

	if ( !self.BehaveThread ) then return end
	
	self:BotThink( fInterval )

	local ok, message = coroutine.resume( self.BehaveThread )
	if ( ok == false ) then

		self.BehaveThread = nil
		Msg( self, "error: ", message, "\n" );

	end

end

--
-- Name: NEXTBOT:OnLeaveGround
-- Desc: Called when the bot's feet leave the ground - for whatever reason
-- Arg1:
-- Ret1:
--
function ENT:OnLeaveGround()

	self.m_bJumping = true
	self.m_flJumpStartTime = CurTime()
	
end

--
-- Name: NEXTBOT:OnLeaveGround
-- Desc: Called when the bot's feet return to the ground
-- Arg1:
-- Ret1:
--
function ENT:OnLandOnGround()

	self.m_bJumping = false
	
end

--
-- Name: NEXTBOT:OnStuck
-- Desc: Called when the bot thinks it is stuck
-- Arg1:
-- Ret1:
--
function ENT:OnStuck()

	--MsgN( "OnStuck" )

end

--
-- Name: NEXTBOT:OnUnStuck
-- Desc: Called when the bot thinks it is un-stuck
-- Arg1:
-- Ret1:
--
function ENT:OnUnStuck()

	--MsgN( "OnUnStuck" )

end

--
-- Name: NEXTBOT:OnInjured
-- Desc: Called when the bot gets hurt
-- Arg1: CTakeDamageInfo|info|damage info
-- Ret1:
--
function ENT:OnInjured( damageinfo )
//	damageinfo:SetDamage( 0 )
end

--
-- Name: NEXTBOT:OnKilled
-- Desc: Called when the bot gets killed
-- Arg1: CTakeDamageInfo|info|damage info
-- Ret1:
--
function ENT:OnKilled( damageinfo )
	self:DropWeapon()
	self:BecomeRagdoll( damageinfo )

end

--
-- Name: NEXTBOT:OnOtherKilled
-- Desc: Called when someone else or something else has been killed
-- Arg1:
-- Ret1:
--
function ENT:OnOtherKilled()

	--MsgN( "OnOtherKilled" )

end


--
-- Name: NextBot:FindSpots
-- Desc: Returns a table of hiding spots.
-- Arg1: table|specs|This table should contain the search info.\n\n * 'type' - the type (either 'hiding')\n * 'pos' - the position to search.\n * 'radius' - the radius to search.\n * 'stepup' - the highest step to step up.\n * 'stepdown' - the highest we can step down without being hurt.
-- Ret1: table|An unsorted table of tables containing\n * 'vector' - the position of the hiding spot\n * 'distance' - the distance to that position
--
function ENT:FindSpots( tbl )

	local tbl = tbl or {}
	
	tbl.pos			= tbl.pos			or self:WorldSpaceCenter()
	tbl.radius		= tbl.radius		or 1000
	tbl.stepdown	= tbl.stepdown		or 20
	tbl.stepup		= tbl.stepup		or 20
	tbl.type		= tbl.type			or 'hiding'

	-- Use a path to find the length
	local path = Path( "Follow" )

	-- Find a bunch of areas within this distance
	local areas = navmesh.Find( tbl.pos, tbl.radius, tbl.stepdown, tbl.stepup )

	local found = {}
	
	-- In each area
	for _, area in pairs( areas ) do

		-- get the spots
		local spots 
		
		if ( tbl.type == 'hiding' ) then spots = area:GetHidingSpots() end
		if ( tbl.type == 'exposed' ) then spots = area:GetExposedSpots() end
		if ( tbl.type == 'both' ) then spots = area:GetHidingSpots() table.Merge(spots,area:GetExposedSpots()) end
		
		for k, vec in pairs( spots ) do

			-- Work out the length, and add them to a table
			path:Invalidate()

			path:Compute( self, vec, 1 ) -- TODO: This is bullshit - it's using 'self.pos' not tbl.pos
				
			table.insert( found, { vector = vec, distance = path:GetLength() } )

		end

	end

	return found

end

--
-- Name: NextBot:FindSpot
-- Desc: Like FindSpots but only returns a vector
-- Arg1: string|type|Either "random", "near", "far"
-- Arg2: table|options|A table containing a bunch of tweakable options. See the function definition for more details
-- Ret1: vector|If it finds a spot it will return a vector. If not it will return nil.
--
function ENT:FindSpot( type,  options )

	local spots = self:FindSpots( options )
	if ( !spots || #spots == 0 ) then return end

	if ( type == "near" ) then

		table.SortByMember( spots, "distance", true )
		return spots[1].vector

	end

	if ( type == "far" ) then

		table.SortByMember( spots, "distance", false )
		return spots[1].vector

	end

	-- random
	return spots[ math.random( 1, #spots ) ].vector

end

--
-- Name: NextBot:FindWeapons
-- Desc: Returns a table of hiding spots.
-- Arg1: table|specs|This table should contain the search info.\n\n * 'type' - the type (either 'hiding')\n * 'pos' - the position to search.\n * 'radius' - the radius to search.\n * 'stepup' - the highest step to step up.\n * 'stepdown' - the highest we can step down without being hurt.
-- Ret1: table|An unsorted table of tables containing\n * 'vector' - the position of the hiding spot\n * 'distance' - the distance to that position
--
local Pickups = { -- This is a table where the keys are the HUD items to hide
	["ut2k4_ammo_assault"] = true,	["ut2k4_ammo_bio"] = true,	["ut2k4_ammo_flak"] = true,	["ut2k4_ammo_lightning"] = true,
	["ut2k4_ammo_minigun"] = true,	["ut2k4_ammo_rocket"] = true,	["ut2k4_ammo_shock"] = true,	["ut2k4_ammo_sniper"] = true,
	["ut2k4_ammo_spider"] = true,	["ut2k4_ammo_sticky"] = true,	["ut2k4_adrenaline"] = true,	["ut2k4_doubledamage"] = true,
	["ut2k4_healthpack"] = true,	["ut2k4_minihealthpack"] = true,	["ut2k4_sheild"] = true,	["ut2k4_superadrenaline"] = true,
	["ut2k4_superkeg"] = true,	["ut2k4_supersheild"] = true,	["CHudCrosshair"] = true,	["CHudCrosshair2"] = true
}
function ENT:FindWeapons( tbl )
--[[
for _, x in pairs(ents.GetAll()) do

	if x:IsWeapon() and x.Owner then
	
		print(tostring(x).."  "..tostring(x.Owner:IsValid()))
		debugoverlay.Cross( x:GetPos(), 10, 1, Color(0, 0, 255), true )
	end
	
end--]]--
	local tbl = tbl or {}
	
	tbl.pos			= tbl.pos			or self:WorldSpaceCenter()
	tbl.radius		= tbl.radius		or 1000
	tbl.stepdown	= tbl.stepdown		or 20
	tbl.stepup		= tbl.stepup		or 20
	tbl.type		= tbl.type			or 'hiding'

	-- Use a path to find the length
	local path = Path( "Follow" )

	-- Find a bunch of areas within this distance
	local weaponz = ents.FindInSphere( self:GetPos(),  tbl.radius )//ents.FindByClass( "ut2k4_weaponbase")
	//debugoverlay.Sphere( tbl.pos, tbl.radius, 0.5, self.color, true)
	local found = {}
	-- In each area
	for _, ent in pairs( weaponz ) do
//		MsgN("----"..tostring(ent))
//		MsgN("----"..tostring(wep:GetOwner()))
		//if wep.GetOwner and wep:GetOwner():IsValid() then return end
//		MsgN("--------"..tostring(ent))
		//if !ent:IsWeapon() then debugoverlay.Cross( ent:GetPos(), 10, 1, Color(255, 0, 0), true ) return end
		
		if  ent:IsWeapon() and !ent.Owner:IsValid() and (!self.Weapon or (self.Weapon and self.Weapon:GetClass() != ent:GetClass())) then
			
			local vec = ent:GetPos()
			debugoverlay.Cross( vec, 10, 1, Color(0, 0, 255), true )
			-- Work out the length, and add them to a table
			path:Invalidate()

			path:Compute( self, vec, 1 ) -- TODO: This is bullshit - it's using 'self.pos' not tbl.pos
				
			if path:GetLength() > tbl.radius + (tbl.radius/8) then return end	-- This should prevent running a mile around the map for a weapon on the other side of a wall
			debugoverlay.Cross( ent:GetPos(), 10, 1, Color(0, 255, 0), true )
			table.insert( found, { vector = vec, distance = path:GetLength() } )
		end
	end

	return found

end
function ENT:FindWeapon( type,  options )

	local spots = self:FindWeapons( options )
	if ( !spots || #spots == 0 ) then return end
	if ( type == "near" ) then

		table.SortByMember( spots, "distance", true )
		return spots[1].vector

	end

	if ( type == "far" ) then

		table.SortByMember( spots, "distance", false )
		return spots[1].vector

	end

	-- random
	return spots[ math.random( 1, #spots ) ].vector

end

--
-- Name: NextBot:HandleStuck
-- Desc: Called from Lua when the NPC is stuck. This should only be called from the behaviour coroutine - so if you want to override this function and do something special that yields - then go for it.\n\nYou should always call self.loco:ClearStuck() in this function to reset the stuck status - so it knows it's unstuck.
-- Arg1: 
-- Ret1: 
--
function ENT:HandleStuck()

	--
	-- Clear the stuck status
	--
	self.loco:ClearStuck();

end

--
-- Name: NextBot:MoveToPos
-- Desc: To be called in the behaviour coroutine only! Will yield until the bot has reached the goal or is stuck
-- Arg1: Vector|pos|The position we want to get to
-- Arg2: table|options|A table containing a bunch of tweakable options. See the function definition for more details
-- Ret1: string|Either "failed", "stuck", "timeout" or "ok" - depending on how the NPC got on
--
function ENT:MoveToPos( pos, options )

	local options = options or {}
	options.repath = options.repath or 1

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, pos )

	if ( !path:IsValid() ) then return "failed" end

	while ( path:IsValid() ) do

		path:Update( self )

		-- Draw the path (only visible on listen servers or single player)
		if ( options.draw ) then
			path:Draw()
		end

		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then

			self:HandleStuck();
			
			return "stuck"

		end

		--
		-- If they set maxage on options then make sure the path is younger than it
		--
		if ( options.maxage ) then
			if ( path:GetAge() > options.maxage ) then return "timeout" end
		end

		--
		-- If they set repath then rebuild the path every x seconds
		--
		if ( options.repath ) then
			if ( path:GetAge() > options.repath ) then path:Compute( self, pos ) end
		end

		coroutine.yield()

	end

	return "ok"

end

function ENT:MoveToPosSearch( pos, options )

	local options = options or {}
	options.repath = options.repath or 1

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, pos )

	if ( !path:IsValid() ) then return "failed" end
	while ( path:IsValid() and !self:GetEnemy() ) do
	
		if ( options.repath ) then
			if ( path:GetAge() > options.repath ) then
				local newpos = self:FindWeapon( "near", { type = 'both', radius = 300 } )
				if newpos then
					path:Compute( self, newpos )
				else
					path:Compute( self, pos )
				end
			end
		end
		path:Update( self )
		if ( options.draw ) then
			path:Draw()
		end
		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then

			self:HandleStuck();
			
			return "stuck"

		end
		if ( options.maxage ) then
			if ( path:GetAge() > options.maxage ) then return "timeout" end
		end
		
		coroutine.yield()
	end
	return "ok"
end

--
-- Name: NextBot:MoveToEnt
-- Desc: To be called in the behaviour coroutine only! Will yield until the bot has reached the entity or is stuck
-- Arg1: Entity|ent|The entity we want to get to
-- Arg2: Float|dist|How close we want to get to it
-- Arg3: table|options|A table containing a bunch of tweakable options. See the function definition for more details
-- Ret1: string|Either "failed", "stuck", "timeout" or "ok" - depending on how the NPC got on
--

function ENT:MoveToEnt( ent, dist, options )

	local options = options or {}

	local path = Path( "Follow" )	-- Define the path for the bot to follow
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 40 )
	path:Compute( self, ent:GetPos() )		-- Calculate the path for the bot

	while ( ent:IsValid() and ent:GetPos():Distance(self:GetPos()) > dist ) do		
		
		path:Compute( self, ent:GetPos() )		-- Calculate the path for the bot

		path:Update( self )		-- "Move the bot along the path"
		if ( options.draw ) then path:Draw() end

		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then
			self:HandleStuck();
			return "stuck"
		end
		coroutine.yield()
	end

	return "ok"

end

function ENT:MoveToEntSearch( ent, dist, options )

	local options = options or {}

	local path = Path( "Follow" )	-- Define the path for the bot to follow
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 40 )
	path:Compute( self, ent:GetPos() )		-- Calculate the path for the bot

	while ( ent:IsValid() and ent:GetPos():Distance(self:GetPos()) > dist ) do		
		
		local newpos = self:FindWeapon( "near", { type = 'both', radius = 400 } )
		if newpos then
			DebugInfo(0,CurTime().."  newpos")
			path:Compute( self, newpos )
		else
			path:Compute( self, ent:GetPos() )		-- Calculate the path for the bot
			DebugInfo(0,CurTime().."  oldpos")
		end
		path:Update( self )		-- "Move the bot along the path"
		if ( options.draw ) then path:Draw() end

		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then
			self:HandleStuck();
			return "stuck"
		end

		coroutine.yield()
	end

	return "ok"

end
--
-- Name: NextBot:PlaySequenceAndWait
-- Desc: To be called in the behaviour coroutine only! Plays an animation sequence and waits for it to end before returning.
-- Arg1: string|name|The sequence name
-- Arg2: number|the speed (default 1)
-- Ret1: 
--
function ENT:PlaySequenceAndWait( name, speed )
	self.m_playingSequence = true
	local len = self:SetSequence( name )
	speed = speed or 1
	
	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( speed  );

	-- wait for it to finish
	coroutine.wait( len / speed )
	self.m_playingSequence = false
end

--
-- Name: NEXTBOT:Use
-- Desc: Called when a player 'uses' the entity
-- Arg1: entity|activator|The entity that activated the use
-- Arg2: entity|called|The entity that called the use
-- Arg3: number|type|The type of use (USE_ON, USE_OFF, USE_TOGGLE, USE_SET)
-- Arg4: number|value|Any passed value
-- Ret1: 
--
function ENT:Use( activator, caller, type, value )

end

--
-- Name: NEXTBOT:Think
-- Desc: Called periodically
-- Arg1:
-- Ret1: 
--
function ENT:Think()

end



function ENT:FirePrimary()
	if !self.Weapon or !self.Weapon:IsValid() and !self.Weapon.PrimaryAttack then return end
	local wep = self.Weapon
	if wep:GetNextPrimaryFire( ) < CurTime() then
		wep:PrimaryAttack()
	end
end

function ENT:FireSecondary()
	if !self.Weapon or !self.Weapon:IsValid() and !self.Weapon.SecondaryAttack then return end
	local wep = self.Weapon
	if wep:GetNextSecondaryFire( ) < CurTime() then
		wep:SecondaryAttack()
	end
end

function ENT:PickUpWeapon(wep)
	if !hook.Call( "PlayerCanPickupWeapon", GAMEMODE, self, wep ) then return false end
	MsgN(self:Name().." picked up "..tostring(wep))
	if self.Weapon and self.Weapon:IsValid() then
		self.Weapon:Remove()
	end
	self.Weapon = wep
	self.Weapon:SetOwner(self)
	self.Weapon:SetParent(self)
	self.Weapon.OldCollisionGroup = self.Weapon:GetCollisionGroup()
	self.Weapon:SetCollisionGroup(COLLISION_GROUP_NONE)
	self.Weapon.OldSolid = self.Weapon:GetSolid()
	self.Weapon:SetSolid(SOLID_NONE)
	self.Weapon:AddEffects(EF_BONEMERGE)
	self.Weapon:Fire( "SetParentAttachment", "anim_attachment_LH" )
	if self.Weapon.Equip then
		self.Weapon:Equip(self)
	end
	return true
end

function ENT:DropWeapon()
	if self.Weapon and self.Weapon:IsValid() then
		local vel = self.Weapon:GetVelocity()
		local pos = self.Weapon:GetPos()
		local ang = self.Weapon:GetAngles()
		MsgN(type(vel),type(pos),type(ang))
		debugoverlay.Axis( pos, ang, 10, self.color, true)
		//debugoverlay.Line( minW, maxW, 0.1, self.color, true)
		self.Weapon:SetParent(nil)
		self.Weapon:SetMoveType(MOVETYPE_VPHYSICS)
		self.Weapon:SetCollisionGroup(self.Weapon.OldCollisionGroup)
		self.Weapon:SetSolid(self.Weapon.OldSolid)
		self.Weapon:SetGravity(1)
		self.Weapon:SetVelocity(vel or Vector(0,0,0))
		self.Weapon:SetPos(pos)
		self.Weapon:SetAngles(ang)
	end
end

function ENT:Jump()
	self.loco:Jump()
end




function ENT:FindEnemy()
	if GetConVarNumber( "ai_disabled") == 1 then return false end
//	debugoverlay.Sphere( self:GetPos(), self.SearchRadius, 1.1, Color(0,100,0), false )
	local ent = ents.FindInSphere( self:GetPos(), 1000 )		// change to cone
	for k,v in pairs( ent ) do
		if self:IsEnemy(v) then
			if (v:IsPlayer() and v:Alive()) and GetConVarNumber( "ai_ignoreplayers") == 0 then
				self:SetEnemy(v)
				return true
			elseif v:IsNPC() then
				v:AddEntityRelationship(self, D_HT, 999 )
				self:SetEnemy(v)
				return true
			elseif v:IsVehicle() and v:GetDriver() and v:GetDriver():IsPlayer()  and GetConVarNumber( "ai_ignoreplayers") == 0 then
				self:SetEnemy(v:GetDriver())
				return true
			end
		else			-- if not a enemy

		end
	end	
	return false
end

function ENT:IsEnemy(ent)
	if IsValid(self:GetOwner()) then
		if self:GetOwner() == ent then		-- owner
			return false
		elseif ent:IsNPC() and ent:Disposition( self:GetOwner() ) == D_HT then	-- enemy npc
			return true
		elseif ent:IsPlayer() and GetConVarNumber( "ai_ignoreplayers") == 0 then //and ent:Team() != self:GetOwner():Team() then	-- non team member
			return true
		elseif ent:IsVehicle() and ent:GetDriver() and ent:GetDriver():IsPlayer() then //and ent:GetDriver():Team() != self:GetOwner():Team() then		--non team member vehicle
			return true
		end
		return false
	elseif (ent:IsNPC() or ent:IsPlayer() or (ent:IsVehicle() and ent:GetDriver() and ent:GetDriver():IsPlayer()) ) and GetConVarNumber( "ai_ignoreplayers") == 0 then
		return true		-- If there is no owner everything is an enemy
	end
end

function ENT:SetEnemy(ent)
	self.Enemy = ent
end

function ENT:GetEnemy()
	if IsValid(self.Enemy) and self.Enemy and self.Enemy != NULL and self.Enemy != nil and self.Enemy:IsValid() and GetConVarNumber( "ai_disabled") == 0 then	//if self.Enemy is real
		//if the enemy isn't too far, dead, or not visible let us know
		if self:GetPos():Distance(self.Enemy:GetPos()) > (self.LoseTargetDist or 1000) then
			if !self:FindEnemy() then	--if the enemy is lost search to find another
				self.Enemy = nil
				return false
			end
		elseif ( self.Enemy:IsPlayer() and !self.Enemy:Alive() ) or (self.Enemy:IsPlayer() and GetConVarNumber( "ai_ignoreplayers") == 1) then
			if !self:FindEnemy() then
				self.Enemy = nil
				return false
			end
		end	
		return self.Enemy
	else
		if !self:FindEnemy() then
			self.Enemy = nil
			return false
		end
	end
end

hook.Add("PlayerCanPickupWeapon", "DontTakeFromBots", function(ply,wep)
	if wep.GetOwner and wep:GetOwner():IsValid() and wep:GetOwner():IsBot() then
		return false
	end
	return true
end)