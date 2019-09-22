obs = obslua
bit = require("bit")

SETTING_INVERT = 'invert_709601'

TEXT_INVERT = 'Invert'

source_def = {}
source_def.id = 'filter-601-709'
source_def.type = obs.OBS_SOURCE_TYPE_FILTER
source_def.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO)

function set_render_size(filter)
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
end

source_def.get_name = function()
    return "601->709 Correction"
end

source_def.create = function(settings, source)
    local effect_path = script_path() .. 'filter-601-709/BT.601 to BT.709.effect'

    filter = {}
    filter.params = {}
    filter.context = source

    set_render_size(filter)

    obs.obs_enter_graphics()
    filter.effect = obs.gs_effect_create_from_file(effect_path, nil)
    if filter.effect ~= nil then
        filter.params.invert_709601 = obs.gs_effect_get_param_by_name(filter.effect, 'invert_709601')
    end
    obs.obs_leave_graphics()

    if filter.effect == nil then
        source_def.destroy(filter)
        return nil
    end

    source_def.update(filter, settings)
    return filter
end

source_def.destroy = function(filter)
    if filter.effect ~= nil then
        obs.obs_enter_graphics()
        obs.gs_effect_destroy(filter.effect)
        obs.obs_leave_graphics()
    end
end

source_def.get_width = function(filter)
    return filter.width
end

source_def.get_height = function(filter)
    return filter.height
end

source_def.update = function(filter, settings)
    filter.invert_709601 = obs.obs_data_get_bool(settings, SETTING_INVERT)

    set_render_size(filter)
end

source_def.video_render = function(filter, effect)
    obs.obs_source_process_filter_begin(filter.context, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)

    obs.gs_effect_set_bool(filter.params.invert_709601, filter.invert_709601)

    obs.obs_source_process_filter_end(filter.context, filter.effect, filter.width, filter.height)
end

source_def.get_properties = function(settings)
    props = obs.obs_properties_create()

    obs.obs_properties_add_bool(props, SETTING_INVERT, TEXT_INVERT)

    return props
end

source_def.get_defaults = function(settings)
    obs.obs_data_set_default_bool(settings, SETTING_INVERT, false)
end

source_def.video_tick = function(filter, seconds)
    set_render_size(filter)
end

obs.obs_register_source(source_def)
