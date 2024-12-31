--[[
    Script: QBCore RP Utilities
    Author: [XauLT]
    Version: 1.0.0
    Description: RP Interaction Utilities
    
    LICENSE TERMS:
    - This script is the intellectual property of [XauLT]
    - Unauthorized copying, modification, or distribution is strictly prohibited
    - Commercial use requires explicit written permission
    - Violation of these terms will result in legal action
    
    USAGE RESTRICTIONS:
    - Single server license
    - Non-transferable
    - No reselling or redistribution
]]

fx_version 'cerulean'
game 'gta5'

name 'qb-rputils'
version '1.0.0'
description 'RP Interaction Commands'
author 'XauLT'
repository 'https://github.com/xault/qb-rputils'

server_scripts {
    'main.lua'
}

client_scripts {
    'main.lua'
}

dependencies {
    'qb-core',
}

lua54 'yes'

permissions {
    'trigger_server_event',
    'trigger_client_event',
    'connect_endpoint'
}

metadata {
    ['name'] = 'QBCore RP Utils',
    ['version'] = '1.0.0',
    ['description'] = 'RP Commands System',
    ['author'] = 'XauLT',
}
