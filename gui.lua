--[[
════════════════════════════════════════════════════
  Gui.lua  —  WindUI-style ImGui builder
  
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
            [ImGui.StyleVar.WindowRounding] = 8,
            [ImGui.StyleVar.FrameRounding]  = 5,
            [ImGui.StyleVar.GrabRounding]   = 5,
            [ImGui.StyleVar.TabRounding]    = 4,
            [ImGui.StyleVar.WindowPadding]  = {10, 10},
            [ImGui.StyleVar.FramePadding]   = {6, 4},
            [ImGui.StyleVar.ItemSpacing]    = {8, 6},
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
            [ImGui.StyleVar.WindowPadding]  = {12, 12},
            [ImGui.StyleVar.FramePadding]   = {7, 5},
            [ImGui.StyleVar.ItemSpacing]    = {8, 7},
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
            [ImGui.StyleVar.WindowPadding]  = {10, 10},
            [ImGui.StyleVar.FramePadding]   = {6, 4},
            [ImGui.StyleVar.ItemSpacing]    = {8, 6},
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
            [ImGui.StyleVar.WindowPadding]  = {10, 10},
            [ImGui.StyleVar.FramePadding]   = {6, 4},
            [ImGui.StyleVar.ItemSpacing]    = {8, 6},
        }
    },
}

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
            if type(v) == "table" then
                ImGui.PushStyleVar(id, v[1], v[2])
            else
                ImGui.PushStyleVar(id, v)
            end
            nv = nv + 1
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
        ImGui.Text(string.format(tostring(text), ...))
    else
        ImGui.Text(tostring(text))
    end
    return self
end

function Element:TextColored(r, g, b, a, text, ...)
    if select("#", ...) > 0 then
        ImGui.TextColored(r, g, b, a, string.format(tostring(text), ...))
    else
        ImGui.TextColored(r, g, b, a, tostring(text))
    end
    return self
end

function Element:TextDisabled(text) ImGui.TextDisabled(tostring(text)) return self end
function Element:TextWrapped(text)  ImGui.TextWrapped(tostring(text))  return self end
function Element:BulletText(text)   ImGui.BulletText(tostring(text))   return self end
function Element:LabelText(lbl, v)  ImGui.LabelText(lbl, tostring(v))  return self end

-- ── Layout helpers

function Element:Separator(label)
    if label then ImGui.SeparatorText(label) else ImGui.Separator() end
    return self
end

function Element:Spacing(n)
    for _ = 1, (n or 1) do ImGui.Spacing() end
    return self
end

function Element:NewLine(n)
    for _ = 1, (n or 1) do ImGui.NewLine() end
    return self
end

function Element:SameLine(offset, spacing)
    ImGui.SameLine(offset or 0, spacing or -1)
    return self
end

function Element:Dummy(w, h)
    ImGui.Dummy(w or 0, h or 0)
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

function Element:Width(w, fn)
    ImGui.PushItemWidth(w)
    if fn then fn(self) end
    ImGui.PopItemWidth()
    return self
end

function Element:ProgressBar(frac, w, h, overlay)
    ImGui.ProgressBar(frac, w or -1, h or 0, overlay or "")
    return self
end

-- ── Button

function Element:Button(cfg)
    -- cfg: string | { label, w, h, color, callback }
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label    = cfg.label or cfg[1] or "Button"
    local clicked  = ImGui.Button(label, cfg.w or 0, cfg.h or 0)
    local hovered  = ImGui.IsItemHovered()
    if clicked and cfg.callback then cfg.callback() end
    if hovered and cfg.tooltip  then
        ImGui.BeginTooltip()
        ImGui.Text(cfg.tooltip)
        ImGui.EndTooltip()
    end
    return self
end

function Element:SmallButton(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "Button"
    if ImGui.SmallButton(label) and cfg.callback then cfg.callback() end
    return self
end

-- ── Checkbox  (stateful)

function Element:Checkbox(cfg)
    -- cfg: string | { label, id, default, callback }
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label   = cfg.label or cfg[1] or "Checkbox"
    local sid     = uid(self._win, cfg.id or label)
    local val     = stateGet(sid, "v", cfg.default or false)
    local nval    = ImGui.Checkbox(label, val)
    if nval ~= val then
        stateSet(sid, "v", nval)
        if cfg.callback then cfg.callback(nval) end
    end
    return self
end

-- ── Toggle  (same as Checkbox, WindUI naming)

function Element:Toggle(cfg)
    return self:Checkbox(cfg)
end

-- ── Radio  (stateful, group by id)

function Element:Radio(cfg)
    -- cfg: { label, group_id, value, callback }
    local label    = cfg.label or cfg[1] or "Radio"
    local sid      = uid(self._win, cfg.group_id or "radio")
    local cur      = stateGet(sid, "v", cfg.default or 0)
    local opt      = cfg.value or 0
    if ImGui.RadioButton(label, cur == opt) then
        stateSet(sid, "v", opt)
        if cfg.callback then cfg.callback(opt) end
    end
    return self
end

-- ── Input  (stateful)

function Element:Input(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label  = cfg.label or cfg[1] or "Input"
    local sid    = uid(self._win, cfg.id or label)
    local val    = stateGet(sid, "v", cfg.default or "")
    local flags  = cfg.flags or 0
    local nval, changed
    if cfg.multiline then
        nval, changed = ImGui.InputTextMultiline(label, val, cfg.buf or 2048,
            cfg.w or -1, cfg.h or 80, flags)
    elseif cfg.hint then
        nval, changed = ImGui.InputTextWithHint(label, cfg.hint, val, cfg.buf or 256, flags)
    else
        nval, changed = ImGui.InputText(label, val, cfg.buf or 256, flags)
    end
    if changed then
        stateSet(sid, "v", nval)
        if cfg.callback then cfg.callback(nval) end
    end
    return self
end

-- ── Slider  (stateful)

function Element:Slider(cfg)
    -- cfg: { label, id, type="float"|"int", min, max, default, fmt, callback }
    local label  = cfg.label or cfg[1] or "Slider"
    local sid    = uid(self._win, cfg.id or label)
    local isInt  = cfg.type == "int"
    local min    = cfg.min or 0
    local max    = cfg.max or (isInt and 100 or 1.0)
    local val    = stateGet(sid, "v", cfg.default or min)
    local nval, changed
    if isInt then
        nval, changed = ImGui.SliderInt(label, val, min, max, cfg.fmt or "%d")
    else
        nval, changed = ImGui.SliderFloat(label, val, min, max, cfg.fmt or "%.2f")
    end
    if changed then
        stateSet(sid, "v", nval)
        if cfg.callback then cfg.callback(nval) end
    end
    return self
end

-- ── Drag  (stateful)

function Element:Drag(cfg)
    local label  = cfg.label or cfg[1] or "Drag"
    local sid    = uid(self._win, cfg.id or label)
    local isInt  = cfg.type == "int"
    local val    = stateGet(sid, "v", cfg.default or 0)
    local nval, changed
    if isInt then
        nval, changed = ImGui.DragInt(label, val, cfg.speed or 1,
            cfg.min or 0, cfg.max or 0)
    else
        nval, changed = ImGui.DragFloat(label, val, cfg.speed or 1.0,
            cfg.min or 0.0, cfg.max or 0.0, cfg.fmt or "%.2f")
    end
    if changed then
        stateSet(sid, "v", nval)
        if cfg.callback then cfg.callback(nval) end
    end
    return self
end

-- ── Combo / Dropdown  (stateful)

function Element:Combo(cfg)
    local label   = cfg.label or cfg[1] or "Combo"
    local items   = cfg.items or cfg.values or {}
    local sid     = uid(self._win, cfg.id or label)
    local idx     = stateGet(sid, "v", cfg.default or 0)
    local preview = items[idx + 1] or ""
    if ImGui.BeginCombo(label, preview, cfg.flags or 0) then
        for i, item in ipairs(items) do
            local sel = (i - 1) == idx
            if ImGui.Selectable(item, sel) then
                stateSet(sid, "v", i - 1)
                if cfg.callback then cfg.callback(item, i - 1) end
            end
            if sel then ImGui.SetItemDefaultFocus() end
        end
        ImGui.EndCombo()
    end
    return self
end

function Element:Dropdown(cfg) return self:Combo(cfg) end

-- ── ColorEdit  (stateful)

function Element:ColorEdit(cfg)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "Color"
    local sid   = uid(self._win, cfg.id or label)
    local r     = stateGet(sid, "r", cfg.r or 1.0)
    local g     = stateGet(sid, "g", cfg.g or 1.0)
    local b     = stateGet(sid, "b", cfg.b or 1.0)
    local a     = stateGet(sid, "a", cfg.a or 1.0)
    local nr, ng, nb, na, changed = ImGui.ColorEdit4(label, r, g, b, a, cfg.flags or 0)
    if changed then
        stateSet(sid, "r", nr) stateSet(sid, "g", ng)
        stateSet(sid, "b", nb) stateSet(sid, "a", na)
        if cfg.callback then cfg.callback(nr, ng, nb, na) end
    end
    return self
end

function Element:Colorpicker(cfg) return self:ColorEdit(cfg) end

-- ── Collapsing / Tree

function Element:Collapsing(cfg, fn)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "Header"
    fn = fn or cfg.OnRender or cfg.callback
    if ImGui.CollapsingHeader(label, cfg.flags or 0) then
        if fn then fn(self) end
    end
    return self
end

function Element:Tree(cfg, fn)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label = cfg.label or cfg[1] or "Tree"
    fn = fn or cfg.OnRender or cfg.callback
    if ImGui.TreeNodeEx(label, cfg.flags or 0) then
        if fn then fn(self) end
        ImGui.TreePop()
    end
    return self
end

-- ── Group  (returns a sub-element that shares state with parent win)

function Element:Group(fn)
    ImGui.BeginGroup()
    if type(fn) == "function" then fn(self) end
    ImGui.EndGroup()
    return self
end

-- ── Section  (CollapsingHeader or just a labeled block)

function Element:Section(cfg, fn)
    if type(cfg) == "string" then cfg = { label = cfg } end
    local label    = cfg.label or cfg[1] or ""
    fn = fn or cfg.OnRender
    if cfg.collapsible then
        if ImGui.CollapsingHeader(label) then
            if fn then fn(self) end
        end
    else
        ImGui.SeparatorText(label)
        if fn then fn(self) end
    end
    return self
end

-- ── Tab Bar  (fluent tab DSL)

function Element:Tabs(id, fn)
    if ImGui.BeginTabBar(id or "##tabs") then
        local TabCtx = setmetatable({ _win = self._win }, Element)
        function TabCtx:Tab(label, tab_fn)
            if ImGui.BeginTabItem(label) then
                if tab_fn then tab_fn(self) end
                ImGui.EndTabItem()
            end
            return self
        end
        if fn then fn(TabCtx) end
        ImGui.EndTabBar()
    end
    return self
end

-- ── Table  (simple data table)

function Element:Table(cfg)
    -- cfg: { id, columns={...}, rows={{...},...}, flags }
    local cols = cfg.columns or cfg.cols or {}
    if #cols == 0 then return self end
    if ImGui.BeginTable(cfg.id or "##tbl", #cols, cfg.flags or 0) then
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
    -- Apply theme
    local nc, nv = 0, 0
    if self._theme then
        nc, nv = applyTheme(self._theme)
    end

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
        if self._onrender then self._onrender(self) end
    end
    ImGui.End()

    -- Notifications overlay
    self:_renderNotifs()

    -- Pop theme
    if nv > 0 then ImGui.PopStyleVar(nv) end
    if nc > 0 then ImGui.PopStyleColor(nc) end
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
