-- 青鸳科技 完整脚本（加载动画优化 + 有进度条加载动画 + 全部原有功能 + 纯文字悬浮框 + 双击灵动岛适配UI）
-- 自动下载必要文件

gg.hide(true)

function sub(fn)
    local r = luajava.createProxy("java.lang.Runnable", { run = fn })
    local t = luajava.newInstance("java.lang.Thread", r)
    t:start()
    return t
end

dialogHandlers = {}

-- ==================== 持久化工具 ====================
function loadConfig(key, defaultValue)
    local path = "/storage/emulated/0/QY科技/" .. key .. ".cfg"
    local f = io.open(path, "r")
    if f then
        local val = f:read("*all"):gsub("%s+", "")
        f:close()
        if val == "1" or val == "0" or val == "light" or val == "dark" or val == "none" or val == "star" or val == "glow" or val == "fall" then return val end
    end
    return defaultValue
end

function saveConfig(key, value)
    local path = "/storage/emulated/0/QY科技/" .. key .. ".cfg"
    local f = io.open(path, "w")
    if f then f:write(value) f:close() end
end

function loadSwitchConfig(id, defaultBool) return loadConfig(id, defaultBool and "1" or "0") == "1" end
function saveSwitchConfig(id, value) saveConfig(id, value) end

-- 全局状态
capsuleTheme = loadConfig("capsule_theme", "dark")
local volumeKeyUI = (loadConfig("volume_key_ui", "0") == "1")
blurBgEnabled = (loadConfig("blur_bg", "1") == "1")
soundEnabled = (loadConfig("sound_enabled", "1") == "1")
capsuleEnabled = (loadConfig("capsule_enabled", "1") == "1")
currentThemeIndex = 0
particleMode = loadConfig("particle_mode", "none")
isToggling = false
floatingButtons = {}
switchFloats = {}
textOnlyFloats = {} -- 新增：纯文字悬浮框管理表

local toastQueue = {}
local toastBusy = false
local restoreTimer = nil
local restoreHandler = nil
toast_timer = nil
toast_runnable = nil

function initMenuDefaults()
    local function processItems(items)
        for _, it in ipairs(items or {}) do
            if it.type == "switch" or it.type == "checkbox" then
                if it.id == "capsule_theme" then
                    it.default = (loadConfig("capsule_theme", "dark") == "light")
                  elseif it.id == "sound_enabled" then it.default = soundEnabled
                  elseif it.id == "volume_key_ui" then it.default = volumeKeyUI
                  elseif it.id == "capsule_enabled" then it.default = capsuleEnabled
                  elseif it.id == "particle_star" then it.default = (particleMode == "star")
                  elseif it.id == "particle_glow" then it.default = (particleMode == "glow")
                  elseif it.id == "particle_fall" then it.default = (particleMode == "fall")
                  else it.default = loadSwitchConfig(it.id, it.default or false) end
            end
        end
    end
    if isGroupedMenu() then for _, g in ipairs(menu) do processItems(g.items) end else processItems(menu) end
end

function findMenuItemById(id)
    local function searchIn(items)
        for _, it in ipairs(items or {}) do
            if it.id == id then return it end
            if it.type == "collapsible" and it.items then
                local found = searchIn(it.items)
                if found then return found end
            end
        end
        return nil
    end
    if isGroupedMenu() then
        for _, g in ipairs(menu) do
            local found = searchIn(g.items)
            if found then return found end
        end
      else
        return searchIn(menu)
    end
    return nil
end

------------------------------------------------------------
-- menu 表（需要外部定义 main_menu）
------------------------------------------------------------
menu = main_menu

------------------------------------------------------------
-- HTML 模板（完整版）
------------------------------------------------------------
htmlTemplate = [[
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<style>
/* ===== 浅色主题 ===== */
:root,body.theme-light{
  --bg-base:#f6f5f4;
  --tint1:#c7e0ff;
  --tint2:#ffdce8;
  --tint3:#daf2e0;
  --tint4:#fff0d0;
  --glass:rgba(255,255,255,.62);
  --glass-strong:rgba(255,255,255,.8);
  --glass-border:rgba(255,255,255,.7);
  --text:#1a1a1e;
  --text-dim:#6d6d72;
  --accent:#0066cc;
  --ok:#34c759;
  --danger:#ff3b30;
  --shadow:rgba(0,0,0,.05);
  --hover:rgba(0,0,0,.03);
  --input-bg:rgba(0,0,0,.03);
  --title-weight:600;
}
/* ===== 深色主题 ===== */
body.theme-dark{
  --bg-base:#0b0c10;
  --tint1:#1f3350;
  --tint2:#3a224a;
  --tint3:#153d2c;
  --tint4:#4d3518;
  --glass:rgba(30,32,40,.6);
  --glass-strong:rgba(48,50,62,.75);
  --glass-border:rgba(255,255,255,.08);
  --text:#e6e6ee;
  --text-dim:#8f8f99;
  --accent:#3b9eff;
  --ok:#32d74b;
  --danger:#ff453a;
  --shadow:rgba(0,0,0,.55);
  --hover:rgba(255,255,255,.05);
  --input-bg:rgba(255,255,255,.05);
  --title-weight:500;
}
/* ===== 森林系主题 ===== */
body.theme-sunset{
  --bg-base:#f2f7f0;
  --tint1:#c4e3c4;
  --tint2:#a8d5a8;
  --tint3:#d0ead0;
  --tint4:#b8d8b8;
  --glass:rgba(240,250,240,.58);
  --glass-strong:rgba(240,250,240,.76);
  --glass-border:rgba(255,255,255,.7);
  --text:#1e2e1a;
  --text-dim:#5a6e52;
  --accent:#2d8c4a;
  --ok:#2ecc71;
  --danger:#e74c3c;
  --shadow:rgba(40,80,40,.1);
  --hover:rgba(0,0,0,.04);
  --input-bg:rgba(255,255,255,.45);
  --title-weight:600;
}
/* ===== 红白主题 ===== */
body.theme-ocean{
  --bg-base:#fef6f6;
  --tint1:#ffb3b3;
  --tint2:#ffcccc;
  --tint3:#ffd9d9;
  --tint4:#ffe5e5;
  --glass:rgba(255,245,245,.58);
  --glass-strong:rgba(255,245,245,.76);
  --glass-border:rgba(255,255,255,.72);
  --text:#2a1414;
  --text-dim:#7a5e5e;
  --accent:#d63031;
  --ok:#2ecc71;
  --danger:#e74c3c;
  --shadow:rgba(180,30,30,.1);
  --hover:rgba(0,0,0,.04);
  --input-bg:rgba(255,255,255,.45);
  --title-weight:600;
}

*{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent;}
html,body{background:transparent;font-family:-apple-system,"SF Pro Display","PingFang SC","Noto Sans SC",sans-serif;color:var(--text);font-size:12px;height:100%;overflow:hidden;}
body{padding:8px;transition:color .4s;border-radius:30px;overflow:hidden;}
.bg{position:fixed;inset:0;z-index:0;overflow:hidden;background-image:url("file:////storage/emulated/0/QY科技/");background-size:cover;background-position:center;background-repeat:no-repeat;transition:background .6s;border-radius:30px;}
.time-tint{position:absolute;inset:0;z-index:2;pointer-events:none;transition:background 1.5s ease;}
body.time-dawn .time-tint{background:rgba(255,200,140,0.15);}
body.time-morning .time-tint{background:rgba(255,255,200,0.08);}
body.time-noon .time-tint{background:transparent;}
body.time-afternoon .time-tint{background:rgba(255,180,100,0.1);}
body.time-evening .time-tint{background:rgba(200,120,80,0.2);}
body.time-night .time-tint{background:rgba(20,30,60,0.3);}
.blob{position:absolute;width:60%;height:60%;border-radius:50%;filter:blur(60px);opacity:.6;animation:drift 22s ease-in-out infinite;}
.blob:nth-child(1){background:var(--tint1);top:-15%;left:-10%;}
.blob:nth-child(2){background:var(--tint2);top:30%;right:-15%;animation-delay:-5s;}
.blob:nth-child(3){background:var(--tint3);bottom:-20%;left:20%;animation-delay:-10s;}
.blob:nth-child(4){background:var(--tint4);top:-5%;right:25%;animation-delay:-15s;width:40%;height:40%;}
@keyframes drift{0%,100%{transform:translate(0,0) scale(1);}25%{transform:translate(8%,12%) scale(1.1);}50%{transform:translate(-6%,8%) scale(.95);}75%{transform:translate(10%,-8%) scale(1.05);}}
.panel{position:relative;z-index:1;display:flex;height:100%;gap:8px;animation:bootIn .5s cubic-bezier(.2,.9,.3,1.1);}
@keyframes bootIn{from{opacity:0;transform:scale(.97);filter:blur(6px);}to{opacity:1;transform:scale(1);filter:blur(0);}}
.glass{position:relative;background:var(--glass);backdrop-filter:none;-webkit-backdrop-filter:none;border:1px solid var(--glass-border);border-radius:24px;box-shadow:0 8px 32px var(--shadow),inset 0 1px 0 rgba(255,255,255,.4);transition: backdrop-filter 0.4s ease, background 0.4s ease, box-shadow 0.4s ease;}
.glass::after{content:'';position:absolute;inset:0;border-radius:inherit;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.03'/%3E%3C/svg%3E");opacity:0.4;pointer-events:none;z-index:0;}
.glass.blur{backdrop-filter:blur(40px) saturate(180%);-webkit-backdrop-filter:blur(40px) saturate(180%);}
body.blur-off .glass { background: rgba(255,255,255,0.25); }
body.blur-off.theme-dark .glass { background: rgba(40,40,50,0.25); }
body.blur-off.theme-sunset .glass { background: rgba(240,250,240,0.25); }
body.blur-off.theme-ocean .glass { background: rgba(255,245,245,0.25); }
body.blur-off .row { background: rgba(255,255,255,0.35); }
body.blur-off.theme-dark .row { background: rgba(40,40,50,0.35); }
body.blur-off.theme-sunset .row { background: rgba(240,250,240,0.35); }
body.blur-off.theme-ocean .row { background: rgba(255,245,245,0.35); }
.sidebar{width:180px;flex-shrink:0;display:flex;flex-direction:column;padding:12px;position:relative;overflow:hidden;}
.brand{display:flex;align-items:center;gap:8px;padding:4px 6px 10px;border-bottom:1px solid var(--glass-border);margin-bottom:8px;}
.brand-icon{width:30px;height:30px;border-radius:10px;background:linear-gradient(135deg,var(--tint1),var(--tint2));display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:14px;box-shadow:0 4px 12px var(--shadow);}
.brand-text{font-size:15px;font-weight:var(--title-weight);letter-spacing:-.3px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}
.nav-title{font-size:9px;letter-spacing:1.2px;color:var(--text-dim);text-transform:uppercase;padding:6px 10px 4px;font-weight:600;}
.nav{flex:1;overflow-y:auto;min-height:0;scrollbar-width:none;-ms-overflow-style:none;}
.nav::-webkit-scrollbar{display:none;}
.nav-item{display:flex;align-items:center;gap:8px;padding:8px 10px;border-radius:12px;cursor:pointer;font-size:12px;font-weight:500;color:var(--text-dim);margin-bottom:2px;transition:all .2s;position:relative;}
body.theme-dark .nav-item { color: var(--text); }
.nav-item:hover{background:var(--hover);color:var(--text);}
.nav-item.active{
  background:var(--glass-strong);
  color:var(--accent);
  border-left:3px solid var(--accent);
  padding-left:7px;
}
.nav-icon{width:22px;height:22px;border-radius:7px;flex-shrink:0;background:rgba(0,0,0,.05);display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:600;transition:all .2s;}
body.theme-dark .nav-icon{background:rgba(255,255,255,.06);}
.nav-item.active .nav-icon{background:var(--accent);color:#fff;box-shadow:0 2px 6px color-mix(in srgb,var(--accent) 40%,transparent);}
.theme-row{display:flex;gap:5px;padding:8px 2px;border-top:1px solid var(--glass-border);}
.theme-dot{flex:1;height:20px;border-radius:7px;cursor:pointer;border:2px solid transparent;transition:all .2s;}
.theme-dot.t0{background:linear-gradient(135deg,#c7e0ff,#ffdce8);}
.theme-dot.t1{background:linear-gradient(135deg,#1f3350,#3a224a);}
.theme-dot.t2{background:linear-gradient(135deg,#a8d5a8,#85b585);}
.theme-dot.t3{background:linear-gradient(135deg,#ffb3b3,#ffcccc);}
.theme-dot.active{border-color:var(--text);transform:scale(1.08);}
.auto-dot {
    background: conic-gradient(red, yellow, lime, cyan, blue, magenta, red) !important;
    border: 2px solid transparent;
}
.auto-dot.active {
    border-color: var(--text);
    transform: scale(1.08);
}

.sidebar-foot{padding-top:6px;}
.floating-scrollbar { position: absolute; left: 2px; width: 4px; background: transparent; pointer-events: none; z-index: 10; transition: opacity 0.3s; opacity: 0; }
.sidebar:hover .floating-scrollbar, .nav:hover ~ .floating-scrollbar, .nav:active ~ .floating-scrollbar { opacity: 1; }
.floating-scrollbar-thumb { position: absolute; left: 0; top: 0; width: 100%; border-radius: 4px; background: var(--accent); min-height: 30px; opacity: 0.7; transition: height 0.1s; }

.content{flex:1;display:flex;flex-direction:column;padding:12px 8px 12px 12px;overflow:hidden;}
.content-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:10px;padding-bottom:8px;padding-right:10px;border-bottom:1px solid var(--glass-border);}
.content-title{font-size:20px;font-weight:var(--title-weight);letter-spacing:-.5px;}
.content-sub{font-size:10px;color:var(--text-dim);margin-top:2px;letter-spacing:1.2px;text-transform:uppercase;}
.head-right{display:flex;align-items:center;gap:8px;}
.pulse{width:7px;height:7px;border-radius:50%;background:var(--ok);box-shadow:0 0 6px var(--ok);animation:pul 1.5s infinite;}
@keyframes pul{50%{opacity:.3;}}
.time{font-family:"SF Mono",monospace;font-size:12px;color:#fff;text-shadow:0 1px 3px rgba(0,0,0,0.6);}
.body{flex:1;overflow-y:auto;padding-right:4px;margin-right:2px;}
.body::-webkit-scrollbar{width:4px;}
.body::-webkit-scrollbar-track{background:transparent;}
.body::-webkit-scrollbar-thumb{background:var(--text-dim);opacity:0.25;border-radius:2px;}
.group{display:none;animation:pageIn .35s cubic-bezier(.2,.9,.3,1) both;}
.group.active{display:block;}
@keyframes pageIn{from{opacity:0;transform:translateY(8px);}to{opacity:1;transform:translateY(0);}}
.row{background:var(--glass-strong);backdrop-filter:none;-webkit-backdrop-filter:none;border:1px solid var(--glass-border);border-radius:12px;padding:8px 10px;margin-bottom:5px;margin-right:2px;display:flex;align-items:center;justify-content:space-between;gap:6px;transition: backdrop-filter 0.4s ease, background 0.4s ease, box-shadow 0.4s ease;animation:in .35s backwards;}
.row.blur{backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);}
.row:hover{transform:translateY(-1px);}
@keyframes in{from{opacity:0;transform:translateY(6px);}to{opacity:1;}}
.row-label{display:flex;align-items:center;gap:8px;flex:1;min-width:0;font-size:12px;}
.row-icon{width:26px;height:26px;border-radius:7px;flex-shrink:0;background:linear-gradient(135deg,color-mix(in srgb,var(--accent) 80%,transparent),color-mix(in srgb,var(--accent) 50%,transparent));color:#fff;font-size:12px;font-weight:700;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px color-mix(in srgb,var(--accent) 30%,transparent);}
.row-label-text{font-size:12px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}
.row.row-block{display:block;padding:10px 12px;}
.row.row-block .row-label{margin-bottom:8px;}
.btn{background:var(--accent);color:#fff;border:none;padding:5px 14px;border-radius:10px;font-family:inherit;font-size:11px;font-weight:600;cursor:pointer;transition:all .15s;min-width:60px;box-shadow:0 2px 8px color-mix(in srgb,var(--accent) 30%,transparent);}
.btn:hover{transform:translateY(-1px);box-shadow:0 4px 12px color-mix(in srgb,var(--accent) 40%,transparent);}
.btn:active{transform:scale(.96);}
.sw{position:relative;width:44px;height:26px;cursor:pointer;flex-shrink:0;}
.sw input{display:none;}
.sw-bg{position:absolute;inset:0;border-radius:14px;background:rgba(0,0,0,.15);transition:all .3s;}
body.theme-dark .sw-bg{background:rgba(255,255,255,.15);}
.sw-knob{position:absolute;top:2px;left:2px;width:22px;height:22px;border-radius:50%;background:#fff;box-shadow:0 2px 4px rgba(0,0,0,.2);transition:all .3s cubic-bezier(.5,1.6,.4,1);}
.sw input:checked + .sw-bg{background:var(--ok);box-shadow:0 0 0 6px color-mix(in srgb,var(--ok) 15%,transparent);}
.sw input:checked + .sw-bg + .sw-knob{left:20px;}
.cb{position:relative;width:20px;height:20px;cursor:pointer;flex-shrink:0;}
.cb input{display:none;}
.cb-box{position:absolute;inset:0;border-radius:7px;background:rgba(0,0,0,.05);border:2px solid rgba(0,0,0,.15);transition:all .2s;display:flex;align-items:center;justify-content:center;}
body.theme-dark .cb-box{background:rgba(255,255,255,.05);border-color:rgba(255,255,255,.2);}
.cb-box::after{content:'';width:8px;height:5px;border-left:2px solid #fff;border-bottom:2px solid #fff;transform:rotate(-45deg) scale(0);transition:transform .2s;margin-top:-2px;}
.cb input:checked + .cb-box{background:var(--accent);border-color:var(--accent);box-shadow:0 0 0 4px color-mix(in srgb,var(--accent) 15%,transparent);}
.cb input:checked + .cb-box::after{transform:rotate(-45deg) scale(1);}
.slider-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;}
.slider-val{background:var(--accent);color:#fff;padding:2px 8px;border-radius:8px;font-size:10px;font-weight:700;font-family:"SF Mono",monospace;box-shadow:0 2px 6px color-mix(in srgb,var(--accent) 30%,transparent);}
.slider {
  -webkit-appearance: none;
  appearance: none;
  width: 100%;
  height: 3px;
  border-radius: 3px;
  background: transparent;
  outline: none;
  cursor: pointer;
  position: relative;
  z-index: 1;
}
.slider::-webkit-slider-runnable-track {
  height: 3px;
  border-radius: 3px;
  background: linear-gradient(to right, var(--accent) 0%, var(--accent) var(--pct, 50%), rgba(128,128,128,0.2) var(--pct, 50%), rgba(128,128,128,0.2) 100%);
}
body.theme-dark .slider::-webkit-slider-runnable-track {
  background: linear-gradient(to right, var(--accent) 0%, var(--accent) var(--pct, 50%), rgba(255,255,255,0.15) var(--pct, 50%), rgba(255,255,255,0.15) 100%);
}
.slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--accent);
  border: 2px solid #fff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2), 0 0 0 0px var(--accent);
  margin-top: -7px;
  cursor: pointer;
  transition: box-shadow 0.2s, transform 0.15s;
}
.slider::-webkit-slider-thumb:hover {
  box-shadow: 0 2px 6px rgba(0,0,0,0.25), 0 0 0 6px rgba(var(--accent), 0.15);
}
.slider::-webkit-slider-thumb:active {
  transform: scale(1.15);
  box-shadow: 0 2px 8px rgba(0,0,0,0.3), 0 0 0 10px rgba(var(--accent), 0.2);
}
.slider::-moz-range-track {
  height: 3px;
  border-radius: 3px;
  background: linear-gradient(to right, var(--accent) 0%, var(--accent) var(--pct, 50%), rgba(128,128,128,0.2) var(--pct, 50%), rgba(128,128,128,0.2) 100%);
}
.slider::-moz-range-thumb {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--accent);
  border: 2px solid #fff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
  cursor: pointer;
}
.inp{width:100%;padding:8px 12px;border-radius:10px;background:var(--input-bg);border:1px solid var(--glass-border);color:var(--text);font-family:inherit;font-size:12px;outline:none;transition:all .2s;}
.inp::placeholder{color:var(--text-dim);}
.inp:focus{border-color:var(--accent);box-shadow:0 0 0 3px color-mix(in srgb,var(--accent) 20%,transparent);}
.text-row { cursor: default; }
.text-row:hover { transform: none; box-shadow: none; }
.custom-select { min-width: 100px; }
.select-btn { background: var(--input-bg); border: 1px solid var(--glass-border); border-radius: 10px; padding: 6px 24px 6px 10px; font-size: 12px; color: var(--text); cursor: pointer; text-align: left; width: 100%; appearance: none; position: relative; font-family: inherit; }
.select-btn::after { content: ''; position: absolute; right: 8px; top: 50%; transform: translateY(-50%); width: 0; height: 0; border-left: 4px solid transparent; border-right: 4px solid transparent; border-top: 5px solid var(--text-dim); pointer-events: none; }
.select-options { display: none; position: fixed; background: var(--glass-strong); backdrop-filter: blur(20px); border-radius: 10px; border: 1px solid var(--glass-border); box-shadow: 0 8px 24px var(--shadow); z-index: 9999; max-height: 180px; overflow-y: auto; scrollbar-width: thin; scrollbar-color: var(--text-dim) transparent; }
.select-options::-webkit-scrollbar { width: 4px; }
.select-options::-webkit-scrollbar-track { background: transparent; }
.select-options::-webkit-scrollbar-thumb { background: var(--text-dim); border-radius: 2px; }
.select-option { padding: 6px 10px; cursor: pointer; font-size: 12px; color: var(--text); transition: background 0.15s; }
.select-option:hover { background: var(--hover); }
.media-image, .parallel-img {
    display: block;
    max-width: 100%;
    width: auto;
    height: auto;
    max-height: 220px;
    border-radius: 12px;
    box-shadow: 0 4px 12px var(--shadow);
    transition: transform 0.2s;
    background: rgba(0,0,0,0.03);
    margin: 0 auto;
}
.media-image:active { transform: scale(0.98); }
.media-video { display: block; width: 100%; max-height: 200px; border-radius: 12px; background: #000; margin-bottom: 6px; box-shadow: 0 4px 12px var(--shadow); }
.carousel-container {
    position: relative;
    width: 100%;
    padding-bottom: 56.25%;
    overflow: hidden;
    border-radius: 12px;
    margin-bottom: 6px;
    box-shadow: 0 4px 12px var(--shadow);
    background: rgba(0,0,0,0.05);
}
.carousel-slide {
    position: absolute;
    top: 0; left: 0;
    width: 100%;
    height: 100%;
    object-fit: contain;
    display: none;
}
.carousel-slide.active { display: block; }
.carousel-dots { text-align: center; margin-bottom: 6px; }
.carousel-dot { display: inline-block; width: 7px; height: 7px; border-radius: 50%; background: rgba(0,0,0,0.2); margin: 0 3px; cursor: pointer; }
.carousel-dot.active { background: var(--accent); }
#toastContainer { position: fixed; bottom: 20px; right: 20px; z-index: 200; display: flex; flex-direction: column; gap: 8px; pointer-events: none; }
.toast-item { background: var(--glass-strong); backdrop-filter: blur(20px); border-radius: 12px; padding: 8px 14px; box-shadow: 0 4px 16px var(--shadow); border: 1px solid var(--glass-border); font-size: 12px; color: var(--text); animation: toastIn 0.3s ease, toastOut 0.3s ease 2s forwards; max-width: 240px; word-break: break-word; }
.toast-item.success { border-left: 3px solid var(--ok); }
.toast-item.error { border-left: 3px solid var(--danger); }
.toast-item.info { border-left: 3px solid var(--accent); }
@keyframes toastIn { from { opacity: 0; transform: translateX(20px); } to { opacity: 1; transform: translateX(0); } }
@keyframes toastOut { from { opacity: 1; } to { opacity: 0; transform: translateX(20px); } }
.input-with-btn { display: flex; gap: 6px; align-items: center; margin-top: 6px; }
.input-with-btn .inp { flex: 1; }
.progress-container {
    position: fixed; bottom: 20px; left: 50%; transform: translateX(-50%);
    width: 80%; max-width: 400px; z-index: 100;
    display: flex; flex-direction: column; gap: 6px;
    pointer-events: none;
}
.progress-item {
    background: var(--glass-strong); backdrop-filter: blur(20px);
    border-radius: 12px; padding: 10px 14px;
    box-shadow: 0 4px 12px var(--shadow);
    border: 1px solid var(--glass-border);
}
.progress-label { font-size: 11px; color: var(--text-dim); margin-bottom: 4px; }
.progress-bar { height: 5px; background: rgba(0,0,0,0.1); border-radius: 5px; overflow: hidden; }
.progress-fill { height: 100%; background: var(--accent); border-radius: 5px; transition: width 0.2s ease; }
.progress-percent { font-size: 10px; color: var(--accent); text-align: right; margin-top: 2px; }

.loading-overlay {
    position: fixed; inset: 0; z-index: 500;
    background: rgba(0,0,0,0.35); backdrop-filter: blur(20px);
    display: flex; flex-direction: column;
    align-items: center; justify-content: center;
    pointer-events: all; gap: 20px;
    border-radius: 30px; overflow: hidden;
}
.loading-spinner {
    width: 44px; height: 44px;
    border: 4px solid rgba(255,255,255,0.15);
    border-top-color: #ffffff;
    border-radius: 50%;
    animation: spin 0.7s linear infinite,
               spinnerPulse 2s ease-in-out infinite;
}
@keyframes spinnerPulse {
    0%, 100% { box-shadow: 0 0 12px rgba(255,255,255,0.2); }
    50%      { box-shadow: 0 0 24px rgba(255,255,255,0.5); }
}
.loading-text {
    font-size: 14px; font-weight: 600;
    color: #ffffff;
    text-align: center;
    letter-spacing: 0.5px;
    text-shadow: 0 1px 4px rgba(0,0,0,0.3);
}

.loading-progress-overlay {
    position: fixed; inset: 0; z-index: 501;
    background: rgba(0,0,0,0.35); backdrop-filter: blur(20px);
    display: flex; flex-direction: column;
    align-items: center; justify-content: center;
    pointer-events: all; gap: 20px;
    border-radius: 30px; overflow: hidden;
}
.loading-progress-spinner {
    width: 44px; height: 44px;
    border: 4px solid rgba(255,255,255,0.15);
    border-top-color: #ffffff;
    border-radius: 50%;
    animation: spin 0.7s linear infinite,
               spinnerPulse 2s ease-in-out infinite;
}
.loading-progress-text {
    font-size: 14px; font-weight: 600;
    color: #ffffff;
    text-align: center;
    letter-spacing: 0.5px;
    text-shadow: 0 1px 4px rgba(0,0,0,0.3);
}
.loading-progress-bar-container {
    width: 70%; max-width: 300px; height: 5px;
    background: rgba(255,255,255,0.15);
    border-radius: 5px; overflow: hidden;
    box-shadow: 0 0 8px rgba(255,255,255,0.2);
    animation: barGlow 2s ease-in-out infinite;
}
@keyframes barGlow {
    0%, 100% { box-shadow: 0 0 8px rgba(255,255,255,0.2); }
    50%      { box-shadow: 0 0 16px rgba(255,255,255,0.5); }
}
.loading-progress-fill {
    height: 100%;
    background: #ffffff;
    border-radius: 5px;
    background-image: linear-gradient(90deg, rgba(255,255,255,0) 0%, rgba(255,255,255,0.4) 50%, rgba(255,255,255,0) 100%);
    background-size: 200% 100%;
    animation: progressShine 1.5s ease-in-out infinite;
    transition: width 0.2s ease;
}
@keyframes progressShine {
    0%   { background-position: 200% 0; }
    100% { background-position: -200% 0; }
}
.loading-progress-percent {
    font-size: 13px; font-weight: 700;
    color: #ffffff;
    text-align: center; margin-top: 4px;
    text-shadow: 0 1px 4px rgba(0,0,0,0.3);
    animation: percentBounce 0.4s ease;
}
@keyframes percentBounce {
    0%   { transform: scale(1); }
    50%  { transform: scale(1.2); }
    100% { transform: scale(1); }
}

@keyframes spin { to { transform: rotate(360deg); } }

.dialog-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.35); z-index: 300; display: flex; align-items: center; justify-content: center; animation: fadeIn 0.2s ease; border-radius: 30px; }
.dialog-box { background: var(--glass-strong); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); border-radius: 18px; padding: 18px; min-width: 220px; max-width: 260px; box-shadow: 0 12px 40px var(--shadow); border: 1px solid var(--glass-border); animation: scaleIn 0.25s cubic-bezier(0.16,1,0.3,1); overflow: hidden; transform: translateZ(0); }
.dialog-title { font-size: 15px; font-weight: 700; margin-bottom: 6px; color: var(--text); }
.dialog-message { font-size: 12px; color: var(--text-dim); margin-bottom: 16px; line-height: 1.4; white-space: pre-line; }
.dialog-buttons { display: flex; gap: 8px; justify-content: flex-end; }
.dialog-buttons button { padding: 6px 18px; border-radius: 8px; border: none; font-size: 12px; font-weight: 600; cursor: pointer; transition: all 0.15s; }
.dialog-btn-cancel { background: var(--input-bg); color: var(--text); }
.dialog-btn-cancel:hover { background: var(--hover); }
.dialog-btn-confirm { background: var(--accent); color: #fff; box-shadow: 0 2px 8px color-mix(in srgb,var(--accent) 30%,transparent); }
.dialog-btn-confirm:hover { transform: translateY(-1px); box-shadow: 0 4px 12px color-mix(in srgb,var(--accent) 40%,transparent); }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
@keyframes scaleIn { from { opacity: 0; transform: scale(0.92); } to { opacity: 1; transform: scale(1); } }

.divider {
    height: 2px;
    background: var(--glass-border);
    margin: 12px 0;
}
.collapsible { margin-bottom: 6px; overflow: hidden; }
.collapsible-header { display: flex; align-items: center; gap: 8px; padding: 8px 12px; background: var(--glass-strong); border: 1px solid var(--glass-border); border-radius: 12px; cursor: pointer; transition: all .25s; }
.collapsible-header:hover { background: var(--hover); }
.collapsible-header .row-icon { width: 26px; height: 26px; border-radius: 7px; background: linear-gradient(135deg,color-mix(in srgb,var(--accent) 80%,transparent),color-mix(in srgb,var(--accent) 50%,transparent)); color: #fff; font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; }
.collapsible-header .row-label-text { font-size: 12px; font-weight: 500; }
.collapsible-header .arrow { margin-left: auto; font-size: 10px; transition: transform .35s ease; }
.collapsible.open .arrow { transform: rotate(90deg); }
.collapsible-body {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.4s ease, padding 0.4s ease;
  padding: 0 10px;
}
.collapsible.open .collapsible-body {
  max-height: 1000px;
  padding: 6px 10px 4px 10px;
}
.collapsible-body .row { margin-bottom: 4px; padding: 8px 10px; }
.collapsible-body .row.row-block { padding: 8px 10px; }
.collapsible-body .slider-top { margin-bottom: 4px; }
.collapsible-body .input-with-btn { margin-top: 4px; }
.collapsible-body .collapsible { margin-top: 4px; }

.stepper { display: flex; align-items: center; gap: 8px; }
.stepper button { width: 26px; height: 26px; border-radius: 8px; border: none; background: var(--accent); color: #fff; font-size: 16px; font-weight: 600; cursor: pointer; display: flex; align-items: center; justify-content: center; }
.stepper .value { min-width: 24px; text-align: center; font-weight: 600; color: var(--text); font-size: 13px; }

.progress-ring { width: 30px; height: 30px; margin-left: 6px; flex-shrink: 0; }
.progress-ring circle { fill: none; stroke-width: 3; stroke-linecap: round; transition: stroke-dashoffset 0.2s ease; }
.progress-ring .bg-ring { stroke: var(--glass-border); }
.progress-ring .fg-ring { stroke: var(--accent); stroke-dasharray: 75.4; stroke-dashoffset: 75.4; }

.webview-container {
  position: relative;
  margin-bottom: 6px;
  width: 100%;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px var(--shadow);
  background: #fff;
}
body.theme-dark .webview-container { background: #2c2c2e; }
.webview-iframe {
  width: 100%;
  height: 280px;
  border: none;
  display: block;
  background: transparent;
}
.webview-fallback {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: inherit;
  color: var(--text-dim);
  font-size: 12px;
  text-align: center;
  padding: 16px;
  pointer-events: none;
  transition: opacity 0.3s;
}
.webview-fallback.hidden { opacity: 0; }
.webview-fallback-btn {
  margin-top: 10px;
  padding: 5px 14px;
  border-radius: 8px;
  background: var(--accent);
  color: #fff;
  border: none;
  cursor: pointer;
  pointer-events: auto;
  font-weight: 600;
  font-size: 12px;
}

.parallel-container {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin: 5px 0;
}
.parallel-item {
    flex: 1 1 0%;
    min-width: 0;
}
.parallel-img {
    display: block !important;
    width: 100% !important;
    height: auto !important;
    max-height: 220px;
    object-fit: contain;
    border-radius: 12px !important;
    box-shadow: 0 4px 12px var(--shadow);
    background: rgba(0,0,0,0.03);
}

@media (max-width: 500px) {
  .sidebar { width: 150px; padding: 10px 8px; }
  .brand-icon { width: 28px; height: 28px; font-size: 13px; }
  .brand-text { font-size: 14px; }
  .nav-item { padding: 7px 8px; font-size: 11px; gap: 6px; }
  .nav-icon { width: 20px; height: 20px; font-size: 10px; }
  .content { padding: 10px 6px 10px 8px; }
  .content-head { margin-bottom: 8px; padding-bottom: 6px; padding-right: 8px; }
  .content-title { font-size: 17px; }
  .row { padding: 7px 8px; margin-bottom: 4px; margin-right: 2px; gap: 5px; border-radius: 10px; }
  .row-label-text { font-size: 11px; }
  .btn { padding: 5px 12px; font-size: 10px; }
  .webview-iframe { height: 180px; }
}

.time-tint { display: none; }
.blob { display: none; }
.time { color: #ffffff !important; text-shadow: 0 1px 3px rgba(0,0,0,0.6); }
.content-sub {
    color: #ffffff !important;
    text-shadow: 0 1px 3px rgba(0,0,0,0.6);
    opacity: 0.9;
}

.chat-panel {
    position: fixed; bottom: 70px; right: 20px;
    width: 300px; max-height: 65vh; height: auto;
    background: var(--glass-strong);
    border-radius: 14px; border: 1px solid var(--glass-border);
    z-index: 400; display: none; flex-direction: column;
    box-shadow: 0 8px 32px var(--shadow);
    backdrop-filter: blur(20px);
    animation: chatIn 0.25s ease;
    overflow: hidden;
}
.chat-panel.show { display: flex; }
@keyframes chatIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
.chat-header {
    padding: 8px 12px; font-weight: 600; color: var(--accent);
    border-bottom: 1px solid var(--glass-border);
    display: flex; justify-content: space-between; align-items: center;
    flex-shrink: 0; font-size: 13px;
}
.chat-messages {
    flex: 1; overflow-y: auto; padding: 8px 6px;
    display: flex; flex-direction: column; gap: 6px;
    min-height: 0;
}
.chat-bubble {
    max-width: 85%; padding: 6px 10px; border-radius: 12px;
    font-size: 11px; line-height: 1.4; word-break: break-word;
    position: relative; animation: bubbleIn 0.2s ease;
}
@keyframes bubbleIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
.chat-bubble.mine {
    align-self: flex-end; background: var(--accent); color: #fff;
    border-bottom-right-radius: 4px;
}
.chat-bubble.other {
    align-self: flex-start; background: var(--input-bg); color: var(--text);
    border-bottom-left-radius: 4px;
}
.chat-bubble .bubble-name {
    font-weight: 700; font-size: 10px; margin-bottom: 2px;
}
.chat-bubble.mine .bubble-name { color: rgba(255,255,255,0.8); }
.chat-bubble.other .bubble-name { color: var(--accent); }
.chat-bubble .bubble-content { font-size: 12px; }
.chat-bubble .bubble-time {
    font-size: 9px; opacity: 0.6; text-align: right; margin-top: 3px;
}
.chat-input-area {
    display: flex; padding: 6px; border-top: 1px solid var(--glass-border);
    gap: 5px; flex-shrink: 0;
}
.chat-input {
    flex: 1; padding: 6px 10px; border-radius: 8px;
    background: var(--input-bg); border: 1px solid var(--glass-border);
    color: var(--text); font-size: 11px; outline: none;
    -webkit-user-select: text;
}
.chat-send-btn {
    background: var(--accent); color: #fff; border: none;
    border-radius: 8px; padding: 0 12px; font-weight: 600; font-size: 11px;
    cursor: pointer;
}

.chat-float-btn {
    position: fixed; bottom: 20px; right: 20px;
    width: 24px; height: 24px; border-radius: 50%;
    background: var(--glass-strong);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid var(--glass-border);
    color: var(--text);
    display: flex; align-items: center; justify-content: center;
    font-size: 12px;
    box-shadow: 0 2px 8px var(--shadow);
    cursor: pointer; z-index: 350;
    border: none;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    animation: floatBtn 3s ease-in-out infinite;
}
.chat-float-btn:hover {
    transform: scale(1.1);
    box-shadow: 0 4px 12px var(--shadow);
    background: var(--glass-strong);
    border: 1px solid var(--accent);
}
.chat-float-btn:active {
    transform: scale(0.95);
    transition: transform 0.1s ease;
}
@keyframes floatBtn {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-5px); }
}

.image-zoom-overlay {
    position: fixed;
    inset: 0;
    z-index: 600;
    background: rgba(0,0,0,0.85);
    backdrop-filter: blur(10px);
    display: flex;
    align-items: center;
    justify-content: center;
    animation: fadeIn 0.2s ease;
    border-radius: 30px;
}
.image-zoom-img {
    max-width: 90vw;
    max-height: 90vh;
    object-fit: contain;
    border-radius: 12px;
    box-shadow: 0 8px 32px rgba(0,0,0,0.5);
    cursor: pointer;
}
</style>
</head>
<body class="theme-light">
<div class="bg">
<canvas id="particleCanvas" style="position:absolute;top:0;left:0;width:100%;height:100%;z-index:1;pointer-events:none;"></canvas>
<div class="time-tint"></div>
<div class="blob"></div><div class="blob"></div><div class="blob"></div><div class="blob"></div>
</div>
<div class="panel">
<aside class="sidebar glass">
<div class="brand"><div class="brand-icon">{{BRAND_ICON}}</div><div class="brand-text">{{TITLE}}</div></div>
<div class="nav-title">菜单</div>
<nav class="nav" id="nav"></nav>
<div class="floating-scrollbar" id="floatingScrollbar">
    <div class="floating-scrollbar-thumb" id="scrollbarThumb"></div>
</div>
<div class="theme-row">
<div class="theme-dot t0 active" onclick="setTheme(0,this)"></div>
<div class="theme-dot t1" onclick="setTheme(1,this)"></div>
<div class="theme-dot t2" onclick="setTheme(2,this)"></div>
<div class="theme-dot t3" onclick="setTheme(3,this)"></div>
<div class="theme-dot auto-dot" onclick="enableAutoTheme()" title="自动取色"></div>
</div>
</aside>
<main class="content glass">
<header class="content-head">
<div><div class="content-sub">{{SUBTITLE}}</div><div class="content-title" id="curTitle" style="display:none;">{{TITLE}}</div></div>
<div class="head-right"><span class="pulse"></span><span class="time" id="time">--:--:--</span></div>
</header>
<div class="body">{{ITEMS}}</div>
</main>
</div>
<div id="toastContainer"></div>
<div class="progress-container" id="progressContainer"></div>

<div class="loading-overlay" id="loadingOverlay" style="display:none;">
    <div class="loading-spinner"></div>
    <div class="loading-text" id="loadingText">加载中...</div>
</div>

<div class="loading-progress-overlay" id="loadingProgressOverlay" style="display:none;">
    <div class="loading-progress-spinner"></div>
    <div class="loading-progress-text" id="loadingProgressText">正在处理...</div>
    <div class="loading-progress-bar-container">
        <div class="loading-progress-fill" id="loadingProgressFill"></div>
    </div>
    <div class="loading-progress-percent" id="loadingProgressPercent">0%</div>
</div>

<button class="chat-float-btn" onclick="toggleChatPanel()" title="公屏聊天">💬</button>
<div class="chat-panel" id="chatPanel">
    <div class="chat-header">
        <span>公屏聊天</span>
        <span style="cursor:pointer" onclick="document.getElementById('chatPanel').classList.remove('show')">✕</span>
    </div>
    <div class="chat-messages" id="chatMessages"></div>
    <div class="chat-input-area">
        <input class="chat-input" type="text" id="chatInput" placeholder="输入消息..." onkeydown="if(event.key==='Enter')sendChatMsg()" autocomplete="off">
        <button class="chat-send-btn" onclick="sendChatMsg()">发送</button>
    </div>
</div>

{{SELECT_OPTIONS}}
<script>
window.__cfg = {{CONFIG}};
window.__soundEnabled = true;

var CHAT_API = "http://as.ziyuanqaq.asia/";
var CHAT_USER = localStorage.getItem('chat_username') || generateRandomName();
var LAST_MESSAGE_COUNT = 0;

function generateRandomName() {
    var surnames = ["青","云","风","月","星","夜","雨","雪","花","影","梦","霜","灵","幽","幻","烟"];
    var names = ["鸳","科技","用户","小","大","一","二","三","四","五","六","七","八","九","十","白","墨","清","浅","深","远"];
    var len = Math.floor(Math.random() * 3) + 2;
    var name = "";
    for (var i = 0; i < len; i++) {
        var pool = i === 0 ? surnames : names;
        name += pool[Math.floor(Math.random() * pool.length)];
    }
    name = name.substring(0, 4);
    localStorage.setItem('chat_username', name);
    return name;
}

window.__luaCallback = function(name, success, data) {
    if (name === 'chat_pull' || name === 'chat_send') {
        if (success && data && data.length > 0) {
            parseAndRenderMessages(data);
        }
    }
};

function toggleChatPanel() {
    var panel = document.getElementById('chatPanel');
    panel.classList.toggle('show');
    if (panel.classList.contains('show')) pullChatMessages();
}

function sendChatMsg() {
    var input = document.getElementById('chatInput');
    var msg = input.value.trim();
    if (!msg) return;
    input.value = '';
    input.blur();
    var url = CHAT_API + "?name=" + encodeURIComponent(CHAT_USER) + "&nr=" + encodeURIComponent(msg);
    if (window.NA && NA.send) {
        NA.send('http_get', 'chat_send|' + url);
        setTimeout(function() { pullChatMessages(); }, 500);
    }
}
function pullChatMessages() {
    var url = CHAT_API + "?hq=true";
    if (window.NA && NA.send) NA.send('http_get', 'chat_pull|' + url);
}

function parseAndRenderMessages(rawText) {
    var lines = rawText.trim().split('\n');
    if (lines.length <= LAST_MESSAGE_COUNT) return;
    var msgDiv = document.getElementById('chatMessages');
    for (var i = LAST_MESSAGE_COUNT; i < lines.length; i++) {
        var line = lines[i].trim();
        if (!line) continue;
        var match = line.match(/^(.+?)\s*\[(.+?)\]:\s*(.*)$/);
        if (match) {
            var name = match[1].trim();
            var time = match[2].trim();
            var content = match[3].trim();
            var lastBubble = msgDiv.lastElementChild;
            if (lastBubble && lastBubble.classList.contains('chat-bubble')) {
                var lastName = (lastBubble.querySelector('.bubble-name')?.textContent || '').trim();
                var lastContent = (lastBubble.querySelector('.bubble-content')?.textContent || '').trim();
                var lastTime = (lastBubble.querySelector('.bubble-time')?.textContent || '').trim();
                if (lastName === name && lastContent === content && lastTime === time) {
                    continue;
                }
            }
            appendBubble(name, content, time, name === CHAT_USER);
        }
    }
    LAST_MESSAGE_COUNT = lines.length;
    msgDiv.scrollTop = msgDiv.scrollHeight;
}

function appendBubble(name, content, time, isMine) {
    var msgDiv = document.getElementById('chatMessages');
    var bubble = document.createElement('div');
    bubble.className = 'chat-bubble ' + (isMine ? 'mine' : 'other');
    bubble.innerHTML = '<div class="bubble-name">' + escapeHtml(name) + '</div>' +
                      '<div class="bubble-content">' + escapeHtml(content) + '</div>' +
                      '<div class="bubble-time">' + escapeHtml(time) + '</div>';
    msgDiv.appendChild(bubble);
}

function escapeHtml(str) {
    var div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

setInterval(function() {
    if (document.getElementById('chatPanel').classList.contains('show')) pullChatMessages();
}, 5000);

var audioCtx = null;
function getAudioContext() { if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)(); return audioCtx; }
function playClickSound() {
    if (!window.__soundEnabled) return;
    try {
        var ctx = getAudioContext(), now = ctx.currentTime;
        var buf = ctx.createBuffer(1, ctx.sampleRate * 0.004, ctx.sampleRate);
        var d = buf.getChannelData(0);
        for(var i = 0; i < d.length; i++) d[i] = (Math.random() * 2 - 1) * 0.5;
        var n = ctx.createBufferSource(); n.buffer = buf;
        var ng = ctx.createGain(); ng.gain.setValueAtTime(0.35, now); ng.gain.exponentialRampToValueAtTime(0.001, now + 0.004);
        n.connect(ng); ng.connect(ctx.destination); n.start(now);
        var o1 = ctx.createOscillator(); var g1 = ctx.createGain();
        o1.type = 'triangle'; o1.frequency.setValueAtTime(1200, now); o1.frequency.exponentialRampToValueAtTime(800, now + 0.03);
        g1.gain.setValueAtTime(0.2, now); g1.gain.exponentialRampToValueAtTime(0.001, now + 0.035);
        o1.connect(g1); g1.connect(ctx.destination); o1.start(now); o1.stop(now + 0.04);
        var o2 = ctx.createOscillator(); var g2 = ctx.createGain();
        o2.type = 'sine'; o2.frequency.setValueAtTime(3500, now);
        g2.gain.setValueAtTime(0.08, now); g2.gain.exponentialRampToValueAtTime(0.001, now + 0.015);
        o2.connect(g2); g2.connect(ctx.destination); o2.start(now); o2.stop(now + 0.015);
    } catch(e){}
}

function onBtn(id,el){ playClickSound(); const r=NA.emit(id,''); if(r) el.textContent=r; }
function onSwitch(id,el){ playClickSound(); NA.send(id,el.checked?'1':'0'); if(id==='blur_bg') setBlur(el.checked); }
function onCheck(id,el){ playClickSound(); NA.send(id,el.checked?'1':'0'); }
var slideTimers = {};
function onSlide(id, el, valId, min, max) {
    document.getElementById(valId).textContent = el.value;
    var pct = ((el.value - min) / (max - min) * 100).toFixed(1);
    el.style.setProperty('--pct', pct + '%');
    var ring = document.querySelector('.progress-ring[data-slider-id="' + id + '"]');
    if (ring) {
        var circle = ring.querySelector('.fg-ring');
        var maxVal = parseFloat(max); var minVal = parseFloat(min);
        var dashVal = 75.4 * (1 - (el.value - minVal) / (maxVal - minVal));
        circle.setAttribute('stroke-dashoffset', dashVal);
    }
    clearTimeout(slideTimers[id]);
    slideTimers[id] = setTimeout(function() { NA.send(id, el.value); }, 300);
}
function onInputConfirm(id, inputEl) { playClickSound(); NA.send(id, inputEl.value); }
function showToast(msg, type) { var c = document.getElementById('toastContainer'), d = document.createElement('div'); d.className = 'toast-item ' + (type || 'info'); d.textContent = msg; c.appendChild(d); setTimeout(function(){ if(d.parentNode) d.parentNode.removeChild(d); }, 2300); }
function updateText(id, text) { var e = document.getElementById('dyn_text_' + id); if(e) e.textContent = text; }
function toggleSelect(id) { var btn=document.getElementById('select_btn_'+id), opt=document.getElementById('select_opts_'+id); if(!btn||!opt)return; document.querySelectorAll('.select-options').forEach(function(e){e.style.display='none'}); if(opt.style.display!=='block'){ var r=btn.getBoundingClientRect(),vh=window.innerHeight; var sb=vh-r.bottom, sa=r.top, mh=180; if(sb<120&&sa>sb){ opt.style.maxHeight=Math.min(sa-10,mh)+'px'; opt.style.bottom=(vh-r.top+4)+'px'; opt.style.top='auto'; } else { opt.style.maxHeight=Math.min(sb-10,mh)+'px'; opt.style.top=(r.bottom+4)+'px'; opt.style.bottom='auto'; } opt.style.left=r.left+'px'; opt.style.width=r.width+'px'; opt.style.display='block'; setTimeout(function(){ window.__selectClickHandler=function(e){ if(!e.target.closest('.select-options')&&!e.target.closest('.select-btn')){opt.style.display='none';window.removeEventListener('click',window.__selectClickHandler);} }; window.addEventListener('click',window.__selectClickHandler); },10); }else{ opt.style.display='none'; if(window.__selectClickHandler) window.removeEventListener('click',window.__selectClickHandler); } }
function selectOption(id,value,text){ var btn=document.getElementById('select_btn_'+id); if(btn) btn.textContent=text; var opt=document.getElementById('select_opts_'+id); if(opt) opt.style.display='none'; if(window.__selectClickHandler) window.removeEventListener('click',window.__selectClickHandler); NA.send(id,value); playClickSound(); }
var carouselTimers = {};
function initCarousel(id, interval) { var slides = document.querySelectorAll('#carousel_' + id + ' .carousel-slide'); if (slides.length === 0) return; var dots = document.querySelectorAll('#carousel_' + id + ' + .carousel-dots .carousel-dot'); if (dots.length === 0) dots = document.querySelectorAll('#carousel_' + id).parentNode.querySelectorAll('.carousel-dot'); var idx = 0; function showSlide(i) { slides.forEach(function(s){ s.classList.remove('active'); }); dots.forEach(function(d){ d.classList.remove('active'); }); slides[i].classList.add('active'); if (dots[i]) dots[i].classList.add('active'); } showSlide(0); carouselTimers[id] = setInterval(function(){ idx = (idx + 1) % slides.length; showSlide(idx); }, interval || 3000); }
function showCarouselSlide(id, idx) { var slides = document.querySelectorAll('#carousel_' + id + ' .carousel-slide'); var dots = document.querySelectorAll('#carousel_' + id + ' + .carousel-dots .carousel-dot'); if (dots.length === 0) dots = document.querySelectorAll('#carousel_' + id).parentNode.querySelectorAll('.carousel-dot'); slides.forEach(function(s){ s.classList.remove('active'); }); dots.forEach(function(d){ d.classList.remove('active'); }); slides[idx-1].classList.add('active'); dots[idx-1].classList.add('active'); clearInterval(carouselTimers[id]); carouselTimers[id] = setInterval(function(){ var cur = (idx) % slides.length; showCarouselSlide(id, cur+1); }, 3000); }
(function() {
    var nav = document.getElementById('nav'); var floatingBar = document.getElementById('floatingScrollbar'); var thumb = document.getElementById('scrollbarThumb'); var sidebar = document.querySelector('.sidebar');
    function syncFloatingScrollbarSize() { if (!nav || !floatingBar || !sidebar) return; var navRect = nav.getBoundingClientRect(); var sidebarRect = sidebar.getBoundingClientRect(); var offsetTop = navRect.top - sidebarRect.top; floatingBar.style.top = offsetTop + 'px'; floatingBar.style.height = nav.clientHeight + 'px'; }
    function updateScrollbar() { if (!nav || !thumb) return; var scrollTop = nav.scrollTop; var scrollHeight = nav.scrollHeight; var clientHeight = nav.clientHeight; if (scrollHeight <= clientHeight) { thumb.style.display = 'none'; return; } thumb.style.display = 'block'; var thumbHeight = Math.max((clientHeight / scrollHeight) * clientHeight, 30); var maxTop = clientHeight - thumbHeight; var scrollPercent = scrollTop / (scrollHeight - clientHeight); var top = scrollPercent * maxTop; thumb.style.height = thumbHeight + 'px'; thumb.style.top = top + 'px'; }
    syncFloatingScrollbarSize(); updateScrollbar(); nav.addEventListener('scroll', updateScrollbar); window.addEventListener('resize', function() { syncFloatingScrollbarSize(); updateScrollbar(); }); var observer = new MutationObserver(function() { syncFloatingScrollbarSize(); updateScrollbar(); }); observer.observe(nav, { childList: true, subtree: true });
})();
function showConfirmDialog(title, message, confirmText, cancelText, cmd) {
  confirmText = confirmText || '确定'; cancelText = cancelText || '取消'; cmd = cmd || '';
  var overlay = document.createElement('div'); overlay.className = 'dialog-overlay';
  overlay.innerHTML = `<div class="dialog-box"><div class="dialog-title">${title}</div><div class="dialog-message">${message}</div><div class="dialog-buttons"><button class="dialog-btn-cancel" id="dialogCancel">${cancelText}</button><button class="dialog-btn-confirm" id="dialogConfirm">${confirmText}</button></div></div>`;
  document.body.appendChild(overlay);
  function close() { document.body.removeChild(overlay); document.removeEventListener('keydown', escHandler); }
  function escHandler(e) { if (e.key === 'Escape') { NA.send('dialog_result', '0|' + cmd); close(); } }
  document.addEventListener('keydown', escHandler);
  overlay.querySelector('#dialogCancel').onclick = function() { NA.send('dialog_result', '0|' + cmd); close(); };
  overlay.querySelector('#dialogConfirm').onclick = function() { playClickSound(); NA.send('dialog_result', '1|' + cmd); close(); };
}
function toggleCollapsible(id) { var el = document.getElementById('collapsible_' + id); if (el) el.classList.toggle('open'); }
function stepperChange(id, delta, min, max) {
    var el = document.getElementById('stepper_val_' + id); if (!el) return;
    var val = parseInt(el.textContent) + delta; if (isNaN(val)) val = min || 0;
    if (min !== undefined && val < min) val = min; if (max !== undefined && val > max) val = max;
    el.textContent = val; NA.send(id, String(val));
}
var particleMode = 'none'; var canvas, ctx, w, h, particles = [], animFrame; var mouse = { x: -1000, y: -1000 };
function getParticleColors() {
    if (document.body.classList.contains('theme-dark')) return { primary: 'rgba(255,255,255,', secondary: 'rgba(100,180,255,', accent: 'rgba(255,120,200,' };
    if (document.body.classList.contains('theme-sunset')) return { primary: 'rgba(30,50,20,', secondary: 'rgba(80,150,80,', accent: 'rgba(60,120,40,' };
    if (document.body.classList.contains('theme-ocean')) return { primary: 'rgba(40,20,20,', secondary: 'rgba(255,80,80,', accent: 'rgba(200,30,30,' };
    return { primary: 'rgba(30,30,40,', secondary: 'rgba(60,100,200,', accent: 'rgba(180,50,100,' };
}
document.addEventListener('touchmove', function(e) { if (e.touches.length > 0) { mouse.x = e.touches[0].clientX; mouse.y = e.touches[0].clientY; } });
document.addEventListener('touchend', function() { mouse.x = -1000; mouse.y = -1000; });
document.addEventListener('mousemove', function(e) { mouse.x = e.clientX; mouse.y = e.clientY; });
document.addEventListener('mouseleave', function() { mouse.x = -1000; mouse.y = -1000; });
function initCanvas() { canvas = document.getElementById('particleCanvas'); if (!canvas) return; ctx = canvas.getContext('2d'); resizeCanvas(); window.addEventListener('resize', resizeCanvas); }
function resizeCanvas() { var rect = canvas.parentElement.getBoundingClientRect(); canvas.width = rect.width; canvas.height = rect.height; w = rect.width; h = rect.height; if (particleMode === 'star') createStarParticles(); else if (particleMode === 'glow') createGalaxyParticles(); else if (particleMode === 'fall') createFallParticles(); }
function createStarParticles() { var count = 80; particles = []; for (var i = 0; i < count; i++) { particles.push({ x: Math.random() * w, y: Math.random() * h, vx: (Math.random() - 0.5) * 0.4, vy: (Math.random() - 0.5) * 0.4, radius: Math.random() * 2 + 0.5, opacity: Math.random() * 0.8 + 0.2 }); } }
function drawStar() { if (!ctx || particles.length === 0) return; ctx.clearRect(0, 0, w, h); var col = getParticleColors(); ctx.strokeStyle = col.primary + '0.15)'; ctx.lineWidth = 0.5; for (var i = 0; i < particles.length; i++) { for (var j = i + 1; j < particles.length; j++) { var dx = particles[i].x - particles[j].x; var dy = particles[i].y - particles[j].y; var dist = Math.sqrt(dx * dx + dy * dy); if (dist < 80) { ctx.beginPath(); ctx.moveTo(particles[i].x, particles[i].y); ctx.lineTo(particles[j].x, particles[j].y); ctx.stroke(); } } } for (var i = 0; i < particles.length; i++) { var p = particles[i]; var mx = mouse.x, my = mouse.y; if (mx > 0 && my > 0) { var dx = p.x - mx, dy = p.y - my; var dist = Math.sqrt(dx*dx+dy*dy); if (dist < 100) { p.vx += (dx / dist) * 0.4; p.vy += (dy / dist) * 0.4; } } p.x += p.vx; p.y += p.vy; if (p.x < 0 || p.x > w) p.vx *= -1; if (p.y < 0 || p.y > h) p.vy *= -1; p.vx *= 0.99; p.vy *= 0.99; ctx.fillStyle = col.primary + p.opacity + ')'; ctx.beginPath(); ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2); ctx.fill(); } }
function createGalaxyParticles() { var count = 300; particles = []; for (var i = 0; i < count; i++) { var angle = Math.random() * Math.PI * 2; var distance = Math.random() * Math.min(w, h) * 0.45; particles.push({ centerX: w / 2, centerY: h / 2, angle: angle, distance: distance, speed: (Math.random() * 0.3 + 0.1) * (Math.random() < 0.5 ? 1 : -1), drift: Math.random() * 0.02, radius: Math.random() * 1.5 + 0.3, opacity: Math.random() * 0.7 + 0.2 }); } }
function drawGalaxy() { if (!ctx || particles.length === 0) return; ctx.clearRect(0, 0, w, h); var col = getParticleColors(); for (var i = 0; i < particles.length; i++) { var p = particles[i]; p.angle += p.speed * 0.01; p.distance += p.drift; if (p.distance > Math.min(w, h) * 0.45 || p.distance < 10) p.drift *= -1; var x = p.centerX + Math.cos(p.angle) * p.distance; var y = p.centerY + Math.sin(p.angle) * p.distance; ctx.fillStyle = col.primary + p.opacity + ')'; ctx.beginPath(); ctx.arc(x, y, p.radius, 0, Math.PI * 2); ctx.fill(); } }
function createFallParticles() { var count = 50; particles = []; for (var i = 0; i < count; i++) { particles.push({ x: Math.random() * w, y: Math.random() * h, size: Math.random() * 3 + 1, speed: Math.random() * 1.5 + 0.5, sway: Math.random() * 0.8 + 0.2, swayOffset: Math.random() * Math.PI * 2, opacity: Math.random() * 0.6 + 0.2 }); } }
function drawFall() { if (!ctx || particles.length === 0) return; ctx.clearRect(0, 0, w, h); var col = getParticleColors(); ctx.fillStyle = col.primary + '1)'; for (var i = 0; i < particles.length; i++) { var p = particles[i]; p.y += p.speed; p.x += Math.sin(Date.now() * 0.002 * p.sway + p.swayOffset) * 0.5; if (p.y > h + 5) { p.y = -5; p.x = Math.random() * w; } ctx.globalAlpha = p.opacity; ctx.fillRect(p.x, p.y, p.size, p.size); } ctx.globalAlpha = 1; }
function animateParticles() { if (particleMode === 'star') drawStar(); else if (particleMode === 'glow') drawGalaxy(); else if (particleMode === 'fall') drawFall(); else ctx && ctx.clearRect(0, 0, w, h); animFrame = requestAnimationFrame(animateParticles); }
function setParticleMode(mode) { if (animFrame) cancelAnimationFrame(animFrame); particleMode = mode; if (!canvas) initCanvas(); if (mode === 'star') createStarParticles(); else if (mode === 'glow') createGalaxyParticles(); else if (mode === 'fall') createFallParticles(); else { particles = []; ctx && ctx.clearRect(0, 0, w, h); } animFrame = requestAnimationFrame(animateParticles); }
function updateTimeTheme() { var hour = new Date().getHours(); var cls = 'time-noon'; if (hour >= 5 && hour < 7) cls = 'time-dawn'; else if (hour >= 7 && hour < 10) cls = 'time-morning'; else if (hour >= 10 && hour < 16) cls = 'time-noon'; else if (hour >= 16 && hour < 18) cls = 'time-afternoon'; else if (hour >= 18 && hour < 20) cls = 'time-evening'; else cls = 'time-night'; document.body.className = document.body.className.replace(/time-\w+/g, '') + ' ' + cls; }
function initProgressRings() { document.querySelectorAll('.slider-top').forEach(function(top) { var slider = top.querySelector('.slider'); if (!slider) return; var id = slider.id; var min = parseFloat(slider.min); var max = parseFloat(slider.max); var val = parseFloat(slider.value); var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg'); svg.setAttribute('class', 'progress-ring'); svg.setAttribute('viewBox', '0 0 28 28'); svg.setAttribute('data-slider-id', id); var bg = document.createElementNS('http://www.w3.org/2000/svg', 'circle'); bg.setAttribute('class', 'bg-ring'); bg.setAttribute('cx', '14'); bg.setAttribute('cy', '14'); bg.setAttribute('r', '12'); var fg = document.createElementNS('http://www.w3.org/2000/svg', 'circle'); fg.setAttribute('class', 'fg-ring'); fg.setAttribute('cx', '14'); fg.setAttribute('cy', '14'); fg.setAttribute('r', '12'); var dashVal = 75.4 * (1 - (val - min) / (max - min)); fg.setAttribute('stroke-dashoffset', dashVal); svg.appendChild(bg); svg.appendChild(fg); top.appendChild(svg); }); }
function initWebviews() { document.querySelectorAll('.webview-container').forEach(function(container) { var iframe = container.querySelector('iframe'); if (!iframe) return; var fallback = container.querySelector('.webview-fallback'); var btn = container.querySelector('.webview-fallback-btn'); var url = iframe.src; var timer = setTimeout(function() { if (fallback) fallback.classList.remove('hidden'); }, 3000); iframe.addEventListener('load', function() { clearTimeout(timer); if (fallback) fallback.classList.add('hidden'); }); iframe.addEventListener('error', function() { clearTimeout(timer); if (fallback) fallback.classList.remove('hidden'); }); if (btn) { btn.addEventListener('click', function(e) { e.stopPropagation(); NA.send('open_browser', url); }); } }); }
function initFloatButtonOnLongPress() {
    document.querySelectorAll('.btn').forEach(function(btn) { var timer = null, startX, startY; btn.addEventListener('touchstart', function(e) { startX = e.touches[0].clientX; startY = e.touches[0].clientY; timer = setTimeout(function() { var match = btn.getAttribute('onclick').match(/onBtn\('([^']+)',this\)/); if (match) { var id = match[1]; var row = btn.closest('.row'); var labelEl = row ? row.querySelector('.row-label-text') : null; var text = labelEl ? labelEl.textContent.trim() : btn.textContent.trim(); NA.send('create_float_btn', id + '|' + text); } }, 500); }); btn.addEventListener('touchmove', function(e) { if (timer && (Math.abs(e.touches[0].clientX - startX) > 10 || Math.abs(e.touches[0].clientY - startY) > 10)) { clearTimeout(timer); timer = null; } }); btn.addEventListener('touchend', function() { if (timer) { clearTimeout(timer); timer = null; } }); btn.addEventListener('touchcancel', function() { if (timer) { clearTimeout(timer); timer = null; } }); });
    document.querySelectorAll('.row').forEach(function(row) { var swInput = row.querySelector('.sw input'); if (!swInput) return; var timer = null, startX, startY; row.addEventListener('touchstart', function(e) { startX = e.touches[0].clientX; startY = e.touches[0].clientY; timer = setTimeout(function() { var id = swInput.id; var labelEl = row.querySelector('.row-label-text'); var text = labelEl ? labelEl.textContent.trim() : ''; NA.send('create_switch_float', id + '|' + text); }, 500); }); row.addEventListener('touchmove', function(e) { if (timer && (Math.abs(e.touches[0].clientX - startX) > 10 || Math.abs(e.touches[0].clientY - startY) > 10)) { clearTimeout(timer); timer = null; } }); row.addEventListener('touchend', function() { if (timer) { clearTimeout(timer); timer = null; } }); row.addEventListener('touchcancel', function() { if (timer) { clearTimeout(timer); timer = null; } }); });
}
function showLoading(text) { var el = document.getElementById('loadingOverlay'); if (el) { var textEl = document.getElementById('loadingText'); if (textEl) textEl.textContent = text || '加载中...'; el.style.display = 'flex'; } }
function hideLoading() { var el = document.getElementById('loadingOverlay'); if (el) el.style.display = 'none'; }
function showLoadingProgress(max, label) { var el = document.getElementById('loadingProgressOverlay'); if (!el) return; var textEl = document.getElementById('loadingProgressText'); var fillEl = document.getElementById('loadingProgressFill'); var pctEl = document.getElementById('loadingProgressPercent'); if (textEl) textEl.textContent = label || '正在处理...'; if (fillEl) fillEl.style.width = '0%'; if (pctEl) pctEl.textContent = '0%'; el.style.display = 'flex'; el._max = max; }
function updateLoadingProgress(current) { var el = document.getElementById('loadingProgressOverlay'); if (!el || !el._max) return; var pct = Math.min(100, Math.round((current / el._max) * 100)); var fillEl = document.getElementById('loadingProgressFill'); var pctEl = document.getElementById('loadingProgressPercent'); if (fillEl) fillEl.style.width = pct + '%'; if (pctEl) pctEl.textContent = pct + '%'; }
function hideLoadingProgress() { var el = document.getElementById('loadingProgressOverlay'); if (el) { el.style.display = 'none'; el._max = undefined; } }
var progressTasks = {};
function showProgress(max, label, id) { id = id || 'default'; if (progressTasks[id]) return; var container = document.getElementById('progressContainer'); var item = document.createElement('div'); item.className = 'progress-item'; item.id = 'progress-' + id; item.innerHTML = `<div class="progress-label">${label || '处理中...'}</div><div class="progress-bar"><div class="progress-fill" style="width:0%"></div></div><div class="progress-percent">0%</div>`; container.appendChild(item); progressTasks[id] = { max: max, current: 0 }; }
function updateProgress(current, id) { id = id || 'default'; if (!progressTasks[id]) return; var task = progressTasks[id]; var pct = Math.min(100, Math.round((current / task.max) * 100)); var item = document.getElementById('progress-' + id); if (item) { item.querySelector('.progress-fill').style.width = pct + '%'; item.querySelector('.progress-percent').textContent = pct + '%'; } if (current >= task.max) { setTimeout(function() { if (item) item.remove(); delete progressTasks[id]; }, 800); } }
function setProgressLabel(text, id) { id = id || 'default'; var item = document.getElementById('progress-' + id); if (item) item.querySelector('.progress-label').textContent = text; }

function initImageZoom() {
    document.body.addEventListener('click', function(e) {
        var img = e.target.closest('.media-image');
        if (!img) return;
        e.preventDefault();
        if (document.querySelector('.image-zoom-overlay')) return;
        var overlay = document.createElement('div');
        overlay.className = 'image-zoom-overlay';
        var zoomedImg = document.createElement('img');
        zoomedImg.src = img.src;
        zoomedImg.className = 'image-zoom-img';
        overlay.appendChild(zoomedImg);
        overlay.addEventListener('click', function() {
            overlay.remove();
        });
        document.body.appendChild(overlay);
    });
}

function rgbToHsl(r, g, b) {
    r /= 255, g /= 255, b /= 255;
    var max = Math.max(r, g, b), min = Math.min(r, g, b);
    var h, s, l = (max + min) / 2;
    if (max == min) {
        h = s = 0;
    } else {
        var d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        switch (max) {
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }
        h /= 6;
    }
    return [h, s, l];
}

function hslToHex(h, s, l) {
    var r, g, b;
    if (s == 0) {
        r = g = b = l;
    } else {
        function hue2rgb(p, q, t) {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1/6) return p + (q - p) * 6 * t;
            if (t < 1/2) return q;
            if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
            return p;
        }
        var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        var p = 2 * l - q;
        r = hue2rgb(p, q, h + 1/3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1/3);
    }
    var toHex = function(c) { return Math.round(c * 255).toString(16).padStart(2, '0'); };
    return '#' + toHex(r) + toHex(g) + toHex(b);
}

function applyGeneratedTheme(r, g, b) {
    var hsl = rgbToHsl(r, g, b);
    var h = hsl[0], s = hsl[1], l = hsl[2];
    var isDark = l < 0.5;
    var accentH = h;
    var accentS = Math.min(1, s * 1.2);
    var accentL = isDark ? 0.65 : 0.35;
    var accent = hslToHex(accentH, accentS, accentL);
    var bgBase = isDark ? hslToHex(h, Math.min(1, s * 0.3), 0.08) : hslToHex(h, Math.min(1, s * 0.1), 0.96);
    var tint1 = hslToHex((h + 0.05) % 1, Math.min(1, s * 0.6), isDark ? 0.2 : 0.85);
    var tint2 = hslToHex((h - 0.05 + 1) % 1, Math.min(1, s * 0.6), isDark ? 0.25 : 0.9);
    var tint3 = hslToHex((h + 0.1) % 1, Math.min(1, s * 0.4), isDark ? 0.15 : 0.92);
    var tint4 = hslToHex((h - 0.1 + 1) % 1, Math.min(1, s * 0.4), isDark ? 0.2 : 0.88);
    var glassColor = isDark ? `rgba(${r},${g},${b},0.2)` : `rgba(${r},${g},${b},0.15)`;
    var glassStrong = isDark ? `rgba(${r},${g},${b},0.4)` : `rgba(${r},${g},${b},0.35)`;
    var glassBorder = isDark ? `rgba(255,255,255,0.08)` : `rgba(255,255,255,0.7)`;
    var textColor = isDark ? '#ffffff' : '#000000';
    var textDim = isDark ? '#b3b3b3' : '#4d4d4d';
    var shadow = isDark ? 'rgba(0,0,0,0.55)' : 'rgba(0,0,0,0.05)';
    var hover = isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)';
    var inputBg = isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)';
    var root = document.documentElement;
    root.style.setProperty('--bg-base', bgBase);
    root.style.setProperty('--tint1', tint1);
    root.style.setProperty('--tint2', tint2);
    root.style.setProperty('--tint3', tint3);
    root.style.setProperty('--tint4', tint4);
    root.style.setProperty('--glass', glassColor);
    root.style.setProperty('--glass-strong', glassStrong);
    root.style.setProperty('--glass-border', glassBorder);
    root.style.setProperty('--text', textColor);
    root.style.setProperty('--text-dim', textDim);
    root.style.setProperty('--accent', accent);
    root.style.setProperty('--ok', isDark ? '#32d74b' : '#34c759');
    root.style.setProperty('--danger', isDark ? '#ff453a' : '#ff3b30');
    root.style.setProperty('--shadow', shadow);
    root.style.setProperty('--hover', hover);
    root.style.setProperty('--input-bg', inputBg);
    root.style.setProperty('--title-weight', isDark ? '500' : '600');
}

function ensureFileUrl(path) {
    if (!path) return path;
    if (/^(file|https?):\/\//i.test(path)) return path;
    return 'file://' + path;
}

function analyzeAndApplyTheme(imageUrl) {
    imageUrl = ensureFileUrl(imageUrl);
    var img = new Image();
    img.crossOrigin = 'Anonymous';
    img.onload = function() {
        try {
            var canvas = document.createElement('canvas');
            var ctx = canvas.getContext('2d');
            var maxSize = 100;
            var ratio = Math.min(maxSize / img.width, maxSize / img.height);
            canvas.width = img.width * ratio;
            canvas.height = img.height * ratio;
            ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
            var data = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
            var maxSat = -1;
            var bestR = 0, bestG = 0, bestB = 0;
            var totalR = 0, totalG = 0, totalB = 0, totalCount = 0;
            for (var i = 0; i < data.length; i += 4) {
                var r = data[i];
                var g = data[i+1];
                var b = data[i+2];
                var a = data[i+3];
                if (a < 128) continue;
                var max = Math.max(r, g, b);
                var min = Math.min(r, g, b);
                var sat = (max + min) > 0 ? (max - min) / (max + min) : 0;
                if (sat > maxSat) {
                    maxSat = sat;
                    bestR = r;
                    bestG = g;
                    bestB = b;
                }
                totalR += r;
                totalG += g;
                totalB += b;
                totalCount++;
            }
            var r, g, b;
            if (maxSat >= 0.1) {
                r = bestR;
                g = bestG;
                b = bestB;
            } else if (totalCount > 0) {
                r = Math.round(totalR / totalCount);
                g = Math.round(totalG / totalCount);
                b = Math.round(totalB / totalCount);
            } else {
                setTheme(0);
                showToast('无法分析图片颜色，已切换为浅色主题', 'error');
                return;
            }
            applyGeneratedTheme(r, g, b);
            showToast('自动主题已应用', 'success');
        } catch(e) {
            showToast('颜色分析失败: ' + e.message, 'error');
        }
    };
    img.onerror = function() {
        showToast('背景图片加载失败，无法取色', 'error');
    };
    img.src = imageUrl;
}
function enableAutoTheme() {
    document.body.classList.remove('theme-light','theme-dark','theme-sunset','theme-ocean');
    document.body.classList.add('theme-auto');
    document.querySelectorAll('.theme-dot').forEach(d => d.classList.remove('active'));
    var autoDot = document.querySelector('.auto-dot');
    if(autoDot) autoDot.classList.add('active');
    localStorage.setItem('themeMode', 'auto');
    var bgEl = document.querySelector('.bg');
    var bgImage = getComputedStyle(bgEl).backgroundImage;
    var urlMatch = bgImage.match(/url\(["']?([^"')]+)["']?\)/);
    if (urlMatch) {
        analyzeAndApplyTheme(urlMatch[1]);
    } else {
        showToast('未检测到背景图，请先设置背景', 'error');
    }
}

window.addEventListener('DOMContentLoaded', ()=>{
    window.__soundEnabled = (window.__cfg.sound_enabled === true || window.__cfg.sound_enabled === '1');
    updateTimeTheme(); setInterval(updateTimeTheme, 600000);
    const groups=document.querySelectorAll('.group'), nav=document.getElementById('nav');
    if(groups.length===0){document.querySelector('.nav-title').style.display='none';return;}
    groups.forEach((g,i)=>{ const name=g.dataset.group||('组'+(i+1)), icon=g.dataset.icon||'·'; const item=document.createElement('div'); item.className='nav-item'+(i===0?' active':''); item.innerHTML='<div class="nav-icon">'+icon+'</div><span>'+name+'</span>'; item.onclick=function(){activate(i,name);}; nav.appendChild(item); if(i===0){g.classList.add('active');document.getElementById('curTitle').textContent=name;} });
    var savedMode = localStorage.getItem('themeMode');
    if (savedMode === 'auto') {
        enableAutoTheme();
    } else {
        var saved = localStorage.getItem('themeIndex');
        if(saved!==null){var idx=parseInt(saved); if(!isNaN(idx)&&idx>=0&&idx<=3){var dots=document.querySelectorAll('.theme-dot'); setTheme(idx,dots[idx]);}}
    }
    var savedBg = localStorage.getItem('bgPath'); if(savedBg){ setBgPath(savedBg); var bgInput=document.getElementById('inp_bg_path'); if(bgInput) bgInput.value=savedBg; }
    var blurSwitch=document.getElementById('blur_bg'), savedBlur=localStorage.getItem('blurEnabled'); if(savedBlur==='1'){if(blurSwitch)blurSwitch.checked=true;setBlur(true);} else if(savedBlur==='0'){if(blurSwitch)blurSwitch.checked=false;setBlur(false);} else{if(blurSwitch&&blurSwitch.checked)setBlur(true);else setBlur(false);}
    setTimeout(function(){ document.querySelectorAll('input[type="text"], input:not([type]), textarea, .chat-input').forEach(function(inp){ inp.addEventListener('focus',function(){NA.send('__input_focus','1');}); inp.addEventListener('blur',function(){NA.send('__input_focus','0');}); }); },300);
    document.querySelectorAll('.carousel-container').forEach(function(car){var id=car.id.split('_')[1]; if(id) initCarousel(id,3000);});
    initCanvas(); var initMode = window.__cfg.particle_mode || 'none'; setParticleMode(initMode); initProgressRings(); initWebviews(); initFloatButtonOnLongPress();
    initImageZoom();
    NA.send('ui_ready', '');
});
function activate(idx,name){ document.querySelectorAll('.nav-item').forEach((el,i)=>el.classList.toggle('active',i===idx)); document.querySelectorAll('.group').forEach((el,i)=>el.classList.toggle('active',i===idx)); document.getElementById('curTitle').textContent=name; }
const themes=['theme-light','theme-dark','theme-sunset','theme-ocean']; let ti=0;
function setTheme(i,el){
    document.body.classList.remove('theme-auto');
    localStorage.setItem('themeMode', i);
    document.body.classList.remove(themes[ti]);
    ti=i;
    document.body.classList.add(themes[ti]);
    document.querySelectorAll('.theme-dot').forEach(x=>x.classList.remove('active'));
    if(el)el.classList.add('active');
    localStorage.setItem('themeIndex', i);
    NA.send('theme_changed', i);
}
function tick(){const d=new Date(),p=n=>String(n).padStart(2,'0');document.getElementById('time').textContent=p(d.getHours())+':'+p(d.getMinutes())+':'+p(d.getSeconds());} tick(); setInterval(tick,1000);
function setBgPath(path){
    var fullPath = ensureFileUrl(path);
    document.querySelector('.bg').style.backgroundImage = `url(${fullPath}?t=${Date.now()})`;
    localStorage.setItem('bgPath', path);
    if (localStorage.getItem('themeMode') === 'auto') {
        analyzeAndApplyTheme(fullPath);
    }
}
function setBlur(enable){ const glasses = document.querySelectorAll('.glass'); const rows = document.querySelectorAll('.row'); glasses.forEach(e => e.classList.toggle('blur', enable)); rows.forEach(e => e.classList.toggle('blur', enable)); document.body.classList.toggle('blur-off', !enable); localStorage.setItem('blurEnabled', enable ? '1' : '0'); }
</script>
</body>
</html>
]]
--======================== 框架代码 ========================--
compile("/storage/emulated/0/QY科技/webBridge.dex")
import "android.view.*"
import "android.graphics.*"
import "android.graphics.drawable.GradientDrawable"
import "android.widget.*"
import "android.webkit.WebView"
import "android.webkit.WebViewClient"
import "android.os.Build"
import "com.Shizuku.WebBridge"
import "android.animation.*"
import "android.view.animation.*"
import "android.os.Handler"
import "android.os.Looper"

window = activity.getSystemService("window")

local carouselHandler = nil
local carouselRunnable = nil

function stopTextCarousel()
    if carouselHandler then carouselHandler.removeCallbacks(carouselRunnable); carouselHandler = nil end
    if toast_timer then toast_timer.removeCallbacks(toast_runnable); toast_timer = nil end
end

function startCapsuleCarousel()
    if not capsule or not capsule_text1 or not capsule_text2 or not capsule_text_container then return end
    stopTextCarousel()
    local texts = lunfanwenzi[2]
    local density = activity.getResources().getDisplayMetrics().density
    local function measureTextWidth(textView, text)
        local paint = textView.getPaint()
        local w = paint.measureText(text)
        return math.max(math.floor(w + 8 * density), math.floor(40 * density))
    end
    local function animateWidth(fromWidth, toWidth, duration)
        local animator = luajava.newInstance("android.animation.ValueAnimator")
        animator.setIntValues(fromWidth, toWidth)
        animator.setDuration(duration or 350)
        animator.setInterpolator(AccelerateDecelerateInterpolator())
        animator.addUpdateListener(luajava.createProxy("android.animation.ValueAnimator$AnimatorUpdateListener", {
            onAnimationUpdate = function(anim)
                local val = anim.getAnimatedValue()
                local lp = capsule_text_container.getLayoutParams()
                lp.width = val
                capsule_text_container.setLayoutParams(lp)
            end
        }))
        animator.start()
    end
    if #texts <= 1 then
        local t = texts[1] or menu.title or "QY"
        capsule_text1.setText(t)
        capsule_text2.setAlpha(0)
        local w = measureTextWidth(capsule_text1, t)
        local lp = capsule_text_container.getLayoutParams()
        lp.width = w
        capsule_text_container.setLayoutParams(lp)
        return
    end
    local distance = 20 * density
    local currentIdx = 1
    capsule_text1.setText(texts[1])
    capsule_text1.setTranslationY(0)
    capsule_text1.setAlpha(1)
    capsule_text2.setText(texts[2] or texts[1])
    capsule_text2.setTranslationY(distance)
    capsule_text2.setAlpha(0)
    local initW = measureTextWidth(capsule_text1, texts[1])
    local lp0 = capsule_text_container.getLayoutParams()
    lp0.width = initW
    capsule_text_container.setLayoutParams(lp0)
    local function doSwitch()
        local nextIdx = currentIdx % #texts + 1
        local outView = capsule_text1
        local inView = capsule_text2
        local nextText = texts[nextIdx]
        inView.setText(nextText)
        inView.setTranslationY(distance)
        inView.setAlpha(0)
        local fromWidth = capsule_text_container.getLayoutParams().width
        local toWidth = measureTextWidth(inView, nextText)
        animateWidth(fromWidth, toWidth, 350)
        outView.animate()
        .translationY(-distance)
        .alpha(0)
        .setDuration(350)
        .setInterpolator(AccelerateDecelerateInterpolator())
        .start()
        inView.animate()
        .translationY(0)
        .alpha(1)
        .setDuration(350)
        .setInterpolator(AccelerateDecelerateInterpolator())
        .withEndAction(luajava.createProxy("java.lang.Runnable", {
            run = function()
                outView.setTranslationY(distance)
                outView.setAlpha(0)
                local temp = capsule_text1
                capsule_text1 = capsule_text2
                capsule_text2 = temp
                currentIdx = nextIdx
                playCapsuleBounce()
            end
        })).start()
    end
    carouselHandler = luajava.newInstance("android.os.Handler", Looper.getMainLooper())
    carouselRunnable = luajava.createProxy("java.lang.Runnable", {
        run = function()
            doSwitch()
            if carouselHandler then
                carouselHandler.postDelayed(carouselRunnable, 10000)
            end
        end
    })
    carouselHandler.postDelayed(carouselRunnable, 10000)
end

function playCapsuleBounce()
    if not capsule then return end
    capsule.animate().cancel()
    capsule.setLayerType(View.LAYER_TYPE_SOFTWARE, nil)
    capsule.animate()
    .scaleX(0.94).scaleY(0.94)
    .setDuration(80)
    .setInterpolator(DecelerateInterpolator())
    .withEndAction(luajava.createProxy("java.lang.Runnable", {
        run = function()
            capsule.animate()
            .scaleX(1.0).scaleY(1.0)
            .setDuration(500)
            .setInterpolator(OvershootInterpolator(1.8))
            .withEndAction(luajava.createProxy("java.lang.Runnable", {
                run = function()
                    capsule.setLayerType(View.LAYER_TYPE_NONE, nil)
                end
            })).start()
        end
    })).start()
end

function htmlEscape(s)
    if not s then return "" end
    s = tostring(s)
    s = s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
    :gsub('"',"&quot;"):gsub("'","&#39;")
    return s
end

function jsonEncode(v)
    local t = type(v)
    if t == "nil" then return "null"
      elseif t == "boolean" then return v and "true" or "false"
      elseif t == "number" then return tostring(v)
      elseif t == "string" then
        local s = v:gsub('\\','\\\\'):gsub('"','\\"')
        :gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
        :gsub('</','<<\\/')
        return '"' .. s .. '"'
      elseif t == "table" then
        local isArr = (#v > 0)
        if isArr then
            local parts = {}
            for i, x in ipairs(v) do parts[i] = jsonEncode(x) end
            return "[" .. table.concat(parts, ",") .. "]"
          else
            local parts = {}
            for k, x in pairs(v) do
                if type(k) == "string" and type(x) ~= "function" then
                    parts[#parts+1] = jsonEncode(k) .. ":" .. jsonEncode(x)
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

function buildConfig()
    local cfg = {}
    for k, v in pairs(menu) do
        if type(k) == "string" and type(v) ~= "function" then
            cfg[k] = v
        end
    end
    cfg.blur_bg_lua = blurBgEnabled
    cfg.particle_mode = particleMode
    cfg.sound_enabled = soundEnabled
    return jsonEncode(cfg)
end

selectOptionsCache = {}

function renderItem(it)
    local id = htmlEscape(it.id or "")
    local label = htmlEscape(it.label or "")
    local icon = htmlEscape(it.icon or (it.label or "?"):sub(1,1))
    -- ======== 新增 parallel 并列控件 ========
    if it.type == "parallel" then
        local gap = it.gap or 8
        local childrenHtml = {}
        for _, subIt in ipairs(it.items or {}) do
            local subHtml = renderItem(subIt)
            if subIt.type == "image" then
                subHtml = subHtml:gsub('class="media-image"', 'class="media-image parallel-img"')
            end
            childrenHtml[#childrenHtml + 1] = string.format(
            '<div class="parallel-item">%s</div>', subHtml
            )
        end
        return string.format(
        '<div class="parallel-container" style="gap:%dpx;">%s</div>',
        gap, table.concat(childrenHtml)
        )
    end
    -- 自动执行控件（不显示）
    if it.type == "auto" then
        return "" -- 不输出任何 HTML
    end
    -- ======== 原有控件类型 ========
    if it.type == "webview" then
        local idAttr = it.id and string.format(' id="webview_%s"', htmlEscape(it.id)) or ""
        local url = it.url or "about:blank"
        return string.format(
        '<div class="webview-container">'..
        '<iframe%s class="webview-iframe" src="%s" sandbox="allow-same-origin allow-scripts allow-popups allow-forms"></iframe>'..
        '<div class="webview-fallback hidden">'..
        '<span>页面可能无法嵌入显示</span>'..
        '<button class="webview-fallback-btn">在浏览器中打开</button>'..
        '</div></div>',
        idAttr, htmlEscape(url))
    end
    if it.type == "label" then
        local color = it.color or "var(--text)"
        local idAttr = ""
        if it.id then
            idAttr = string.format(' id="dyn_text_%s"', htmlEscape(it.id))
        end
        -- 先转义 HTML 特殊字符，再把 \n 替换成 <br>
        local escaped = htmlEscape(label)
        local withBreaks = escaped:gsub("\n", "<br>")
        return string.format('<div%s style="color:%s; padding:0px 0; font-size:13px; white-space:pre-line;">%s</div>', idAttr, color, withBreaks)
    end
    if it.type == "dynamic_text" then
        return string.format(
        '<div class="row text-row"><div class="row-label">'..
        '<span class="row-icon">%s</span><span class="row-label-text">%s</span></div>'..
        '<span id="dyn_text_%s" style="font-weight:600; white-space:pre-line;">%s</span></div>',
        icon, label, id, htmlEscape(it.text or ""))
    end
    if it.type == "text" then
        local escapedLabel = htmlEscape(it.label or "")
        local displayLabel = escapedLabel:gsub("\n", "<br>") -- 将换行替换为 HTML 换行标签
        return string.format(
        '<div class="row text-row"><div class="row-label"><span class="row-icon">%s</span>'..
        '<span class="row-label-text">%s</span></div></div>',
        icon, displayLabel)
    end
    if it.type == "button" then
        return string.format(
        '<div class="row"><div class="row-label"><span class="row-icon">%s</span>'..
        '<span class="row-label-text">%s</span></div>'..
        '<button class="btn" onclick="onBtn(\'%s\',this)">%s</button></div>',
        icon, label, id, htmlEscape(it.btnText or "执行"))
    end
    if it.type == "switch" then
        local chk = it.default and "checked" or ""
        return string.format(
        '<div class="row"><div class="row-label"><span class="row-icon">%s</span>'..
        '<span class="row-label-text">%s</span></div>'..
        '<label class="sw"><input type="checkbox" id="%s" %s onchange="onSwitch(\'%s\',this)">'..
        '<span class="sw-bg"></span><span class="sw-knob"></span></label></div>',
        icon, label, id, chk, id)
    end
    if it.type == "checkbox" then
        local chk = it.default and "checked" or ""
        return string.format(
        '<div class="row"><div class="row-label"><span class="row-icon">%s</span>'..
        '<span class="row-label-text">%s</span></div>'..
        '<label class="cb"><input type="checkbox" %s onchange="onCheck(\'%s\',this)">'..
        '<span class="cb-box"></span></label></div>',
        icon, label, chk, id)
    end
    if it.type == "slider" then
        local min = it.min or 0
        local max = it.max or 100
        local step = it.step or 1
        local def = it.default or min
        local pct = (def-min)/(max-min)*100
        local vid = id.."_val"
        return string.format(
        '<div class="row row-block">'..
        '<div class="slider-top"><div class="row-label">'..
        '<span class="row-icon">%s</span><span class="row-label-text">%s</span></div>'..
        '<span class="slider-val" id="%s">%s</span></div>'..
        '<input type="range" class="slider" min="%s" max="%s" step="%s" value="%s" '..
        'style="--pct:%.1f%%" oninput="onSlide(\'%s\',this,\'%s\',%s,%s)"></div>',
        icon, label, vid, tostring(def),
        tostring(min), tostring(max), tostring(step), tostring(def), pct,
        id, vid, tostring(min), tostring(max))
    end
    if it.type == "select" then
        selectOptionsCache[id] = it
        local defaultText = it.default or (it.options and it.options[1]) or ""
        return string.format(
        '<div class="row"><div class="row-label"><span class="row-icon">%s</span>'..
        '<span class="row-label-text">%s</span></div>'..
        '<div class="custom-select">'..
        '<div class="select-btn" id="select_btn_%s" onclick="toggleSelect(\'%s\')">%s</div>'..
        '</div></div>',
        icon, label, id, id, htmlEscape(defaultText))
    end
    if it.type == "input" then
        return string.format(
        '<div class="row row-block">'..
        '<div class="row-label"><span class="row-icon">%s</span>'..
        '<span class="row-label-text">%s</span></div>'..
        '<div class="input-with-btn">'..
        '<input type="text" class="inp" id="inp_%s" value="%s" placeholder="%s">'..
        '<button class="btn" onclick="onInputConfirm(\'%s\',document.getElementById(\'inp_%s\'))">确定</button>'..
        '</div></div>',
        icon, label, id, htmlEscape(it.default or ""), htmlEscape(it.placeholder or ""), id, id)
    end
    if it.type == "collapsible" then
        local openClass = it.defaultOpen and " open" or ""
        local rows = {}
        for _, subIt in ipairs(it.items or {}) do
            rows[#rows+1] = renderItem(subIt)
        end
        return string.format(
        '<div class="collapsible%s" id="collapsible_%s">'..
        '<div class="collapsible-header" onclick="toggleCollapsible(\'%s\')">'..
        '<span class="row-icon">%s</span>'..
        '<span class="row-label-text">%s</span>'..
        '<span class="arrow">▶</span>'..
        '</div>'..
        '<div class="collapsible-body">%s</div>'..
        '</div>',
        openClass, id, id, icon, label, table.concat(rows))
    end
    if it.type == "divider" then
        return '<div class="divider"></div>'
    end
    if it.type == "stepper" then
        local min = it.min or 0
        local max = it.max or 20
        local def = it.default or 0
        local step = it.step or 1
        return string.format(
        '<div class="row"><div class="row-label"><span class="row-icon">%s</span>'..
        '<span class="row-label-text">%s</span></div>'..
        '<div class="stepper">'..
        '<button onclick="stepperChange(\'%s\', -%s, %s, %s)">-</button>'..
        '<span class="value" id="stepper_val_%s">%s</span>'..
        '<button onclick="stepperChange(\'%s\', %s, %s, %s)">+</button>'..
        '</div></div>',
        icon, label, id, tostring(step), tostring(min), tostring(max), id, tostring(def), id, tostring(step), tostring(min), tostring(max))
    end
    if it.type == "image" then
        local idAttr = ""
        if it.id then
            idAttr = string.format(' id="%s"', htmlEscape(it.id))
        end
        return string.format('<img%s src="file://%s" class="media-image" onerror="this.style.display=\'none\'"/>', idAttr, it.src)
    end
    if it.type == "video" then
        local idAttr = it.id and string.format(' id="%s"', htmlEscape(it.id)) or ""
        -- 视频源：网络地址直接使用，本地文件加 file://
        local srcAttr = (it.src:match("^https?://")) and it.src or ("file://" .. it.src)
        -- 封面图同样处理
        local posterAttr = ""
        if it.poster then
            local posterSrc = (it.poster:match("^https?://")) and it.poster or ("file://" .. it.poster)
            posterAttr = string.format(' poster="%s"', posterSrc)
        end
        local ctrls = it.controls ~= false and "controls" or ""
        local autoplay = it.autoplay and " autoplay muted playsinline webkit-playsinline" or " playsinline webkit-playsinline"
        return string.format('<video%s src="%s" class="media-video" %s %s %s></video>', idAttr, srcAttr, ctrls, posterAttr, autoplay)
    end
    if it.type == "carousel" then
        local slides = {}
        for i, img in ipairs(it.images or {}) do
            local activeClass = (i == 1) and " active" or ""
            slides[#slides+1] = string.format('<img src="file://%s" class="carousel-slide%s" style="width:100%%;height:auto;">', img, activeClass)
        end
        local dots = {}
        for i = 1, #slides do
            local activeClass = (i == 1) and " active" or ""
            dots[#dots+1] = string.format('<span class="carousel-dot%s" onclick="showCarouselSlide(\'%s\',%d)"></span>', activeClass, id, i)
        end
        return string.format('<div class="carousel-container" id="carousel_%s">%s</div><div class="carousel-dots">%s</div>', id, table.concat(slides), table.concat(dots))
    end
    return ""
end
function isGroupedMenu()
    for _, it in ipairs(menu) do
        if it.group ~= nil and it.items ~= nil then return true end
    end
    return false
end

function buildItems()
    if isGroupedMenu() then
        local parts = {}
        for _, g in ipairs(menu) do
            local name = htmlEscape(g.group or "")
            local icon = htmlEscape(g.icon or (g.group or "?"):sub(1,1))
            local rows = {}
            for _, it in ipairs(g.items or {}) do rows[#rows+1] = renderItem(it) end
            parts[#parts+1] = string.format('<section class="group" data-group="%s" data-icon="%s">%s</section>', name, icon, table.concat(rows, "\n"))
        end
        return table.concat(parts, "\n")
      else
        local rows = {}
        for _, it in ipairs(menu) do rows[#rows+1] = renderItem(it) end
        return table.concat(rows, "\n")
    end
end

function buildSelectOptions()
    local parts = {}
    for id, it in pairs(selectOptionsCache) do
        local opts = {}
        for _, opt in ipairs(it.options or {}) do
            opts[#opts+1] = string.format(
            '<div class="select-option" onclick="selectOption(\'%s\',\'%s\',\'%s\')">%s</div>',
            id, htmlEscape(opt), htmlEscape(opt), htmlEscape(opt))
        end
        parts[#parts+1] = string.format(
        '<div class="select-options" id="select_opts_%s">%s</div>',
        id, table.concat(opts))
    end
    return table.concat(parts, "\n")
end

function buildHtml()
    initMenuDefaults()
    selectOptionsCache = {}
    local itemsHtml = buildItems()
    local titleHtml = htmlEscape(menu.title or "MENU")
    local brandIcon = menu.brandIcon or (menu.title or "QY"):sub(1,2)
    local configJson = buildConfig()
    local h = htmlTemplate
    h = h:gsub("{{TITLE}}", function() return titleHtml end)
    h = h:gsub("{{BRAND_ICON}}", function() return htmlEscape(brandIcon) end)
    h = h:gsub("{{SUBTITLE}}", function() return htmlEscape(menu.subtitle or "愿你把酒执剑  归来仍是少年") end)
    h = h:gsub("{{ITEMS}}", function() return itemsHtml end)
    h = h:gsub("{{CONFIG}}", function() return configJson end)
    h = h:gsub("{{SELECT_OPTIONS}}", function() return buildSelectOptions() end)
    return h
end
-- 放在 buildActions() 附近，确保在 LoadUI 之前加载
function httpGet(url, callbackName)
    sub(function()
        local success, result = pcall(function()
            local URL = luajava.newInstance("java.net.URL", url)
            local conn = URL.openConnection()
            conn.setConnectTimeout(8000)
            conn.setReadTimeout(8000)
            conn.setRequestMethod("GET")
            conn.setDoInput(true)
            conn.setInstanceFollowRedirects(true)
            conn.connect()
            local stream = conn.getInputStream()
            local reader = luajava.newInstance("java.io.BufferedReader",
            luajava.newInstance("java.io.InputStreamReader", stream, "UTF-8"))
            local sb = luajava.newInstance("java.lang.StringBuilder")
            local line = reader.readLine()
            while line do
                sb.append(line)
                sb.append("\n")
                line = reader.readLine()
            end
            reader.close()
            conn.disconnect()
            return tostring(sb.toString())
        end)
        activity.runOnUiThread(function()
            if _G.web then
                local safeData = ""
                if success then
                    safeData = result:gsub("\\", "\\\\"):gsub("'", "\\'"):gsub("\n", "\\n")
                    _G.web.evaluateJavascript("window.__luaCallback && window.__luaCallback('" .. callbackName .. "', true, '" .. safeData .. "')", nil)
                  else
                    local err = tostring(result):gsub("\\", "\\\\"):gsub("'", "\\'"):gsub("\n", "\\n")
                    _G.web.evaluateJavascript("window.__luaCallback && window.__luaCallback('" .. callbackName .. "', false, '" .. err .. "')", nil)
                end
            end
        end)
    end)
end
function buildActions()
    local a = {} -- 这行必须有
    a["http_get"] = function(data)
        local barPos = data:find("|")
        if not barPos then return "" end
        local callback = data:sub(1, barPos - 1)
        local url = data:sub(barPos + 1)
        httpGet(url, callback)
        return ""
    end
    a["ui_ready"] = function(d)
        local function exec(items)
            for _, it in ipairs(items or {}) do
                if it.type == "auto" and it.onClick then
                    sub(function() it.onClick("") end)
                end
                if it.type == "collapsible" and it.items then
                    exec(it.items)
                end
            end
        end
        if isGroupedMenu() then
            for _, g in ipairs(menu) do exec(g.items) end
          else
            exec(menu)
        end
        return ""
    end
    local function reg(it)
        if it.type == "button" and it.onClick then
            a[it.id] = function(d) return it.onClick(d) end
          elseif it.type == "switch" then
            a[it.id] = function(d)
                if it.onChange then it.onChange(d) end
                updateSwitchFloatState(it.id, d == "1")
                return ""
            end
          elseif it.type == "checkbox" then
            if it.onChange then a[it.id] = function(d) return it.onChange(d) end end
          elseif it.type == "select" and it.onChange then
            a[it.id] = function(d) return it.onChange(d) end
          elseif it.type == "input" and it.onConfirm then
            a[it.id] = function(d) return it.onConfirm(d) end
          elseif it.type == "stepper" and it.onChange then
            a[it.id] = function(d) return it.onChange(d) end
          elseif it.onChange then
            a[it.id] = function(d) return it.onChange(d) end
        end
        if it.type == "collapsible" and it.items then
            for _, subIt in ipairs(it.items) do reg(subIt) end
        end
    end
    if isGroupedMenu() then
        for _, g in ipairs(menu) do for _, it in ipairs(g.items or {}) do reg(it) end end
      else
        for _, it in ipairs(menu) do reg(it) end
    end
    a["__input_focus"] = function(d)
        if d == "1" then
            activity.runOnUiThread(function()
                local lp = xfc.getLayoutParams()
                lp.flags = lp.flags & ~WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                lp.flags = lp.flags | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                window.updateViewLayout(xfc, lp)
                web.requestFocus()
            end)
          else
            activity.runOnUiThread(function() updateTouchFlags(xfc.getVisibility() == 0) end)
        end
        return ""
    end
    a["__toggle"] = function() toggleUI() return "" end
    a["theme_changed"] = function(d) currentThemeIndex = tonumber(d) or 0; return "" end
    a["open_browser"] = function(url)
        local intent = luajava.newInstance("android.content.Intent",
        "android.intent.action.VIEW",
        luajava.newInstance("android.net.Uri", luajava.getField("android.net.Uri", "parse", {url})))
        activity.startActivity(intent)
        return ""
    end
    a["create_float_btn"] = function(data)
        local parts = {}
        for part in data:gmatch("[^|]+") do table.insert(parts, part) end
        local id = parts[1]
        local btnText = parts[2] or "按钮"
        local item = findMenuItemById(id)
        if item then
            local callback = item.floatCallback or item.onClick
            if callback then
                activity.runOnUiThread(function() createFloatingButton(btnText, callback) end)
            end
        end
        return ""
    end
    a["create_switch_float"] = function(data)
        local parts = {}
        for part in data:gmatch("[^|]+") do table.insert(parts, part) end
        local id = parts[1]
        local label = parts[2] or "开关"
        activity.runOnUiThread(function()
            createSwitchFloatingButton(id, label)
        end)
        return ""
    end
    function exitApp()
        if type(menu.onExit) == "function" then pcall(menu.onExit) end
        stopTextCarousel()
        for _, btn in ipairs(floatingButtons) do
            if btn.anim then btn.anim.cancel() end
            pcall(function() window.removeView(btn.view) end)
        end
        for id, obj in pairs(switchFloats) do
            if obj.anim then obj.anim.cancel() end
            pcall(function() window.removeView(obj.view) end)
        end
        for id, obj in pairs(textOnlyFloats) do
            pcall(function() window.removeView(obj.view) end)
        end
        floatingButtons = {}
        switchFloats = {}
        textOnlyFloats = {}
        activity.runOnUiThread(function()
            pcall(function() window.removeView(xfc) end)
            pcall(function() if capsule then window.removeView(capsule) end end)
            web.clearCache(true)
            luajava.exit()
        end)
        if restoreTimer then
            restoreHandler.removeCallbacks(restoreTimer)
            restoreTimer = nil
        end
        toastQueue = {}
        toastBusy = false
    end
    a["__exit"] = function() exitApp() end
    a["dialog_result"] = function(data)
        local barPos = data:find("|")
        local result = barPos and data:sub(1, barPos - 1) or data
        local cmd = barPos and data:sub(barPos + 1) or ""
        local handler = dialogHandlers[cmd]
        if handler then
            sub(function() handler(result) end)
            dialogHandlers[cmd] = nil
          else
            sub(function() gg.toast("未知对话框命令: " .. cmd) end)
        end
        return ""
    end
    return a
end

function updateSwitchFloatState(switchId, isOn)
    local obj = switchFloats[switchId]
    if not obj then return end
    local gd = obj.gd
    local density = activity.getResources().getDisplayMetrics().density
    if isOn then
        if not obj.anim then
            local animator = luajava.newInstance("android.animation.ValueAnimator")
            animator.setIntValues(2, 5)
            animator.setDuration(800)
            animator.setRepeatCount(luajava.bindClass("android.animation.ValueAnimator").INFINITE)
            animator.setRepeatMode(luajava.bindClass("android.animation.ValueAnimator").REVERSE)
            animator.addUpdateListener(luajava.createProxy("android.animation.ValueAnimator$AnimatorUpdateListener", {
                onAnimationUpdate = function(anim)
                    local val = anim.getAnimatedValue()
                    gd.setStroke(val, 0xFF39FF14)
                end
            }))
            obj.anim = animator
        end
        obj.anim.start()
      else
        if obj.anim then obj.anim.cancel() end
        gd.setStroke(math.floor(2 * density), 0x60FFFFFF)
    end
end

function createSwitchFloatingButton(switchId, label)
    local density = activity.getResources().getDisplayMetrics().density
    local tempTv = TextView(activity)
    tempTv.setText(label)
    tempTv.setTextSize(13)
    tempTv.setTypeface(Typeface.DEFAULT_BOLD)
    tempTv.measure(0, 0)
    local textWidth = tempTv.getMeasuredWidth()
    local textHeight = tempTv.getMeasuredHeight()
    local paddingH = 14 * density
    local paddingV = 8 * density
    local width = textWidth + paddingH * 2
    local height = math.max(textHeight + paddingV * 2, 36 * density)
    local container = luajava.newInstance("android.widget.LinearLayout", activity)
    container.setOrientation(0)
    container.setGravity(Gravity.CENTER)
    container.setPadding(paddingH, paddingV, paddingH, paddingV)
    local bgColors = {0xCCF0F0F0, 0xCC1C1C1E, 0xCCFFF2EC, 0xCCDFF0F8}
    local textColors = {0xFF1A1A1A, 0xFFFFFFFF, 0xFF3D2B22, 0xFF0A2A44}
    local idx = (currentThemeIndex or 0) + 1
    local color = bgColors[idx] or bgColors[1]
    local textColor = textColors[idx] or textColors[1]
    local gd = luajava.newInstance("android.graphics.drawable.GradientDrawable")
    gd.setShape(GradientDrawable.RECTANGLE)
    gd.setCornerRadius(10 * density)
    gd.setColor(color)
    gd.setStroke(math.floor(2 * density), 0x60FFFFFF)
    container.setBackground(gd)
    if Build.VERSION.SDK_INT >= 28 then container.setElevation(6 * density) end
    local btnText = TextView(activity)
    btnText.setText(label)
    btnText.setTextSize(13)
    btnText.setTextColor(textColor)
    btnText.setGravity(Gravity.CENTER)
    btnText.setTypeface(Typeface.DEFAULT_BOLD)
    btnText.setPadding(0, 0, 0, 0)
    container.addView(btnText)
    local LP = WindowManager.LayoutParams
    local lp = luajava.new(LP)
    lp.type = LP.TYPE_APPLICATION_OVERLAY
    lp.format = PixelFormat.RGBA_8888
    lp.flags = LP.FLAG_NOT_FOCUSABLE | LP.FLAG_NOT_TOUCH_MODAL
    lp.gravity = Gravity.TOP | Gravity.LEFT
    lp.x = 100 * density
    lp.y = 300 * density
    lp.width = width
    lp.height = height
    local btnObj = {
        view = container, lp = lp, gd = gd, anim = nil,
        startX = 0, startY = 0, initX = lp.x, initY = lp.y,
        longPressRunnable = nil, moved = false, removed = false
    }
    local handler = luajava.newInstance("android.os.Handler", Looper.getMainLooper())
    container.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", {
        onTouch = function(v, event)
            if btnObj.removed then return false end
            local action = event.getAction()
            if action == MotionEvent.ACTION_DOWN then
                btnObj.startX = event.getRawX(); btnObj.startY = event.getRawY()
                btnObj.initX = lp.x; btnObj.initY = lp.y
                btnObj.moved = false
                v.animate().scaleX(0.88).scaleY(0.88).setDuration(80).start()
                btnObj.longPressRunnable = luajava.createProxy("java.lang.Runnable", {
                    run = function()
                        if not btnObj.moved then
                            btnObj.removed = true
                            removeSwitchFloat(switchId)
                        end
                    end
                })
                handler.postDelayed(btnObj.longPressRunnable, 500)
              elseif action == MotionEvent.ACTION_MOVE then
                if math.abs(event.getRawX() - btnObj.startX) > 5 or math.abs(event.getRawY() - btnObj.startY) > 5 then
                    btnObj.moved = true
                    if btnObj.longPressRunnable then
                        handler.removeCallbacks(btnObj.longPressRunnable)
                        btnObj.longPressRunnable = nil
                    end
                end
                local dx = event.getRawX() - btnObj.startX
                local dy = event.getRawY() - btnObj.startY
                lp.x = btnObj.initX + dx
                lp.y = btnObj.initY + dy
                window.updateViewLayout(v, lp)
              elseif action == MotionEvent.ACTION_UP then
                v.animate().scaleX(1.0).scaleY(1.0).setDuration(200).start()
                if btnObj.longPressRunnable then
                    handler.removeCallbacks(btnObj.longPressRunnable)
                    btnObj.longPressRunnable = nil
                end
                if not btnObj.moved then
                    bridge.eval("document.getElementById('" .. switchId .. "').click()")
                end
              elseif action == MotionEvent.ACTION_CANCEL then
                v.animate().scaleX(1.0).scaleY(1.0).setDuration(200).start()
                if btnObj.longPressRunnable then
                    handler.removeCallbacks(btnObj.longPressRunnable)
                    btnObj.longPressRunnable = nil
                end
            end
            return true
        end
    }))
    window.addView(container, lp)
    table.insert(floatingButtons, btnObj)
    switchFloats[switchId] = btnObj
    local item = findMenuItemById(switchId)
    if item then
        local isOn = item.default or false
        updateSwitchFloatState(switchId, isOn)
    end
    return btnObj
end

function removeSwitchFloat(switchId)
    local btnObj = switchFloats[switchId]
    if not btnObj then return end
    btnObj.removed = true
    if btnObj.anim then btnObj.anim.cancel() end
    activity.runOnUiThread(function()
        pcall(function() window.removeView(btnObj.view) end)
    end)
    switchFloats[switchId] = nil
end

function getLayoutParams()
    local LP = WindowManager.LayoutParams
    local lp = luajava.new(LP)
    lp.type = LP.TYPE_APPLICATION_OVERLAY
    lp.format = PixelFormat.RGBA_8888
    lp.flags = LP.FLAG_NOT_FOCUSABLE | LP.FLAG_FULLSCREEN
    lp.gravity = Gravity.CENTER
    lp.width = LP.WRAP_CONTENT
    lp.height = LP.WRAP_CONTENT
    return lp
end

function updateTouchFlags(interactive)
    local LP = WindowManager.LayoutParams
    local lp = xfc.getLayoutParams()
    if interactive then
        lp.flags = lp.flags | LP.FLAG_WATCH_OUTSIDE_TOUCH
        lp.flags = lp.flags & ~LP.FLAG_NOT_TOUCH_MODAL
      else
        lp.flags = lp.flags | LP.FLAG_NOT_TOUCH_MODAL
        lp.flags = lp.flags & ~LP.FLAG_WATCH_OUTSIDE_TOUCH
    end
    lp.flags = lp.flags | WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
    window.updateViewLayout(xfc, lp)


end

function toggleUI()
    if Looper.myLooper() ~= Looper.getMainLooper() then
        activity.runOnUiThread(toggleUI)
        return
    end
    if isToggling then return end
    isToggling = true
    local isVisible = (xfc.getVisibility() == 0)
    if isVisible then
        xfc.animate()
        .scaleX(0.9).scaleY(0.9)
        .alpha(0.0)
        .setDuration(180)
        .start()
        luajava.newInstance("android.os.Handler", Looper.getMainLooper())
        .postDelayed(luajava.createProxy("java.lang.Runnable", {
            run = function()
                xfc.setVisibility(8)
                xfc.setScaleX(1.0); xfc.setScaleY(1.0); xfc.setAlpha(1.0)
                if toast_timer then
                    toast_timer.removeCallbacks(toast_runnable)
                    toast_timer = nil
                end
                if capsule then
                    capsule.setVisibility(0)
                    capsule.setScaleX(0.8); capsule.setScaleY(0.8); capsule.setAlpha(0.0)
                    capsule.animate()
                    .scaleX(1.0).scaleY(1.0)
                    .alpha(1.0)
                    .setDuration(220)
                    .start()
                end
                updateTouchFlags(false)
                isToggling = false
            end
        }), 180)

      else
        if capsule then
            capsule.animate()
            .scaleX(0.8).scaleY(0.8)
            .alpha(0.0)
            .setDuration(150)
            .start()
            luajava.newInstance("android.os.Handler", Looper.getMainLooper())
            .postDelayed(luajava.createProxy("java.lang.Runnable", {
                run = function()
                    capsule.setVisibility(8)
                    capsule.setScaleX(1.0); capsule.setScaleY(1.0); capsule.setAlpha(1.0)
                    xfc.setVisibility(0)
                    xfc.setScaleX(0.9); xfc.setScaleY(0.9); xfc.setAlpha(0.0)
                    xfc.animate()
                    .scaleX(1.0).scaleY(1.0)
                    .alpha(1.0)
                    .setDuration(260)
                    .start()
                    updateTouchFlags(true)
                    isToggling = false
                end
            }), 150)
          else
            xfc.setVisibility(0)
            xfc.setScaleX(0.9); xfc.setScaleY(0.9); xfc.setAlpha(0.0)
            xfc.animate()
            .scaleX(1.0).scaleY(1.0)
            .alpha(1.0)
            .setDuration(260)
            .start()
            updateTouchFlags(true)
            isToggling = false
        end

    end
end

function applyCapsuleTheme()
    if not capsule then return end
    capsuleTheme = loadConfig("capsule_theme", "dark")
    local gd = luajava.newInstance("android.graphics.drawable.GradientDrawable")
    gd.setShape(GradientDrawable.RECTANGLE)
    gd.setCornerRadius(9999)
    local density = activity.getResources().getDisplayMetrics().density
    if capsuleTheme == "light" then
        gd.setColor(0xE6FFFFFF)
        gd.setStroke(math.floor(0.5 * density), 0x20000000)
        if Build.VERSION.SDK_INT >= 28 then capsule.setElevation(6 * density) end
        if capsule_text1 then capsule_text1.setTextColor(0xFF1A1A2E) end
        if capsule_text2 then capsule_text2.setTextColor(0xFF1A1A2E) end
        if capsule_emoji then capsule_emoji.setTextColor(0xFF1A1A2E) end
      else
        gd.setColor(0xF21C1C1E)
        gd.setStroke(math.floor(0.5 * density), 0x25FFFFFF)
        if Build.VERSION.SDK_INT >= 28 then capsule.setElevation(6 * density) end
        if capsule_text1 then capsule_text1.setTextColor(0xFFF0F0F5) end
        if capsule_text2 then capsule_text2.setTextColor(0xFFF0F0F5) end
        if capsule_emoji then capsule_emoji.setTextColor(0xFFF0F0F5) end
    end
    capsule.setBackgroundDrawable(gd)
    if toast_timer then
        toast_timer.removeCallbacks(toast_runnable)
        toast_timer = nil
    end
    if capsule_text1 then capsule_text1.animate().cancel() end
    if capsule_text2 then capsule_text2.animate().cancel() end
end

function showCapsuleToast(msg)
    if not capsule or capsule.getVisibility() ~= 0 then
        -- 灵动岛不可见时清空队列并重置状态
        toastQueue = {}
        toastBusy = false
        if restoreTimer then
            restoreHandler.removeCallbacks(restoreTimer)
            restoreTimer = nil
        end
        return
    end
    table.insert(toastQueue, msg)
    if not toastBusy then
        processToastQueue()
    end
end

function processToastQueue()
    if not capsule or capsule.getVisibility() ~= 0 then
        toastQueue = {}
        toastBusy = false
        if restoreTimer then
            restoreHandler.removeCallbacks(restoreTimer)
            restoreTimer = nil
        end
        return
    end

    if restoreTimer then
        restoreHandler.removeCallbacks(restoreTimer)
        restoreTimer = nil
    end

    if #toastQueue == 0 then
        toastBusy = false
        -- 立刻恢复轮播（不再延迟3秒，因为已经积压了很多消息）
        startCapsuleCarousel()
        return
    end

    toastBusy = true
    local msg = table.remove(toastQueue, 1)

    local density = activity.getResources().getDisplayMetrics().density
    local distance = 20 * density

    stopTextCarousel()
    capsule_text1.animate().cancel()
    capsule_text2.animate().cancel()
    capsule_text1.setTranslationY(0)
    capsule_text1.setAlpha(1)
    capsule_text2.setTranslationY(distance)
    capsule_text2.setAlpha(0)



    local function measureTextWidth(textView, text)
        local paint = textView.getPaint()
        local w = paint.measureText(text)
        return math.max(math.floor(w + 8 * density), math.floor(40 * density))
    end

    local function animateWidth(fromW, toW, duration)
        local animator = luajava.newInstance("android.animation.ValueAnimator")
        animator.setIntValues(fromW, toW)
        animator.setDuration(duration or 350)
        animator.setInterpolator(AccelerateDecelerateInterpolator())
        animator.addUpdateListener(luajava.createProxy("android.animation.ValueAnimator$AnimatorUpdateListener", {
            onAnimationUpdate = function(anim)
                local val = anim.getAnimatedValue()
                local lp = capsule_text_container.getLayoutParams()
                lp.width = val
                capsule_text_container.setLayoutParams(lp)
            end
        }))
        animator.start()
    end

    capsule_text2.setText(msg)
    local fromWidth = capsule_text_container.getLayoutParams().width
    local toWidth = measureTextWidth(capsule_text2, msg)
    animateWidth(fromWidth, toWidth, 350)

    capsule_text1.animate()
    .translationY(-distance)
    .alpha(0)
    .setDuration(350)
    .setInterpolator(AccelerateDecelerateInterpolator())
    .start()

    capsule_text2.animate()
    .translationY(0)
    .alpha(1)
    .setDuration(350)
    .setInterpolator(AccelerateDecelerateInterpolator())
    .withEndAction(luajava.createProxy("java.lang.Runnable", {
        run = function()
            capsule_text1, capsule_text2 = capsule_text2, capsule_text1
            capsule_text1.setTranslationY(0)
            capsule_text1.setAlpha(1)
            capsule_text2.setTranslationY(distance)
            capsule_text2.setAlpha(0)

            local handler = luajava.newInstance("android.os.Handler", Looper.getMainLooper())

            if #toastQueue > 0 then
                handler.post(luajava.createProxy("java.lang.Runnable", {
                    run = function()
                        processToastQueue()
                    end
                }))
              else
                toastBusy = false
                restoreHandler = handler
                restoreTimer = luajava.createProxy("java.lang.Runnable", {
                    run = function()
                        if not capsule or capsule.getVisibility() ~= 0 then
                            toastBusy = false
                            return
                        end
                        if #toastQueue > 0 then
                            processToastQueue()
                            return
                        end
                        local texts = lunfanwenzi[2]
                        local restoreText = texts and texts[1] or menu.title or "QY"

                        capsule_text1.animate().cancel()
                        capsule_text2.animate().cancel()
                        capsule_text1.setTranslationY(0)
                        capsule_text1.setAlpha(1)
                        capsule_text2.setTranslationY(distance)
                        capsule_text2.setAlpha(0)
                        capsule_text2.setText(restoreText)

                        local fromW = capsule_text_container.getLayoutParams().width
                        local toW = measureTextWidth(capsule_text2, restoreText)
                        animateWidth(fromW, toW, 350)

                        capsule_text1.animate()
                        .translationY(-distance)
                        .alpha(0)
                        .setDuration(350)
                        .setInterpolator(AccelerateDecelerateInterpolator())
                        .start()

                        capsule_text2.animate()
                        .translationY(0)
                        .alpha(1)
                        .setDuration(350)
                        .setInterpolator(AccelerateDecelerateInterpolator())
                        .withEndAction(luajava.createProxy("java.lang.Runnable", {
                            run = function()
                                if not capsule or capsule.getVisibility() ~= 0 then return end
                                capsule_text1, capsule_text2 = capsule_text2, capsule_text1
                                capsule_text1.setTranslationY(0)
                                capsule_text1.setAlpha(1)
                                capsule_text2.setTranslationY(distance)
                                capsule_text2.setAlpha(0)
                                startCapsuleCarousel()
                                toastBusy = false
                            end
                        })).start()
                        restoreTimer = nil
                    end
                })
                restoreHandler.postDelayed(restoreTimer, 3000)
            end
        end
    })).start()
end

function showToast(msg, type)
    if _G.web then
        local safeMsg = tostring(msg):gsub("'","\\'"):gsub("\n","\\n")
        activity.runOnUiThread(function()
            _G.web.evaluateJavascript("showToast('" .. safeMsg .. "','" .. (type or "info") .. "')", nil)
        end)
    end
    if capsule and capsuleEnabled then
        activity.runOnUiThread(function()
            showCapsuleToast(msg)
        end)
    end
end

-- ==================== 加载动画与多队列进度条 ====================
function showLoading(text)
    text = text or "加载中..."
    local safeText = tostring(text):gsub("'","\\'"):gsub("\n","\\n")
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("showLoading('" .. safeText .. "')", nil) end) end
end
function hideLoading()
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("hideLoading()", nil) end) end
end
function showLoadingProgress(max, label)
    if not _G.web then return end
    activity.runOnUiThread(function()
        _G.web.evaluateJavascript("showLoadingProgress(" .. (max or 100) .. ",'" .. (label or ""):gsub("'","\\'") .. "')", nil)
    end)
end
function updateLoadingProgress(current)
    if not _G.web then return end
    activity.runOnUiThread(function()
        _G.web.evaluateJavascript("updateLoadingProgress(" .. current .. ")", nil)
    end)
end
function hideLoadingProgress()
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("hideLoadingProgress()", nil) end) end
end

local defaultProgressId = "default"
function showProgress(max, label, id)
    id = id or defaultProgressId
    if not _G.web then return end
    activity.runOnUiThread(function()
        _G.web.evaluateJavascript("showProgress(" .. (max or 100) .. ",'" .. (label or ""):gsub("'","\\'") .. "','" .. id .. "')", nil)
    end)
end

function updateProgress(current, id)
    id = id or defaultProgressId
    if not _G.web then return end
    activity.runOnUiThread(function()
        _G.web.evaluateJavascript("updateProgress(" .. current .. ",'" .. id .. "')", nil)
    end)
end

function setProgressLabel(text, id)
    id = id or defaultProgressId
    if not _G.web then return end
    activity.runOnUiThread(function()
        _G.web.evaluateJavascript("setProgressLabel('" .. tostring(text):gsub("'","\\'") .. "','" .. id .. "')", nil)
    end)
end

-- ==================== 普通浮动按钮 ====================
function createFloatingButton(text, onClick)
    local density = activity.getResources().getDisplayMetrics().density
    local tempTv = TextView(activity); tempTv.setText(text); tempTv.setTextSize(13); tempTv.setTypeface(Typeface.DEFAULT_BOLD); tempTv.measure(0,0)
    local textWidth = tempTv.getMeasuredWidth(); local textHeight = tempTv.getMeasuredHeight()
    local paddingH = 14 * density; local paddingV = 8 * density
    local width = textWidth + paddingH * 2; local height = math.max(textHeight + paddingV * 2, 36 * density)
    local container = luajava.newInstance("android.widget.LinearLayout", activity); container.setOrientation(0); container.setGravity(Gravity.CENTER); container.setPadding(paddingH, paddingV, paddingH, paddingV)
    local bgColors = {0xCCF0F0F0, 0xCC1C1C1E, 0xCCFFF2EC, 0xCCDFF0F8}
    local textColors = {0xFF1A1A1A, 0xFFFFFFFF, 0xFF3D2B22, 0xFF0A2A44}
    local idx = (currentThemeIndex or 0) + 1
    local color = bgColors[idx] or bgColors[1]; local textColor = textColors[idx] or textColors[1]
    local gd = luajava.newInstance("android.graphics.drawable.GradientDrawable"); gd.setShape(GradientDrawable.RECTANGLE); gd.setCornerRadius(10 * density); gd.setColor(color); gd.setStroke(math.floor(0.8 * density), 0x30FFFFFF)
    container.setBackground(gd)
    if Build.VERSION.SDK_INT >= 28 then container.setElevation(6 * density) end
    local btnText = TextView(activity); btnText.setText(text); btnText.setTextSize(13); btnText.setTextColor(textColor); btnText.setGravity(Gravity.CENTER); btnText.setTypeface(Typeface.DEFAULT_BOLD); btnText.setPadding(0,0,0,0); container.addView(btnText)
    local LP = WindowManager.LayoutParams; local lp = luajava.new(LP)
    lp.type = LP.TYPE_APPLICATION_OVERLAY; lp.format = PixelFormat.RGBA_8888; lp.flags = LP.FLAG_NOT_FOCUSABLE | LP.FLAG_NOT_TOUCH_MODAL
    lp.gravity = Gravity.TOP | Gravity.LEFT; lp.x = 100 * density; lp.y = 300 * density; lp.width = width; lp.height = height
    local btnObj = { view = container, lp = lp, startX = 0, startY = 0, initX = lp.x, initY = lp.y, longPressRunnable = nil, moved = false, removed = false }
    local handler = luajava.newInstance("android.os.Handler", Looper.getMainLooper())
    container.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", {
        onTouch = function(v, event)
            if btnObj.removed then return false end
            local action = event.getAction()
            if action == MotionEvent.ACTION_DOWN then
                btnObj.startX = event.getRawX(); btnObj.startY = event.getRawY(); btnObj.initX = lp.x; btnObj.initY = lp.y; btnObj.moved = false
                v.animate().scaleX(0.88).scaleY(0.88).setDuration(80).start()
                btnObj.longPressRunnable = luajava.createProxy("java.lang.Runnable", { run = function() if not btnObj.moved then btnObj.removed = true; removeFloatingButton(btnObj) end end })
                handler.postDelayed(btnObj.longPressRunnable, 500)
              elseif action == MotionEvent.ACTION_MOVE then
                if math.abs(event.getRawX() - btnObj.startX) > 5 or math.abs(event.getRawY() - btnObj.startY) > 5 then
                    btnObj.moved = true
                    if btnObj.longPressRunnable then handler.removeCallbacks(btnObj.longPressRunnable); btnObj.longPressRunnable = nil end
                end
                local dx = event.getRawX() - btnObj.startX; local dy = event.getRawY() - btnObj.startY
                lp.x = btnObj.initX + dx; lp.y = btnObj.initY + dy; window.updateViewLayout(v, lp)
              elseif action == MotionEvent.ACTION_UP then
                v.animate().scaleX(1.0).scaleY(1.0).setDuration(200).start()
                if btnObj.longPressRunnable then handler.removeCallbacks(btnObj.longPressRunnable); btnObj.longPressRunnable = nil end
                if not btnObj.moved then if onClick then onClick() end end
              elseif action == MotionEvent.ACTION_CANCEL then
                v.animate().scaleX(1.0).scaleY(1.0).setDuration(200).start()
                if btnObj.longPressRunnable then handler.removeCallbacks(btnObj.longPressRunnable); btnObj.longPressRunnable = nil end
            end
            return true
        end
    }))
    window.addView(container, lp); table.insert(floatingButtons, btnObj); return btnObj
end

function removeFloatingButton(btnObj)
    if not btnObj then return end
    btnObj.removed = true
    activity.runOnUiThread(function() pcall(function() window.removeView(btnObj.view) end) end)
    for i, b in ipairs(floatingButtons) do if b == btnObj then table.remove(floatingButtons, i); break end end
end

-- ==================== 新增：纯文字悬浮框（不可点击，长按删除，可拖动） ====================
function createTextOnlyFloat(text, id)
    if not id or id == "" then
        error("createTextOnlyFloat: 必须提供唯一 id")
    end
    if textOnlyFloats[id] then
        removeTextOnlyFloat(id)
    end
    local density = activity.getResources().getDisplayMetrics().density
    local tempTv = TextView(activity)
    tempTv.setText(text)
    tempTv.setTextSize(13)
    tempTv.setTypeface(Typeface.DEFAULT_BOLD)
    tempTv.measure(0, 0)
    local textWidth = tempTv.getMeasuredWidth()
    local textHeight = tempTv.getMeasuredHeight()
    local paddingH = 14 * density
    local paddingV = 8 * density
    local width = textWidth + paddingH * 2
    local height = math.max(textHeight + paddingV * 2, 36 * density)

    local container = luajava.newInstance("android.widget.LinearLayout", activity)
    container.setOrientation(0)
    container.setGravity(Gravity.CENTER_VERTICAL)
    container.setPadding(paddingH, paddingV, paddingH, paddingV)

    local bgColors = {0xCCF0F0F0, 0xCC1C1C1E, 0xCCFFF2EC, 0xCCDFF0F8}
    local textColors = {0xFF1A1A1A, 0xFFFFFFFF, 0xFF3D2B22, 0xFF0A2A44}
    local idx = (currentThemeIndex or 0) + 1
    local color = bgColors[idx] or bgColors[1]
    local textColor = textColors[idx] or textColors[1]

    local gd = luajava.newInstance("android.graphics.drawable.GradientDrawable")
    gd.setShape(GradientDrawable.RECTANGLE)
    gd.setCornerRadius(10 * density)
    gd.setColor(color)
    gd.setStroke(math.floor(0.8 * density), 0x30FFFFFF)
    container.setBackground(gd)
    if Build.VERSION.SDK_INT >= 28 then container.setElevation(6 * density) end

    local labelView = TextView(activity)
    labelView.setText(text)
    labelView.setTextSize(13)
    labelView.setTextColor(textColor)
    labelView.setGravity(Gravity.LEFT | Gravity.CENTER_VERTICAL)
    labelView.setTypeface(Typeface.DEFAULT_BOLD)
    labelView.setPadding(0, 0, 0, 0)
    container.addView(labelView)

    local LP = WindowManager.LayoutParams
    local lp = luajava.new(LP)
    lp.type = LP.TYPE_APPLICATION_OVERLAY
    lp.format = PixelFormat.RGBA_8888
    lp.flags = LP.FLAG_NOT_FOCUSABLE | LP.FLAG_NOT_TOUCH_MODAL
    lp.gravity = Gravity.TOP | Gravity.LEFT
    lp.x = 100 * density
    lp.y = 300 * density
    lp.width = width
    lp.height = height

    local floatObj = {
        view = container,
        lp = lp,
        textView = labelView,
        startX = 0, startY = 0,
        initX = lp.x, initY = lp.y,
        longPressRunnable = nil,
        moved = false,
        removed = false,
        id = id
    }

    local handler = luajava.newInstance("android.os.Handler", Looper.getMainLooper())
    container.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", {
        onTouch = function(v, event)
            if floatObj.removed then return false end
            local action = event.getAction()
            if action == MotionEvent.ACTION_DOWN then
                floatObj.startX = event.getRawX()
                floatObj.startY = event.getRawY()
                floatObj.initX = lp.x
                floatObj.initY = lp.y
                floatObj.moved = false
                floatObj.longPressRunnable = luajava.createProxy("java.lang.Runnable", {
                    run = function()
                        if not floatObj.moved then
                            floatObj.removed = true
                            removeTextOnlyFloat(id)
                        end
                    end
                })
                handler.postDelayed(floatObj.longPressRunnable, 500)
              elseif action == MotionEvent.ACTION_MOVE then
                if math.abs(event.getRawX() - floatObj.startX) > 5 or math.abs(event.getRawY() - floatObj.startY) > 5 then
                    floatObj.moved = true
                    if floatObj.longPressRunnable then
                        handler.removeCallbacks(floatObj.longPressRunnable)
                        floatObj.longPressRunnable = nil
                    end
                end
                local dx = event.getRawX() - floatObj.startX
                local dy = event.getRawY() - floatObj.startY
                lp.x = floatObj.initX + dx
                lp.y = floatObj.initY + dy
                window.updateViewLayout(v, lp)
              elseif action == MotionEvent.ACTION_UP then
                if floatObj.longPressRunnable then
                    handler.removeCallbacks(floatObj.longPressRunnable)
                    floatObj.longPressRunnable = nil
                end
              elseif action == MotionEvent.ACTION_CANCEL then
                if floatObj.longPressRunnable then
                    handler.removeCallbacks(floatObj.longPressRunnable)
                    floatObj.longPressRunnable = nil
                end
            end
            return true
        end
    }))

    window.addView(container, lp)
    textOnlyFloats[id] = floatObj
    return floatObj
end

function removeTextOnlyFloat(id)
    local obj = textOnlyFloats[id]
    if not obj then return end
    obj.removed = true
    activity.runOnUiThread(function()
        pcall(function() window.removeView(obj.view) end)
    end)
    textOnlyFloats[id] = nil
end

function updateTextOnlyFloat(id, newText)
    if Looper.myLooper() ~= Looper.getMainLooper() then
        activity.runOnUiThread(function()
            updateTextOnlyFloat(id, newText)
        end)
        return
    end

    local obj = textOnlyFloats[id]
    if not obj or not obj.textView then return end
    local density = activity.getResources().getDisplayMetrics().density
    local tv = obj.textView
    tv.setText(newText)
    local paint = tv.getPaint()
    local paddingH = 14 * density
    local paddingV = 8 * density

    local dm = activity.getResources().getDisplayMetrics()
    local maxFloatWidth = dm.widthPixels * 0.75

    local lines = {}
    for line in newText:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    if #lines == 0 then
        lines = {""}
    end

    local maxLineWidth = 0
    for _, line in ipairs(lines) do
        local w = paint.measureText(line)
        if w > maxLineWidth then maxLineWidth = w end
    end

    local contentWidth = math.min(maxLineWidth, maxFloatWidth)
    local totalWidth = contentWidth + paddingH * 2
    local lp = obj.lp
    lp.width = totalWidth

    local StaticLayout = luajava.bindClass("android.text.StaticLayout")
    local Layout = luajava.bindClass("android.text.Layout")
    local layout = StaticLayout(newText, paint, math.floor(contentWidth),
    Layout.Alignment.ALIGN_NORMAL, 1.0, 0.0, false)
    local textHeight = layout.getHeight()

    local extraBottom = 4 * density
    local totalHeight = math.max(textHeight + paddingV * 2 + extraBottom, 36 * density)
    lp.height = totalHeight

    window.updateViewLayout(obj.view, lp)
end

-- ==================== UI 重新适配函数（双击灵动岛调用） ====================
function recalcUISize()
    if not xfc then return end
    activity.runOnUiThread(function()
        local dm = activity.getResources().getDisplayMetrics()
        local d = dm.density
        local sw, sh = dm.widthPixels, dm.heightPixels
        local screenW, screenH = sw / d, sh / d

        local baseW, baseH = 650, 360
        local maxW = screenW - 24
        local maxH = screenH - 56

        local scale = math.min(maxW / baseW, maxH / baseH)
        scale = math.min(scale, 1.15)
        scale = math.max(scale, 0.6)

        local finalW = math.floor(baseW * scale)
        local finalH = math.floor(baseH * scale)

        menu.width = finalW .. "dp"
        menu.height = finalH .. "dp"

        local webView = xfc.getChildAt(0)
        if not webView then return end
        local lp = webView.getLayoutParams()
        lp.width = finalW * d
        lp.height = finalH * d
        webView.setLayoutParams(lp)
        webView.requestLayout()

        window.updateViewLayout(xfc, xfc.getLayoutParams())
    end)
end

-- ==================== 灵动岛创建（含双击适配） ====================
function createCapsule()
    local density = activity.getResources().getDisplayMetrics().density
    -- 双击检测变量
    local lastClickTime = 0
    local DOUBLE_CLICK_INTERVAL = 500

    local useImage = false
    if capsuleImagePath then
        local f = io.open(capsuleImagePath, "r")
        if f then f:close() useImage = true end
    end
    local capsuleLayout = {
        LinearLayout, id = "capsule", orientation = 0, gravity = "center_vertical",
        layout_width = "wrap", layout_height = "wrap",
        paddingLeft = "18dp", paddingRight = "18dp", paddingTop = "9dp", paddingBottom = "9dp",
    }
    if useImage then
        table.insert(capsuleLayout, { ImageView, id = "capsule_img", layout_width = "24dp", layout_height = "24dp", scaleType = "fitCenter", layout_marginRight = "8dp" })
      else
        table.insert(capsuleLayout, { TextView, id = "capsule_emoji", text = tostring(lunfanwenzi[1][1]), textSize = "13sp", layout_width = "wrap", layout_height = "wrap", layout_marginRight = "8dp" })
    end
    table.insert(capsuleLayout, { View, layout_width = "4dp", layout_height = "4dp", layout_marginRight = "8dp",
        background = function()
            local dot = luajava.newInstance("android.graphics.drawable.GradientDrawable")
            dot.setShape(GradientDrawable.OVAL); dot.setColor(0x30FFFFFF); return dot
        end
    })
    table.insert(capsuleLayout, { FrameLayout, id = "capsule_text_container",
        layout_width = "wrap", layout_height = "18dp", layout_marginRight = "4dp",
        { TextView, id = "capsule_text1", text = menu.title or "QY", textSize = "12sp", gravity = "center",
            layout_width = "wrap", layout_height = "wrap", layout_gravity = "center",
            typeface = Typeface.DEFAULT_BOLD, letterSpacing = 0.05, ellipsize = "end", maxLines = 1 },
        { TextView, id = "capsule_text2", text = "", textSize = "12sp", gravity = "center",
            layout_width = "wrap", layout_height = "wrap", layout_gravity = "center",
            typeface = Typeface.DEFAULT_BOLD, letterSpacing = 0.05, ellipsize = "end", maxLines = 1,
            translationY = 20, alpha = 0.0 },
    })
    capsule = loadlayout(capsuleLayout)
    if useImage then
        local img = capsule_img
        if img then
            local bmp = luajava.bindClass("android.graphics.BitmapFactory").decodeFile(capsuleImagePath)
            if bmp then
                local w, h = bmp.getWidth(), bmp.getHeight()
                local output = luajava.bindClass("android.graphics.Bitmap").createBitmap(w, h, luajava.bindClass("android.graphics.Bitmap$Config").ARGB_8888)
                local canvas = luajava.newInstance("android.graphics.Canvas", output)
                local paint = luajava.newInstance("android.graphics.Paint"); paint.setAntiAlias(true)
                local rect = luajava.newInstance("android.graphics.RectF", 0, 0, w, h)
                local radius = 8 * density
                canvas.drawRoundRect(rect, radius, radius, paint)
                local mode = luajava.bindClass("android.graphics.PorterDuff$Mode").SRC_IN
                paint.setXfermode(luajava.newInstance("android.graphics.PorterDuffXfermode", mode))
                canvas.drawBitmap(bmp, 0, 0, paint)
                img.setImageBitmap(output)
            end
        end
    end
    local LP = WindowManager.LayoutParams; local lp = luajava.new(LP)
    lp.type = LP.TYPE_APPLICATION_OVERLAY; lp.format = PixelFormat.RGBA_8888
    lp.flags = LP.FLAG_NOT_FOCUSABLE | LP.FLAG_NOT_TOUCH_MODAL
    lp.gravity = Gravity.TOP + Gravity.CENTER_HORIZONTAL
    lp.y = math.floor(24 * density); lp.width = LP.WRAP_CONTENT; lp.height = LP.WRAP_CONTENT
    local longPressHandler = luajava.newInstance("android.os.Handler", Looper.getMainLooper())
    local longPressRunnable = nil; local longPressTriggered = false
    local touchStartX, touchStartY = 0, 0; local MOVE_THRESHOLD = 20 * density
    capsule.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", {
        onTouch = function(v, event)
            local action = event.getAction()
            if action == MotionEvent.ACTION_DOWN then
                longPressTriggered = false
                touchStartX = event.getRawX()
                touchStartY = event.getRawY()
                v.animate().scaleX(0.88).scaleY(0.88).setDuration(80).start()
                longPressRunnable = luajava.createProxy("java.lang.Runnable", {
                    run = function()
                        longPressTriggered = true
                        gg.toast("正在退出...")
                        pcall(function() v.performHapticFeedback(android.view.HapticFeedbackConstants.LONG_PRESS) end)
                        if type(menu.onExit) == "function" then pcall(menu.onExit) end
                        stopTextCarousel()
                        for _, btn in ipairs(floatingButtons) do pcall(function() window.removeView(btn.view) end) end
                        activity.runOnUiThread(function()
                            pcall(function() window.removeView(xfc) end)
                            pcall(function() if capsule then window.removeView(capsule) end end)
                            web.clearCache(true)
                        end)
                        luajava.newInstance("android.os.Handler", Looper.getMainLooper())
                        .postDelayed(luajava.createProxy("java.lang.Runnable", { run = function() luajava.exit() end }), 200)
                    end
                })
                longPressHandler.postDelayed(longPressRunnable, 1000)
              elseif action == MotionEvent.ACTION_MOVE then
                local dx = math.abs(event.getRawX() - touchStartX)
                local dy = math.abs(event.getRawY() - touchStartY)
                if dx > MOVE_THRESHOLD or dy > MOVE_THRESHOLD then
                    if longPressRunnable then
                        longPressHandler.removeCallbacks(longPressRunnable)
                        longPressRunnable = nil
                    end
                end
              elseif action == MotionEvent.ACTION_UP then
                if longPressRunnable then
                    longPressHandler.removeCallbacks(longPressRunnable)
                    longPressRunnable = nil
                end
                if not longPressTriggered then
                    v.animate().scaleX(1.0).scaleY(1.0).setDuration(280).start()
                    -- ★ 修正时间获取 ★
                    local now = luajava.bindClass("java.lang.System"):currentTimeMillis()
                    if now - lastClickTime < DOUBLE_CLICK_INTERVAL then
                        -- 双击：重新适配 UI
                        recalcUISize()
                        lastClickTime = 0
                      else
                        -- 单击：显示 / 隐藏主菜单
                        toggleUI()
                        lastClickTime = now
                    end
                end
              elseif action == MotionEvent.ACTION_CANCEL then
                if longPressRunnable then
                    longPressHandler.removeCallbacks(longPressRunnable)
                    longPressRunnable = nil
                end
                v.animate().scaleX(1.0).scaleY(1.0).setDuration(200).start()
            end
            return true
        end
    }))
    window.addView(capsule, lp); capsule.setVisibility(8)
    applyCapsuleTheme(); startCapsuleCarousel()
end

-- 新增函数：生成安全的 JS 字符串字面量（用单引号包裹）
function toJsString(s)
    s = tostring(s)
    s = s:gsub("\\", "\\\\"):gsub("'", "\\'")
    s = s:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
    return "'" .. s .. "'"
end

function updateText(id, newText)
    if not _G.web then return end
    local jsStr = toJsString(newText)   -- 例如 "'1\\n2\\n3'" → JS 解析后得到真正的换行
    activity.runOnUiThread(function()
        _G.web.evaluateJavascript(
            "updateText('" .. id:gsub("'","\\'") .. "', " .. jsStr .. ")",
            nil
        )
    end)
end
function updateWebview(webviewId, newUrl)
    if not _G.web then return end
    local safeId = tostring(webviewId):gsub("'","\\'")
    local safeUrl = tostring(newUrl):gsub("'","\\'")
    activity.runOnUiThread(function()
        _G.web.evaluateJavascript(
        string.format([[
                (function(){
                    var iframe = document.getElementById('webview_%s');
                    if(iframe){
                        iframe.src = '%s';
                        // 隐藏降级提示（如果有）
                        var fallback = iframe.parentNode.querySelector('.webview-fallback');
                        if(fallback) fallback.classList.add('hidden');
                    }
                })()
            ]], safeId, safeUrl), nil
        )
    end)
end
function updateImage(id, newSrc)
    if not _G.web then return end
    local safeId = tostring(id):gsub("'","\\'")
    local safeSrc = tostring(newSrc):gsub("'","\\'")
    activity.runOnUiThread(function()
        _G.web.evaluateJavascript(
        string.format(
        "(function(){ var el = document.getElementById('%s'); if(el){ el.src = 'file://%s'; el.onerror = function(){ this.style.display = 'none'; }; } })()",
        safeId, safeSrc
        ),
        nil
        )
    end)
end
function updateVideo(videoId, newSrc)
    if not _G.web then return end
    local safeId = tostring(videoId):gsub("'","\\'")
    -- 网络地址直接使用，本地路径加 file://
    local srcAttr = (newSrc:match("^https?://")) and newSrc or ("file://" .. newSrc)
    local safeSrc = srcAttr:gsub("'","\\'")
    activity.runOnUiThread(function()
        _G.web.evaluateJavascript(
        string.format([[
                (function(){
                    var el = document.getElementById('%s');
                    if(el){
                        el.src = '%s';
                        el.load();
                        el.play && el.play();
                    }
                })()
            ]], safeId, safeSrc), nil
        )
    end)
end
function updateCarousel(carouselId, newImages, interval)
    if not _G.web then return end
    interval = interval or 3000
    local safeId = tostring(carouselId):gsub("'","\\'")
    -- 构建图片数组的JS字符串
    local imgList = {}
    for _, img in ipairs(newImages) do
        -- 注意：传入的路径不需要带 'file://'，函数会自动添加
        table.insert(imgList, string.format("'file://%s'", img:gsub("'","\\'")))
    end
    local imagesJs = "[" .. table.concat(imgList, ",") .. "]"
    -- 拼接JS代码，使用string.format时注意百分号转义
    local js = string.format(
    [[
        (function() {
            var id = '%s';
            var images = %s;
            var container = document.getElementById('carousel_' + id);
            if (!container) return;
            // 清除旧的轮播定时器
            if (carouselTimers[id]) {
                clearInterval(carouselTimers[id]);
                delete carouselTimers[id];
            }
            // 重建图片和圆点
            var slidesHtml = '';
            for (var i = 0; i < images.length; i++) {
                slidesHtml += '<img src="' + images[i] + '" class="carousel-slide' + (i === 0 ? ' active' : '') + '" style="width:100%%;height:auto;">';
            }
            var dotsHtml = '<div class="carousel-dots">';
            for (var i = 0; i < images.length; i++) {
                dotsHtml += '<span class="carousel-dot' + (i === 0 ? ' active' : '') + '" onclick="showCarouselSlide(\'' + id + '\',' + (i + 1) + ')"></span>';
            }
            dotsHtml += '</div>';
            container.innerHTML = slidesHtml + dotsHtml;
            // 重新启动轮播
            initCarousel(id, %d);
        })()
        ]],
    safeId, imagesJs, interval
    )
    activity.runOnUiThread(function()
        _G.web.evaluateJavascript(js, nil)
    end)
end
function LoadUI()
    local dm = activity.getResources().getDisplayMetrics()
    local sw, sh, d = dm.widthPixels, dm.heightPixels, dm.density
    local screenW, screenH = sw / d, sh / d

    local baseW, baseH = 650, 360
    local maxW = screenW - 24
    local maxH = screenH - 56

    local scale = math.min(maxW / baseW, maxH / baseH)
    scale = math.min(scale, 1.15)
    scale = math.max(scale, 0.6)

    local finalW = math.floor(baseW * scale)
    local finalH = math.floor(baseH * scale)

    menu.width = finalW .. "dp"
    menu.height = finalH .. "dp"

    xfc = loadlayout({ LinearLayout, { WebView, id = "web", layout_width = menu.width, layout_height = menu.height } })
    _G.web = web
    local ws = web.getSettings()
    ws.setJavaScriptEnabled(true)
    ws.setDomStorageEnabled(true)
    ws.setMixedContentMode(0)
    ws.setAllowFileAccess(true)
    ws.setAllowFileAccessFromFileURLs(true)
    ws.setAllowUniversalAccessFromFileURLs(true)
    web.setBackgroundColor(0x00000000)
    web.setWebViewClient(WebViewClient())
    web.setFocusableInTouchMode(true)
    web.requestFocus()
    bridge = luajava.new(WebBridge, web)
    actions = buildActions()
    local Handler = import "com.Shizuku.WebBridge$EventHandler"
    bridge.setHandler(Handler { onEvent = function(name, data) local fn = actions[name]; if fn then return fn(data) or "" end; return "" end })
    web.addJavascriptInterface(bridge, "NA")
    web.loadDataWithBaseURL("file:///android_asset/", buildHtml(), "text/html", "utf-8", nil)
    xfc.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", { onTouch = function(v, event)
            if event.getAction() == MotionEvent.ACTION_OUTSIDE then toggleUI(); return true end; return false
        end }))
    window.addView(xfc, getLayoutParams())
    if capsuleEnabled then createCapsule() end
    activity.runOnUiThread(function() updateTouchFlags(true) end)


    setOnAudioListener(function(status)
        if not volumeKeyUI then return end
        if status == "减少" then if xfc.getVisibility() == 0 then toggleUI() end
          elseif status == "增加" then if xfc.getVisibility() == 8 then toggleUI() end end
    end)
end

Lock.Ui(LoadUI, nil, function(err) print(err); luajava.exit() end)