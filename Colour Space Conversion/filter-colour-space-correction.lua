obs = obslua
bit = require("bit")

SETTING_INVERT = 'invert'

TEXT_INVERT = 'Invert (709 -> 601)'


source_def = {}
source_def.id = 'filter-colour-space-correction'
source_def.type = obs.OBS_SOURCE_TYPE_FILTER
source_def.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO)

source_def.get_name = function()
    return "Colour Space Correction"
end

function script_description()
	return "Adds a filter to correct 601/709 colour space decoding issues."
end



function reload_filter(filter)
    local effect_path = script_path() .. 'filter-601-709/BT.601 to BT.709.effect'
    obs.obs_enter_graphics()

    if filter.effect ~= nil then
        print('destroying filter ' .. tostring(filter.effect))
        obs.gs_effect_destroy(filter.effect)
    end

    filter.effect = obs.gs_effect_create_from_file(effect_path, nil)

    if filter.effect ~= nil then
        filter.params.pixel_size = obs.gs_effect_get_param_by_name(filter.effect, 'pixel_size')
        filter.params.invert = obs.gs_effect_get_param_by_name(filter.effect, 'invert')
    end

    obs.obs_leave_graphics()
end





source_def.update = function(filter, settings)
    filter.invert = obs.obs_data_get_bool(settings, SETTING_INVERT)

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

    filter.pixel_size = obs.vec2()

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
        obs.gs_effect_set_bool(filter.params.invert, filter.invert)
        obs.obs_source_process_filter_end(filter.context, effect, filter.width, filter.height)
    end
end

source_def.get_properties = function(filter)
    props = obs.obs_properties_create()

    obs.obs_properties_add_bool(props, SETTING_INVERT, TEXT_INVERT)

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
    filter.pixel_size.x = 1.0 / width
    filter.pixel_size.y = 1.0 / height
end

obs.obs_register_source(source_def)
