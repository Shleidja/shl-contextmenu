fx_version 'cerulean'
games { 'gta5' }

author 'Shleidja'
description 'Context Menu for FiveM - Modern and Optimized'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/script.js',
    'web/style.css'
}

client_scripts {
    'client/screen.lua',
    'client/main.lua',

    'client/modules/misc.lua',
    'client/modules/object.lua',
    'client/modules/vehicle.lua',
    'client/modules/player.lua',
    'client/modules/ped.lua'
}