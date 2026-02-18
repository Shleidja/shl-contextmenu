--[[
    Module: Player
    Menu contextuel pour le joueur local (clic sur soi-même).
    Inclut : animations (scroll & paginated).
]]

local ECM = ContextMenu

-- ============================================================================
-- Animation Data
-- ============================================================================

local anims = {
    { "Carry box",          "anim@heists@box_carry@",                                       "idle"                  },
    { "Load box",           "anim@heists@load_box",                                         "load_box_1"            },
    { "Carry coffee",       "amb@world_human_aa_coffee@base",                               "base"                  },
    { "Place box",          "anim@mp_fireworks",                                            "place_firework_3_box"  },
    { "Pickup drink",       "anim@amb@nightclub@mini@drinking@drinking_shots@ped_c@normal", "pickup"                },
    { "Pickup briefcase",   "missheist_agency2aig_13",                                      "pickup_briefcase"      },
    { "Pickup object",      "pickup_object",                                                "pickup_low"            },
    { "Pickup box",         "anim@heists@load_box",                                         "lift_box"              },
    { "Carry box",          "anim@heists@box_carry@",                                       "idle"                  },
    { "Load box",           "anim@heists@load_box",                                         "load_box_1"            },
    { "Carry coffee",       "amb@world_human_aa_coffee@base",                               "base"                  },
    { "Place box",          "anim@mp_fireworks",                                            "place_firework_3_box"  },
    { "Pickup drink",       "anim@amb@nightclub@mini@drinking@drinking_shots@ped_c@normal", "pickup"                },
    { "Pickup briefcase",   "missheist_agency2aig_13",                                      "pickup_briefcase"      },
    { "Pickup object",      "pickup_object",                                                "pickup_low"            },
    { "Pickup box",         "anim@heists@load_box",                                         "lift_box"              },
    { "Carry box",          "anim@heists@box_carry@",                                       "idle"                  },
    { "Load box",           "anim@heists@load_box",                                         "load_box_1"            },
    { "Carry coffee",       "amb@world_human_aa_coffee@base",                               "base"                  },
    { "Place box",          "anim@mp_fireworks",                                            "place_firework_3_box"  },
    { "Pickup drink",       "anim@amb@nightclub@mini@drinking@drinking_shots@ped_c@normal", "pickup"                },
    { "Pickup briefcase",   "missheist_agency2aig_13",                                      "pickup_briefcase"      },
    { "Pickup object",      "pickup_object",                                                "pickup_low"            },
    { "Pickup box",         "anim@heists@load_box",                                         "lift_box"              },
    { "Carry box",          "anim@heists@box_carry@",                                       "idle"                  },
    { "Load box",           "anim@heists@load_box",                                         "load_box_1"            },
    { "Carry coffee",       "amb@world_human_aa_coffee@base",                               "base"                  },
    { "Place box",          "anim@mp_fireworks",                                            "place_firework_3_box"  },
    { "Pickup drink",       "anim@amb@nightclub@mini@drinking@drinking_shots@ped_c@normal", "pickup"                },
    { "Pickup briefcase",   "missheist_agency2aig_13",                                      "pickup_briefcase"      },
    { "Pickup object",      "pickup_object",                                                "pickup_low"            },
    { "Pickup box",         "anim@heists@load_box",                                         "lift_box"              },
    { "Carry box",          "anim@heists@box_carry@",                                       "idle"                  },
    { "Load box",           "anim@heists@load_box",                                         "load_box_1"            },
    { "Carry coffee",       "amb@world_human_aa_coffee@base",                               "base"                  },
    { "Place box",          "anim@mp_fireworks",                                            "place_firework_3_box"  },
    { "Pickup drink",       "anim@amb@nightclub@mini@drinking@drinking_shots@ped_c@normal", "pickup"                },
    { "Pickup briefcase",   "missheist_agency2aig_13",                                      "pickup_briefcase"      },
    { "Pickup object",      "pickup_object",                                                "pickup_low"            },
    { "Pickup box",         "anim@heists@load_box",                                         "lift_box"              },
    { "Carry box",          "anim@heists@box_carry@",                                       "idle"                  },
    { "Load box",           "anim@heists@load_box",                                         "load_box_1"            },
    { "Carry coffee",       "amb@world_human_aa_coffee@base",                               "base"                  },
    { "Place box",          "anim@mp_fireworks",                                            "place_firework_3_box"  },
    { "Pickup drink",       "anim@amb@nightclub@mini@drinking@drinking_shots@ped_c@normal", "pickup"                },
    { "Pickup briefcase",   "missheist_agency2aig_13",                                      "pickup_briefcase"      },
    { "Pickup object",      "pickup_object",                                                "pickup_low"            },
    { "Pickup box",         "anim@heists@load_box",                                         "lift_box"              },
}

-- ============================================================================
-- Helpers
-- ============================================================================

--- Charge un dictionnaire d'animation de manière synchrone.
local function LoadAnimDictSync(animDict)
    if HasAnimDictLoaded(animDict) then
        return
    end

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(0)
    end
end

--- Joue une animation sur le ped du joueur.
local function PlayAnimOnPlayer(animDict, anim)
    local ped = PlayerPedId()
    LoadAnimDictSync(animDict)
    TaskPlayAnim(ped, animDict, anim, 8.0, 8.0, 5000, 49, 1.0, false, false, false)
    RemoveAnimDict(animDict)
end

-- ============================================================================
-- Context Menu Registration
-- ============================================================================

ECM.Register(function(screenPosition, hitSomething, worldPosition, hitEntity, normalDirection)
    local playerPed = PlayerPedId()
    if hitEntity ~= playerPed then return end

    -- 1. Informations
    local infoMenuId, _ = ECM.AddSubmenu(0, "🧙 Informations")
    
    -- Placeholders pour les données joueur
    ECM.AddTextItem(infoMenuId, "🆔 ID: ~y~1") 
    ECM.AddTextItem(infoMenuId, "📝 Nom: ~b~10 pts pour oragonn svp")
    ECM.AddTextItem(infoMenuId, "💼 Job: ~b~On est en desh")
    
    ECM.AddSeparator(infoMenuId)
    
    local boutiqueItem = ECM.AddItem(infoMenuId, "🛒 Boutique")
    ECM.OnActivate(boutiqueItem, function() 
        print("Ouvrir Boutique") 
    end)

    -- Informations -> Options
    local optionsMenuId, _ = ECM.AddSubmenu(infoMenuId, "⚙️ Options")
    
    local refreshItem = ECM.AddItem(optionsMenuId, "🔄 Rafraîchir le personnage")
    ECM.OnActivate(refreshItem, function() ExecuteCommand("refreshskin") end)

    local cinematicItem = ECM.AddItem(optionsMenuId, "🎥 Mode cinématique")
    ECM.OnActivate(cinematicItem, function() print("Toggle Mode Cinématique") end)

    local freecamItem = ECM.AddItem(optionsMenuId, "📸 Mode vue libre")
    ECM.OnActivate(freecamItem, function() print("Toggle Freecam") end)

    local rockstarEditorItem = ECM.AddItem(optionsMenuId, "🎬 Rockstar Editor")
    ECM.OnActivate(rockstarEditorItem, function() print("Ouvrir Rockstar Editor") end)

    -- 2. Magie
    local magieMenuId, _ = ECM.AddSubmenu(0, "✨ Magie")
    
    local statsItem = ECM.AddItem(magieMenuId, "📖 Statistiques")
    ECM.OnActivate(statsItem, function() print("Ouvrir Statistiques") end)

    local spellsItem = ECM.AddItem(magieMenuId, "🪄 Gestion sortilèges")
    ECM.OnActivate(spellsItem, function() print("Ouvrir Gestion Sortilèges") end)

    local questsItem = ECM.AddItem(magieMenuId, "📜 Gestion quêtes")
    ECM.OnActivate(questsItem, function() print("Ouvrir Gestion Quêtes") end)

    -- 3. Animations
    local animMenuId, _ = ECM.AddSubmenu(0, "🕺 Animations")

    -- Animations -> Perso
    local persoAnimMenuId, _ = ECM.AddScrollSubmenu(animMenuId, "🚶 Perso", 10)
    for i = 1, #anims do
        local item = ECM.AddItem(persoAnimMenuId, anims[i][1])
        ECM.OnActivate(item, function()
            PlayAnimOnPlayer(anims[i][2], anims[i][3])
        end)
    end

    -- Animations -> Partagées
    local sharedAnimMenuId, _ = ECM.AddScrollSubmenu(animMenuId, "👬 Partagées", 10)
    local sharedAnims = {
        { label = "🤝 Check", dict = "mp_ped_interaction", anim = "handshake_guy_a" },
        { label = "🤗 Câlin", dict = "mp_ped_interaction", anim = "kisses_guy_a" }, -- Placeholder
        { label = "💋 Bisou", dict = "mp_ped_interaction", anim = "kisses_guy_a" }, -- Placeholder
        { label = "🤚 Gifle", dict = "mp_ped_interaction", anim = "handshake_guy_a" }, -- Placeholder
        { label = "👊 Coup de poing", dict = "melee@unarmed@streamed_core_fps", anim = "heavy_punch_a" }, 
        { label = "🧐 Examiner au sol", dict = "amb@medic@standing@kneel@base", anim = "base" },
        { label = "❤️ Réanimation", dict = "mini@cpr@char_a@cpr_str", anim = "cpr_pumpchest" },
        { label = "👶 Porter avec douceur", dict = "anim@heists@box_carry@", anim = "idle" }, -- Placeholder
        { label = "🎒 Porter sur le dos", dict = "anim@heists@box_carry@", anim = "idle" }, -- Placeholder
    }
    for _, animData in ipairs(sharedAnims) do
        local item = ECM.AddItem(sharedAnimMenuId, animData.label)
        ECM.OnActivate(item, function()
            print("Animation partagée : " .. animData.label)
            -- Note: Shared animations often require complex synchronization logic not included here.
        end)
    end

    -- 4. Autres options
    local meItem = ECM.AddItem(0, "💬 Me (...)")
    ECM.OnActivate(meItem, function() 
        print("Ouvrir menu Me") 
    end)

    local desItem = ECM.AddItem(0, "🎲 Dés")
    ECM.OnActivate(desItem, function() 
        print("Lancer les dés") 
    end)

    local pmmsItem = ECM.AddItem(0, "📻 PMMS")
    ECM.OnActivate(pmmsItem, function() 
        ExecuteCommand("pmms") 
    end)

end)
