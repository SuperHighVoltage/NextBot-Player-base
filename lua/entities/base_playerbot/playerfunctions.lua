//include( "sv_nextbot.lua" )
//include( "animation.lua" )
//function ENT:() 
//	
//end
function ENT:AddCleanup(typ, ent)
	
end
function ENT:AddCount(typ, ent)
	
end
function ENT:AddDeaths(num)
	self.m_Deaths = self.m_Deaths or 0
	self.m_Deaths = self.m_Deaths + num
end
function ENT:AddFrags(num)
	self.m_Frags = self.m_Frags or 0
	self.m_Frags = self.m_Frags + num
end
function ENT:AddFrozenPhysicsObject(ent, physobj)
	
end
function ENT:AddPlayerOption( name, timeout, votecallback, drawcallback )
	
end
function ENT:AddVCDSequenceToGestureSlot()
	
end
function ENT:Alive()
	return true
end
function ENT:AllowFlashlight(bool)
	self.canFlashlight =  bool
end
function ENT:AnimResetGestureSlot(numSlot)
	
end
function ENT:AnimRestartGesture(numSlot, act, loop)
	self:RestartGesture( act );
end
function ENT:AnimRestartMainSequence()
	
end
function ENT:AnimSetGestureWeight()
	
end
function ENT:Armor()
	return self.m_Armor or 0
end
function ENT:Ban(min, reason)
	MsgN("Bot "..self:Name().." was banned. Being removed")
	self:Remove()
end
function ENT:CanUseFlashlight()
	return self.canFlashlight
end
function ENT:ChatPrint(msg)
	// Do nothing because there is no screen for the message to be printed to
end
function ENT:ConCommand(command)
	concommand.Run(self, command, nil, nil)
end
 function ENT:CreateRagdoll()
	// At some point make a ragdoll spawn here
end
function ENT:CrosshairDisable()
	// Maybe lower accuracy?
end
function ENT:CrosshairEnable()
end
function ENT:Crouching()
	return self.isCrouching
end
function ENT:Deaths()
	return self.m_Deaths
end
function ENT:DebugInfo()
	MsgN("Name: "..self:GetName())
	MsgN("Pos: "..tostring(self:GetPos()))
end
function ENT:DetonateTripmines()
	// There isn't any?
end
function ENT:DoAnimationEvent( event, data )
	MsgN("Nextbot:DoAnimationEvent: event = "..tostring(event)..", data = "..tostring(data))
	DoAnimationEvent( self, event, data )
end
function ENT:DoAttackEvent(...)
	Msg("DoAttackEvent: ")
	MsgN(...)
end
function ENT:DoCustomAnimEvent(...)
	Msg("DoCustomAnimEvent: ")
	MsgN(...)
end
function ENT:DoReloadEvent(...)
	Msg("DoReloadEvent: ")
	MsgN(...)
end
function ENT:DoSecondaryAttack(...)
	Msg("DoSecondaryAttack: ")
	MsgN(...)
end
function ENT:DrawViewModel(bool)
	// There is no view model
end
function ENT:DrawWorldModel(bool)
	if self.Weapon and self.Weapon:IsValid() then
		self.Weapon:SetNoDraw(!bool)
	end
end
function ENT:DropNamedWeapon(class)
	if self.Weapons[class] then
		self:DropWeapon(self.Weapons[class])
	end
end
function ENT:DropObject()
	
end
//function ENT:DropWeapon(wep)
	// Unattach weapon from then hand and toss infront
//end
function ENT:EnterVehicle(veh)
	// In the future there should be a ai mod for vehicles we could enable
end
function ENT:EquipSuit()
	
end
function ENT:ExitVehicle()
	
end
function ENT:Flashlight(bool)
	self.flashlightIsOn = bool
	if bool and self.canFlashlight then
		// self.flashlight = self.flashlight or new light entity
		// self.flashlight:TurnOn()
	else
		// self.flashlight:TurnOff()
	end
end
function ENT:FlashlightIsOn()
	return self.flashlightIsOn
end
function ENT:Frags()
	return self.m_Frags
end
function ENT:Freeze(bool)
	// skip over everything in RunBehaviour()?
	self.m_Frozen = bool
end
function ENT:GetActiveWeapon()
	return self.Weapon
end
function ENT:GetAimVector()
//	local vec =  self.Enemy and ( self.Enemy:LocalToWorld(self.Enemy:OBBCenter()) - self:GetShootPos()):Angle():Forward()
	return  vec or self:GetForward()
--[[
	if self:GetEnemy() then
		//return vector angle between eyes/hand? and enemy
	else
		//return the vector angle of the eyes/face
	end]]--
end
function ENT:GetAllowFullRotation()
	return false
end
function ENT:GetAmmoCount(ammoType)
	self.ammoNum = self.ammoNum or {}
	self.ammoNum[ammoType] = self.ammoNum[ammoType] or 0
//	if self.ammoNum[ammoType] then
//	PrintTable(self.ammoNum)
		return self.ammoNum[ammoType]
//	else
//		return 0 
//	end
end
function ENT:GetAvoidPlayers()	// Gets if the player will be pushed out of nocollided players.
	return self.m_AvoidPlayers
end
function ENT:GetCanWalk()
	return self.m_CanWalk
end
function ENT:GetEyeTrace()
	TraceData = {}
	TraceData.start		= self:GetShootPos()
	TraceData.endpos	= self:GetShootPos()+self:GetAimVector()*1000
	TraceData.filter	= {self, self.Weapon}
	TraceData.mask		= MASK_BLOCKLOS_AND_NPCS

	return util.TraceLine( TraceData )
end

function ENT:GetPData( name, default )
	name = Format( "%s[%s]", self:UniqueID(), name )
	local val = sql.QueryValue( "SELECT value FROM playerpdata WHERE infoid = " .. SQLStr(name) .. " LIMIT 1" )
	if ( val == nil ) then return default end
	return val
end
function ENT:GetShootPos()
	local shootPos = self:GetAttachment(self:LookupAttachment( "eyes") ).Pos
	
	if self.Weapon and self.Weapon:IsValid() and self.Weapon:LookupAttachment( "muzzle") != 0 then
		//MsgN(self.Weapon:LookupAttachment( "muzzle"))
		shootPos = self.Weapon:GetAttachment(self.Weapon:LookupAttachment( "muzzle") ).Pos
	end
	
	return shootPos
end

function ENT:GetViewModel()
	return self.Weapon
end
function ENT:GetViewOffset()
	return Vector(0,0,0)
end
function ENT:GetViewOffsetDucked()
	return Vector(0,0,0)
end
--
---- Do the rest of get functions after set functions
--
function ENT:Give(class)
	//make and spawn weapon at feet
end
function ENT:GiveAmmo(num, ammoType, displayPopup)
	self.ammoNum = self.ammoNum or {}
	self.ammoNum[ammoType] = self.ammoNum[ammoType] or 0
	self.ammoNum[ammoType] = self.ammoNum[ammoType] + num
	MsgN("Bot now has "..self.ammoNum[ammoType].." "..ammoType)
end
function ENT:GodDisable()
	self.m_God = false
end
function ENT:GodEnable()
	self.m_God = true
end
function ENT:HasWeapon(class)
	if self.Weapons[class] then
		return true
	else
		return false
	end
end
function ENT:InVehicle()
	return false	// return false until vehicle ai stuff
end
function ENT:IPAddress()
	return "0.0.0.0"
end
function ENT:IsAdmin()
	-- Admin SteamID need to be fully authenticated by Steam!
	if ( self.IsFullyAuthenticated && !self:IsFullyAuthenticated() ) then return false end
	if ( self:IsSuperAdmin() ) then return true end
	if ( self:IsUserGroup("admin") ) then return true end
	return false
end
function ENT:IsBot()
	return true
end
function ENT:IsConnected()
	return true
end
function ENT:IsDrivingEntity()
	return false	// Bots cant drive entities
end
function ENT:IsFrozen()
	return self.m_Frozen
end
function ENT:IsFullyAuthenticated()
	return true
end
function ENT:IsListenServerHost()
	return false
end
function ENT:IsMuted()
	return false
end
function ENT:IsNPC()
	return false
end
--[[function ENT:IsPlayer()
	return true		// why u no work!!!
end--]]--
local meta = FindMetaTable("Entity")
meta.oldIsPlayer = meta.oldIsPlayer or meta.IsPlayer -- Save old action and protect from autorefresh fucking it up
function meta:IsPlayer()
	MsgN(tostring(self.IsPlayerBot)..tostring(self))
    if ( self.IsPlayerBot ) then return true end -- Note, that's not a function call in the if , you might want to just check self:GetClass()
    return self:oldIsPlayer()
end
function ENT:IsPlayerBot()
	return true
end
function ENT:IsPlayingTaunt()
	return false	// Will add taunts one day
end
function ENT:IsSpeaking()
	return false
end
function ENT:IsSuitEquipped()
	return false	// Remove the abitity to run and have armor?
end
function ENT:IsSuperAdmin()
	-- Admin SteamID need to be fully authenticated by Steam!
	if ( self.IsFullyAuthenticated && !self:IsFullyAuthenticated() ) then return false end
	return ( self:IsUserGroup("superadmin") )
end
function ENT:IsTyping()
	return false
end
function ENT:IsUserGroup( name )
	if ( !self:IsValid() ) then return false end
	return ( self:GetNetworkedString( "UserGroup" ) == name )
end
function ENT:IsVehicle()
	return false
end
function ENT:IsVoiceAudible()
	return false
end
function ENT:IsWeapon()
	return false
end
function ENT:IsWorldClicking()
	return false
end
function ENT:KeyDown(key)
	return false	// Maybe return true for movement keys when they move in certin directions?
end
function ENT:KeyDownLast(key)
	return false	// Same as above
end
function ENT:KeyPressed(key)
	return false	// Diddo
end
function ENT:KeyReleased(key)
	return false 	// diddo
end
function ENT:Kick(reason)
	MsgN("Bot "..self:Name().." was kicked. Being removed")
	self:Remove()
end
function ENT:Kill(dmginfo)
	//self:BecomeRagdoll( damageinfo )
	self:OnKilled(dmginfo or DamageInfo())
//	self:Remove()
end
function ENT:KillSilent()
	//self:BecomeRagdoll( damageinfo )
	self:Remove()
end
function ENT:LagCompensation(bool)
end
function ENT:LastHitGroup()
	return self.m_LastHitGroup or 0		// Save hitgroup when damaged
end
function ENT:LimitHit(typ)
	
end
function ENT:Lock()
	self.m_Locked = true
end
function ENT:MotionSensorPos()
	// Should be safe to return nothing
end
function ENT:Name()
	return self.m_Name or "Bot"
end
function ENT:Nick()
	return self:Name()
end
function ENT:PacketLoss()
	return 0
end
function ENT:PhysgunUnfreeze()
	
end
function ENT:PickupObject(ent)
	
end
function ENT:Ping()
	return 0
end
function ENT:PlayScene()
	
end
function ENT:PlayStepSound()
	
end
function ENT:PrintMessage(typ, msg)
	
end
function ENT:RemoveAllAmmo()
	table.Empty( self.ammoNum )
end
function ENT:RemoveAllItems()
	self:RemoveAllAmmo()
	self:StripWeapons()
end
function ENT:RemoveAmmo(num, ammoType)
	self.ammoNum = self.ammoNum or {}
	self.ammoNum[ammoType] = self.ammoNum[ammoType] or 0
	self.ammoNum[ammoType] = math.Clamp( self.ammoNum[ammoType] - num, 0, 99999 )
	MsgN("Bot now has "..self.ammoNum[ammoType].." "..ammoType)
end
function ENT:RemovePData( name )
	name = Format( "%s[%s]", self:UniqueID(), name )
	sql.Query( "DELETE FROM playerpdata WHERE infoid = "..SQLStr(name) )
end

function ENT:RemoveSuit()
	
end
function ENT:ResetHull()
	
end
function ENT:TranslateWeaponActivity(act)
	if self.Weapon and self.Weapon:IsValid() and self.Weapon.TranslateActivity then
		return self.Weapon:TranslateActivity(act)
	end
	return act
end
--[[
function ENT:()
	
end
function ENT:()
	
end]]--
function ENT:SetArmor(num)
	self.m_Armor = num
end
function ENT:SetEyeAngles()
	
end
function ENT:SetName(name)
	self.m_Name = name
end
function ENT:SetPData( name, value )
	name = Format( "%s[%s]", self:UniqueID(), name )
	sql.Query( "REPLACE INTO playerpdata ( infoid, value ) VALUES ( "..SQLStr(name)..", "..SQLStr(value).." )" )
end
function ENT:SetUserGroup( name )
	self:SetNetworkedString( "UserGroup", name )
end