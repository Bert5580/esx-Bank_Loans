fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Bert5580'
description 'Bank Loans system for QB-Core with credit scoring, paycheck deductions, and admin tools.'
version 'Qv1.1.1'

dependencies {
    'qb-core'
    -- 'mysql-async' or 'oxmysql' must be running; we include mysql-async lib for compatibility.
}

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua', -- present on most setups; harmless if mysql-async is ensured
    'server.lua'
}
