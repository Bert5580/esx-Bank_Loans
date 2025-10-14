fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Bert5580'
description 'Bank Loans system for QB-Core with credit scoring, paycheck deductions, and admin tools.'
version 'Qv1.1.2'

dependencies {
    'qb-core'
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
    '@mysql-async/lib/MySQL.lua', -- fallback compatibility if oxmysql is not present
    'server.lua'
}
