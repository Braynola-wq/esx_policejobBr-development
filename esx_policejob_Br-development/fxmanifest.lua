fx_version 'bodacious'
game 'gta5'

lua54 'yes'

name 'esx_policejob'
description 'Br-development Police Job'

shared_scripts {
	'@es_extended/imports.lua',
	'@es_extended/locale.lua',
	'@ox_lib/init.lua',
	'locales/en.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'config.lua',
	'server/main.lua',
	-- 'server/music.lua',
	'server/evidence.lua',
}

client_scripts {
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/ComboZone.lua',
	'config.lua',
	'client/main.lua',
	'client/evidence.lua',
	-- 'client/music.lua',
	'client/badge.lua',
	'client/tackle.lua',
	'client/transport.lua',
}

dependencies {
	'es_extended',
}

ui_page 'html/index.html'

files {
    'weapon*.meta',
	'html/index.html',
	'html/script.js',
	'html/fingerprint.png',
	'html/vcr-ocd.ttf'
}
  
data_file 'WEAPONINFO_FILE_PATCH' 'weapon*.meta'
  
export "IsPCuffed"
export "RefreshAction"