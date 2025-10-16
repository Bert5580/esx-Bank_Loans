fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx-Bank_Loans'
description 'Bank Loan System for ESX Legacy (mysql-async)'
author 'Bert + ChatGPT Fix'
version 'Ev1.1.5'

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'locales/en.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

shared_scripts {
    'config.lua',
    'locales/en.lua'
}
