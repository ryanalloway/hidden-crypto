local userData = {}

function SendReactMessage(action, data)
  SendNUIMessage({
    action = action,
    data = data
  })
end

local function toggleNuiFrame(shouldShow)
  SetNuiFocus(shouldShow, shouldShow)
  SendReactMessage('setVisible', shouldShow)
end

RegisterNUICallback('closeUI', function(_, cb)
  toggleNuiFrame(false)
  debugPrint('UI Hidden')
  cb({})
  TriggerServerEvent('hidden-crypto:server:destroyCryptoSoftware')
end)

--toggleNuiFrame(false)

local function cryptoUSB()
  toggleNuiFrame(true)
  debugPrint('Opened UI')
end

RegisterNetEvent('hidden-crypto:client:openCryptoSoftware', function()
	cryptoUSB()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
	toggleNuiFrame(false)
end)

RegisterNetEvent('hidden-crypto:client:updateData', function(data)
    SendReactMessage('updateData', data)
end)

RegisterNUICallback('register', function(data, cb)
	TriggerServerEvent('hidden-crypto:server:register', data)
	
	Wait(150)
	
	local userData = lib.callback('hidden-crypto:server:getUserData')
	TriggerServerEvent('hidden-crypto:server:updateData', data)
	cb({ success = userData.success, error = userData.error, userData = data.userData })
end)

RegisterNUICallback('login', function(data, cb)
	TriggerServerEvent('hidden-crypto:server:login', data)
	
	Wait(150)
	
	local userData = lib.callback('hidden-crypto:server:getUserData')
	TriggerServerEvent('hidden-crypto:server:updateData', userData)
	cb({ success = userData.success, userData = data.userData })
end)

local function awaitServerResponse(eventName, timeout)
    local p = promise.new()

    RegisterNetEvent(eventName, function(response)
        p:resolve(response)
    end)

    return Citizen.Await(p, timeout)
end

RegisterNUICallback('sellCrypto', function(data, cb)
    TriggerServerEvent('hidden-crypto:server:sell', data)

    local response = awaitServerResponse('hidden-crypto:client:sellResponse', 5000)
    if response then
        cb({ success = response.success, userData = { newBalance = response.balance, newBankBalance = response.bankBalance, cryptoValue = response.cryptoValue } })
    else
        cb({ success = false, userData = {} })
    end
end)

RegisterNUICallback('getCurrentPrice', function(data, cb)
	local currentPrice = lib.callback.await('hidden-crypto:server:getCurrentPrice')
    cb({ currentPrice = currentPrice })
end)

RegisterNUICallback('getCryptoBalance', function(data, cb)
	local cryptoBalance = lib.callback.await('hidden-crypto:server:getCryptoBalance')
    cb({ cryptoBalance = cryptoBalance })
end)

RegisterNUICallback('getBankBalance', function(data, cb)
	local bankBalance = lib.callback.await('hidden-crypto:server:getBankBalance')
    cb({ bankBalance = bankBalance })
end)

toggleNuiFrame(true)

exports.ox_inventory:displayMetadata({
    tierLvl = 'Tier Level'
})

exports.ox_target:addModel({
	'prop_dyn_pc',
	'prop_monitor_li',
	'prop_laptop_01a',
	'prop_monitor_01a',
	'prop_monitor_w_large',
	
}, {
	icon = "fa-brands fa-usb",
	name = "insertCryptoUSB",
	label = "Insert USB Device",
	items = {"crypto_usb"},
	onSelect = function()
		cryptoUSB()
	end,
})

local servCoords = lib.callback.await('hidden-crypto:server:getCoords')

local point = lib.points.new({
	coords = vec3(servCoords.x, servCoords.y, servCoords.z),
	distance = 6,
})
 
local marker = lib.marker.new({
	coords = vec3(1275.6504, -1710.3663, 54.7714),
	direction = vec3(1275.6504, -1710.3663, 54.7714),
	width = 0.25,
	height = 0.25,
	color = { r = 255, g = 000, b = 000, a = 255 },
	type = 20,
})

function point:onEnter()
	inRange = true
end
 
function point:onExit()
	inRange = false
end
 
function point:nearby()
	if self.currentDistance < 2.0 then
		if exports.ox_inventory:Search('count', 'cryptostick') > 0 then
			marker:draw()
			if not lib.isTextUIOpen() then
				lib.showTextUI("[ACTION REQUIRED] Use Crypto Stick")
			end
		else
			if lib.isTextUIOpen() then
				lib.hideTextUI()
			end
		end
	else
		if lib.isTextUIOpen() then
			lib.hideTextUI()
		end
	end
end

exports('cryptostick', function(data, slot)
    if inRange then
        exports.ox_inventory:useItem(data, function(data)
            if data then
                TriggerEvent('hidden-crypto:client:startHack', data.metadata.tierLvl)
            end
        end)
    else
        lib.notify({type = 'error', description = 'You cannot use this here!'})
		return false
    end
end)

exports('crypto_usb', function(data, slot)
	lib.notify({type = 'error', description = 'You cannot use this here. Try inserting it into a laptop or a desktop device!'})
	return false
end)

local timers = {
	[1] = math.random(25, 30),
	[2] = math.random(17, 23),
	[3] = math.random(14, 16),
}

RegisterNetEvent('hidden-crypto:client:startHack', function(tierLvl)
	local success = exports.bl_ui:MineSweeper(3, {
		grid = 6,
		duration = 10000, 
		target = 4,
		previewDuration = 1500
	})
	
	if success then -- Success
		TriggerServerEvent('hidden-crypto:server:redeemCryptoStick', tierLvl)
	else
		lib.notify({
			title = 'Crypto Stick (vCoins)',
			description = 'You failed the Crypto Stick hack! (Tier Level: '..tierLvl..')',
			duration = 5000,
			type = 'error'
		})
	end
end)
