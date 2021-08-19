-- Title: SimpleCombatHud
-- Author: Richard Chambers
-- Date: November 15, 2011
-- Description: A simple combat heads up display addon for World of Warcraft.
-- Copyright:  Richard Chambers, November 15, 2011
-- Licensing: Code Project Open License, http://www.codeproject.com


-- This is the main table which we use to encapsulate all the other
-- functionality.  We create the table then we create the main frame.
-- By encapsulating all of our functionality into a single table
-- we are not cluttering up the global name space with various variables.

SimpleCombatHud = SimpleCombatHud or {};


-- The following table is our persistant store area for the data that we
-- ask World of Warcraft to store for us.  This persistant store area
-- contains data that we want to save between play sessions.  This
-- table is specified in the SavedVariables: line of the .toc file.
-- This table is saved as a .lua file in a sub-folder of the WTF folder.
SimpleCombatHudPerCharDB = SimpleCombatHudPerCharDB or {
		Frame_myPoint = "CENTER",
		Frame_myRelativePoint = "CENTER",
		Frame_myXOfs = -50,
		Frame_myYOfs = -50
	};


-- Now create our main frame which will be used for all of our event processing
-- and from which our various other display components such as the status bars will
-- be added on to.

SimpleCombatHud.frame = CreateFrame("Frame", nil, UIParent);
SimpleCombatHud.frame:SetFrameStrata("BACKGROUND");


-- Create a helper function for OnEvent() so that our event handlers will be
-- separate functions rather than one large OnEvent() function.
-- We will specify our event handlers as being functions within our frame variable
-- using the name of the event after the colon such as Rjc_CombatLog.frame:ADDON_LOADED().
-- This way we can divide up our event handlers into separate functions that are automatically
-- invoked when the event is transfered to the main frame.
-- This line of code sets the OnEvent handler to be an anonymous (lambda) function which dispatches the
-- received event to the function assigned to that event name if such an event handler exists.
-- Notice that when we call the event handler, the first argument is self allowing us to use the colon notation of Lua.

SimpleCombatHud.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end);


-- Now we register for the events that tell us that the player has entered the World of Warcraft world
-- and that this addon is loaded and running.
SimpleCombatHud.frame:RegisterEvent("ADDON_LOADED");
SimpleCombatHud.frame:RegisterEvent("PLAYER_ENTERING_WORLD");


-- This is the end of our initialization when the addon is loaded
-- By this point we have:
--   - created the main frame allowing us to see events
--   - registered for the events so that World of Warcraft can notify us when we are loaded
-- We now wait until the addon is loaded and the player has entered the world.  When that
-- happens we will then execute the additional initialization to create the status bars
-- and register for the events that we want to see allowing us to monitor the health and power
-- of the player character.

-- The source following is for the various functions that we use to implement the functionality
-- of our addon.

-- ------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------

-- This is a simple debug print function that will print messages to the standard
-- chat dialog/frame in the World of Warcraft standard user interface.
-- This function is very helpful when determining whether particular events are being
-- handled as well as to print out data to see what is going on.
local Debug = function  (str, ...)
	if ... then str = str:format(...) end
	DEFAULT_CHAT_FRAME:AddMessage(("Addon: %s"):format(str));
end


-- This is a function that will create a new horizontal status bar frame beneath
-- the frame that is specified.
local MakeStatusBar = function (parent, above, xOffset, yOffset)
	local statusbar = CreateFrame("StatusBar", nil, parent);

	-- check to see if the optional offsets have been specified
	if (xOffset == nil) then xOffset = 0; end
	if (yOffset == nil) then yOffset = -5; end

	statusbar:SetPoint("TOP", above, "BOTTOM", xOffset, yOffset);
	statusbar:SetHeight(20);
	statusbar:SetWidth(80);
	statusbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	statusbar:GetStatusBarTexture():SetHorizTile(false)
	statusbar:GetStatusBarTexture():SetVertTile(false)

	statusbar.bg = statusbar:CreateTexture(nil,"BACKGROUND");
	statusbar.bg:SetTexture(.65, .5, .5, .75);
	statusbar.bg:SetAllPoints(true);

	return statusbar;
end

-- ----------------------------------------------------------------------------------

--        Mouse Drag of Frame
-- Following two functions are used to implement dragging of the
-- frame.  When dragging stops, we want to remember where the player has
-- positioned the frame so that the next time the addon starts, we will
-- position the frame at that location.
function SimpleCombatHud.frame:OnDragStart (button)
	-- Debug ("Drag Start");
	self:StartMoving();
end

function SimpleCombatHud.frame:OnDragStop ()
	-- Debug ("Drag stop");
	self:StopMovingOrSizing();

	-- Save this location in our saved variables for the next time this character
	-- is played.
	local myPoint, myRelativeTo, myRelativePoint, myXOfs, myYOfs = self:GetPoint();
	SimpleCombatHudPerCharDB.Frame_myPoint = myPoint;
	SimpleCombatHudPerCharDB.Frame_myRelativeTo = myRelativeTo;
	SimpleCombatHudPerCharDB.Frame_myRelativePoint = myRelativePoint;
	SimpleCombatHudPerCharDB.Frame_myXOfs = myXOfs;
	SimpleCombatHudPerCharDB.Frame_myYOfs = myYOfs ;
end

-- ----------------------------------------------------------------------------------

-- Following functions are used to register for particular events.
-- The name of the function is the event which it is to handle.
function SimpleCombatHud.frame:ADDON_LOADED(addon)
	Debug ("ADDON_LOADED");

	self:UnregisterEvent("ADDON_LOADED");
	self.ADDON_LOADED = nil;

	if IsLoggedIn() then
		self:PLAYER_LOGIN(true);
	else
		self:RegisterEvent("PLAYER_LOGIN");
	end
end

function SimpleCombatHud.frame:PLAYER_LOGIN(delayed)
	Debug ("PLAYER_LOGIN");
	self:UnregisterEvent("PLAYER_LOGIN");
	self.PLAYER_LOGIN = nil;
end


function SimpleCombatHud.frame:PLAYER_ENTERING_WORLD(delayed)

	-- player has entered the world so we are no longer interested in this event
	Debug ("PLAYER_ENTERING_WORLD");
	self:UnregisterEvent("PLAYER_ENTERING_WORLD");
	self.PLAYER_ENTERING_WORLD = nil;

	-- adjust our main frame so we position it to the last place the player moved it to
	-- and so that we can move it along with the status bars when requested.
	self:SetHeight(40);
	self:SetWidth(80);
	self.texture = self:CreateTexture(nil,"BACKGROUND");
	self.texture:SetAllPoints(self);
	self.texture:SetTexture(.15, .15, .15, .5);
	self.labelText = self:CreateFontString(nil,"ARTWORK","GameFontNormal");
	self.labelText:SetPoint("TOP",self,"TOP");
	self.labelText:SetText("Player");
	self.threatText = self:CreateFontString(nil,"ARTWORK","GameFontNormal");
	self.threatText:SetPoint("BOTTOM",self,"BOTTOM");
	self.threatText:SetText("Hello");

	self:SetPoint(SimpleCombatHudPerCharDB.Frame_myPoint, UIParent, SimpleCombatHudPerCharDB.Frame_myRelativePoint, SimpleCombatHudPerCharDB.Frame_myXOfs, SimpleCombatHudPerCharDB.Frame_myYOfs);

	-- enable the frame to be moveable using the left mouse button.
	-- then set the scripts or functions to be triggered when movement starts and ends.
	self:SetMovable(true);
	self:EnableMouse(true)
	self:RegisterForDrag("LeftButton");
	self:SetScript("OnDragStart", self.OnDragStart);
	self:SetScript("OnDragStop", self.OnDragStop);
	self:Show();

	-- Now create the two different status bars that we will be displaying.
	-- as we create each one, we will call the function to initialize the bar.
	-- The health status bar will be on top and the power status bar below.
	-- This first set of status bars is to display the player character's health and power.
	SimpleCombatHud.statusbar = {};
	SimpleCombatHud.statusbar["player"] = {};
	SimpleCombatHud.statusbar["pet"] = {};
	SimpleCombatHud.statusbar["target"] = {};

	SimpleCombatHud.statusbar["player"].health = MakeStatusBar (self, self);
	SimpleCombatHud.statusbar["player"].health:SetMinMaxValues(0,1);
	SimpleCombatHud.statusbar["player"].health:Show();

	SimpleCombatHud.statusbar["player"].power = MakeStatusBar (self, SimpleCombatHud.statusbar["player"].health);
	SimpleCombatHud.statusbar["player"].power:SetMinMaxValues(0,1);
	SimpleCombatHud.statusbar["player"].power:Show();

	self:UNIT_HEALTH("player");
	self:UNIT_POWER("player");

	-- Next we create a set of status bars to display the player character's pet, if he should have one.
	-- These status bars will be hidden unless the character has a pet out.
	SimpleCombatHud.statusbar["pet"].health = MakeStatusBar (self, SimpleCombatHud.statusbar["player"].power, 0, -20);
	SimpleCombatHud.statusbar["pet"].health:SetMinMaxValues(0,1);
	SimpleCombatHud.statusbar["pet"].health:Hide();

	SimpleCombatHud.statusbar["pet"].power = MakeStatusBar (self, SimpleCombatHud.statusbar["pet"].health);
	SimpleCombatHud.statusbar["pet"].power:SetMinMaxValues(0,1);
	SimpleCombatHud.statusbar["pet"].power:Hide();

	self:UNIT_HEALTH("pet");
	self:UNIT_POWER("pet");

	-- Next we create a set of status bars to display the target's health and power.  The target is whatever
	-- character the player has selected and it may be an enemy or a friend.
	-- As with the pet status bars, these are only displayed if the player has a target.
	SimpleCombatHud.statusbar["target"].health = MakeStatusBar (self, SimpleCombatHud.statusbar["pet"].power);
	SimpleCombatHud.statusbar["target"].health:SetMinMaxValues(0,1);
	SimpleCombatHud.statusbar["target"].health:Hide();
	-- we need to clear the current attachement and set a new attachement point for the target status bar.
	-- we want the target status bar to be to the right of the player's status bar.
	SimpleCombatHud.statusbar["target"].health:ClearAllPoints ();
	SimpleCombatHud.statusbar["target"].health:SetPoint ("LEFT", SimpleCombatHud.statusbar["player"].health, "RIGHT", 10, 0);

	SimpleCombatHud.statusbar["target"].power = MakeStatusBar (self, SimpleCombatHud.statusbar["target"].health);
	SimpleCombatHud.statusbar["target"].power:SetMinMaxValues(0,1);
	SimpleCombatHud.statusbar["target"].power:Hide();

	-- finally, lets check to see if the player has a pet out.  if so then display the pet status bars.
	local hasUI, isHunterPet = HasPetUI();
	if hasUI then
		SimpleCombatHud.statusbar["pet"].health:Show();
		SimpleCombatHud.statusbar["pet"].power:Show();
		--Debug ("has Pet Ui");
		--if isHunterPet then
		--	Debug ("Pet is a hunter pet");
		--else
		--	Debug ("Pet is a warlock minion");
		--end
	end

	-- register for the events in which we are interested, one for changes in health
	-- and the other for changes in power (mana, rage, focus, etc.).  Some of these types
	-- of power begin at a max value and are consumed by player actions until regenerated through
	-- resting or drinking/eating (e.g. mana).  Other types of power begin at 0 and are generated
	-- through player actions such as combat (e.g. rage).

	self:RegisterEvent("UNIT_HEALTH");            -- changes in the character's health
	self:RegisterEvent("UNIT_MAXHEALTH");

	self:RegisterEvent("UNIT_POWER");             -- changes in the character's power (mana, rage, focus, etc.)
	self:RegisterEvent("UNIT_MAXPOWER");

	self:RegisterEvent("UNIT_PET");               -- whether character has a pet out or not
	self:RegisterEvent("PLAYER_TARGET_CHANGED");  -- whether character has changed selected target

	self:RegisterEvent("UNIT_THREAT_LIST_UPDATE"); -- changes what enemies are feeling threatened by the character
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE");

	-- we also register for the various zone change events so that we can update our
	-- display after a zone change.  a zone change happens when the character moves
	-- from one zone to another.  one example of a zone change is when a character is
	-- entering or leaving an instance.  sometimes a zone change can take many seconds
	-- and during that time the health and/or power may have changed quite a bit during
	-- that wait time. a problem seen is that between the time that a character leaves
	-- one zone and then appears in another can be large enough that the character's
	-- data on the server is at its maximum or its minimum so the server stops sending
	-- update messages to the client.  the result is the display is out of date however
	-- since the server is no longer sending update messages, the display will not be
	-- corrected until the next time the server sends a message.
	self:RegisterEvent("ZONE_CHANGED");
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	self:RegisterEvent("ZONE_CHANGED_INDOORS");
end


-- --------------------------------------------------------------------------------

--     Frame event handlers
-- The following functions are the handlers for those events that we have
-- decided we want to handle.  Handling an event requires that you register
-- for the event and then supply some kind of a handler.
-- We have written our event handling functionality so that handling events
-- requires two steps:
--    register for the event using the RegisterEvent() method of the Frame widget
--    write a function whose name is the event label



--             ----------------------------------------------
-- handle the events about threat changes. threat changes come from
-- how much threat the character generates due to damage and threat
-- increasing actions (tanks have actions that generate large amounts
-- of threat as do some spells or weapon imbues) or threat decreasing
-- actions (some classes have spells to reduce threat such as priest fade).
function SimpleCombatHud.frame:UNIT_THREAT_LIST_UPDATE (...)
	-- Debug ("  Player target: Type=UNIT_THREAT_LIST_UPDATE  ");
	self:UNIT_THREAT_SITUATION_UPDATE (...);
end

function SimpleCombatHud.frame:UNIT_THREAT_SITUATION_UPDATE (...)
	local destName = select (1, ...);
	local isTanking,threatstatus,threatpct,rawthreatpct,threatvalue = UnitDetailedThreatSituation("player", "target");

	threatpct = (threatpct or 0);

	--Debug ("  Player target: Type=UNIT_THREAT_SITUATION_UPDATE  threat "..threatpct);
	if (threatpct > 75) then
		self.texture:SetTexture(.45, .45, .45, 1.0);
	elseif (threatpct > 60) then
		self.texture:SetTexture(.30, .30, .30, .75);
	else
		self.texture:SetTexture(.15, .15, .15, .5);
	end
	threatpct = math.floor (threatpct + .4);
	self.threatText:SetText("Threat "..(threatpct or 0));
end

--             ----------------------------------------------
-- handle the events sent by the server for health changes.
-- we look at who the event is for then update that unit's status
-- if it is a unit we are interested in.
-- we also do some color coding of the display to warn the player
-- if the health or the power is getting low.
-- we look for changes in the maximum health that can be from spells
-- or potions that increase max health through stamina increases
-- or other effects.
function SimpleCombatHud.frame:UNIT_MAXHEALTH (...)
	-- Debug ("  Player target: Type=UNIT_MAXHEALTH  Health ");
	self:UNIT_HEALTH (...);
end

function SimpleCombatHud.frame:UNIT_HEALTH (...)
	local destName = select (1, ...);

	if (destName == "player" or destName == "pet" or destName == "target") then
		local myHealthMax = UnitHealthMax (destName);

		if (myHealthMax > 0) then
			local myHealth = UnitHealth (destName)/myHealthMax;
			--Debug ("  Type=UNIT_HEALTH  Health "..myHealth.." destname = "..destName);
			SimpleCombatHud.statusbar[destName].health:SetValue(myHealth);
			SimpleCombatHud.statusbar[destName].health:Show();
			if (myHealth > .5) then
				SimpleCombatHud.statusbar[destName].health:SetStatusBarColor(0.15, 0.75, 0.15);
			elseif (myHealth > .33) then
				SimpleCombatHud.statusbar[destName].health:SetStatusBarColor(0.85, 0.75, 0.15);
			else
				SimpleCombatHud.statusbar[destName].health:SetStatusBarColor(0.85, 0.15, 0.15);
			end
		end
	end
end

--             ----------------------------------------------
-- Handle the events for power.  There are several different kinds of power
-- as what used to be different attributes such as mana, focus, and rage have
-- been grouped together into a single event with an additional argument indicating
-- the type of power.  This change happened with Warcraft 4.0 and the old style
-- events have been deprecated.
function SimpleCombatHud.frame:UNIT_MAXPOWER (...)
	-- Debug ("  Player target: Type=UNIT_MAXPOWER  power ");
	self:UNIT_POWER (...);
end

function SimpleCombatHud.frame:UNIT_POWER (...)
	local destName = select (1, ...);

	-- Debug ("UnitPowerType = "..UnitPowerType(destName).." power max "..UnitPowerMax(destName));

	if (destName == "player" or destName == "pet" or destName == "target") then
		local myPowerMax = UnitPowerMax (destName);

		if (myPowerMax > 0) then
			local myPower = 0;
			myPower = UnitPower (destName)/myPowerMax;

			--Debug ("  Type=UNIT_POWER  power "..myPower.." destname = "..destName);
			SimpleCombatHud.statusbar[destName].power:SetValue(myPower);
			SimpleCombatHud.statusbar[destName].power:Show();
			if (myPower > .5) then
				SimpleCombatHud.statusbar[destName].power:SetStatusBarColor(0.15, 0.15, 0.75);
			elseif (myPower > .33) then
				SimpleCombatHud.statusbar[destName].power:SetStatusBarColor(0.85, 0.15, 0.75);
			else
				SimpleCombatHud.statusbar[destName].power:SetStatusBarColor(0.85, 0.15, 0.15);
			end
		end
	end
end

--             ----------------------------------------------
-- handle the event of when the character gets or dismisses a pet.
-- we use the HasPetUI() function to see if there is a pet that
-- is out and has a pet user interface bar displayed.  if there is
-- a pet then we want to update the pet's status otherwise we will
-- hide the pet status bars.
function SimpleCombatHud.frame:UNIT_PET (...)
	local destName = select (1, ...);

	--Debug ("  Player target: Type=UNIT_PET   destname = "..destName);
	local hasUI, isHunterPet = HasPetUI();
	if hasUI then
		self:UNIT_HEALTH("pet");
		self:UNIT_POWER("pet");
		SimpleCombatHud.statusbar["pet"].health:Show();
		SimpleCombatHud.statusbar["pet"].power:Show();
		--Debug ("has Pet Ui");
		--if isHunterPet then
		--	Debug ("Pet is a hunter pet");
		--else
		--	Debug ("Pet is a warlock minion");
		--end
	else
		--Debug ("HasPetUI() failed ");
		SimpleCombatHud.statusbar["pet"].health:Hide();
		SimpleCombatHud.statusbar["pet"].power:Hide();
	end
end

--             ----------------------------------------------
-- the player has selected a different target or the player has
-- unselected what was previously targeted.  so decide if the
-- target indicators should be updated or not depending on whether
-- there is a target.  If the target does not exist, just hide the
-- target status display.
function SimpleCombatHud.frame:PLAYER_TARGET_CHANGED()
	if (UnitExists("target")) then
		self:UNIT_HEALTH("target");
		self:UNIT_POWER("target");
	else
		SimpleCombatHud.statusbar["target"].health:Hide();
		SimpleCombatHud.statusbar["target"].power:Hide();
	end
end

--             ----------------------------------------------
-- the different zone change events signify different types of actions and
-- situations however in our case we just want to update the combat display
-- so all of the zone change events are handled by the same code in the
-- same way.
function SimpleCombatHud.frame:ZONE_CHANGED()
	self:UNIT_HEALTH("player");
	self:UNIT_POWER("player");
	self:UNIT_HEALTH("pet");
	self:UNIT_POWER("pet");
	self:PLAYER_TARGET_CHANGED();
end

function SimpleCombatHud.frame:ZONE_CHANGED_NEW_AREA()
	self:ZONE_CHANGED();
end

function SimpleCombatHud.frame:ZONE_CHANGED_INDOORS ()
	self:ZONE_CHANGED();
end

function SimpleCombatHud.frame:UNIT_COMBAT ()
	--Debug (" UNOT_COMBAT fired");
end