--[[
════════════════════════════════════════════════════
  Gui.lua  —  WindUI-style ImGui builder (FIXED)
  
  local Gui = require("Gui")
  
  local Win = Gui.New({
      title  = "My Window",
      size   = { 400, 300 },
      theme  = "dark",          -- "dark" | "neon" | "brown" | "light" | nil
      flags  = 0,               -- ImGui.WindowFlags (optional)
      OnRender = function(win)
          win:Text("Hello!")
      end
  })
  
  AddHook("OnDraw", "ui", function()
      Win:Render()
  end)
════════════════════════════════════════════════════
--]]

local Gui = {}

-- ─────────────────────────────────────────────────────────────
-- INTERNAL UTILS
-- ─────────────────────────────────────────────────────────────

local _state = {}   -- global persistent state

local function stateGet(id, key, default)
    if not _state[id] then _state[id] = {} end
    if _state[id][key] == nil then _state[id][key] = default end
    return _state[id][key]
end

local function stateSet(id, key, val)
    if not _state[id] then _state[id] = {} end
    _state[id][key] = val
end

local function uid(win_title, label)
    return win_title .. "::" .. label
end

-- ─────────────────────────────────────────────────────────────
-- THEMES
-- ─────────────────────────────────────────────────────────────

local Themes = {
    dark = {
        colors = {
            [ImGui.Col.WindowBg]       = { 0.10, 0.10, 0.12, 1.0 },
            [ImGui.Col.ChildBg]        = { 0.12, 0.12, 0.15, 1.0 },
            [ImGui.Col.PopupBg]        = { 0.10, 0.10, 0.13, 0.98 },
            [ImGui.Col.TitleBg]        = { 0.12, 0.12, 0.15, 1.0 },
            [ImGui.Col.TitleBgActive]  = { 0.16, 0.16, 0.20, 1.0 },
            [ImGui.Col.FrameBg]        = { 0.14, 0.14, 0.18, 1.0 },
            [ImGui.Col.FrameBgHovered] = { 0.20, 0.20, 0.25, 1.0 },
            [ImGui.Col.FrameBgActive]  = { 0.24, 0.24, 0.30, 1.0 },
            [ImGui.Col.Button]         = { 0.22, 0.22, 0.28, 1.0 },
            [ImGui.Col.ButtonHovered]  = { 0.30, 0.30, 0.38, 1.0 },
            [ImGui.Col.ButtonActive]   = { 0.40, 0.40, 0.50, 1.0 },
            [ImGui.Col.Header]         = { 0.22, 0.22, 0.28, 1.0 },
            [ImGui.Col.HeaderHovered]  = { 0.30, 0.30, 0.38, 1.0 },
            [ImGui.Col.HeaderActive]   = { 0.40, 0.40, 0.50, 1.0 },
            [ImGui.Col.SliderGrab]     = { 0.55, 0.55, 0.65, 1.0 },
            [ImGui.Col.SliderGrabActive] = { 0.70, 0.70, 0.85, 1.0 },
            [ImGui.Col.CheckMark]      = { 0.85, 0.85, 1.00, 1.0 },
            [ImGui.Col.Separator]      = { 0.22, 0.22, 0.28, 1.0 },
            [ImGui.Col.Tab]            = { 0.14, 0.14, 0.18, 1.0 },
            [ImGui.Col.TabHovered]     = { 0.30, 0.30, 0.38, 1.0 },
            [ImGui.Col.TabActive]      = { 0.24, 0.24, 0.32, 1.0 },
        },
        vars = {
            -- Single value StyleVars
            [ImGui.StyleVar.WindowRounding] = 8,
            [ImGui.StyleVar.FrameRounding]  = 5,
            [ImGui.StyleVar.GrabRounding]   = 5,
            [ImGui.StyleVar.TabRounding]    = 4,
            -- Vec2 StyleVars - commented out, adjust based on your binding
            -- [ImGui.StyleVar.WindowPadding]  = {10, 10},
            -- [ImGui.StyleVar.FramePadding]   = {6, 4},
            -- [ImGui.StyleVar.ItemSpacing]    = {8, 6},
        }
    },

    neon = {
        colors = {
            [ImGui.Col.WindowBg]       = { 0.04, 0.04, 0.09, 0.97 },
            [ImGui.Col.ChildBg]        = { 0.05, 0.05, 0.11, 1.0 },
            [ImGui.Col.PopupBg]        = { 0.04, 0.04, 0.09, 0.98 },
            [ImGui.Col.TitleBg]        = { 0.05, 0.05, 0.11, 1.0 },
            [ImGui.Col.TitleBgActive]  = { 0.00, 0.40, 0.70, 1.0 },
            [ImGui.Col.FrameBg]        = { 0.07, 0.07, 0.14, 1.0 },
            [ImGui.Col.FrameBgHovered] = { 0.09, 0.09, 0.20, 1.0 },
            [ImGui.Col.FrameBgActive]  = { 0.11, 0.11, 0.25, 1.0 },
            [ImGui.Col.Button]         = { 0.00, 0.35, 0.65, 1.0 },
            [ImGui.Col.ButtonHovered]  = { 0.00, 0.55, 0.95, 1.0 },
            [ImGui.Col.ButtonActive]   = { 0.00, 0.75, 1.00, 1.0 },
            [ImGui.Col.Header]         = { 0.00, 0.30, 0.55, 1.0 },
            [ImGui.Col.HeaderHovered]  = { 0.00, 0.50, 0.85, 1.0 },
            [ImGui.Col.HeaderActive]   = { 0.00, 0.65, 1.00, 1.0 },
            [ImGui.Col.SliderGrab]     = { 0.00, 0.75, 1.00, 1.0 },
            [ImGui.Col.SliderGrabActive] = { 0.00, 1.00, 0.85, 1.0 },
            [ImGui.Col.CheckMark]      = { 0.00, 1.00, 0.80, 1.0 },
            [ImGui.Col.Separator]      = { 0.00, 0.40, 0.70, 1.0 },
            [ImGui.Col.Tab]            = { 0.05, 0.05, 0.11, 1.0 },
            [ImGui.Col.TabHovered]     = { 0.00, 0.45, 0.80, 1.0 },
            [ImGui.Col.TabActive]      = { 0.00, 0.35, 0.65, 1.0 },
        },
        vars = {
            [ImGui.StyleVar.WindowRounding] = 10,
            [ImGui.StyleVar.FrameRounding]  = 6,
            [ImGui.StyleVar.GrabRounding]   = 6,
            [ImGui.StyleVar.TabRounding]    = 5,
        }
    },

    brown = {
        colors = {
            [ImGui.Col.WindowBg]       = { 0.15, 0.10, 0.07, 1.0 },
            [ImGui.Col.ChildBg]        = { 0.17, 0.12, 0.08, 1.0 },
            [ImGui.Col.PopupBg]        = { 0.15, 0.10, 0.07, 0.98 },
            [ImGui.Col.TitleBg]        = { 0.18, 0.12, 0.08, 1.0 },
            [ImGui.Col.TitleBgActive]  = { 0.45, 0.28, 0.12, 1.0 },
            [ImGui.Col.FrameBg]        = { 0.20, 0.13, 0.09, 1.0 },
            [ImGui.Col.FrameBgHovered] = { 0.28, 0.18, 0.11, 1.0 },
            [ImGui.Col.FrameBgActive]  = { 0.35, 0.22, 0.13, 1.0 },
            [ImGui.Col.Button]         = { 0.38, 0.23, 0.11, 1.0 },
            [ImGui.Col.ButtonHovered]  = { 0.55, 0.33, 0.15, 1.0 },
            [ImGui.Col.ButtonActive]   = { 0.70, 0.42, 0.18, 1.0 },
            [ImGui.Col.Header]         = { 0.35, 0.22, 0.11, 1.0 },
            [ImGui.Col.HeaderHovered]  = { 0.50, 0.30, 0.14, 1.0 },
            [ImGui.Col.HeaderActive]   = { 0.65, 0.40, 0.18, 1.0 },
            [ImGui.Col.SliderGrab]     = { 0.75, 0.50, 0.22, 1.0 },
            [ImGui.Col.SliderGrabActive] = { 0.90, 0.65, 0.30, 1.0 },
            [ImGui.Col.CheckMark]      = { 0.95, 0.75, 0.40, 1.0 },
            [ImGui.Col.Separator]      = { 0.35, 0.22, 0.11, 1.0 },
            [ImGui.Col.Tab]            = { 0.20, 0.13, 0.09, 1.0 },
            [ImGui.Col.TabHovered]     = { 0.45, 0.27, 0.13, 1.0 },
            [ImGui.Col.TabActive]      = { 0.38, 0.23, 0.11, 1.0 },
        },
        vars = {
            [ImGui.StyleVar.WindowRounding] = 6,
            [ImGui.StyleVar.FrameRounding]  = 4,
            [ImGui.StyleVar.GrabRounding]   = 4,
            [ImGui.StyleVar.TabRounding]    = 3,
        }
    },

    light = {
        colors = {
            [ImGui.Col.WindowBg]       = { 0.94, 0.94, 0.96, 1.0 },
            [ImGui.Col.ChildBg]        = { 0.90, 0.90, 0.93, 1.0 },
            [ImGui.Col.PopupBg]        = { 0.98, 0.98, 0.99, 1.0 },
            [ImGui.Col.TitleBg]        = { 0.86, 0.86, 0.90, 1.0 },
            [ImGui.Col.TitleBgActive]  = { 0.60, 0.60, 0.80, 1.0 },
            [ImGui.Col.FrameBg]        = { 0.85, 0.85, 0.88, 1.0 },
            [ImGui.Col.FrameBgHovered] = { 0.78, 0.78, 0.84, 1.0 },
            [ImGui.Col.FrameBgActive]  = { 0.70, 0.70, 0.80, 1.0 },
            [ImGui.Col.Button]         = { 0.75, 0.75, 0.85, 1.0 },
            [ImGui.Col.ButtonHovered]  = { 0.62, 0.62, 0.80, 1.0 },
            [ImGui.Col.ButtonActive]   = { 0.50, 0.50, 0.75, 1.0 },
            [ImGui.Col.Header]         = { 0.75, 0.75, 0.85, 1.0 },
            [ImGui.Col.HeaderHovered]  = { 0.62, 0.62, 0.80, 1.0 },
            [ImGui.Col.CheckMark]      = { 0.25, 0.25, 0.65, 1.0 },
            [ImGui.Col.SliderGrab]     = { 0.45, 0.45, 0.75, 1.0 },
            [ImGui.Col.Separator]      = { 0.75, 0.75, 0.85, 1.0 },
            [ImGui.Col.Text]           = { 0.10, 0.10, 0.15, 1.0 },
            [ImGui.Col.Tab]            = { 0.82, 0.82, 0.87, 1.0 },
            [ImGui.Col.TabHovered]     = { 0.65, 0.65, 0.82, 1.0 },
            [ImGui.Col.TabActive]      = { 0.70, 0.70, 0.90, 1.0 },
        },
        vars = {
            [ImGui.StyleVar.WindowRounding] = 7,
            [ImGui.StyleVar.FrameRounding]  = 4,
            [ImGui.StyleVar.GrabRounding]   = 4,
            [ImGui.StyleVar.TabRounding]    = 4,
        }
    },
}

-- FIXED: applyTheme function - only apply single-value StyleVars
local function applyTheme(theme_name)
    local t = Themes[theme_name]
    if not t then return 0, 0 end
    local nc, nv = 0, 0
    if t.colors then
        for id, c in pairs(t.colors) do
            ImGui.PushStyleColor(id, c[1], c[2], c[3], c[4] or 1.0)
            nc = nc + 1
        end
    end
    if t.vars then
        for id, v in pairs(t.vars) do
            -- Only push single-value StyleVars (float/int)
            -- Vec2 StyleVars are commented out in themes above
            if type(v) == "number" then
                ImGui.PushStyleVar(id, v)
                nv = nv + 1
            end
            -- If you need Vec2 support, check your binding documentation
            -- Some bindings might use: ImGui.PushStyleVar(id, ImVec2(x, y))
        end
    end
    return nc, nv
end

-- ─────────────────────────────────────────────────────────────
-- ELEMENT MIXIN  (methods available on Win, Section, and Group)
-- ─────────────────────────────────────────────────────────────

local Element = {}
Element.__index = Element

-- ── Text

function Element:Text(text, ...)
    if select("#", ...) > 0 then
        ImGui.Text(string.format(text, ...))
    else
        ImGui.Text(tostring(text))
    end
    return self
end

function Element:TextColored(r, g, b, a, text, ...)
    if select("#", ...) > 0 then
        ImGui.TextColored(r, g, b, a, string.format(text, ...))
    else
        ImGui.TextColored(r, g, b, a, tostring(text))
    end
    return self
end

function Element:TextDisabled(text)
    ImGui.TextDisabled(tostring(text))
    return self
end

function Element:TextWrapped(text)
    ImGui.TextWrapped(tostring(text))
    return self
end

function Element:LabelText(label, text)
    ImGui.LabelText(label, tostring(text))
    return self
end

function Element:BulletText(text)
    ImGui.BulletText(tostring(text))
    return self
end

-- ── Buttons

function Element:Button(cfg, callback)
    if type(cfg) == "string" then cfg = { label = cfg } end
    callback = callback or cfg.callback
    local w = cfg.width or cfg.w or 0
    local h = cfg.height or cfg.h or 0
    if ImGui.Button(cfg.label or cfg[1] or "Button", w, h) then
        if callback then callback(self) end
    end
    return self
end

function Element:SmallButton(label, callback)
    if ImGui.SmallButton(label) then
        if callback then callback(self) end
    end
    return self
end

function Element:InvisibleButton(cfg, callback)
    if type(cfg) == "string" then cfg = { id = cfg } end
    callback = callback or cfg.callback
    local w = cfg.width or cfg.w or 100
    local h = cfg.height or cfg.h or 20
    if ImGui.InvisibleButton(cfg.id or cfg.label or "##inv", w, h) then
        if callback then callback(self) end
    end
    return self
end

function Element:ArrowButton(id, dir, callback)
    if ImGui.ArrowButton(id, dir or ImGui.Dir.Right) then
        if callback then callback(self) end
    end
    return self
end

function Element:RadioButton(cfg)
    if type(cfg) == "string" then cfg = { label = cfg, id = cfg } end
    local id  = cfg.id or cfg.label or "radio"
    local sid = uid(self._win, id)
    local val = stateGet(sid, "v", cfg.value or 0)
    local chk = stateGet(sid, "choice", cfg.choice or 0)
    if ImGui.RadioButton(cfg.label or cfg[1] or "Radio", chk == val) then
        stateSet(sid, "choice", val)
        if cfg.callback then cfg.callback(val) end
    end
    return self
end

-- ── Checkbox / Toggle

function Element:Checkbox(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "Checkbox"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or false)
    local changed, new = ImGui.Checkbox(label, val)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

-- ── Input fields

function Element:InputText(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##input"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or "")
    local changed, new = ImGui.InputText(label, val, cfg.flags or 0)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

function Element:InputTextWithHint(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##inputhint"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or "")
    local changed, new = ImGui.InputTextWithHint(label, cfg.hint or "", val, cfg.flags or 0)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

function Element:InputTextMultiline(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##textarea"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or "")
    local w = cfg.width or cfg.w or 0
    local h = cfg.height or cfg.h or 0
    local changed, new = ImGui.InputTextMultiline(label, val, w, h, cfg.flags or 0)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

function Element:InputInt(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##int"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or 0)
    local changed, new = ImGui.InputInt(label, val)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

function Element:InputFloat(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##float"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or 0.0)
    local changed, new = ImGui.InputFloat(label, val)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

-- ── Sliders

function Element:SliderInt(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##sliderint"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or 0)
    local changed, new = ImGui.SliderInt(label, val, cfg.min or 0, cfg.max or 100)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

function Element:SliderFloat(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##sliderfloat"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or 0.0)
    local changed, new = ImGui.SliderFloat(label, val, cfg.min or 0.0, cfg.max or 1.0)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

function Element:SliderAngle(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##angle"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or 0.0)
    local changed, new = ImGui.SliderAngle(label, val, cfg.min or -360, cfg.max or 360)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

-- ── Drag

function Element:DragInt(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##dragint"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or 0)
    local changed, new = ImGui.DragInt(label, val, cfg.speed or 1, cfg.min or 0, cfg.max or 100)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

function Element:DragFloat(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##dragfloat"
    local sid = uid(self._win, label)
    local val = stateGet(sid, "v", cfg.default or 0.0)
    local changed, new = ImGui.DragFloat(label, val, cfg.speed or 0.1, cfg.min or 0.0, cfg.max or 1.0)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

-- ── Color picker

function Element:ColorEdit4(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##color"
    local sid = uid(self._win, label)
    local r = stateGet(sid, "r", cfg.r or 1.0)
    local g = stateGet(sid, "g", cfg.g or 1.0)
    local b = stateGet(sid, "b", cfg.b or 1.0)
    local a = stateGet(sid, "a", cfg.a or 1.0)
    local changed, nr, ng, nb, na = ImGui.ColorEdit4(label, r, g, b, a, cfg.flags or 0)
    if changed then
        stateSet(sid, "r", nr)
        stateSet(sid, "g", ng)
        stateSet(sid, "b", nb)
        stateSet(sid, "a", na)
        if cfg.callback then cfg.callback(nr, ng, nb, na) end
    end
    return self
end

function Element:ColorButton(cfg)
    if type(cfg) == "string" then cfg = { id = cfg } end
    local id = cfg.id or "##colorbtn"
    local r, g, b, a = cfg.r or 1, cfg.g or 1, cfg.b or 1, cfg.a or 1
    local w = cfg.width or cfg.w or 0
    local h = cfg.height or cfg.h or 0
    if ImGui.ColorButton(id, r, g, b, a, cfg.flags or 0, w, h) then
        if cfg.callback then cfg.callback(r, g, b, a) end
    end
    return self
end

-- ── Combo

function Element:Combo(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##combo"
    local sid = uid(self._win, label)
    local idx = stateGet(sid, "v", cfg.default or 0)
    local items = cfg.items or {}
    local preview = (idx >= 0 and idx < #items) and items[idx+1] or ""
    if ImGui.BeginCombo(label, preview, cfg.flags or 0) then
        for i, item in ipairs(items) do
            local selected = (i - 1) == idx
            if ImGui.Selectable(item, selected) then
                stateSet(sid, "v", i - 1)
                if cfg.callback then cfg.callback(i - 1, item) end
            end
            if selected then
                ImGui.SetItemDefaultFocus()
            end
        end
        ImGui.EndCombo()
    end
    return self
end

-- ── List box

function Element:ListBox(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "##list"
    local sid = uid(self._win, label)
    local idx = stateGet(sid, "v", cfg.default or 0)
    local items = cfg.items or {}
    local h = cfg.height or cfg.h or -1
    if ImGui.BeginListBox(label, 0, h) then
        for i, item in ipairs(items) do
            local selected = (i - 1) == idx
            if ImGui.Selectable(item, selected) then
                stateSet(sid, "v", i - 1)
                if cfg.callback then cfg.callback(i - 1, item) end
            end
            if selected then
                ImGui.SetItemDefaultFocus()
            end
        end
        ImGui.EndListBox()
    end
    return self
end

-- ── Tree / Collapsing

function Element:TreeNode(cfg, fn)
    if type(cfg) == "string" then cfg = { label = cfg } end
    fn = fn or cfg.OnRender
    if ImGui.TreeNode(cfg.label or cfg[1] or "Node") then
        if fn then fn(self) end
        ImGui.TreePop()
    end
    return self
end

function Element:CollapsingHeader(cfg, fn)
    if type(cfg) == "string" then cfg = { label = cfg } end
    fn = fn or cfg.OnRender
    if ImGui.CollapsingHeader(cfg.label or cfg[1] or "Header", cfg.flags or 0) then
        if fn then fn(self) end
    end
    return self
end

-- ── Selectable

function Element:Selectable(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "Item"
    local sid = uid(self._win, label)
    local sel = stateGet(sid, "v", cfg.selected or false)
    local changed, new = ImGui.Selectable(label, sel, cfg.flags or 0)
    if changed then
        stateSet(sid, "v", new)
        if cfg.callback then cfg.callback(new) end
    end
    return self
end

-- ── Layout

function Element:SameLine(offset, spacing)
    ImGui.SameLine(offset or 0, spacing or -1)
    return self
end

function Element:NewLine()
    ImGui.NewLine()
    return self
end

function Element:Spacing()
    ImGui.Spacing()
    return self
end

function Element:Dummy(w, h)
    ImGui.Dummy(w or 0, h or 0)
    return self
end

function Element:Separator()
    ImGui.Separator()
    return self
end

function Element:SeparatorText(text)
    ImGui.SeparatorText(text or "")
    return self
end

function Element:Indent(w)
    ImGui.Indent(w or 0)
    return self
end

function Element:Unindent(w)
    ImGui.Unindent(w or 0)
    return self
end

function Element:BeginGroup()
    ImGui.BeginGroup()
    return self
end

function Element:EndGroup()
    ImGui.EndGroup()
    return self
end

-- ── Tab bar

function Element:TabBar(cfg, fn)
    if type(cfg) == "string" then cfg = { id = cfg } end
    fn = fn or cfg.OnRender
    if ImGui.BeginTabBar(cfg.id or "##tabs", cfg.flags or 0) then
        if fn then fn(self) end
        ImGui.EndTabBar()
    end
    return self
end

function Element:TabItem(cfg, fn)
    if type(cfg) == "string" then cfg = { label = cfg } end
    fn = fn or cfg.OnRender
    local open, visible = ImGui.BeginTabItem(cfg.label or cfg[1] or "Tab", cfg.flags or 0)
    if visible then
        if fn then fn(self) end
        ImGui.EndTabItem()
    end
    return self
end

-- ── Table

function Element:Table(cfg)
    if type(cfg) == "string" then cfg = { id = cfg } end
    local cols = cfg.columns or {}
    if ImGui.BeginTable(cfg.id or "##table", #cols, cfg.flags or 0) then
        for _, c in ipairs(cols) do ImGui.TableSetupColumn(c) end
        ImGui.TableHeadersRow()
        if cfg.rows then
            for _, row in ipairs(cfg.rows) do
                ImGui.TableNextRow()
                for ci, cell in ipairs(row) do
                    ImGui.TableSetColumnIndex(ci - 1)
                    ImGui.Text(tostring(cell))
                end
            end
        end
        ImGui.EndTable()
    end
    return self
end

-- ── Child window inside a window

function Element:Child(cfg, fn)
    if type(cfg) == "string" then cfg = { id = cfg } end
    fn = fn or cfg.OnRender
    if ImGui.BeginChild(cfg.id or "##child", cfg.w or 0, cfg.h or 0,
        cfg.border or false, cfg.flags or 0) then
        if fn then fn(self) end
    end
    ImGui.EndChild()
    return self
end

-- ── Popup / Modal

function Element:OpenPopup(name)
    ImGui.OpenPopup(name)
    return self
end

function Element:Modal(name, fn, flags)
    if ImGui.BeginPopupModal(name, flags or 0) then
        if fn then fn(self) end
        ImGui.EndPopup()
    end
    return self
end

-- ── Menu bar

function Element:MenuBar(fn)
    if ImGui.BeginMenuBar() then
        if fn then fn(self) end
        ImGui.EndMenuBar()
    end
    return self
end

function Element:Menu(label, fn)
    if ImGui.BeginMenu(label) then
        if fn then fn(self) end
        ImGui.EndMenu()
    end
    return self
end

function Element:MenuItem(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "Item"
    if ImGui.MenuItem(label, cfg.shortcut or "", cfg.selected or false) then
        if cfg.callback then cfg.callback() end
    end
    return self
end

-- ── State access

function Element:GetValue(id)
    return stateGet(uid(self._win, id), "v", nil)
end

function Element:SetValue(id, val)
    stateSet(uid(self._win, id), "v", val)
    return self
end

function Element:GetColor(id)
    local sid = uid(self._win, id)
    return stateGet(sid,"r",1), stateGet(sid,"g",1),
           stateGet(sid,"b",1), stateGet(sid,"a",1)
end

-- ── Notify (static, rendered by main loop)
local _notifs = {}

function Element:Notify(cfg)
    if type(cfg) == "string" then cfg = { text = cfg } end
    table.insert(_notifs, {
        text    = cfg.text or cfg.title or cfg[1] or "",
        expires = ImGui.GetTime() + (cfg.duration or 3.0),
    })
    return self
end

-- ─────────────────────────────────────────────────────────────
-- WINDOW OBJECT
-- ─────────────────────────────────────────────────────────────

local Window = setmetatable({}, { __index = Element })
Window.__index = Window

function Window:Render()
    -- Set initial size/pos (once)
    if not self._sized then
        self._sized = true
        if self._size then
            ImGui.SetNextWindowSize(self._size[1], self._size[2], ImGui.Cond.FirstUseEver)
        end
        if self._pos then
            ImGui.SetNextWindowPos(self._pos[1], self._pos[2], ImGui.Cond.FirstUseEver)
        end
        if self._alpha then
            ImGui.SetNextWindowBgAlpha(self._alpha)
        end
    end

    if ImGui.Begin(self._title, self._flags or 0) then
        -- Apply theme INSIDE the window
        local nc, nv = 0, 0
        if self._theme then
            nc, nv = applyTheme(self._theme)
        end
        
        -- Render content
        if self._onrender then 
            self._onrender(self) 
        end
        
        -- Pop theme BEFORE End
        if nv > 0 then ImGui.PopStyleVar(nv) end
        if nc > 0 then ImGui.PopStyleColor(nc) end
    end
    ImGui.End()

    -- Notifications overlay
    self:_renderNotifs()
end

function Window:_renderNotifs()
    local now   = ImGui.GetTime()
    local alive = {}
    local any   = false
    for _, n in ipairs(_notifs) do
        if n.expires > now then any = true; break end
    end
    if any then
        ImGui.SetNextWindowPos(10, 10, ImGui.Cond.Always)
        ImGui.SetNextWindowBgAlpha(0.80)
        local f = ImGui.WindowFlags.NoDecoration + ImGui.WindowFlags.NoInputs +
                  ImGui.WindowFlags.AlwaysAutoResize + ImGui.WindowFlags.NoNav +
                  ImGui.WindowFlags.NoMove
        if ImGui.Begin("##_gui_notifs", f) then
            for _, n in ipairs(_notifs) do
                if n.expires > now then
                    local fade = math.min((n.expires - now) * 2, 1.0)
                    ImGui.TextColored(1, 1, 1, fade, n.text)
                    table.insert(alive, n)
                end
            end
        end
        ImGui.End()
    end
    _notifs = alive
end

-- Destroy: stop rendering by clearing OnRender
function Window:Destroy()
    self._onrender = nil
end

-- Change theme at runtime
function Window:SetTheme(name)
    self._theme = name
    return self
end

-- Change title at runtime
function Window:SetTitle(title)
    self._title = title
    return self
end

-- ─────────────────────────────────────────────────────────────
-- Gui.New  —  main entry point
-- ─────────────────────────────────────────────────────────────

--[[
  cfg = {
    title    = "Window Title",
    size     = { w, h },          -- optional
    pos      = { x, y },          -- optional
    alpha    = 0.95,              -- optional bg alpha
    theme    = "dark",            -- "dark"|"neon"|"brown"|"light"|nil
    flags    = 0,                 -- ImGui.WindowFlags
    OnRender = function(win) end, -- called every frame
  }
--]]
function Gui.New(cfg)
    local win = setmetatable({}, Window)
    win._title    = cfg.title or "Window"
    win._size     = cfg.size
    win._pos      = cfg.pos
    win._alpha    = cfg.alpha
    win._theme    = cfg.theme
    win._flags    = cfg.flags or 0
    win._onrender = cfg.OnRender
    win._win      = win._title   -- key for state scoping
    win._sized    = false
    return win
end

-- Expose themes so user can add custom ones
Gui.Themes = Themes

-- Clear all state (or one key)
function Gui.ClearState(id)
    if id then _state[id] = nil else _state = {} end
end

return Gui
