
AddCSLuaFile()

ENT.Base 			= "base_playerbot"
ENT.Spawnable		= true
ENT.IsPlayerBot = true
function ENT:Initialize()

	--self:SetModel( "models/props_halloween/ghost_no_hat.mdl" );
	--self:SetModel( "models/props_wasteland/controlroom_filecabinet002a.mdl" );
	local model, name = table.Random( player_manager.AllValidModels())
	self:SetModel( model );
	self:SetCollisionBounds( Vector(-4,-4,0), Vector(4,4,64) )
	self:SetHealth(100)
	//self:SetGravity(0.1)
	self:SetName(name)

	self.color = Color(math.random( 1,255 ),math.random( 1,255 ),math.random( 1,255 ),10)
	util.AddNetworkString( "DrawBotInfo" )
	self.InitTime = CurTime()
	self.nextWeaponCheck = 0
	self.nextWeaponFire = 0
	
	local entitys = ents.GetAll( )
	for k,v in pairs( entitys ) do
		if v:IsNPC() then
			v:AddEntityRelationship(self, D_HT, 9999)
			v:AddRelationship( self:GetClass().." D_HT 9999" )
		end
	end
//	 self.IsPlayerBot = true
end

function ENT:BotThink( fInterval )
	if self.loco:IsAttemptingToMove( ) then		//Lets push props out of the way
		local frontEnts = ents.FindInCone( self:GetPos() + self:GetUp()*15, self:GetForward(), 20, 30 )
		for k,v in pairs( frontEnts ) do
			local phys = v:GetPhysicsObject( )
			if IsValid(phys) then
				local ang = ( v:GetPos() - self:GetPos()):Angle()

				local vec = ang:Forward()
				local vec2 = ang:Right()*math.random()
				phys:SetVelocity( (vec+vec2)*100 )
			end
		end	
	end
		local min, max = Vector(-18,-18,-1), Vector(18,18,64)
		local minW, maxW = self:LocalToWorld(min), self:LocalToWorld(max)

	//	debugoverlay.Line( minW, maxW, 0.1, self.color, true)
	//	debugoverlay.Box( self:GetPos(),min, max, 0.1, self.color, true)
	if CurTime() > self.nextWeaponCheck then

		local weaponz = ents.FindInBox( minW, maxW)
		for k,v in pairs( weaponz ) do
			if v:IsWeapon() and v != self.Weapon then
				self:PickUpWeapon(v)
			end
		end	
		self.nextWeaponCheck = CurTime()+0.25
	end


	
	self:FirePrimary()
	//self:FireSecondary()
	
	local trace = self:GetEyeTrace()
	debugoverlay.Line( trace.StartPos, trace.HitPos, 0.1, self.color, true)
	
	if self.InitTime and self.InitTime + 2 < CurTime() then
	net.Start( "DrawBotInfo" )
		net.WriteString( self:GetName() )
		net.WriteVector( self:GetPos()+Vector(0,0,90) )
		net.WriteAngle( self:GetAngles()+Angle(0,90,90) )
		net.WriteFloat( self:Health() )
		net.WriteFloat( self:Armor() or 0 )
		net.WriteEntity( self.Weapon or nil )
		local clip1 = -1
		if self.Weapon and self.Weapon:IsValid() and self.Weapon:Clip1() then
			clip1 = self.Weapon:Clip1() or -1
		end
		net.WriteFloat( clip1 )
	net.Broadcast() // Send it to all players.
	end
	if Entity(1):KeyPressed(IN_USE) then
		self:Jump()
	end	
end

local options = {draw = true}
function ENT:RunBehaviour()

	while ( true ) do
	
		if true then	-- Set true to run
			self:SetEnemy(Entity(1))											-- I havn't made dectecting enemys work yet
			if self:GetEnemy() then												-- If we have an enemy
				DebugInfo2(20,CurTime().."  We have a enemy")
				if self:GetActiveWeapon() and self:GetActiveWeapon():IsValid() and self:GetAmmoCount(self:GetActiveWeapon().Primary.Ammo) != 0 then	-- If we have a weapon with ammo
					MsgN(self:GetActiveWeapon().Primary.Ammo,"   ",self:GetAmmoCount(self:GetActiveWeapon().Primary.Ammo))
					DebugInfo2(21,CurTime().."  We have a weapon with ammo")
					if self.Enemy:GetPos():Distance(self:GetPos()) < 300 then 	-- if enemy is close
						DebugInfo2(22,CurTime().."  Enemy is near")
						self.loco:SetDesiredSpeed( 170 )						-- move around at a mid speed
						self:MoveToPos( self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 100, options )
					else														-- if enemy it far away
						DebugInfo2(22,CurTime().."  Enemy is far")
						self.loco:SetDesiredSpeed( 200 )						-- run towards enemy
						self:MoveToEntSearch(self.Enemy, math.Rand( 200, 400 ), options)
					end
					coroutine.wait(math.Rand( 0, 2 ))							-- wait a bit before doing something else
				else															-- if we don't have a weapon or ammo
					DebugInfo2(21,CurTime().."  We don't have a weapon with ammo")
					self.loco:SetDesiredSpeed( 200 )							-- sprint because we don't have an enemy
					local pos = self:FindWeapon( "near", { type = 'both', radius = 100000 } )	-- find a weapon
					if (pos) then													-- if we found a weapon
						DebugInfo2(22,CurTime().."  Found weapon")
						self:MoveToPos( pos, options )							-- get weapon
					else														-- if we cant find a weapon
						DebugInfo2(22,CurTime().."  Can't find weapon")
						local hidespot = self:FindSpot( "random", { type = 'both', radius = 5000 } )
						if hidespot then										-- if we have somewhere to hide
							DebugInfo2(23,CurTime().."  Hiding")
							self:MoveToPos( hidespot, options )						-- hide
						else													-- well fuck
							DebugInfo2(23,CurTime().."  Fuck it, suicide run")
							self:MoveToEntSearch(self.Enemy, 10, options)				-- suicide run I guess
						end
					end
				end
			else																--if we don't have a enemy
				DebugInfo2(20,CurTime().."  We don't have a enemy")
				-- find weapon, look around, wander, follow owner
				if self:GetActiveWeapon() and self:GetActiveWeapon():IsValid() and self:GetAmmoCount(self:GetActiveWeapon():GetPrimaryAmmoType()) != 0 then	-- If we have a weapon with ammo
					DebugInfo2(21,CurTime().."  We have a weapon with ammo")
					self.loco:SetDesiredSpeed( 150 )							-- just walk around looking for enemy
					local pos = self:FindSpot( "random", { type = 'both', radius = 5000 } )
					pos = pos or self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200
					self:MoveToPos( pos, options )								-- wander
				else															-- If we don't have a weapon
					DebugInfo2(21,CurTime().."  We don't have a weapon with ammo")
					self.loco:SetDesiredSpeed( 170 )							-- we don't have to sprint because there is no enemy
					local pos = self:FindWeapon( "near", { type = 'both', radius = 1000 } )	-- find a weapon
					if pos then													-- if we found a weapon
						DebugInfo2(22,CurTime().."  Found weapon")
						self:MoveToPos( pos, options )							-- get weapon
					else														-- if we cant find a weapon
						DebugInfo2(22,CurTime().."  Can't find weapon")
						self.loco:SetDesiredSpeed( 150 )							-- just walk around looking for enemy
						local pos = self:FindSpot( "random", { type = 'both', radius = 5000 } )
						pos = pos or self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200
						self:MoveToPos( pos, options )								-- wander
					end
				end
				//self.loco:SetDesiredSpeed( 100 )
				//self:MoveToPos( self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 400, options ) -- walk to a random place
				//coroutine.wait(math.Rand( 1, 3 ))							-- wait a bit before doing something else
			end
			
			
			
		else
		--[[
			local pos = self:FindWeapon( "random", { type = 'both', radius = 5000 } )	-- find a weapon

			if ( pos ) then
				self.loco:SetDesiredSpeed( 200 )										-- run speed
				self:MoveToPos( pos, options )													-- move to position (yielding)
			else
				self.loco:SetDesiredSpeed( math.Rand(75, 250) )							-- pick a random speed
				self:MoveToPos( self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 400, options ) -- walk to a random place within about 200 units (yielding)
				//coroutine.wait(1)
			end
			if self.Weapon then														-- If a weapon was picked up
				self.loco:SetDesiredSpeed( math.Rand(75, 250) )						-- pick a random speed
				self:MoveToEnt(Entity(1), 100, options)										-- move towards entity 1 (you) untill within 100 units
				//self:PlayScene( "scenes/npc/male01/watchout.vcd" )					-- yell out something
				//self:PlaySequenceAndWait( "death_0".. math.random( 1,4 ) )			-- play random death animation
				//self:Kill( )	
			end
			
			]]--
			self.loco:SetDesiredSpeed( 200 )
			self:MoveToEntSearch(Entity(1), 100, options)	
			
			
			
			
			
			
		end
		coroutine.yield()

	end


end
	
function DebugInfo2(num,str)
	for i=0,num-20 do
		Msg("\t")
	end
	MsgN(str)
	DebugInfo(num,str)
end
--
-- List the NPC as spawnable
--
list.Set( "NPC", "bottest", 	{	Name = "PlayerBot", 
										Class = "bottest",
										Category = "NextBot"	
									})
