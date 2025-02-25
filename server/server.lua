local userData = {}

local currentPrice = math.random(500, 750)

CreateThread(function()
	while true do
		Wait(60 * 60 * 1000)
		
		local isDecline = math.random() < 0.30
		local change = math.random(1, 10) / 100 * currentPrice

		if isDecline then
			currentPrice = math.max(currentPrice - change, 500)
		else
			currentPrice = math.min(currentPrice + change, 750)
		end
		
		currentPrice = math.floor(currentPrice + 0.5)
	end
end)

function getCurrentPrice()
    return currentPrice
end
exports('getCurrentPrice', getCurrentPrice)

lib.addCommand('cryptoprice', {
    help = 'Gets the price of vCoins manually.',
    restricted = 'group.admin'
}, function(source, args, rawCommand)
	TriggerClientEvent('ox_lib:notify', source, {
		title = 'Price of vCoins',
		description = 'The price of x1 vCoin is: $'..currentPrice,
		duration = 5000,
		type = 'success'
	})
end)

lib.addCommand('cryptoset', {
    help = 'Set the price of vCoins manually.',
    params = {
        { 	name = 'price', 
			help = 'The new price for vCoins', 
			type = 'number'
		}
    },
    restricted = 'group.admin'
}, function(source, args, rawCommand)
    local newPrice = tonumber(args.price)

    if newPrice == nil or newPrice < minPrice or newPrice > maxPrice then
		TriggerClientEvent('ox_lib:notify', source, {
			title = 'Price of vCoins',
			description = "Invalid price. Price must be a number between " .. minPrice .. " and " .. maxPrice,
			duration = 5000,
			type = 'error'
		})
		return
    end

    currentPrice = newPrice
	
	TriggerClientEvent('ox_lib:notify', source, {
		title = 'Price of vCoins',
		description = 'You successfully set the price of vCoins to: $'..currentPrice,
		duration = 5000,
		type = 'success'
	})
end)

local coords = { x = 1275.6416, y = -1710.3468, z = 54.7715, h = 323.4998 }

local tierLvls = {
	[1] = math.random(2, 4),
	[2] = math.random(6, 12),
	[3] = math.random(16, 24),
}

lib.callback.register('hidden-crypto:server:getCoords', function()
	return coords
end)

RegisterNetEvent("hidden-crypto:server:addCryptoStick", function(item, amount, tierLvl, metadata)
    local itemData = metadata
    if tierLvl then
        itemData["tierLvl"] = tonumber(tierLvl)
    end
    exports.ox_inventory:AddItem(source, item, amount, itemData)
end)

RegisterNetEvent("hidden-crypto:server:destroyCryptoSoftware", function()
	TriggerClientEvent('ox_lib:notify', source, {
		title = 'vCoin Vault',
		description = 'Weird, the program like went haywire... maybe a self destruct system?',
		duration = 5000,
		type = 'error'
	})
    exports.ox_inventory:RemoveItem(source, "crypto_usb", 1)
end)

RegisterNetEvent("hidden-crypto:server:redeemCryptoStick", function(tierLvl)
    local src = source
	
	local vCoins = tierLvls[tierLvl]
	
	TriggerClientEvent('ox_lib:notify', source, {
		title = 'Crypto Stick (vCoins)',
		description = 'You successfully redeemed x'..vCoins..' vCoins from x1 Crypto Stick! (Tier Level: '..tierLvl..')',
		duration = 5000,
		type = 'success'
	})
	exports['rahe-boosting']:givePlayerCrypto(source, vCoins)
end)

-- UI --
lib.callback.register('hidden-crypto:server:getBankBalance', function()
	local src = source
	local Player = exports.qbx_core:GetPlayer(src)
	return Player.PlayerData.money["bank"]
end)

lib.callback.register('hidden-crypto:server:getCurrentPrice', function()
	return getCurrentPrice()
end)

lib.callback.register('hidden-crypto:server:getUserData', function()
	local src = source
	
	local Player = exports.qbx_core:GetPlayer(src)
	local citizenId = Player.PlayerData.citizenid
	
	return userData[citizenId]
end)

RegisterNetEvent('hidden-crypto:server:updateData', function(data)
	local src = source

	local Player = exports.qbx_core:GetPlayer(src)
	local citizenId = Player.PlayerData.citizenid

	userData[citizenId] = { 
		error = data.error,
		success = data.success,
		username = data.username,
		balance = GetCryptoBalance(Player.PlayerData.citizenid),
		bankBalance = Player.PlayerData.money["bank"], 
		cryptoValue = currentPrice
	}
	TriggerClientEvent('hidden-crypto:client:updateData', src, userData)
end)

RegisterNetEvent('hidden-crypto:server:register', function(data)
	local src = source
	
	local Player = exports.qbx_core:GetPlayer(src)
	local citizenId = Player.PlayerData.citizenid
	
	local hasAccount = exports.oxmysql:scalarSync('SELECT citizenId FROM crypto_users WHERE citizenId = ?', {citizenId})
	
	if hasAccount then
		exports.oxmysql:scalarSync('DELETE FROM crypto_users WHERE citizenId = ?', {citizenId})
	end
	
	local doesUserExist = exports.oxmysql:scalarSync('SELECT COUNT(*) AS count FROM crypto_users WHERE username = ?', {data.username})
	
	if doesUserExist >= 1 then
		userData[citizenId] = {
			error = "Username taken",
			success = false,
			username = nil,
			balance = nil,
			bankBalance = nil,
			cryptoValue = nil,
		}
		return
	end

	MySQL.Async.execute('INSERT INTO crypto_users (citizenid, username, password) VALUES (@citizenid, @username, @password)', {
        ['@username'] = data.username,
        ['@password'] = data.password,
        ['@citizenid'] = citizenId
    }, function(rowsChanged)
        if rowsChanged > 0 then
            MySQL.Async.fetchAll('SELECT * FROM crypto_users WHERE username = @username', {
                ['@username'] = data.username
            }, function(result)
                if result[1] then
                    userData[citizenId] = {
						error = "None",
						success = true,
                        username = result[1].username,
                        balance = GetCryptoBalance(citizenId),
                        bankBalance = Player.PlayerData.money["bank"],
                        cryptoValue = getCurrentPrice()
                    }
                else
					userData[citizenId] = {
						error = "None",
						success = false,
                        username = nil,
                        balance = nil,
                        bankBalance = nil,
                        cryptoValue = nil,
                    }
                end
            end)
        else
			userData[citizenId] = {
				error = "None",
				success = false,
				username = nil,
				balance = nil,
				bankBalance = nil,
				cryptoValue = nil,
			}
        end
    end)
	TriggerClientEvent('hidden-crypto:client:updateData', src, userData)
end)

RegisterNetEvent('hidden-crypto:server:login', function(data)
	local src = source
	local Player = exports.qbx_core:GetPlayer(src)
	
	local username = data.username
    local password = data.password
	
    local citizenId = Player.PlayerData.citizenid
	
	local loginResponse = MySQL.query.await('SELECT * FROM crypto_users WHERE citizenid = ? AND username = ? AND password = ?', {citizenId, username, password})

	if loginResponse ~= nil and #loginResponse > 0 then
		userData[citizenId] = {
			error = "None",
			success = true,
			username = username,
			balance = GetCryptoBalance(citizenId),
			bankBalance = Player.PlayerData.money["bank"], 
			cryptoValue = getCurrentPrice()
		}
	else
		userData[citizenId] = {
			error = "None",
			success = false,
			username = nil,
			balance = nil,
			bankBalance = nil,
			cryptoValue = nil,
		}
	end
	TriggerClientEvent('hidden-crypto:client:updateData', src, userData)
end)

RegisterNetEvent('hidden-crypto:server:sell', function(data)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    local citizenId = Player.PlayerData.citizenid
    local amount = tonumber(data.amount)

    local vCoinBalance = GetCryptoBalance(citizenId)
    local response = {}

    if vCoinBalance >= amount then
        local vCoins = vCoinBalance - amount
        local profit = amount * currentPrice

        exports.oxmysql:update('UPDATE ra_boosting_user_settings SET crypto = ? WHERE player_identifier = ?', {vCoins, Player.PlayerData.citizenid})
        Player.Functions.AddMoney("bank", profit)

        userData[citizenId] = {
            error = "None",
            success = true,
            username = username,
            balance = GetCryptoBalance(citizenId),
            bankBalance = Player.PlayerData.money["bank"],
            cryptoValue = getCurrentPrice()
        }
        response = userData[citizenId]
    else
        userData[citizenId] = {
            error = "None",
            success = false,
            username = nil,
            balance = nil,
            bankBalance = nil,
            cryptoValue = nil,
        }
        response = userData[citizenId]
    end
    TriggerClientEvent('hidden-crypto:client:updateData', src, userData, citizenId)
    TriggerClientEvent('hidden-crypto:client:sellResponse', src, response)
end)

function GetCryptoBalance(citizenId)
	local vCoins = exports.oxmysql:scalarSync('SELECT crypto FROM ra_boosting_user_settings WHERE player_identifier = ?', {citizenId})
    return vCoins
end

lib.callback.register('hidden-crypto:server:getCryptoBalance', function(source)
	local src = source
	local Player = exports.qbx_core:GetPlayer(src)
    local citizenId = Player.PlayerData.citizenid
	return GetCryptoBalance(citizenId)
end)