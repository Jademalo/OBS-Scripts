--By Jademalo, using code by DarkLink (https://obsproject.com/forum/resources/darklinks-script-pack.655/)

obs = obslua
bit = require("bit")

SETTING_COL_SPACE = 'col_space'

TEXT_COL_SPACE = 'Colour Space'
TEXT_COL_SPACE_1 = 'No Change'
TEXT_COL_SPACE_2 = 'BT.601 -> BT.709'
TEXT_COL_SPACE_3 = 'BT.709 -> BT.601'
TEXT_COL_SPACE_4 = 'BT.601 -> BT.601'
TEXT_COL_SPACE_5 = 'BT.709 -> BT.709'
TEXT_COL_SPACE_6 = 'XRGB Mini RGB Output Fix'


source_def = {}
source_def.id = 'filter-colour-space-correction'
source_def.type = obs.OBS_SOURCE_TYPE_FILTER
source_def.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO)

source_def.get_name = function()
    return "Colour Space Correction"
end

function script_description()
	return "Adds a filter to correct BT.601/BT.709 colour space decoding issues. \n\nBy Jademalo"
end



function reload_filter(filter)
    local effect_path = script_path() .. 'filter-colour-space-correction/colour-space-correction.effect'
    obs.obs_enter_graphics()

    if filter.effect ~= nil then
        print('destroying filter ' .. tostring(filter.effect))
        obs.gs_effect_destroy(filter.effect)
    end

    filter.effect = obs.gs_effect_create_from_file(effect_path, nil)

    if filter.effect ~= nil then
        filter.params.col_space = obs.gs_effect_get_param_by_name(filter.effect, 'col_space')
    end

    obs.obs_leave_graphics()
end





source_def.update = function(filter, settings)
    filter.col_space = obs.obs_data_get_int(settings, SETTING_COL_SPACE)

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
        obs.gs_effect_set_int(filter.params.col_space, filter.col_space)
        obs.obs_source_process_filter_end(filter.context, effect, filter.width, filter.height)
    end
end

source_def.get_properties = function(filter)
    props = obs.obs_properties_create()

    p = obs.obs_properties_add_list(props, SETTING_COL_SPACE, TEXT_COL_SPACE, obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
--    obs.obs_property_list_add_int(p, TEXT_COL_SPACE_1, 0)
    obs.obs_property_list_add_int(p, TEXT_COL_SPACE_2, 1)
    obs.obs_property_list_add_int(p, TEXT_COL_SPACE_3, 2)
--    obs.obs_property_list_add_int(p, TEXT_COL_SPACE_4, 3)
--    obs.obs_property_list_add_int(p, TEXT_COL_SPACE_5, 4)
    obs.obs_property_list_add_int(p, TEXT_COL_SPACE_6, 1)

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
