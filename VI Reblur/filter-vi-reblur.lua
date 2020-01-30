--By Jademalo, using code by DarkLink (https://obsproject.com/forum/resources/darklinks-script-pack.655/)

obs = obslua
bit = require("bit")

SETTING_OFFSET = 'offset' -- This is the name of the variable in the .effect file

TEXT_OFFSET = 'Offset Fix'


source_def = {}
source_def.id = 'filter-vi-reblur'
source_def.type = obs.OBS_SOURCE_TYPE_FILTER
source_def.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO)

source_def.get_name = function()
    return "VI Reblur"
end

function script_description()
	return "Adds a filter to blur with a single pixel offset to imitate the \"VI Blur\" from N64. \n\nBy Jademalo"
end



function reload_filter(filter)
    local effect_path = script_path() .. 'filter-vi-reblur/vi-reblur.effect'
    obs.obs_enter_graphics()

    if filter.effect ~= nil then
        print('destroying filter ' .. tostring(filter.effect))
        obs.gs_effect_destroy(filter.effect)
    end

    filter.effect = obs.gs_effect_create_from_file(effect_path, nil) --This creates a new effect from the separate effect file

    if filter.effect ~= nil then
        filter.params.offset = obs.gs_effect_get_param_by_name(filter.effect, SETTING_OFFSET) --This sets up the filter.params.offset object as a filter.effect object with a specific name
        filter.params.width = obs.gs_effect_get_param_by_name(filter.effect, 'width')
    end

    obs.obs_leave_graphics()
end





source_def.update = function(filter, settings)
    filter.offset = obs.obs_data_get_bool(settings, SETTING_OFFSET) --This is getting the value from the dropdown box and setting filter.offset to that value

    reload_filter(filter)
end




source_def.destroy = function(filter)
    if filter.effect ~= nil then
        obs.obs_enter_graphics()
        obs.gs_effect_destroy(filter.effect)
        obs.obs_leave_graphics()
    end
end

source_def.create = function(settings, source)
    filter = {}
    filter.params = {}
    filter.context = source
    filter.width = 0
    filter.height = 0

    source_def.update(filter, settings)
    return filter
end

source_def.get_width = function(filter)
    return filter.width
end

source_def.get_height = function(filter)
    return filter.height
end

source_def.video_render = function(filter, effect)
    local effect = filter.effect

    if effect ~= nil then
        obs.obs_source_process_filter_begin(filter.context, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)
        obs.gs_effect_set_bool(filter.params.offset, filter.offset) --This sets the parameter in the effect file with the value of filter.offset
        obs.gs_effect_set_int(filter.params.width, filter.width)
        obs.obs_source_process_filter_end(filter.context, effect, filter.width, filter.height)
    end
end

source_def.get_properties = function(filter)
    props = obs.obs_properties_create()

    p = obs.obs_properties_add_bool(props, SETTING_OFFSET, TEXT_OFFSET)

    return props
end

source_def.video_tick = function(filter, seconds)
    target = obs.obs_filter_get_target(filter.context)

    local width, height
    if target == nil then
        width = 0
        height = 0
    else
        width = obs.obs_source_get_base_width(target)
        height = obs.obs_source_get_base_height(target)
    end

    filter.width = width
    filter.height = height
    width = width == 0 and 1 or width
    height = height == 0 and 1 or height
end

obs.obs_register_source(source_def)
