fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Bank Loan System with ESX Legacy Integration'
version 'Ev1.0.6' -- Updated version prefix for ESX

lua54 'yes'

shared_scripts {
    'config.lua' -- Ensures shared config access
}

client_scripts {
    'locales/en.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'es_extended',
    'oxmysql',
    'esx_menu_default' -- ESX equivalent of qb-menu
    --'esx_target' -- ESX equivalent of qb-target for NPC interaction
}
