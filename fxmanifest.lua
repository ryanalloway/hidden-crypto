fx_version 'cerulean'
game 'gta5'

author 'ItsVinnyX'
description 'Reworked Crypto for Hidden Roleplay.'
version '1.0'

ui_page 'web/build/index.html'

client_script "client/**/*"

server_scripts {
	"server/**/*",
	"@oxmysql/lib/MySQL.lua"
}

shared_scripts {
    '@ox_lib/init.lua',
}

files {
  'web/build/index.html',
  'web/build/**/*'
}

lua54 'yes'
