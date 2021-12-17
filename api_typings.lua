-- YOU SHOULDN'T REQUIRE THIS LUA FILE IN ANY OF YOUR SCRIPTS!
-- YOU SHOULDN'T REQUIRE THIS LUA FILE IN ANY OF YOUR SCRIPTS!
-- YOU SHOULDN'T REQUIRE THIS LUA FILE IN ANY OF YOUR SCRIPTS!
---@diagnostic disable: lowercase-global

--@param missionName string
function changeMission(missionName) end

---@param playerId number
---@param text string
function sendClientMessage(playerId, text) end

---@param text string
function sendClientMessageToAll(text) end


---@param playerId number
function humanSpawn(playerId) end

---@param playerId number
function humanDespawn(playerId) end

---@param playerId number
---@return boolean isSpawned
function humanIsSpawned(playerId) end

---@param playerId number
---@param name string
function humanSetName(playerId, name) end

---@param playerId number
---@return string name
function humanGetName(playerId) end

---@param playerId number
---@param health number
function humanSetHealth(playerId, health) end

---@param playerId number
---@return number health
function humanGetHealth(playerId) end

---@param playerId number
---@param position table
function humanSetPos(playerId, position) end

---@param playerId number
---@return table position
function humanGetPos(playerId) end

---@param playerId number
---@param direction table
function humanSetDir(playerId, direction) end

---@param playerId number
---@return table direction
function humanGetDir(playerId) end

---@param playerId number
---@return boolean isDead
function humanIsDead(playerId) end

---@param playerId number
---@return string model
function humanGetModel(playerId) end

---@param playerId number
---@param model string
function humanSetModel(playerId, model) end

---@param playerId number
---@param speed number
function humanSetSpeed(playerId, speed) end

---@param playerId number
---@return number speed
function humanGetSpeed(playerId) end

---@param playerId number
---@param state boolean
function humanLockControls(playerId, state) end

---@param playerId number
---@return table pos
function humanGetCameraPos(playerId) end

---@param playerId number
function humanDie(playerId) end


---@param playerId number
---@param weaponId number
---@param ammoLoaded number
---@param ammoHidden number
---@return boolean success
function inventoryAddWeapon(playerId, weaponId, ammoLoaded, ammoHidden) end

---@param playerId number
---@param weaponId number
---@return boolean success
function inventoryAddWeaponDefault(playerId, weaponId) end

---returns -1 when there's no item in players inventory
---@param playerId number
---@param weaponId number
---@return number slotIndex
function inventoryHasWeapon(playerId, weaponId) end

---@param playerId number
---@param weaponId number
---@return boolean success
function inventoryRemoveWeapon(playerId, weaponId) end

---@param playerId number
---@param forced boolean
---@return boolean success
function inventoryDropWeapon(playerId, forced) end

---clears invenotry
---@param playerId number
function inventoryTruncateWeapons(playerId) end

---@param playerId number
---@param weaponId number
---@return boolean success
function inventorySwitchWeapon(playerId, weaponId) end

---@param playerId number
---@param weaponId number
---@return boolean success
function inventoryReloadWeapon(playerId, weaponId) end

---@param playerId number
---@param weaponId number
---@return boolean success
function inventoryReloadWeapon(playerId, weaponId) end

---@param playerId number
---@return boolean success
function inventoryHolsterWeapon(playerId) end

---@param playerId number
---@return table itemsInfos table of {weaponId, ammoLoaded, ammoHidden} tables
function inventoryGetItems(playerId) end

---@param playerId number
---@return table info weaponId, ammoLoaded, ammoHidden
function inventoryGetCurrentItem(playerId) end


---@param weaponId number
---@param pos table
---@param respawnTime number
---@param ammoLoaded number
---@param ammoHidden number
---@return number pickupId
function weaponDropCreate(weaponId, pos, respawnTime, ammoLoaded, ammoHidden) end

---@param weaponId number
---@param pos table
---@param respawnTime number
---@return number pickupId
function weaponDropCreateDefault(weaponId, pos, respawnTime) end


---@param pos table
---@param modelName string
---@return number pickupId
function pickupCreate(pos, modelName) end

---@param pickupId number
---@param radius number
function pickupSetRadius(pickupId, radius) end

---@param pickupId number
function pickupDestroy(pickupId) end

---@param pickupId number
---@param pos table
function pickupSetPos(pickupId, pos) end

---@param pickupId number
---@return table pos
function pickupGetPos(pickupId) end

---@param pickupId number
---@param playerId number
---@param offsetPos table
function pickupAttachTo(pickupId, playerId, offsetPos) end

---@param pickupId number
function pickupDetach(pickupId) end


---@param playerId number
---@param pos table
---@param rot table
function cameraLookAt(playerId, pos, rot) end

---@param playerId number
---@param posStart table
---@param rotStart table
---@param posEnd table
---@param rotEnd table
---@param duration number
function cameraInterpolate(playerId, posStart, rotStart, posEnd, rotEnd, duration) end

---@param playerId number
---@param followPlayerId number
function cameraFollow(playerId, followPlayerId) end


---@param playerId number
---@param name string
---@param pos table
---@param range number
---@param volume number
---@param repeatSound boolean
function playSound(playerId, name, pos, range, volume, repeatSound) end

---@param name string
---@param pos table
---@param range number
---@param volume number
---@param repeatSound boolean
function playSoundForAll(name, pos, range, volume, repeatSound) end


---@param pos table
---@param force number
---@param radius number
function createExplosion(pos, force, radius) end


---@param playerId number
---@param text string
---@param color number
function hudAddMessage(playerId, text, color) end

---@param playerId number
---@param text string
---@param timeToShow number
function hudAnnounce(playerId, text, timeToShow) end

---@param playerId number
---@param fadeIn boolean
---@param time number
---@param color number
function hudFade(playerId, fadeIn, time, color) end

---@param playerId number
---@param state boolean
function hudEnableMap(playerId, state) end


---@return number currentTimeInMilliseconds
function getTime() end