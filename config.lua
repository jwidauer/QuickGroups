local addon_name, addon = ...
local config = addon.new_module("config")

local config_category
local config_category_initialized = false

config.AutofillModes = {ROUND = 1, STATIC = 2}

local CONFIG_DEFAULTS = {
    autofill_ilvl = true,
    autofill_ilvl_mode = config.AutofillModes.ROUND,
    autofill_ilvl_nr = 10
}

local function on_autofill_ilvl_mode_clicked(name, checked)
    for _, button_frame in pairs(autofill_ilvl_mode.button_frames) do
        button_frame.checkbox:SetChecked(false)
    end

    local this = autofill_ilvl_mode.button_frames[name]
    this.checkbox:SetChecked(true)

    if name == "round_to_10" then
        addon.set_config_value("autofill_ilvl_mode", config.AutofillModes.ROUND)
        addon.set_config_value("autofill_ilvl_nr", 10)
    end

    if name == "round_to_5" then
        addon.set_config_value("autofill_ilvl_mode", config.AutofillModes.ROUND)
        addon.set_config_value("autofill_ilvl_nr", 5)
    end

    if name == "static" then
        addon.set_config_value("autofill_ilvl_mode", config.AutofillModes.STATIC)
        addon.set_config_value("autofill_ilvl_nr",
                               tonumber(this.textbox:GetText()))
    end
end

local function on_autofill_ilvl_checkbox_click(name, checked)
    addon.set_config_value(name, checked)

    for _, v in pairs(autofill_ilvl_mode.button_frames) do
        if checked then
            v.checkbox:Enable()
            v.checkbox.Text:SetTextColor(1,1,1)
        else
            v.checkbox:Disable()
            v.checkbox.Text:SetTextColor(.5,.5,.5)
        end

    end
end

local function on_config_default() QuickGroupsConfig = CONFIG_DEFAULTS end

local function on_config_refresh(self)
    if config_category_initialized then return end
    config_category_initialized = true

    -- Create category header
    local name_frame = self:CreateFontString(nil, "OVERLAY",
                                             "GameFontNormalLarge")
    local font_path, _, font_flags = name_frame:GetFont()
    name_frame:SetFont(font_path, 16, font_flags)
    name_frame:SetPoint("TOPLEFT", 10, -16)
    name_frame:SetText(addon_name)

    local config_gui = addon.get_module("config_gui")

    -- Create autofill ilvl checkbox
    local autofill_ilvl_checkbox = config_gui.create_checkbox("autofill_ilvl",
                                                              "Autofill ilvl requirement during group creation?",
                                                              addon.c(
                                                                  "autofill_ilvl"),
                                                              on_autofill_ilvl_checkbox_click,
                                                              "Whether to autofill the ilvl requirement information.",
                                                              self)
    autofill_ilvl_checkbox:SetPoint("TOPLEFT", name_frame, "BOTTOMLEFT", 0, -5)

    local autofill_ilvl_mode_frame = CreateFrame("Frame", "autofill_ilvl_mode",
                                                 self)

    autofill_ilvl_mode_frame.button_frames = {}
    local prev_radiobutton = nil
    for _, nr in ipairs({10, 5}) do
        local name = "round_to_" .. nr
        local text = "Round to closest multiple of " .. nr .. "."
        local tooltip = "Round to the closest multiple of " .. nr ..
                            " lower than your current ilvl."
        local is_checked = addon.c("autofill_ilvl_mode") ==
                               config.AutofillModes.ROUND and
                               addon.c("autofill_ilvl_nr") == nr

        local radio_button = config_gui.create_radiobutton(name, text,
                                                           is_checked,
                                                           on_autofill_ilvl_mode_clicked,
                                                           tooltip,
                                                           autofill_ilvl_mode_frame)

        if not prev_radiobutton then
            radio_button:SetPoint("TOPLEFT", autofill_ilvl_mode_frame, "TOPLEFT")
        else
            radio_button:SetPoint("TOPLEFT", prev_radiobutton, "BOTTOMLEFT")
        end

        autofill_ilvl_mode_frame.button_frames[name] = radio_button
        prev_radiobutton = radio_button
    end

    local frame_height = 0
    local frame_width = 0
    for _, frame in pairs(autofill_ilvl_mode_frame.button_frames) do
        frame_width = math.max(frame_width, frame:GetWidth())
        frame_height = frame_height + frame:GetHeight()
    end
    autofill_ilvl_mode_frame:SetWidth(frame_width)
    autofill_ilvl_mode_frame:SetHeight(frame_height)

    autofill_ilvl_mode_frame:SetPoint("TOPLEFT", autofill_ilvl_checkbox,
                                      "BOTTOMLEFT", 20, 0)
end

local function create_options_category()
    config_category = CreateFrame("Frame")
    config_category.name = addon_name
    config_category.default = on_config_default
    config_category.refresh = on_config_refresh

    InterfaceOptions_AddCategory(config_category)
end

local function slash_handler(msg, editbox)
    if not config_category then return end

    InterfaceOptionsFrame_OpenToCategory(config_category)
    InterfaceOptionsFrame_OpenToCategory(config_category)
end

function config:init()
    if QuickGroupsConfig == nil then QuickGroupsConfig = CONFIG_DEFAULTS end

    addon.set_config(QuickGroupsConfig)

    create_options_category()

    -- Set up slash commands
    SLASH_QUICKGROUPS1 = "/qg"
    SLASH_QUICKGROUPS2 = "/quickgroups"
    SlashCmdList["QUICKGROUPS"] = function(msg, editbox)
        slash_handler(msg, editbox)
    end
end
