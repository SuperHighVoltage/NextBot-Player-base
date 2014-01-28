//include( "sv_nextbot.lua" )
//include( "playerfunctions.lua" )

--
-- Name: NEXTBOT:BodyUpdate
-- Desc: Called to update the bot's animation
-- Arg1:
-- Ret1:
--
function ENT:BodyUpdate()

	if !self.m_playingSequence then
		local newact = self:CalcMainActivity( self:GetVelocity() )
		
		if self:GetActivity() == newact then
			//self:SetAnimation( newact )
		else
			self:StartActivity( newact )	
		end
	end
	-- 
	-- If we're not walking or running we probably just want to update the anim system
	--
	self:FrameAdvance()

end

function ENT:CalcMainActivity( velocity )	

	self.CalcIdeal = ACT_MP_STAND_IDLE

	self:HandlePlayerLanding( velocity, self.m_bWasOnGround );

	if ( self:HandlePlayerNoClipping( velocity ) ||
		self:HandlePlayerVaulting( velocity ) ||
		self:HandlePlayerJumping( velocity ) ||
		self:HandlePlayerDucking( velocity ) ||
		self:HandlePlayerSwimming( velocity ) ) then

	else

		local len2d = velocity:Length2D()
		if ( len2d > 150 ) then 
			self.CalcIdeal = ACT_MP_RUN 
		elseif ( len2d > 0.5 ) then 
			self.CalcIdeal = ACT_MP_WALK 
		end
		
		local Velocity = self:GetVelocity()
		local fwd = self:GetRight()                       
		local dp = fwd:Dot( Vector(0,0,1) )
		local dp2 = fwd:Dot( Velocity )
	//DebugInfo(4, "Right Velecoty "..tostring(dp2))
		DebugInfo(4, tostring(dp2)) 
		if ( dp2 > 150 ) then 
			self:SetPoseParameter( "move_y", dp2/149.85  ) 
			DebugInfo(5, tostring(dp2/149.85)) 
		elseif ( dp2 > 0.5 ) then 
			self:SetPoseParameter( "move_y", dp2/51.91  ) 
			DebugInfo(5, tostring(dp2/51.91)) 
		else 
			self:SetPoseParameter( "move_y", 0 ) 
			DebugInfo(5, tostring(0)) 
		end
		//self:SetPoseParameter( "move_y", dp2/149.85  )

		local Velocity = self:GetVelocity()
		local fwd = self:GetForward()                       
		local dp = fwd:Dot( Vector(0,0,1) )
		local dp2 = fwd:Dot( Velocity )
		if ( dp2 > 150 ) then 
			self:SetPoseParameter( "move_x", dp2/207.43  ) 
		elseif ( dp2 > 0.5 ) then 
			self:SetPoseParameter( "move_x", dp2/78.78  ) 
		end
		//self:SetPoseParameter( "move_x", dp2/207.43  )

	end
	
	if self.Enemy then
		//self.loco:FaceTowards( self.Enemy:GetPos() )
		local ang1 = ( self.Enemy:LocalToWorld(self.Enemy:OBBCenter()) - self:GetShootPos()):Angle()
		local ang2 = self:GetAimVector():Angle()
		local ang = ang1.y - ang2.y
		if ang > 180 then
			ang = ang - 360
		end
		self:SetPoseParameter( "aim_yaw", math.Clamp(ang, -90, 90)  ) 
		local ang = ang1.p - ang2.p
		if ang > 180 then
			ang = ang - 360
		end
		self:SetPoseParameter( "aim_pitch", math.Clamp(ang, -90, 90)  ) 

	end

	self.m_bWasOnGround = self:IsOnGround()
	self.m_bWasNoclipping = ( self:GetMoveType() == MOVETYPE_NOCLIP && !self:InVehicle() )

	return self:TranslateActivity( self.CalcIdeal )

end

function ENT:HandlePlayerJumping( velocity )
	
	if ( self:GetMoveType() == MOVETYPE_NOCLIP ) then
		self.m_bJumping = false;
		return
	end

	-- airwalk more like hl2mp, we airwalk until we have 0 velocity, then it's the jump animation
	-- underwater we're alright we airwalking
	if ( !self.m_bJumping && !self:OnGround() && self:WaterLevel() <= 0 ) then
	
		if ( !self.m_fGroundTime ) then

			self.m_fGroundTime = CurTime()
			
		elseif (CurTime() - self.m_fGroundTime) > 0 && velocity:Length2D() < 0.5 then

			self.m_bJumping = true
			self.m_bFirstJumpFrame = false
			self.m_flJumpStartTime = 0

		end
	end
	
	if self.m_bJumping then
	
		if self.m_bFirstJumpFrame then

			self.m_bFirstJumpFrame = false
			self:AnimRestartMainSequence()

		end
		
		if ( self:WaterLevel() >= 2 ) ||	( (CurTime() - self.m_flJumpStartTime) > 0.2 && self:OnGround() ) then

			self.m_bJumping = false
			self.m_fGroundTime = nil
			self:AnimRestartMainSequence()

		end
		
		if self.m_bJumping then
			self.CalcIdeal = ACT_MP_JUMP
			return true
		end
	end
	
	return false
end

function ENT:HandlePlayerDucking( velocity )

	if ( !self:Crouching() ) then return false end

	if ( velocity:Length2D() > 0.5 ) then
		self.CalcIdeal = ACT_MP_CROUCHWALK
	else
		self.CalcIdeal = ACT_MP_CROUCH_IDLE
	end
		
	return true

end

function ENT:HandlePlayerNoClipping( velocity )

	if ( self:GetMoveType() != MOVETYPE_NOCLIP || self:InVehicle() ) then 

		if ( self.m_bWasNoclipping ) then

			self.m_bWasNoclipping = nil
			self:AnimResetGestureSlot( GESTURE_SLOT_CUSTOM )
			if ( CLIENT ) then self:SetIK( true ); end

		end

		return

	end

	if ( !self.m_bWasNoclipping ) then

		self:AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_GMOD_NOCLIP_LAYER, false )
		if ( CLIENT ) then self:SetIK( false ); end

	end

			
	return true

end

function ENT:HandlePlayerVaulting( velocity )

	if ( velocity:Length() < 1000 ) then return end
	if ( self:IsOnGround() ) then return end

	self.CalcIdeal = ACT_MP_SWIM		
	return true

end

function ENT:HandlePlayerSwimming( velocity )

	if ( self:WaterLevel() < 2 ) then 
		self.m_bInSwim = false
		return false 
	end
	
	if ( velocity:Length2D() > 10 ) then
		self.CalcIdeal = ACT_MP_SWIM
	else
		self.CalcIdeal = ACT_MP_SWIM_IDLE
	end
		
	self.m_bInSwim = true
	return true
	
end

function ENT:HandlePlayerLanding( velocity, WasOnGround ) 

	if ( self:GetMoveType() == MOVETYPE_NOCLIP ) then return end

	if ( self:IsOnGround() && !WasOnGround ) then
		self:RestartGesture( ACT_LAND );
	end

end

local IdleActivity = ACT_HL2MP_IDLE
local IdleActivityTranslate = {}
	IdleActivityTranslate [ ACT_MP_STAND_IDLE ] 				= IdleActivity
	IdleActivityTranslate [ ACT_MP_WALK ] 						= IdleActivity+1
	IdleActivityTranslate [ ACT_MP_RUN ] 						= IdleActivity+2
	IdleActivityTranslate [ ACT_MP_CROUCH_IDLE ] 				= IdleActivity+3
	IdleActivityTranslate [ ACT_MP_CROUCHWALK ] 				= IdleActivity+4
	IdleActivityTranslate [ ACT_MP_ATTACK_STAND_PRIMARYFIRE ] 	= IdleActivity+5
	IdleActivityTranslate [ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ]	= IdleActivity+5
	IdleActivityTranslate [ ACT_MP_RELOAD_STAND ]		 		= IdleActivity+6
	IdleActivityTranslate [ ACT_MP_RELOAD_CROUCH ]		 		= IdleActivity+6
	IdleActivityTranslate [ ACT_MP_JUMP ] 						= ACT_HL2MP_JUMP_SLAM
	IdleActivityTranslate [ ACT_MP_SWIM_IDLE ] 					= ACT_MP_SWIM_IDLE
	IdleActivityTranslate [ ACT_MP_SWIM ] 						= ACT_MP_SWIM
	IdleActivityTranslate [ ACT_LAND ] 							= ACT_LAND
	
-- it is preferred you return ACT_MP_* in CalcMainActivity, and if you have a specific need to not tranlsate through the weapon do it here
function ENT:TranslateActivity( act )

	local newact = self:TranslateWeaponActivity( act )
	
	-- a bit of a hack because we're missing ACTs for a couple holdtypes
	if ( act == ACT_MP_CROUCH_IDLE ) then
		local wep = self:GetActiveWeapon()
		
		if ( IsValid(wep) ) then
			-- there really needs to be a way to get the holdtype set in sweps with SWEP.SetWeaponHoldType
			-- people just tend to use wep.HoldType because that's what most of1the SWEP examples do
			if wep.HoldType == "knife" or wep:GetHoldType() == "knife" then
				newact = ACT_HL2MP_IDLE_CROUCH_KNIFE
			end
		end
	end
	
	-- select idle anims if the weapon didn't decide
	if ( act == newact ) then
		return IdleActivityTranslate[ act ]
	end

	return newact

end