--   (
-- c|_|
-- $$\      $$\                    $$\                       
-- $$$\    $$$ |                   $$ |                      
-- $$$$\  $$$$ |$$$$$$\  $$$$$$$\$$$$$$\   $$$$$$\  $$$$$$\  
-- $$\$$\$$ $$ |\____$$\$$  _____\_$$  _| $$  __$$\$$  __$$\ 
-- $$ \$$$  $$ |$$$$$$$ \$$$$$$\   $$ |   $$$$$$$$ $$ |  \__|
-- $$ |\$  /$$ $$  __$$ |\____$$\  $$ |$$\$$   ____$$ |      
-- $$ | \_/ $$ \$$$$$$$ $$$$$$$  | \$$$$  \$$$$$$$\$$ |      
-- \__|     \__|\_______\_______/   \____/ \_______\__|      
--  $$$$$$\            $$\    $$\                            
-- $$  __$$\           $$ |   \__|                           
-- $$ /  $$ |$$$$$$$\$$$$$$\  $$\ $$$$$$\ $$$$$$$\  $$$$$$$\ 
-- $$$$$$$$ $$  _____\_$$  _| $$ $$  __$$\$$  __$$\$$  _____|
-- $$  __$$ $$ /       $$ |   $$ $$ /  $$ $$ |  $$ \$$$$$$\  
-- $$ |  $$ $$ |       $$ |$$\$$ $$ |  $$ $$ |  $$ |\____$$\ 
-- $$ |  $$ \$$$$$$$\  \$$$$  $$ \$$$$$$  $$ |  $$ $$$$$$$  |
-- \__|  \__|\_______|  \____/\__|\______/\__|  \__\_______/ 

util.require_natives("3095a")
require("lib/MasterActions/translations")

data = require("lib/MasterActions/data_management")
local ui = require("lib/MasterActions/user_interface")

data.LoadSettings()
data.LoadAllActions()
TranslationUtils.SetupLanguage(data.settings.language)

local running_actions = {
    is_running_any_animation = false,
    is_any_prop_spawned = false,
    is_any_effect_spawned = false,
    is_playing_any_sound = false,

    animations = {},
    props = {},
    effects = {},
    sounds = {}
}

local function play_animation(dict, anim, blendin, blendout, duration, flag, playback, ped, delay)
    STREAMING.REQUEST_ANIM_DICT(dict)
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        util.yield()
    end

    if delay then
        util.yield(delay)
    end

    TASK.TASK_PLAY_ANIM(ped, dict, anim, blendin, blendout, duration, flag, playback, false, false, false)
    PED.SET_PED_CONFIG_FLAG(ped, 179, true)
end

local function spawn_prop(hash, coords, delay)
    if not STREAMING.IS_MODEL_VALID(hash) then return end
    local request_time = os.time()
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end

    if delay then
        util.yield(delay)
    end

    local obj = entities.create_object(hash, {x = coords.posX, y = coords.posY, z = coords.posZ})
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
    return obj
end

local function spawn_attached_prop(hash, coords, ped, boneID, delay)
    if not STREAMING.IS_MODEL_VALID(hash) then return end
    local request_time = os.time()
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end

    if delay then
        util.yield(delay)
    end

    local entityCoord = ENTITY.GET_ENTITY_COORDS(ped)
    local obj = entities.create_object(hash, entityCoord)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(obj, ped, PED.GET_PED_BONE_INDEX(ped, boneID), coords.posX, coords.posY, coords.posZ, coords.rotX, coords.rotY, coords.rotZ, true, true, false, true, 1, true, 1, 1, 1)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
    return obj
end

local function play_sound_in_entity(soundName, soundSet, target, delay)
    if delay then
        util.yield(delay)
    end

    local sound_id = AUDIO.GET_SOUND_ID()
    AUDIO.PLAY_SOUND_FROM_ENTITY(sound_id, soundName, target, soundSet, true, 0)
    return sound_id
end

local function play_pfx_in_coords(effectAsset, pfxName, delay, x, y, z, rotX, rotY, rotZ, scale)
    STREAMING.REQUEST_NAMED_PTFX_ASSET(effectAsset)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effectAsset) do
        util.yield()
    end
    if delay then
        util.yield(delay)
    end

    GRAPHICS.USE_PARTICLE_FX_ASSET(effectAsset)
    return GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(pfxName, x, y, z, rotX, rotY, rotZ, scale, 1065353216, 1065353216, 1065353216, 0)
end

local function play_pfx_in_entity(effectAsset, effectName, delay, entity, x, y, z, rotX, rotY, rotZ, scale)
    STREAMING.REQUEST_NAMED_PTFX_ASSET(effectAsset)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effectAsset) do
        util.yield()
    end
    if delay then
        util.yield(delay)
    end

    GRAPHICS.USE_PARTICLE_FX_ASSET(effectAsset)
    return GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY(effectName, entity, x, y, z, rotX, rotY, rotZ, scale, 1065353216, 1065353216, 1065353216, 0)
end

local function play_pfx_in_bone(effectAsset, effectName, delay, ped, boneID, x, y, z, rotX, rotY, rotZ, scale)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effectAsset) do
        STREAMING.REQUEST_NAMED_PTFX_ASSET(effectAsset)
        util.yield()
    end
    if delay then
        util.yield(delay)
    end
    GRAPHICS.USE_PARTICLE_FX_ASSET(effectAsset)

    return GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(effectName, ped, x, y, z, rotX, rotY, rotZ, PED.GET_PED_BONE_INDEX(ped, boneID), scale, 1065353216, 1065353216, 1065353216, 0, 0, 0, 0)
end


local function remove_all_attached_objects(ped)
    local function request_control_of_ent(entity)
        local tick = 0
        local tries = 0
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and tick <= 1000 do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
            tick = tick + 1
            tries = tries + 1
            if tries == 50 then 
                util.yield()
                tries = 0
            end
        end
        return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
    end

    local function get_all_objects()
        local out = {}
            for key, value in pairs(entities.get_all_objects_as_handles()) do
                out[#out+1] = value
            end
            for key, value in pairs(entities.get_all_objects_as_handles()) do
                out[#out+1] = value
            end
            for key, value in pairs(entities.get_all_objects_as_handles()) do
                out[#out+1] = value
            end
            for key, value in pairs(entities.get_all_objects_as_handles()) do
                out[#out+1] = value
            end
        return out
    end

    local function remove_objects_from_player(ped)
        if ped then
            for key, value in pairs(get_all_objects()) do
                if ped == ENTITY.GET_ENTITY_ATTACHED_TO(value) then
                    if WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(ped, 0) ~= value then
                    request_control_of_ent(value)
                    local hash = ENTITY.GET_ENTITY_MODEL(value)
                    ENTITY.DETACH_ENTITY(value, true,false)
                    ENTITY.SET_ENTITY_COORDS(value,0,0,0,true,false,false,true)
                    end
                end
            end
        end
    end

    remove_objects_from_player(ped)
end

local function cleanup(force_stop)
    local cleaned_animations = 0
    local cleaned_props = 0
    local cleaned_effects = 0
    local cleaned_sounds = 0
    
    --if force_stop then
        --remove_all_attached_objects(PLAYER.PLAYER_PED_ID())
    --end
    
    -- Clear Animations
    if running_actions.is_running_any_animation then
        if force_stop then
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
        else
            TASK.CLEAR_PED_TASKS(PLAYER.PLAYER_PED_ID())
            TASK.CLEAR_PED_SECONDARY_TASK(PLAYER.PLAYER_PED_ID())
        end
        
        for i = #running_actions.animations, 1, -1 do
            local data = running_actions.animations[i]
            STREAMING.REMOVE_ANIM_DICT(data.dict)

            table.remove(running_actions.animations, i)
            cleaned_animations = cleaned_animations + 1
        end
    end
    running_actions.is_running_any_animation = false

    -- Clear Props
    if running_actions.is_any_prop_spawned then
        for i = #running_actions.props, 1, -1 do
            local data = running_actions.props[i]
            if force_stop or (not data.require_force_stop) then
                if ENTITY.DOES_ENTITY_EXIST(data.spawned_prop) then
                    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(data.spawned_prop) then
                        NETWORK.REQUEST_CONTROL_OF_ENTITY(data.spawned_prop)
                        local timeout = util.current_time_millis() + 5000 -- tempo limite de 5 segundos
                        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(data.spawned_prop) do
                            util.yield()
                            if util.current_time_millis() > timeout then
                                break
                            end
                        end
                    end
                    
                    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(data.spawned_prop) then
                        entities.delete_by_handle(data.spawned_prop)
                    else
                        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(data.spawned_prop)
                        util.yield(100)
                        entities.delete_by_handle(data.spawned_prop)
                    end
                end
                
                table.remove(running_actions.props, i)
                cleaned_props = cleaned_props + 1
            end
        end
    end
    if #running_actions.props == 0 then
        running_actions.is_any_prop_spawned = false
    end

    -- Clear Effects
    if(running_actions.is_any_effect_spawned) then
        for i = #running_actions.effects, 1, -1 do
            local data = running_actions.effects[i]
            if force_stop or (not data.require_force_stop) then
                STREAMING.REMOVE_NAMED_PTFX_ASSET(data.effect_asset)
                if data.loopedFX then
                    GRAPHICS.STOP_PARTICLE_FX_LOOPED(data.loopedFX)
                end
                
                table.remove(running_actions.effects, i)
                cleaned_effects = cleaned_effects + 1
            end
        end
    end
    if #running_actions.effects == 0 then
        running_actions.is_any_effect_spawned = false
    end

    -- Clear Sounds
    if(running_actions.is_playing_any_sound) then
        for i = #running_actions.sounds, 1, -1 do
            local data = running_actions.sounds[i]
            if force_stop or (not data.require_force_stop) then
                AUDIO.STOP_SOUND(data.soundId)
                AUDIO.RELEASE_SOUND_ID(data.soundId)
                
                table.remove(running_actions.sounds, i)
                cleaned_sounds = cleaned_sounds + 1
            end
        end
    end
    if #running_actions.sounds == 0 then
        running_actions.is_playing_any_sound = false
    end

    if data.settings.dev_mode then
        util.toast("Cleanup \n" .. cleaned_animations .. " Animations\n" .. cleaned_props .. " Props\n" .. cleaned_effects .. " Effects\n" .. cleaned_sounds .. " Sounds")
    end
end

local function start_action(action)
    local player_ped = PLAYER.PLAYER_PED_ID()

    if not action.additive then
        cleanup()
    end

    if action.animations then
        running_actions.is_running_any_animation = true
        for _, anim_data in ipairs(action.animations) do
            --play_animation(animData.dict, animData.anim, player_ped, animData.flag, animData.delay)
            play_animation(anim_data.dict, anim_data.anim, anim_data.blendin, anim_data.blendout, anim_data.duration, anim_data.flag, anim_data.playback, player_ped, anim_data.delay)
            table.insert(running_actions.animations, {dict = anim_data.dict, anim = anim_data.anim, flag = anim_data.flag})
        end
    end

    if action.props then
        running_actions.is_any_prop_spawned = true
        for _, prop_data in ipairs(action.props) do
            if prop_data.attached then
                local obj = spawn_attached_prop(prop_data.prop, {posX = prop_data.posX, posY = prop_data.posY, posZ = prop_data.posZ, rotX = prop_data.rotX, rotY = prop_data.rotY, rotZ = prop_data.rotZ}, player_ped, prop_data.boneID, prop_data.delay)
                util.toast(prop_data.require_force_stop)
                table.insert(running_actions.props, {require_force_stop = prop_data.require_force_stop, spawned_prop = obj})
            else
                local position = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                local obj = spawn_prop(prop_data.prop, {posX = prop_data.posX + position.x, posY = prop_data.posY + position.y, posZ = prop_data.posZ + position.z, rotX = prop_data.rotX, rotY = prop_data.rotY, rotZ = prop_data.rotZ}, prop_data.delay)
                table.insert(running_actions.props, {require_force_stop = prop_data.require_force_stop, spawned_prop = obj, is_attached = true})
            end
        end
    end

    if action.effects then
        running_actions.is_any_effect_spawned = true
        for _, effect_data in ipairs(action.effects) do
            if effect_data.attached then
                local effect = play_pfx_in_bone(effect_data.effect_asset, effect_data.effect_name, effect_data.delay, player_ped, effect_data.boneID, effect_data.posX or 0.0, effect_data.posY or 0.0, effect_data.posZ or 0.0, effect_data.rotX or 0.0, effect_data.rotY or 0.0, effect_data.rotZ or 0.0, effect_data.scale or 1.0)
                table.insert(running_actions.effects, {require_force_stop = effect_data.require_force_stop, loopedFX = effect, effect_asset = effect_data.effect_asset})
            elseif effect_data.attachedToProp and running_actions.is_any_prop_spawned then
                local prop = running_actions.props[#running_actions.props].spawnedProp
                local effect = play_pfx_in_entity(effect_data.effect_asset, effect_data.effect_name, effect_data.delay, prop, effect_data.posX or 0.0, effect_data.posY or 0.0, effect_data.posZ or 0.0, effect_data.rotX or 0.0, effect_data.rotY or 0.0, effect_data.rotZ or 0.0, effect_data.scale or 1.0)
                table.insert(running_actions.effects, {require_force_stop = effect_data.require_force_stop, loopedFX = effect, effect_asset = effect_data.effect_asset})
            else
                local coords = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true)
                local effect = play_pfx_in_coords(effect_data.effect_asset, effect_data.effect_name, effect_data.delay, effect_data.posX + coords.x, effect_data.posY + coords.y, effect_data.posZ + coords.z, effect_data.rotX or 0.0, effect_data.rotY or 0.0, effect_data.rotZ or 0.0, effect_data.scale or 1.0)
                table.insert(running_actions.effects, {require_force_stop = effect_data.require_force_stop, pfxHandle = effect, effect_asset = effect_data.effect_asset})
            end
        end
    end

    if action.sounds then
        running_actions.is_playing_any_sound = true
        for _, sound_data in ipairs(action.sounds) do
            local soundId = play_sound_in_entity(sound_data.sound_name, sound_data.sound_set, player_ped, sound_data.delay)
            table.insert(running_actions.sounds, {require_force_stop = sound_data.require_force_stop, soundId = soundId, })
        end
    end
end

util.on_pre_stop(function()
    cleanup(true)
end)

ui.create_interface(start_action, cleanup)