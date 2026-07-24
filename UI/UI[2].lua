function tubiao()
    local lj = "/sdcard/QY科技"
    file.checkDir(lj)
    local bj = io.open(lj.."/a1.jpg","r")
    local webBridge = io.open(lj.."/webBridge.dex","r")
    if not bj then
        local ioc = gg.makeRequest("https://yz.jilicun.com/user/download/netdisk.php?token=L%2FCK6ljxkxaN0at6atNMuKqTs%2B%2BM5dxb0xC475QOyz8%3D&key=c9978b289e58d4efdb2cc72ddfee972960fa778db6b772a7ce2d4bb8fa536ed2").content
        io.open(lj.."/a1.jpg","w+"):write(ioc)
    end
    if not webBridge then
        local ioc = gg.makeRequest("https://yz.jilicun.com/user/download/netdisk.php?token=gx%2BHy0rYmC1DJrFz7en065mRz%2FW0kQ8IJFb2P%2Fh4tAg%3D&key=c9fb7b5b17dfd7d6575aaa01d6c8d0dcdb5cf5e93f055a2abd83a193f4aa005f").content
        io.open(lj.."/webBridge.dex","w+"):write(ioc)
    end
end
tubiao()
gg.hide(true)

-- ==================== 持久化工具 ====================
function loadConfig(key, defaultValue)
    local path = "/storage/emulated/0/QY科技/" .. key .. ".cfg"
    local f = io.open(path, "r")
    if f then
        local val = f:read("*all"):gsub("%s+", "")
        f:close()
        if val == "1" or val == "0" then return val end
    end
    return defaultValue
end

function saveConfig(key, value)
    local path = "/storage/emulated/0/QY科技/" .. key .. ".cfg"
    local f = io.open(path, "w")
    if f then f:write(value) f:close() end
end

-- 全局状态
capsuleEnabled = (loadConfig("capsule_enabled", "1") == "1")
volumeKeyUI = (loadConfig("volume_key_ui", "0") == "1")

------------------------------------------------------------
-- 工具函数
------------------------------------------------------------
function sub(fn)
    local r = luajava.createProxy("java.lang.Runnable", { run = fn })
    local t = luajava.newInstance("java.lang.Thread", r)
    t:start()
    return t
end

dialogHandlers = {}

------------------------------------------------------------
-- 菜单定义
------------------------------------------------------------
menu = {
    title = "青鸳科技",
    onExit = function() print("退出脚本") end,
    { group = "基础", icon = "◐", items = {
            { type="switch", id="sw_god", label="无敌模式", icon="🈚️", default=false,
                onChange = function(v) sub(function() gg.alert("无敌: "..(v=="1" and "开" or "关")) end) end },
            { type="text", label="欢迎使用本脚本", icon="👋" },
            { type="label", label="当前版本 v2.1" },
            { type="label", label="红色警告", color="#ff453a" },
            { type="switch", id="sw_ammo", label="无限弹药", icon="B", default=true,
                onChange = function(v) print("弹药: "..v) end },
            { type="checkbox", id="cb_auto", label="自动战斗", icon="C",
                onChange = function(v) print("自动: "..v) end },
            { type="slider", id="speed", label="移动速度", icon="V",
                min=1, max=100, default=30,
                onChange = function(v) print("速度: "..v) end },
            { type="slider", id="atk", label="攻击倍率", icon="★",
                min=1, max=999, default=100,
                onChange = function(v) print("攻击: "..v) end },
            { type="slider", id="speed_fine", label="微调速度(小数)", icon="🎚️",
                min=1, max=10, default=5.5, step=0.1,
                onChange = function(v) print("微调: "..v) end },
            { type="button", id="apply", label="一键应用", icon="▶", btnText="执行",
                onClick = function() gg.toast("已应用") return "完成" end },
            { type="select", id="dd_demo", label="下拉框示例", icon="📋",
                options = {"选项A","选项B","选项C","选项D","选项E","选项F","选项G"},
              default = "选项B",
                onChange = function(v) sub(function() gg.toast("选择了: "..v) end) end },
            { type="input", id="name", label="输入框", icon="✏️", placeholder="请输入...",
                onConfirm = function(v) print("输入: "..v) end },
        }},
    { group = "步进器", icon = "🔢", items = {
            { type="label", label="步进器控件示例" },
            { type="stepper", id="step_count", label="数量", icon="🔢", min=0, max=99, default=1, step=1,
                onChange = function(v) gg.toast("数量: "..v) end },
            { type="stepper", id="step_price", label="价格微调", icon="💰", min=0, max=1000, default=50, step=0.5,
                onChange = function(v) print("价格: "..v) end },
            { type="stepper", id="step_level", label="等级", icon="⭐", min=1, max=100, default=1, step=1,
                onChange = function(v) print("等级: "..v) end },
        }},
    { group = "折叠框", icon = "📁", items = {
            { type="collapsible", id="colla_demo", label="高级设置", icon="⚙️", defaultOpen=false, items = {
                    { type="switch", id="colla_sw1", label="子开关1", default=false, onChange=function(v) gg.toast("子开关1: "..v) end },
                    { type="slider", id="colla_sl", label="子滑块", min=0,max=50,default=25,step=1, onChange=function(v) print("子滑块: "..v) end },
                    { type="button", id="colla_btn", label="子按钮", btnText="点我", onClick=function() gg.toast("子按钮点击") return "ok" end },
                }},
        }},
    { group = "弹窗测试", icon = "💬", items = {
            { type="label", label="消息弹窗、加载动画与进度条示例" },
            { type="button", id="test_toast", label="Toast消息", icon="🔔", btnText="测试",
                onClick = function() showToast("这是一条Toast消息！", "success") return "" end },
            { type="button", id="test_toast_info", label="Toast(同步灵动岛)", icon="🔥", btnText="测试",
                onClick = function() showToast("青鸳科技 - 同步灵动岛消息", "info") return "" end },
            { type="button", id="test_dialog", label="确认对话框", icon="❓", btnText="弹出",
                onClick = function()
                    showConfirm("操作确认", "确定要执行此操作吗？",
                    function() showToast("已确认操作！", "success") end,
                    function() showToast("已取消操作", "error") end)
                    return ""
                end },
            { type="button", id="test_loading", label="无进度条动画", icon="⏳", btnText="显示",
                onClick = function()
                    showLoading("正在加载中...")
                    sub(function() for i=1,20 do os.sleep(0.1) end hideLoading() end)
                    return ""
                end },
            { type="button", id="test_progress", label="有进度条动画", icon="📊", btnText="开始",
                onClick = function()
                    local total = 100
                    showLoadingProgress(total, "正在处理中...")
                    sub(function() for i=1,total do updateLoadingProgress(i) gg.sleep(50) end hideLoadingProgress() showToast("处理完成！", "success") end)
                    return ""
                end },
            { type="button", id="start_progress_demo", label="手动进度条演示", icon="📈", btnText="开始",
                onClick = function()
                    showProgress(100, "任务进度")
                    sub(function()
                        for i=1,100 do
                            updateProgress(i)
                            gg.sleep(30)
                        end
                    end)
                    return ""
                end },
        }},
    { group = "图片", icon = "🖼", items = {
            { type="label", label="图片展示控件" },
            { type="custom", id="image_viewer", label="image", data = { src = "file:///storage/emulated/0/QY科技/a1.jpg" }},
        }},
    { group = "视频", icon = "🎬", items = {
            { type="label", label="视频播放控件" },
            { type="custom", id="video_player", label="video", data = { src = "file:///sdcard/Video/demo.mp4", poster = "file:///sdcard/Pictures/video_poster.jpg" }},
        }},
    { group = "轮播", icon = "🎠", items = {
            { type="label", label="轮播图控件" },
            { type="custom", id="carousel", label="carousel", data = {
                    slides = {
                        { img="file:///storage/emulated/0/QY科技/a1.jpg", title="幻灯片 1" },
                        { img="file:///storage/emulated/0/QY科技/a2.jpg", title="幻灯片 2" },
                        { bg="linear-gradient(135deg,#667eea,#764ba2)", title="幻灯片 3" },
                        { bg="linear-gradient(135deg,#f093fb,#f5576c)", title="幻灯片 4" },
                    }}},
        }},
    { group = "浏览器", icon = "🌐", items = {
            { type="label", label="内嵌浏览器示例" },
            { type="browser", id="browser_demo", label="打开网页", icon="🌍", url = "https://www.example.com" },
        }},
    { group = "系统", icon = "⚙️", items = {
            { type="switch", id="capsule_enabled", label="灵动岛", icon="🏝️", default=capsuleEnabled,
                onChange = function(v)
                    capsuleEnabled = (v == "1")
                    saveConfig("capsule_enabled", v)
                    if capsuleEnabled then
                        if not capsule then createCapsule() end
                      else
                        if capsule then
                            activity.runOnUiThread(function()
                                pcall(function() window.removeView(capsule) end)
                                capsule = nil
                            end)
                        end
                    end
                end
            },
            { type="switch", id="volume_key_ui", label="音量键控制UI", icon="🔊", default=volumeKeyUI,
                onChange = function(v)
                    volumeKeyUI = (v == "1")
                    saveConfig("volume_key_ui", v)
                end
            },
        }},
    -- 更新演示
    { group = "更新演示", icon = "🔄", items = {
            { type="label", label="更新控件内容示例" },
            { type="button", id="btn_update_image", label="更新图片", icon="🖼", btnText="更新",
                onClick = function()
                    updateImage("https://cdn.jsdelivr.net/gh/fisdhfsuz/tupian@main/7.5%E5%85%A8%E8%BA%AB7.png", "image_viewer")
                    showToast("图片已更新", "success")
                    return ""
                end },
            { type="button", id="btn_update_video", label="更新视频", icon="🎬", btnText="更新",
                onClick = function()
                    updateVideo("https://www.w3schools.com/html/mov_bbb.mp4", "https://picsum.photos/400/225", "video_player")
                    showToast("视频源已更新", "success")
                    return ""
                end },
            { type="button", id="btn_update_carousel", label="更新轮播", icon="🎠", btnText="更新",
                onClick = function()
                    updateCarousel({
                        { img = "https://picsum.photos/400/200?random=1", title = "新幻灯片 1" },
                        { img = "https://picsum.photos/400/200?random=2", title = "新幻灯片 2" },
                        { bg = "linear-gradient(135deg,#11998e,#38ef7d)", title = "新渐变 1" },
                        { bg = "linear-gradient(135deg,#fc4a1a,#f7b733)", title = "新渐变 2" },
                    }, "carousel")
                    showToast("轮播已更新", "success")
                    return ""
                end },
            { type="button", id="btn_update_browser", label="更新浏览器URL", icon="🌐", btnText="跳转",
                onClick = function()
                    updateBrowser("https://www.baidu.com", "browser_demo")
                    showToast("浏览器已跳转", "success")
                    return ""
                end },
        }},
}

------------------------------------------------------------
-- HTML 模板
------------------------------------------------------------
htmlTemplate = [[
<!DOCTYPE html><html><head><meta charset="UTF-8">
<meta name="viewport" content="{{VIEWPORT_CONTENT}}">
<style>
:root{
  --imgui-bg:#1e1e1e;
  --imgui-title:#2d2d30;
  --imgui-panel:#252526;
  --imgui-row:#2d2d30;
  --imgui-row-hover:#3e3e42;
  --imgui-text:#cccccc;
  --imgui-text-dim:#858585;
  --imgui-accent:#0e639c;
  --imgui-accent-hover:#1177bb;
  --imgui-border:#3e3e42;
  --imgui-btn:#0e639c;
  --imgui-btn-hover:#1177bb;
  --imgui-ok:#238636;
  --imgui-danger:#f85149;
  --imgui-switch-bg:#3e3e42;
  --imgui-switch-active:#0e639c;
  --imgui-input-bg:#3c3c3c;
  --imgui-slider-track:#3e3e42;
  --imgui-nav-active:#37373d;
  --imgui-nav-hover:#2a2d2e;
  --imgui-check:#0e639c;
}
*{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent;}
html,body{background:transparent;font-family:"Segoe UI","Microsoft YaHei",sans-serif;color:var(--imgui-text);font-size:13px;height:100%;overflow:hidden;touch-action:manipulation;}
body{padding:6px;}

.window{position:relative;display:flex;flex-direction:column;height:100%;background:transparent;border-radius:8px;border:1px solid var(--imgui-border);overflow:hidden;animation:bootIn .25s ease-out;z-index:1;}
@keyframes bootIn{from{opacity:0;transform:scale(.98);}to{opacity:1;transform:scale(1);}}

.titlebar{height:36px;background:var(--imgui-title);display:flex;align-items:center;justify-content:space-between;padding:0 12px;flex-shrink:0;position:relative;z-index:2;}
.titlebar-left{display:flex;align-items:center;gap:8px;}
.titlebar-icon{width:18px;height:18px;background:var(--imgui-accent);border-radius:3px;display:flex;align-items:center;justify-content:center;color:#fff;font-size:10px;font-weight:700;}
.titlebar-text{font-size:13px;font-weight:600;color:var(--imgui-text);}
.titlebar-right{display:flex;align-items:center;gap:10px;}
.titlebar-time{font-family:"Consolas",monospace;font-size:11px;color:var(--imgui-text-dim);}
.titlebar-close{width:24px;height:24px;border-radius:4px;border:none;background:transparent;color:var(--imgui-text-dim);font-size:14px;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .15s;}
.titlebar-close:hover{background:var(--imgui-danger);color:#fff;}

.main{flex:1;display:flex;overflow:hidden;background:rgba(30,30,30,0.92);position:relative;z-index:1;}

.sidebar{width:160px;background:var(--imgui-panel);border-right:1px solid var(--imgui-border);display:flex;flex-direction:column;padding:8px 0;flex-shrink:0;overflow-y:auto;max-height:100%;}
.nav-item{display:flex;align-items:center;gap:8px;padding:7px 12px;margin:0 6px;border-radius:4px;cursor:pointer;font-size:12px;color:var(--imgui-text-dim);transition:all .12s;position:relative;}
.nav-item:hover{background:var(--imgui-nav-hover);color:var(--imgui-text);}
.nav-item.active{background:var(--imgui-nav-active);color:var(--imgui-text);}
.nav-item.active::before{content:'';position:absolute;left:0;top:50%;transform:translateY(-50%);width:2px;height:16px;background:var(--imgui-accent);border-radius:1px;}
.nav-icon{width:18px;height:18px;display:flex;align-items:center;justify-content:center;font-size:11px;}
.nav-label{flex:1;}

.content{flex:1;display:flex;flex-direction:column;overflow:hidden;}
.body{flex:1;overflow-y:auto;padding:12px 16px;-webkit-overflow-scrolling:touch;}
.body::-webkit-scrollbar{width:8px;}
.body::-webkit-scrollbar-track{background:transparent;}
.body::-webkit-scrollbar-thumb{background:#424242;border-radius:4px;}

.group{display:none;}
.group.active{display:block;animation:fadeIn .2s ease;}
@keyframes fadeIn{from{opacity:0;}to{opacity:1;}}

.row{background:var(--imgui-row);border:1px solid var(--imgui-border);border-radius:4px;padding:8px 12px;margin-bottom:6px;display:flex;align-items:center;justify-content:space-between;gap:10px;transition:all .12s;touch-action:manipulation;}
.row:hover{background:var(--imgui-row-hover);border-color:#4e4e52;}
.row.row-block{display:block;padding:10px 12px;}
.row.row-block .row-label{margin-bottom:8px;}
.row-label{display:flex;align-items:center;gap:8px;flex:1;min-width:0;font-size:12px;}
.row-icon{width:22px;height:22px;border-radius:3px;background:var(--imgui-panel);display:flex;align-items:center;justify-content:center;font-size:11px;color:var(--imgui-text-dim);flex-shrink:0;border:1px solid var(--imgui-border);}
.row-label-text{font-size:12px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}

.btn{background:var(--imgui-btn);color:#fff;border:none;padding:5px 14px;border-radius:3px;font-family:inherit;font-size:12px;font-weight:500;cursor:pointer;transition:all .12s;min-width:60px;touch-action:manipulation;}
.btn:hover{background:var(--imgui-btn-hover);}
.btn:active{transform:translateY(1px);}

.sw{position:relative;width:40px;height:20px;cursor:pointer;flex-shrink:0;touch-action:manipulation;}
.sw input{display:none;}
.sw-bg{position:absolute;inset:0;border-radius:2px;background:var(--imgui-switch-bg);transition:all .15s;}
.sw-knob{position:absolute;top:2px;left:2px;width:16px;height:16px;border-radius:2px;background:#c0c0c0;transition:all .15s;}
.sw input:checked + .sw-bg{background:var(--imgui-switch-active);}
.sw input:checked + .sw-bg + .sw-knob{left:22px;background:#fff;}

.cb{position:relative;width:16px;height:16px;cursor:pointer;flex-shrink:0;touch-action:manipulation;}
.cb input{display:none;}
.cb-box{position:absolute;inset:0;border-radius:3px;background:var(--imgui-row);border:1px solid var(--imgui-border);transition:all .12s;display:flex;align-items:center;justify-content:center;}
.cb-box::after{content:'';width:8px;height:5px;border-left:2px solid #fff;border-bottom:2px solid #fff;transform:rotate(-45deg) scale(0);transition:transform .12s;margin-top:-1px;}
.cb input:checked + .cb-box{background:var(--imgui-check);border-color:var(--imgui-check);}
.cb input:checked + .cb-box::after{transform:rotate(-45deg) scale(1);}

.slider-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;}
.slider-val{background:var(--imgui-input-bg);color:var(--imgui-text);padding:2px 8px;border-radius:3px;font-size:11px;font-family:"Consolas",monospace;border:1px solid var(--imgui-border);}
.slider{-webkit-appearance:none;width:100%;height:4px;border-radius:2px;background:linear-gradient(90deg,var(--imgui-accent) var(--pct,50%),var(--imgui-slider-track) var(--pct,50%));outline:none;cursor:pointer;touch-action:manipulation;}
.slider::-webkit-slider-thumb{-webkit-appearance:none;width:14px;height:14px;border-radius:3px;background:#c0c0c0;border:1px solid #808080;cursor:grab;transition:all .12s;}
.slider::-webkit-slider-thumb:hover{background:#fff;}
.slider::-webkit-slider-thumb:active{background:var(--imgui-accent);border-color:var(--imgui-accent);}

.inp{width:100%;padding:6px 10px;border-radius:3px;background:var(--imgui-input-bg);border:1px solid var(--imgui-border);color:var(--imgui-text);font-family:inherit;font-size:12px;outline:none;transition:all .12s;-webkit-appearance:none;touch-action:manipulation;}
.inp::placeholder{color:var(--imgui-text-dim);}
.inp:focus{border-color:var(--imgui-accent);}

.input-row{display:flex;align-items:center;gap:8px;}
.input-row .inp{flex:1;}
.input-confirm-btn{background:var(--imgui-btn);color:#fff;border:none;padding:5px 12px;border-radius:3px;font-size:12px;font-weight:500;cursor:pointer;transition:all .12s;white-space:nowrap;}
.input-confirm-btn:hover{background:var(--imgui-btn-hover);}

.text-row{background:transparent;border:none;padding:6px 0;}
.text-row .row-icon{background:transparent;border:none;}
.label-row{padding:4px 0;font-size:12px;color:var(--imgui-text-dim);}

.collapsible{margin-bottom:6px;overflow:hidden;}
.collapsible-header{display:flex;align-items:center;gap:10px;padding:8px 12px;background:var(--imgui-row);border:1px solid var(--imgui-border);border-radius:4px;cursor:pointer;transition:all .2s;}
.collapsible-header:hover{background:var(--imgui-row-hover);}
.collapsible-header .arrow{margin-left:auto;font-size:12px;transition:transform .3s;}
.collapsible.open .arrow{transform:rotate(90deg);}
.collapsible-body{max-height:0;overflow:hidden;transition:max-height 0.4s ease,padding 0.4s ease;padding:0 12px;}
.collapsible.open .collapsible-body{max-height:1000px;padding:8px 12px 4px 12px;overflow:visible;}
.collapsible-body .row{margin-bottom:4px;}

.custom-select{position:relative;min-width:120px;}
.select-btn{background:var(--imgui-input-bg);border:1px solid var(--imgui-border);border-radius:3px;padding:6px 28px 6px 10px;font-size:12px;color:var(--imgui-text);cursor:pointer;text-align:left;width:100%;appearance:none;font-family:inherit;position:relative;}
.select-btn::after{content:'';position:absolute;right:8px;top:50%;transform:translateY(-50%);width:0;height:0;border-left:4px solid transparent;border-right:4px solid transparent;border-top:5px solid var(--imgui-text-dim);pointer-events:none;}
.select-options{display:none;position:fixed;background:var(--imgui-panel);border-radius:4px;border:1px solid var(--imgui-border);box-shadow:0 4px 12px rgba(0,0,0,.4);z-index:9999;max-height:200px;overflow-y:auto;scrollbar-width:thin;scrollbar-color:var(--imgui-border) transparent;}
.select-options::-webkit-scrollbar{width:4px;}
.select-options::-webkit-scrollbar-track{background:transparent;}
.select-options::-webkit-scrollbar-thumb{background:var(--imgui-border);border-radius:2px;}
.select-option{padding:6px 10px;cursor:pointer;font-size:12px;color:var(--imgui-text);transition:background .12s;}
.select-option:hover{background:var(--imgui-row-hover);}

.img-container{background:var(--imgui-panel);border:1px solid var(--imgui-border);border-radius:6px;overflow:hidden;margin-bottom:6px; min-height:60px; display:flex; align-items:center; justify-content:center;}
.img-container img{width:100%;height:auto;display:block;max-height:200px;object-fit:cover;}
.img-error{color:var(--imgui-text-dim); font-size:12px; padding: 20px;}

.video-container{background:var(--imgui-panel);border:1px solid var(--imgui-border);border-radius:6px;overflow:hidden;margin-bottom:6px;}
.video-wrapper{position:relative;width:100%;padding-top:56.25%;background:#000;}
.video-wrapper video{position:absolute;top:0;left:0;width:100%;height:100%;object-fit:contain;}
.video-overlay{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,.3);cursor:pointer;transition:opacity .2s;}
.video-overlay.hidden{opacity:0;pointer-events:none;}
.video-play-btn{width:56px;height:56px;background:rgba(255,255,255,.9);border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;color:#333;}
.video-controls{padding:8px 12px;display:flex;align-items:center;gap:8px;}
.video-progress{flex:1;height:4px;background:var(--imgui-slider-track);border-radius:2px;cursor:pointer;position:relative;touch-action:manipulation;}
.video-progress-fill{height:100%;background:var(--imgui-accent);border-radius:2px;width:0%;transition:width .1s;}
.video-time{font-size:11px;color:var(--imgui-text-dim);font-family:"Consolas",monospace;min-width:90px;text-align:center;}
.video-btn-sm{background:var(--imgui-row);border:1px solid var(--imgui-border);color:var(--imgui-text);width:32px;height:32px;border-radius:4px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:14px;}
.video-btn-sm:hover{background:var(--imgui-row-hover);}

.carousel-container{position:relative;background:var(--imgui-panel);border:1px solid var(--imgui-border);border-radius:6px;overflow:hidden;margin-bottom:6px;}
.carousel-track{position:relative;height:180px;overflow:hidden;}
.carousel-slides{display:flex;transition:transform .4s ease;height:100%;}
.carousel-slide{width:100%;flex-shrink:0;height:100%;display:flex;align-items:center;justify-content:center;font-size:48px;color:#fff;position:relative;}
.carousel-slide img{width:100%;height:100%;object-fit:cover;}
.carousel-slide::after{content:attr(data-title);position:absolute;bottom:0;left:0;right:0;padding:8px 12px;background:linear-gradient(transparent,rgba(0,0,0,.7));font-size:12px;text-align:left;}
.carousel-dots{position:absolute;bottom:8px;right:12px;display:flex;gap:6px;z-index:2;}
.carousel-dot{width:8px;height:8px;border-radius:50%;background:rgba(255,255,255,.4);cursor:pointer;transition:all .2s;touch-action:manipulation;}
.carousel-dot.active{background:#fff;width:20px;border-radius:4px;}
.carousel-arrow{position:absolute;top:50%;transform:translateY(-50%);background:rgba(0,0,0,.4);border:none;color:#fff;width:32px;height:32px;border-radius:50%;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:14px;z-index:2;transition:background .2s;touch-action:manipulation;}
.carousel-arrow:hover{background:rgba(0,0,0,.6);}
.carousel-arrow.prev{left:8px;}
.carousel-arrow.next{right:8px;}

.browser-container{background:var(--imgui-panel);border:1px solid var(--imgui-border);border-radius:6px;overflow:hidden;margin-bottom:6px;position:relative;height:300px;}
.browser-container iframe{width:100%;height:100%;border:none;}

.toast-container{position:absolute;bottom:10px;right:12px;pointer-events:none;z-index:9999;display:flex;flex-direction:column;align-items:flex-end;gap:6px;}
.toast{background:rgba(0,0,0,.85);color:#fff;padding:10px 18px;border-radius:6px;font-size:13px;max-width:240px;text-align:center;animation:toastIn .3s ease;word-break:break-word;}
@keyframes toastIn{from{opacity:0;transform:translateX(20px);}to{opacity:1;transform:translateX(0);}}

.loading-overlay{position:absolute;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,.7);display:none;align-items:center;justify-content:center;z-index:9998;border-radius:8px;}
.loading-overlay.show{display:flex;}
.loading-box{background:var(--imgui-bg);border:1px solid var(--imgui-border);border-radius:8px;padding:24px 32px;text-align:center;}
.loading-spinner{width:40px;height:40px;border:3px solid var(--imgui-border);border-top-color:var(--imgui-accent);border-radius:50%;animation:spin 1s linear infinite;margin:0 auto 12px;}
@keyframes spin{to{transform:rotate(360deg);}}
.loading-text{color:var(--imgui-text);font-size:13px;margin-bottom:8px;}
.progress-bar{width:200px;height:6px;background:var(--imgui-border);border-radius:3px;overflow:hidden;margin-top:8px;}
.progress-fill{height:100%;background:var(--imgui-accent);border-radius:3px;transition:width .2s;}
.progress-percent{color:var(--imgui-text-dim);font-size:11px;margin-top:4px;}

.dialog-overlay{position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,.6);display:flex;align-items:center;justify-content:center;z-index:99999;animation:fadeIn .15s ease;}
.dialog-box{background:var(--imgui-bg);border:1px solid var(--imgui-border);border-radius:8px;padding:20px;min-width:250px;max-width:90%;animation:scaleIn .2s ease;}
@keyframes scaleIn{from{transform:scale(.9);opacity:0;}to{transform:scale(1);opacity:1;}}
.dialog-title{font-size:15px;font-weight:600;color:var(--imgui-text);margin-bottom:12px;}
.dialog-message{font-size:13px;color:var(--imgui-text-dim);margin-bottom:16px;line-height:1.5;}
.dialog-buttons{display:flex;gap:8px;justify-content:flex-end;}
.dialog-btn-cancel,.dialog-btn-confirm{padding:6px 16px;border-radius:4px;font-size:13px;cursor:pointer;border:none;transition:all .12s;touch-action:manipulation;}
.dialog-btn-cancel{background:var(--imgui-row);color:var(--imgui-text);border:1px solid var(--imgui-border);}
.dialog-btn-cancel:hover{background:var(--imgui-row-hover);}
.dialog-btn-confirm{background:var(--imgui-accent);color:#fff;}
.dialog-btn-confirm:hover{background:var(--imgui-accent-hover);}

.progress-container {
    position: fixed;
    bottom: 16px;
    left: 16px;
    right: 16px;
    pointer-events: none;
    z-index: 9997;
    display: none;
    flex-direction: column;
    gap: 4px;
    min-height: 40px;
    background: rgba(0,0,0,0.7);
    border-radius: 8px;
}
.progress-item{background:var(--imgui-bg);border:1px solid var(--imgui-border);border-radius:4px;padding:6px 10px;display:flex;flex-direction:column;gap:2px;}
.progress-item .progress-label{font-size:11px;color:var(--imgui-text-dim);}
.progress-item .progress-bar{width:100%;height:4px;background:var(--imgui-border);border-radius:2px;overflow:hidden;}
.progress-item .progress-fill{height:100%;background:var(--imgui-accent);width:0%;border-radius:2px;transition:width .2s;}
.progress-item .progress-percent{font-size:10px;color:var(--imgui-text-dim);text-align:right;}

.stepper{display:flex;align-items:center;gap:4px;}
.stepper-btn{width:28px;height:28px;border-radius:4px;background:var(--imgui-btn);color:#fff;border:none;font-size:16px;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .12s;touch-action:manipulation;}
.stepper-btn:hover{background:var(--imgui-btn-hover);}
.stepper-btn:active{transform:scale(0.9);}
.stepper-btn:disabled{background:var(--imgui-row);color:var(--imgui-text-dim);cursor:not-allowed;}
.stepper-val{background:var(--imgui-input-bg);color:var(--imgui-text);padding:4px 10px;border-radius:3px;font-size:12px;font-family:"Consolas",monospace;border:1px solid var(--imgui-border);min-width:40px;text-align:center;}
</style></head>
<body>
<div class="window">
  <div class="titlebar">
    <div class="titlebar-left"><div class="titlebar-icon">QY</div><div class="titlebar-text">{{TITLE}}</div></div>
    <div class="titlebar-right"><span class="titlebar-time" id="time">--:--:--</span><button class="titlebar-close" onclick="NA.send('__exit','')">×</button></div>
  </div>
  <div class="main">
    <aside class="sidebar" id="sidebar"><nav class="nav" id="nav"></nav></aside>
    <main class="content"><div class="body">{{ITEMS}}</div></main>
  </div>
  <div class="toast-container" id="toastContainer"></div>
  <div class="loading-overlay" id="loadingOverlay">
    <div class="loading-box">
      <div class="loading-spinner"></div>
      <div class="loading-text" id="loadingText">加载中...</div>
      <div class="progress-bar" id="progressBar" style="display:none;"><div class="progress-fill" id="progressFill"></div></div>
      <div class="progress-percent" id="progressPercent" style="display:none;">0%</div>
    </div>
  </div>
</div>
<div class="progress-container" id="progressContainer"></div>

{{SELECT_OPTIONS}}

<script>
// 步进器
function onStepper(id, delta, min, max, step){
  var el = document.getElementById('stepper_val_' + id);
  if(!el) return;
  var v = parseFloat(el.textContent) || 0;
  var s = parseFloat(step) || 1;
  var newVal = v + (delta * s);
  var mn = parseFloat(min);
  var mx = parseFloat(max);
  if(!isNaN(mn) && newVal < mn) newVal = mn;
  if(!isNaN(mx) && newVal > mx) newVal = mx;
  var decimals = s < 1 ? (s.toString().split('.')[1]?.length || 1) : 0;
  el.textContent = newVal.toFixed(decimals);
  var btnMinus = document.getElementById('stepper_minus_' + id);
  var btnPlus = document.getElementById('stepper_plus_' + id);
  if(btnMinus) btnMinus.disabled = (!isNaN(mn) && newVal <= mn);
  if(btnPlus) btnPlus.disabled = (!isNaN(mx) && newVal >= mx);
  NA.send(id, newVal.toString());
}

window.__cfg = {{CONFIG}};

function onBtn(id,el){const r=NA.emit(id,'');if(r)el.textContent=r;}
function onSwitch(id,el){NA.send(id,el.checked?'1':'0');}
function onCheck(id,el){NA.send(id,el.checked?'1':'0');}
function onSlide(id,el,valId,min,max){
  var v=parseFloat(el.value);
  var step=parseFloat(el.step)||1;
  var decimals=step<1?(step.toString().split('.')[1]?.length||1):0;
  document.getElementById(valId).textContent=v.toFixed(decimals);
  el.style.setProperty('--pct',((v-min)/(max-min)*100).toFixed(1)+'%');
  NA.send(id,v.toString());
}
function onInput(id,el){NA.send(id,el.value);}
function onInputConfirm(id, el){
  var inp = document.getElementById(id);
  if(inp) NA.send(id, inp.value);
}

function showToast(msg,type){
  type=type||'info';
  var container=document.getElementById('toastContainer');
  var toast=document.createElement('div');
  toast.className='toast '+type;
  toast.textContent=msg;
  container.appendChild(toast);
  setTimeout(function(){
    toast.style.opacity='0';
    toast.style.transform='translateX(20px)';
    toast.style.transition='all .3s';
    setTimeout(function(){toast.remove();},300);
  },2000);
}

function showLoading(text){
  document.getElementById('loadingText').textContent=text||'加载中...';
  document.getElementById('progressBar').style.display='none';
  document.getElementById('progressPercent').style.display='none';
  document.getElementById('loadingOverlay').classList.add('show');
}
function hideLoading(){document.getElementById('loadingOverlay').classList.remove('show');}
function showLoadingProgress(max,label){
  document.getElementById('loadingText').textContent=label||'正在处理中...';
  document.getElementById('progressBar').style.display='block';
  document.getElementById('progressPercent').style.display='block';
  document.getElementById('progressFill').style.width='0%';
  document.getElementById('progressPercent').textContent='0%';
  document.getElementById('loadingOverlay').classList.add('show');
}
function updateLoadingProgress(current){
  var pct=Math.min(100,Math.max(0,current));
  document.getElementById('progressFill').style.width=pct+'%';
  document.getElementById('progressPercent').textContent=pct+'%';
}

var progressTasks = {};
function showProgress(max, label, id) {
  id = id || 'default';
  var container = document.getElementById('progressContainer');
  if (!container) return;
  var old = document.getElementById('progress-' + id);
  if (old) old.remove();
  container.style.display = 'flex';
  var item = document.createElement('div');
  item.className = 'progress-item';
  item.id = 'progress-' + id;
  item.innerHTML = '<div class="progress-label">' + (label || '处理中...') + '</div>' +
    '<div class="progress-bar"><div class="progress-fill" style="width:0%"></div></div>' +
    '<div class="progress-percent">0%</div>';
  container.appendChild(item);
  progressTasks[id] = { max: max, current: 0 };
}
function updateProgress(current, id) {
  id = id || 'default';
  var task = progressTasks[id];
  if (!task) return;
  task.current = current;
  var pct = Math.min(100, Math.round((current / task.max) * 100));
  var item = document.getElementById('progress-' + id);
  if (item) {
    var fill = item.querySelector('.progress-fill');
    var percent = item.querySelector('.progress-percent');
    if (fill) fill.style.width = pct + '%';
    if (percent) percent.textContent = pct + '%';
    if (current >= task.max) {
      setTimeout(function() {
        if (item) item.remove();
        delete progressTasks[id];
        if (Object.keys(progressTasks).length === 0) {
          document.getElementById('progressContainer').style.display = 'none';
        }
      }, 500);
    }
  }
}

function toggleCollapsible(id){
  var el=document.getElementById('collapsible_'+id);
  if(!el) return;
  el.classList.toggle('open');
}

function toggleSelect(id) {
  var btn = document.getElementById('select_btn_'+id);
  var opt = document.getElementById('select_opts_'+id);
  if(!btn||!opt) return;
  document.querySelectorAll('.select-options').forEach(function(e){e.style.display='none'});
  if(opt.style.display!=='block'){
    var r = btn.getBoundingClientRect();
    var vh = window.innerHeight;
    var sb = vh - r.bottom, sa = r.top, mh = 200;
    if(sb<150 && sa>sb){
      opt.style.maxHeight = Math.min(sa-10,mh)+'px';
      opt.style.bottom = (vh - r.top + 4) + 'px';
      opt.style.top = 'auto';
    } else {
      opt.style.maxHeight = Math.min(sb-10,mh)+'px';
      opt.style.top = (r.bottom + 4) + 'px';
      opt.style.bottom = 'auto';
    }
    opt.style.left = r.left + 'px';
    opt.style.width = r.width + 'px';
    opt.style.display = 'block';
    setTimeout(function(){
      window.__selectClickHandler = function(e){
        if(!e.target.closest('.select-options') && !e.target.closest('.select-btn')){
          opt.style.display='none';
          window.removeEventListener('click',window.__selectClickHandler);
        }
      };
      window.addEventListener('click',window.__selectClickHandler);
    },10);
  } else {
    opt.style.display='none';
    if(window.__selectClickHandler) window.removeEventListener('click',window.__selectClickHandler);
  }
}
function selectOption(id,value,text){
  var btn = document.getElementById('select_btn_'+id);
  if(btn) btn.textContent = text;
  var opt = document.getElementById('select_opts_'+id);
  if(opt) opt.style.display='none';
  if(window.__selectClickHandler) window.removeEventListener('click',window.__selectClickHandler);
  NA.send(id, value);
}

function showConfirmDialog(title, message, confirmText, cancelText, cmd) {
  confirmText = confirmText || '确定'; cancelText = cancelText || '取消'; cmd = cmd || '';
  var overlay = document.createElement('div');
  overlay.className = 'dialog-overlay';
  overlay.innerHTML = '<div class="dialog-box"><div class="dialog-title">' + title + '</div><div class="dialog-message">' + message + '</div><div class="dialog-buttons"><button class="dialog-btn-cancel" id="dialogCancel">' + cancelText + '</button><button class="dialog-btn-confirm" id="dialogConfirm">' + confirmText + '</button></div></div>';
  document.body.appendChild(overlay);
  function close() { document.body.removeChild(overlay); }
  document.getElementById('dialogCancel').onclick = function() { NA.send('dialog_result', '0|' + cmd); close(); };
  document.getElementById('dialogConfirm').onclick = function() { NA.send('dialog_result', '1|' + cmd); close(); };
}

// 长按悬浮按钮
(function() {
  var btnTimers = {};
  var swTimers = {};
  var MOVE_THRESHOLD = 15;
  function getBtnId(btn) {
    var m = btn.getAttribute('onclick').match(/onBtn\('([^']+)',this\)/);
    return m ? m[1] : null;
  }
  function getSwitchId(row) {
    var sw = row.querySelector('.sw input');
    return sw ? sw.id : null;
  }
  document.addEventListener('touchstart', function(e) {
    var btn = e.target.closest('.btn');
    if (btn) {
      var id = getBtnId(btn); if(!id) return;
      var t = e.changedTouches[0];
      btnTimers[t.identifier] = { timer: setTimeout(function(){
        delete btnTimers[t.identifier];
        var row = btn.closest('.row');
        var text = row ? row.querySelector('.row-label-text').textContent : btn.textContent;
        NA.send('create_float_btn', id + '|' + text);
      },600), sx: t.clientX, sy: t.clientY };
    }
    var row = e.target.closest('.row');
    if (row && row.querySelector('.sw input')) {
      var id = getSwitchId(row); if(!id) return;
      var t = e.changedTouches[0];
      swTimers['sw_'+t.identifier] = { timer: setTimeout(function(){
        delete swTimers['sw_'+t.identifier];
        var text = row.querySelector('.row-label-text').textContent;
        NA.send('create_switch_float', id + '|' + text);
      },600), sx: t.clientX, sy: t.clientY };
    }
  }, {passive:true});
  document.addEventListener('touchmove', function(e) {
    var t = e.changedTouches[0];
    if (btnTimers[t.identifier]) {
      if (Math.abs(t.clientX-btnTimers[t.identifier].sx)>MOVE_THRESHOLD || Math.abs(t.clientY-btnTimers[t.identifier].sy)>MOVE_THRESHOLD) {
        clearTimeout(btnTimers[t.identifier].timer); delete btnTimers[t.identifier];
      }
    }
    var st = swTimers['sw_'+t.identifier];
    if (st) {
      if (Math.abs(t.clientX-st.sx)>MOVE_THRESHOLD || Math.abs(t.clientY-st.sy)>MOVE_THRESHOLD) {
        clearTimeout(st.timer); delete swTimers['sw_'+t.identifier];
      }
    }
  }, {passive:true});
  document.addEventListener('touchend', function(e) {
    var t = e.changedTouches[0];
    if (btnTimers[t.identifier]) { clearTimeout(btnTimers[t.identifier].timer); delete btnTimers[t.identifier]; }
    var st = swTimers['sw_'+t.identifier]; if(st){ clearTimeout(st.timer); delete swTimers['sw_'+t.identifier]; }
  });
  document.addEventListener('touchcancel', function(e) {
    var t = e.changedTouches[0];
    if (btnTimers[t.identifier]) { clearTimeout(btnTimers[t.identifier].timer); delete btnTimers[t.identifier]; }
    var st = swTimers['sw_'+t.identifier]; if(st){ clearTimeout(st.timer); delete swTimers['sw_'+t.identifier]; }
  });
})();

function initImageViewer(){
  document.querySelectorAll('.img-container').forEach(function(c){
    var img = c.querySelector('img');
    if(img) img.onerror = function(){
      c.innerHTML = '<div class="img-error">图片加载失败</div>';
    };
  });
}

function initVideoPlayer(){}
function toggleVideo(v,ov){ if(v.paused){v.play();ov.classList.add('hidden');}else{v.pause();ov.classList.remove('hidden');} }
function fmt(s){ var m=Math.floor(s/60),sec=Math.floor(s%60); return m.toString().padStart(2,'0')+':'+sec.toString().padStart(2,'0'); }

var carouselIndex=0, carouselTimer=null;
function updateImage(src, widgetId) {
  var container = document.querySelector('[data-widget-id="'+widgetId+'"]');
  if(!container) return;
  var img = container.querySelector('img');
  if(img){
    img.src = src; img.style.display='';
    var err = container.querySelector('.img-error'); if(err) err.remove();
    img.onerror = function(){ container.innerHTML='<div class="img-error">图片加载失败</div>'; };
  } else {
    var newImg = document.createElement('img'); newImg.src=src; newImg.style.display='';
    newImg.onerror=function(){ container.innerHTML='<div class="img-error">图片加载失败</div>'; };
    container.innerHTML=''; container.appendChild(newImg);
  }
}
function updateVideo(src, poster, widgetId){
  var c = document.querySelector('[data-widget-id="'+widgetId+'"]');
  if(!c) return;
  var v = c.querySelector('video');
  if(v){ if(src)v.src=src; if(poster)v.poster=poster; v.load(); c.querySelector('.video-overlay').classList.remove('hidden'); v.currentTime=0; }
}
function updateCarousel(slides, widgetId){
  var c = document.querySelector('[data-widget-id="'+widgetId+'"]');
  if(!c) return;
  var track = c.querySelector('.carousel-slides'), dots = c.querySelector('.carousel-dots');
  if(!track||!dots) return;
  clearInterval(carouselTimer); carouselIndex=0;
  track.innerHTML=''; dots.innerHTML='';
  slides.forEach(function(s,i){
    var d=document.createElement('div'); d.className='carousel-slide';
    if(s.img) d.innerHTML='<img src="'+s.img+'" alt="">';
    else d.style.background=s.bg||'#333';
    if(s.title) d.setAttribute('data-title',s.title);
    track.appendChild(d);
    var dot=document.createElement('div'); dot.className='carousel-dot'+(i==0?' active':'');
    dot.onclick = (function(idx){ return function(){ goToSlideCarousel(widgetId, idx); }; })(i);
    dots.appendChild(dot);
  });
  track.style.transform='translateX(0%)';
  initCarouselEventsFor(widgetId);
}
function goToSlideCarousel(widgetId, index){
  var c = document.querySelector('[data-widget-id="'+widgetId+'"]');
  if(!c) return;
  var slides=c.querySelectorAll('.carousel-slide');
  if(!slides.length) return;
  if(index<0) index=slides.length-1;
  if(index>=slides.length) index=0;
  carouselIndex=index;
  c.querySelector('.carousel-slides').style.transform='translateX(-'+(index*100)+'%)';
  c.querySelectorAll('.carousel-dot').forEach(function(d,i){ d.classList.toggle('active',i===index); });
}
function initCarouselEventsFor(widgetId){
  var c = document.querySelector('[data-widget-id="'+widgetId+'"]');
  if(!c) return;
  var prev=c.querySelector('.carousel-arrow.prev'), next=c.querySelector('.carousel-arrow.next');
  if(prev) prev.onclick=function(){ goToSlideCarousel(widgetId, carouselIndex-1); };
  if(next) next.onclick=function(){ goToSlideCarousel(widgetId, carouselIndex+1); };
  if(carouselTimer) clearInterval(carouselTimer);
  carouselTimer=setInterval(function(){ goToSlideCarousel(widgetId, carouselIndex+1); },4000);
}
function updateBrowser(url, widgetId){
  var c = document.querySelector('[data-widget-id="'+widgetId+'"]');
  if(c) { var f=c.querySelector('iframe'); if(f) f.src=url; }
}

window.addEventListener('DOMContentLoaded', function(){
  var groups=document.querySelectorAll('.group'), nav=document.getElementById('nav');
  if(groups.length===0){ document.getElementById('sidebar').style.display='none'; return; }
  groups.forEach(function(g,i){
    var name=g.dataset.group||('组'+(i+1)), icon=g.dataset.icon||'·';
    var item=document.createElement('div'); item.className='nav-item'+(i===0?' active':'');
    item.innerHTML='<div class="nav-icon">'+icon+'</div><div class="nav-label">'+name+'</div>';
    item.onclick=function(){ activate(i,name); };
    nav.appendChild(item);
    if(i===0) g.classList.add('active');
  });
  initImageViewer();
  document.querySelectorAll('.carousel-container').forEach(function(c){ var id=c.getAttribute('data-widget-id'); if(id) initCarouselEventsFor(id); });
  setTimeout(function(){
    document.querySelectorAll('input[type="text"], input:not([type]), textarea, .inp').forEach(function(inp){
      inp.addEventListener('focus',function(){ NA.send('__input_focus','1'); });
      inp.addEventListener('blur',function(){ NA.send('__input_focus','0'); });
      inp.addEventListener('keydown',function(e){ if(e.key==='Enter'){ var btn=inp.closest('.row').querySelector('.input-confirm-btn'); if(btn) btn.click(); } });
    });
  },300);
});
function activate(idx, name){
  document.querySelectorAll('.nav-item').forEach(function(el,i){ el.classList.toggle('active',i===idx); });
  document.querySelectorAll('.group').forEach(function(el,i){ el.classList.toggle('active',i===idx); });
}
function tick(){
  var d=new Date(), p=function(n){ return n.toString().padStart(2,'0'); };
  document.getElementById('time').textContent = p(d.getHours())+':'+p(d.getMinutes())+':'+p(d.getSeconds());
}
tick(); setInterval(tick,1000);
</script>
</body></html>
]]

compile("/storage/emulated/0/QY科技/webBridge.dex")
import "android.view.*"
import "android.graphics.*"
import "android.graphics.drawable.GradientDrawable"
import "android.widget.*"
import "android.webkit.WebView"
import "android.webkit.WebViewClient"
import "android.os.Build"
import "android.os.Looper"
import "android.util.TypedValue"
import "android.text.TextUtils"
import "com.Shizuku.WebBridge"
import "android.animation.*"
import "android.view.animation.*"
import "android.os.Handler"

window = activity.getSystemService("window")

local isToggling = false
local lunfanwenzi = {{"🔥"}, {"青鸳科技", "欢迎使用", "点击切换UI"}}
local floatingButtons = {}
local switchFloats = {}
local lastClickTime = 0
local DOUBLE_CLICK_INTERVAL = 300
selectOptionsCache = {}

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
        :gsub('</','<\\/')
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
    return jsonEncode(cfg)
end

function renderItem(it)
    local id = htmlEscape(it.id or "")
    local label = htmlEscape(it.label or "")
    local icon = htmlEscape(it.icon or (it.label or "?"):sub(1,1))
    if it.type == "text" then
        return string.format('<div class="row text-row"><div class="row-label"><span class="row-icon">%s</span><span class="row-label-text">%s</span></div></div>', icon, label)
    end
    if it.type == "label" then
        local color = it.color or "var(--imgui-text-dim)"
        return string.format('<div class="label-row" style="color:%s;">%s</div>', color, label)
    end
    if it.type == "button" then
        return string.format('<div class="row"><div class="row-label"><span class="row-icon">%s</span><span class="row-label-text">%s</span></div><button class="btn" onclick="onBtn(\'%s\',this)">%s</button></div>', icon, label, id, htmlEscape(it.btnText or "执行"))
      elseif it.type == "switch" then
        local chk = it.default and "checked" or ""
        return string.format('<div class="row"><div class="row-label"><span class="row-icon">%s</span><span class="row-label-text">%s</span></div><label class="sw"><input type="checkbox" id="%s" %s onchange="onSwitch(\'%s\',this)"><span class="sw-bg"></span><span class="sw-knob"></span></label></div>', icon, label, id, chk, id)
      elseif it.type == "checkbox" then
        local chk = it.default and "checked" or ""
        return string.format('<div class="row"><div class="row-label"><span class="row-icon">%s</span><span class="row-label-text">%s</span></div><label class="cb"><input type="checkbox" %s onchange="onCheck(\'%s\',this)"><span class="cb-box"></span></label></div>', icon, label, chk, id)
      elseif it.type == "slider" then
        local min = it.min or 0
        local max = it.max or 100
        local def = it.default or min
        local pct = (def-min)/(max-min)*100
        local vid = id.."_val"
        return string.format('<div class="row row-block"><div class="slider-top"><div class="row-label"><span class="row-icon">%s</span><span class="row-label-text">%s</span></div><span class="slider-val" id="%s">%s</span></div><input type="range" class="slider" id="%s" min="%s" max="%s" value="%s" step="%s" style="--pct:%.1f%%" oninput="onSlide(\'%s\',this,\'%s\',%s,%s)"></div>', icon, label, vid, tostring(def), id, tostring(min), tostring(max), tostring(def), tostring(it.step or 1), pct, id, vid, tostring(min), tostring(max))
      elseif it.type == "input" then
        return string.format('<div class="row"><div class="row-label"><span class="row-icon">%s</span><span class="row-label-text">%s</span></div><div class="input-row"><input type="text" class="inp" id="%s" value="%s" placeholder="%s"><button class="input-confirm-btn" onclick="onInputConfirm(\'%s\',this)">确定</button></div></div>', icon, label, id, htmlEscape(it.default or ""), htmlEscape(it.placeholder or ""), id)
      elseif it.type == "select" then
        selectOptionsCache[id] = it
        local defaultText = it.default or (it.options and it.options[1]) or ""
        return string.format('<div class="row"><div class="row-label"><span class="row-icon">%s</span><span class="row-label-text">%s</span></div><div class="custom-select"><div class="select-btn" id="select_btn_%s" onclick="toggleSelect(\'%s\')">%s</div></div></div>', icon, label, id, id, htmlEscape(defaultText))
      elseif it.type == "stepper" then
        local min = it.min or 0
        local max = it.max or 100
        local def = it.default or min
        local step = it.step or 1
        local minusDisabled = def <= min and " disabled" or ""
        local plusDisabled = def >= max and " disabled" or ""
        local vid = "stepper_val_" .. id
        local defStr = tostring(def)
        return string.format('<div class="row"><div class="row-label"><span class="row-icon">%s</span><span class="row-label-text">%s</span></div><div class="stepper"><button class="stepper-btn" id="stepper_minus_%s" onclick="onStepper(\'%s\',-1,%s,%s,%s)"%s>−</button><span class="stepper-val" id="%s">%s</span><button class="stepper-btn" id="stepper_plus_%s" onclick="onStepper(\'%s\',1,%s,%s,%s)"%s>+</button></div></div>', icon, label, id, id, tostring(min), tostring(max), tostring(step), minusDisabled, vid, defStr, id, id, tostring(min), tostring(max), tostring(step), plusDisabled)
      elseif it.type == "collapsible" then
        local openClass = it.defaultOpen and " open" or ""
        local rows = {}
        for _, subIt in ipairs(it.items or {}) do rows[#rows+1] = renderItem(subIt) end
        return string.format('<div class="collapsible%s" id="collapsible_%s"><div class="collapsible-header" onclick="toggleCollapsible(\'%s\')"><span class="row-icon">%s</span><span class="row-label-text">%s</span><span class="arrow">▶</span></div><div class="collapsible-body">%s</div></div>', openClass, id, id, icon, label, table.concat(rows))
      elseif it.type == "custom" then
        local data = it.data or {}
        if it.id == "image_viewer" then
            local src = data.src or ""
            return string.format('<div class="img-container" data-widget-id="%s"><img src="%s" alt="图片"></div>', id, src)
          elseif it.id == "video_player" then
            local src = data.src or ""
            local poster = data.poster or ""
            return string.format([[<div class="video-container" data-widget-id="%s"><div class="video-wrapper"><video src="%s" poster="%s"></video><div class="video-overlay"><div class="video-play-btn">▶</div></div></div><div class="video-controls"><button class="video-btn-sm vol-btn">🔊</button><div class="video-progress"><div class="video-progress-fill"></div></div><span class="video-time">00:00 / 00:00</span><button class="video-btn-sm" onclick="NA.send('fullscreen','')">⛶</button></div></div>]], id, src, poster)
          elseif it.id == "carousel" then
            local slides = data.slides or {}
            local slidesHtml = ""
            local dotsHtml = ""
            for i, slide in ipairs(slides) do
                local img = slide.img or ""
                local title = slide.title or ("幻灯片 "..i)
                if img ~= "" then
                    slidesHtml = slidesHtml .. string.format('<div class="carousel-slide"><img src="%s" data-title="%s"></div>', img, title)
                  else
                    local bg = slide.bg or "#333"
                    slidesHtml = slidesHtml .. string.format('<div class="carousel-slide" style="background:%s;" data-title="%s">%s</div>', bg, title, slide.num or i)
                end
                dotsHtml = dotsHtml .. string.format('<div class="carousel-dot%s"></div>', i == 1 and " active" or "")
            end
            return string.format('<div class="carousel-container" data-widget-id="%s"><div class="carousel-track"><div class="carousel-slides">%s</div><button class="carousel-arrow prev">‹</button><button class="carousel-arrow next">›</button></div><div class="carousel-dots">%s</div></div>', id, slidesHtml, dotsHtml)
        end
      elseif it.type == "browser" then
        local url = it.url or "about:blank"
        return string.format('<div class="browser-container" data-widget-id="%s"><iframe src="%s" sandbox="allow-scripts allow-same-origin"></iframe></div>', id, url)
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
            opts[#opts+1] = string.format('<div class="select-option" onclick="selectOption(\'%s\',\'%s\',\'%s\')">%s</div>', id, htmlEscape(opt), htmlEscape(opt), htmlEscape(opt))
        end
        parts[#parts+1] = string.format('<div class="select-options" id="select_opts_%s">%s</div>', id, table.concat(opts))
    end
    return table.concat(parts, "\n")
end

function buildHtml()
    selectOptionsCache = {}
    local itemsHtml = buildItems()
    local titleHtml = htmlEscape(menu.title or "MENU")
    local configJson = buildConfig()
    local h = htmlTemplate
    h = h:gsub("{{TITLE}}", function() return titleHtml end)
    h = h:gsub("{{ITEMS}}", function() return itemsHtml end)
    h = h:gsub("{{CONFIG}}", function() return configJson end)
    h = h:gsub("{{SELECT_OPTIONS}}", function() return buildSelectOptions() end)
    return h
end

function buildActions()
    local a = {}
    local function reg(it)
        if it.type == "button" and it.onClick then
            a[it.id] = function(d) return it.onClick(d) end
          elseif it.type == "switch" then
            a[it.id] = function(d)
                if it.onChange then it.onChange(d) end
                updateSwitchFloatState(it.id, d == "1")
                return ""
            end
          elseif it.type == "checkbox" and it.onChange then
            a[it.id] = function(d) return it.onChange(d) end
          elseif it.type == "select" and it.onChange then
            a[it.id] = function(d) return it.onChange(d) end
          elseif it.type == "slider" and it.onChange then
            a[it.id] = function(d) return it.onChange(d) end
          elseif it.type == "stepper" and it.onChange then
            a[it.id] = function(d) return it.onChange(d) end
          elseif it.type == "input" and it.onConfirm then
            a[it.id] = function(d) return it.onConfirm(d) end
          elseif it.onChange then
            a[it.id] = function(d) return it.onChange(d) end
        end
        if it.type == "collapsible" and it.items then
            for _, subIt in ipairs(it.items) do reg(subIt) end
        end
    end
    if isGroupedMenu() then
        for _, g in ipairs(menu) do
            for _, it in ipairs(g.items or {}) do reg(it) end
        end
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

    a["create_float_btn"] = function(data)
        local parts = {}
        for part in data:gmatch("[^|]+") do table.insert(parts, part) end
        local id = parts[1]
        local btnText = parts[2] or "按钮"
        local item = findMenuItemById(id)
        if item then
            local callback = item.onClick
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
        activity.runOnUiThread(function() createSwitchFloatingButton(id, label) end)
        return ""
    end

    a["dialog_result"] = function(data)
        local parts = {}
        for part in data:gmatch("[^|]+") do table.insert(parts, part) end
        local result = parts[1]
        local cmd = parts[2] or ""
        local handler = dialogHandlers[cmd]
        if handler then
            handler(result == "1")
            dialogHandlers[cmd] = nil
        end
        return ""
    end

    a["__exit"] = function()
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
        floatingButtons = {}
        switchFloats = {}
        activity.runOnUiThread(function()
            pcall(function() window.removeView(xfc) end)
            pcall(function() if capsule then window.removeView(capsule) end end)
            luajava.exit()
        end)
    end
    return a
end

function showConfirm(title, message, onConfirm, onCancel)
    local cmd = tostring(os.time()) .. math.random(1000)
    dialogHandlers[cmd] = function(confirmed)
        if confirmed and onConfirm then onConfirm() end
        if not confirmed and onCancel then onCancel() end
    end
    activity.runOnUiThread(function()
        local script = string.format("showConfirmDialog('%s','%s','确定','取消','%s')", title:gsub("'","\\'"):gsub("\n","\\n"), message:gsub("'","\\'"):gsub("\n","\\n"), cmd)
        _G.web.evaluateJavascript(script, nil)
    end)
end

------------------------------------------------------------
-- 动态岛功能
------------------------------------------------------------
local capsule = nil
local capsule_text1 = nil
local capsule_text2 = nil
local capsule_text_container = nil
local carouselHandler = nil
local carouselRunnable = nil
local capsuleMsgTimer = nil

function stopTextCarousel()
    if carouselHandler then carouselHandler.removeCallbacks(carouselRunnable); carouselHandler = nil end
    if capsuleMsgTimer then capsuleMsgTimer.cancel(); capsuleMsgTimer = nil end
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
                run = function() capsule.setLayerType(View.LAYER_TYPE_NONE, nil) end
            })).start()
        end
    })).start()
end

function measureTextWidth(textView, text)
    local paint = textView.getPaint()
    local w = paint.measureText(text)
    return math.max(math.floor(w + 8 * activity.getResources().getDisplayMetrics().density), math.floor(40 * activity.getResources().getDisplayMetrics().density))
end

function animateWidth(fromWidth, toWidth, duration)
    if not capsule_text_container then return end
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

function startCapsuleCarousel()
    if not capsule or not capsule_text1 or not capsule_text2 or not capsule_text_container then return end
    stopTextCarousel()
    local texts = lunfanwenzi[2]
    local density = activity.getResources().getDisplayMetrics().density
    if not texts or #texts == 0 then texts = {menu.title or "QY"} end
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
            if carouselHandler then carouselHandler.postDelayed(carouselRunnable, 10000) end
        end
    })
    carouselHandler.postDelayed(carouselRunnable, 10000)
end

function showCapsuleMessage(msg)
    if not capsule or not capsule_text1 or not capsule_text2 then return end
    stopTextCarousel()
    capsule_text1.animate().cancel()
    capsule_text2.animate().cancel()
    capsule_text1.setText(msg)
    capsule_text1.setTranslationY(0)
    capsule_text1.setAlpha(1)
    capsule_text2.setAlpha(0)
    local w = measureTextWidth(capsule_text1, msg)
    local lp = capsule_text_container.getLayoutParams()
    lp.width = w
    capsule_text_container.setLayoutParams(lp)
    local handler = luajava.newInstance("android.os.Handler", Looper.getMainLooper())
    capsuleMsgTimer = luajava.createProxy("java.lang.Runnable", {
        run = function()
            capsuleMsgTimer = nil
            startCapsuleCarousel()
        end
    })
    handler.postDelayed(capsuleMsgTimer, 3000)
end

function createCapsule()
    local density = activity.getResources().getDisplayMetrics().density
    local capsuleLayout = {
        LinearLayout,
        id = "capsule",
        orientation = 0,
        gravity = "center_vertical",
        layout_width = "wrap",
        layout_height = "wrap",
        paddingLeft = "18dp",
        paddingRight = "18dp",
        paddingTop = "9dp",
        paddingBottom = "9dp",
    }
    table.insert(capsuleLayout, { TextView, id = "capsule_emoji", text = tostring(lunfanwenzi[1][1]), textSize = "13sp", layout_width = "wrap", layout_height = "wrap", layout_marginRight = "8dp" })
    table.insert(capsuleLayout, { View, layout_width = "4dp", layout_height = "4dp", layout_marginRight = "8dp",
        background = function()
            local dot = luajava.newInstance("android.graphics.drawable.GradientDrawable")
            dot.setShape(GradientDrawable.OVAL); dot.setColor(0x30FFFFFF); return dot
        end
    })
    table.insert(capsuleLayout, { FrameLayout, id = "capsule_text_container", layout_width = "wrap", layout_height = "18dp", layout_marginRight = "4dp" })
    capsule = loadlayout(capsuleLayout)
    capsule_text_container = capsule.getChildAt(2)
    capsule_text1 = TextView(activity)
    capsule_text1.setText(menu.title or "QY"); capsule_text1.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12); capsule_text1.setTextColor(0xFFF0F0F5); capsule_text1.setTypeface(nil, 1)
    capsule_text1.setGravity(android.view.Gravity.CENTER); capsule_text1.setEllipsize(android.text.TextUtils.TruncateAt.END); capsule_text1.setMaxLines(1)
    local t1lp = FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT); t1lp.gravity = android.view.Gravity.CENTER
    capsule_text1.setLayoutParams(t1lp); capsule_text_container.addView(capsule_text1)
    capsule_text2 = TextView(activity)
    capsule_text2.setText(""); capsule_text2.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12); capsule_text2.setTextColor(0xFFF0F0F5); capsule_text2.setTypeface(nil, 1)
    capsule_text2.setGravity(android.view.Gravity.CENTER); capsule_text2.setEllipsize(android.text.TextUtils.TruncateAt.END); capsule_text2.setMaxLines(1)
    capsule_text2.setAlpha(0.0); capsule_text2.setTranslationY(math.floor(20 * density))
    local t2lp = FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT); t2lp.gravity = android.view.Gravity.CENTER
    capsule_text2.setLayoutParams(t2lp); capsule_text_container.addView(capsule_text2)
    local gd = luajava.newInstance("android.graphics.drawable.GradientDrawable")
    gd.setShape(GradientDrawable.RECTANGLE); gd.setCornerRadius(9999); gd.setColor(0xF21C1C1E); gd.setStroke(math.floor(0.5 * density), 0x25FFFFFF)
    if Build.VERSION.SDK_INT >= 28 then capsule.setElevation(6 * density) end
    capsule.setBackgroundDrawable(gd)
    local LP = WindowManager.LayoutParams
    local lp = luajava.new(LP)
    lp.type = LP.TYPE_APPLICATION_OVERLAY; lp.format = PixelFormat.RGBA_8888; lp.flags = LP.FLAG_NOT_FOCUSABLE | LP.FLAG_NOT_TOUCH_MODAL
    lp.gravity = Gravity.TOP + Gravity.CENTER_HORIZONTAL; lp.y = math.floor(24 * density); lp.width = LP.WRAP_CONTENT; lp.height = LP.WRAP_CONTENT
    local longPressHandler = luajava.newInstance("android.os.Handler", Looper.getMainLooper())
    local longPressRunnable = nil; local longPressTriggered = false; local touchStartX, touchStartY = 0, 0
    local MOVE_THRESHOLD = 20 * density
    capsule.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", {
        onTouch = function(v, event)
            local action = event.getAction()
            if action == MotionEvent.ACTION_DOWN then
                longPressTriggered = false; touchStartX = event.getRawX(); touchStartY = event.getRawY()
                v.animate().scaleX(0.88).scaleY(0.88).setDuration(80).start()
                longPressRunnable = luajava.createProxy("java.lang.Runnable", {
                    run = function()
                        longPressTriggered = true; gg.toast("正在退出...")
                        if type(menu.onExit) == "function" then pcall(menu.onExit) end
                        activity.runOnUiThread(function()
                            pcall(function() window.removeView(xfc) end)
                            pcall(function() if capsule then window.removeView(capsule) end end)
                        end)
                        luajava.newInstance("android.os.Handler", Looper.getMainLooper())
                        .postDelayed(luajava.createProxy("java.lang.Runnable", { run = function() luajava.exit() end }), 200)
                    end
                })
                longPressHandler.postDelayed(longPressRunnable, 1000)
            elseif action == MotionEvent.ACTION_MOVE then
                local dx = math.abs(event.getRawX() - touchStartX); local dy = math.abs(event.getRawY() - touchStartY)
                if dx > MOVE_THRESHOLD or dy > MOVE_THRESHOLD then
                    if longPressRunnable then longPressHandler.removeCallbacks(longPressRunnable); longPressRunnable = nil end
                end
            elseif action == MotionEvent.ACTION_UP then
                if longPressRunnable then longPressHandler.removeCallbacks(longPressRunnable); longPressRunnable = nil end
                if not longPressTriggered then
                    v.animate().scaleX(1.0).scaleY(1.0).setDuration(280).start()
                    local now = luajava.bindClass("java.lang.System").currentTimeMillis()
                    if now - lastClickTime < DOUBLE_CLICK_INTERVAL then recalcUISize(); lastClickTime = 0
                    else toggleUI(); lastClickTime = now end
                end
            elseif action == MotionEvent.ACTION_CANCEL then
                if longPressRunnable then longPressHandler.removeCallbacks(longPressRunnable); longPressRunnable = nil end
                v.animate().scaleX(1.0).scaleY(1.0).setDuration(200).start()
            end
            return true
        end
    }))
    window.addView(capsule, lp)
    capsule.setVisibility(8)
    startCapsuleCarousel()
end

function recalcUISize()
    if not xfc then return end
    activity.runOnUiThread(function()
        local dm = activity.getResources().getDisplayMetrics()
        local d = dm.density
        local sw, sh = dm.widthPixels, dm.heightPixels
        local resources = activity.getResources()
        local statusBarId = resources.getIdentifier("status_bar_height", "dimen", "android")
        local statusBarH = 0
        if statusBarId > 0 then statusBarH = resources.getDimensionPixelSize(statusBarId) end
        local navigationBarId = resources.getIdentifier("navigation_bar_height", "dimen", "android")
        local navigationBarH = 0
        if navigationBarId > 0 then navigationBarH = resources.getDimensionPixelSize(navigationBarId) end
        local usableW = sw
        local usableH = sh - statusBarH - navigationBarH
        local baseW, baseH = 650, 360
        local maxW = usableW / d - 24
        local maxH = usableH / d - 56
        local scale = math.min(maxW / baseW, maxH / baseH)
        scale = math.min(scale, 1.15)
        scale = math.max(scale, 0.6)
        local finalW = math.floor(baseW * scale)
        local finalH = math.floor(baseH * scale)
        local targetW = math.floor(finalW * d + 0.5)
        local targetH = math.floor(finalH * d)
        -- 更新WebView尺寸
        local webView = xfc.getChildAt(0)
        if webView then
            local wlp = webView.getLayoutParams()
            wlp.width = targetW
            wlp.height = targetH
            webView.setLayoutParams(wlp)
            webView.requestLayout()
        end
        -- 更新外层容器窗口尺寸
        local xlp = xfc.getLayoutParams()
        xlp.width = targetW
        xlp.height = targetH
        window.updateViewLayout(xfc, xlp)
        -- 更新viewport
        if _G.web then
            local js = string.format("var meta = document.querySelector('meta[name=viewport]');if(meta){meta.content='width=%dpx,initial-scale=1.0,user-scalable=no';}window.dispatchEvent(new Event('resize'));", targetW)
            _G.web.evaluateJavascript(js, nil)
        end
    end)
end

function createFloatingButton(text, onClick)
    local density = activity.getResources().getDisplayMetrics().density
    local tempTv = TextView(activity); tempTv.setText(text); tempTv.setTextSize(13); tempTv.setTypeface(Typeface.DEFAULT_BOLD); tempTv.measure(0,0)
    local textWidth = tempTv.getMeasuredWidth(); local textHeight = tempTv.getMeasuredHeight()
    local paddingH = 14 * density; local paddingV = 8 * density
    local width = textWidth + paddingH * 2; local height = math.max(textHeight + paddingV * 2, 36 * density)
    local container = luajava.newInstance("android.widget.LinearLayout", activity)
    container.setOrientation(0); container.setGravity(Gravity.CENTER); container.setPadding(paddingH, paddingV, paddingH, paddingV)
    local gd = luajava.newInstance("android.graphics.drawable.GradientDrawable")
    gd.setShape(GradientDrawable.RECTANGLE); gd.setCornerRadius(10 * density); gd.setColor(0xCC1C1C1E); gd.setStroke(math.floor(0.8 * density), 0x30FFFFFF)
    container.setBackground(gd); if Build.VERSION.SDK_INT >= 28 then container.setElevation(6 * density) end
    local btnText = TextView(activity); btnText.setText(text); btnText.setTextSize(13); btnText.setTextColor(0xFFFFFFFF); btnText.setGravity(Gravity.CENTER); btnText.setTypeface(Typeface.DEFAULT_BOLD)
    container.addView(btnText)
    local LP = WindowManager.LayoutParams; local lp = luajava.new(LP)
    lp.type = LP.TYPE_APPLICATION_OVERLAY; lp.format = PixelFormat.RGBA_8888; lp.flags = LP.FLAG_NOT_FOCUSABLE | LP.FLAG_NOT_TOUCH_MODAL
    lp.gravity = Gravity.TOP | Gravity.LEFT; lp.x = math.floor(100 * density); lp.y = math.floor(300 * density); lp.width = math.floor(width); lp.height = math.floor(height)
    local btnObj = { view = container, lp = lp, startX = 0, startY = 0, initX = lp.x, initY = lp.y, longPressRunnable = nil, moved = false, removed = false }
    local handler = luajava.newInstance("android.os.Handler", Looper.getMainLooper())
    container.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", {
        onTouch = function(v, event)
            if btnObj.removed then return false end
            local action = event.getAction()
            if action == MotionEvent.ACTION_DOWN then
                btnObj.startX = event.getRawX(); btnObj.startY = event.getRawY(); btnObj.initX = lp.x; btnObj.initY = lp.y; btnObj.moved = false
                v.animate().scaleX(0.88).scaleY(0.88).setDuration(80).start()
                btnObj.longPressRunnable = luajava.createProxy("java.lang.Runnable", { run = function()
                    if not btnObj.moved then btnObj.removed = true; removeFloatingButton(btnObj) end
                end})
                handler.postDelayed(btnObj.longPressRunnable, 500)
            elseif action == MotionEvent.ACTION_MOVE then
                if math.abs(event.getRawX() - btnObj.startX) > 5 or math.abs(event.getRawY() - btnObj.startY) > 5 then
                    btnObj.moved = true; if btnObj.longPressRunnable then handler.removeCallbacks(btnObj.longPressRunnable); btnObj.longPressRunnable = nil end
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

function updateSwitchFloatState(switchId, isOn)
    local obj = switchFloats[switchId]; if not obj then return end
    local gd = obj.gd; local density = activity.getResources().getDisplayMetrics().density
    if isOn then
        if not obj.anim then
            local animator = luajava.newInstance("android.animation.ValueAnimator")
            animator.setIntValues(2, 5); animator.setDuration(800)
            animator.setRepeatCount(luajava.bindClass("android.animation.ValueAnimator").INFINITE)
            animator.setRepeatMode(luajava.bindClass("android.animation.ValueAnimator").REVERSE)
            animator.addUpdateListener(luajava.createProxy("android.animation.ValueAnimator$AnimatorUpdateListener", {
                onAnimationUpdate = function(anim) gd.setStroke(anim.getAnimatedValue(), 0xFF39FF14) end
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
    local tempTv = TextView(activity); tempTv.setText(label); tempTv.setTextSize(13); tempTv.setTypeface(Typeface.DEFAULT_BOLD); tempTv.measure(0,0)
    local textWidth = tempTv.getMeasuredWidth(); local textHeight = tempTv.getMeasuredHeight()
    local paddingH = 14 * density; local paddingV = 8 * density
    local width = textWidth + paddingH * 2; local height = math.max(textHeight + paddingV * 2, 36 * density)
    local container = luajava.newInstance("android.widget.LinearLayout", activity)
    container.setOrientation(0); container.setGravity(Gravity.CENTER); container.setPadding(paddingH, paddingV, paddingH, paddingV)
    local gd = luajava.newInstance("android.graphics.drawable.GradientDrawable")
    gd.setShape(GradientDrawable.RECTANGLE); gd.setCornerRadius(10 * density); gd.setColor(0xCC1C1C1E); gd.setStroke(math.floor(2 * density), 0x60FFFFFF)
    container.setBackground(gd); if Build.VERSION.SDK_INT >= 28 then container.setElevation(6 * density) end
    local btnText = TextView(activity); btnText.setText(label); btnText.setTextSize(13); btnText.setTextColor(0xFFFFFFFF); btnText.setGravity(Gravity.CENTER); btnText.setTypeface(Typeface.DEFAULT_BOLD)
    container.addView(btnText)
    local LP = WindowManager.LayoutParams; local lp = luajava.new(LP)
    lp.type = LP.TYPE_APPLICATION_OVERLAY; lp.format = PixelFormat.RGBA_8888; lp.flags = LP.FLAG_NOT_FOCUSABLE | LP.FLAG_NOT_TOUCH_MODAL
    lp.gravity = Gravity.TOP | Gravity.LEFT; lp.x = math.floor(100 * density); lp.y = math.floor(300 * density); lp.width = math.floor(width); lp.height = math.floor(height)
    local btnObj = { view = container, lp = lp, gd = gd, anim = nil, btnText = btnText, startX = 0, startY = 0, initX = lp.x, initY = lp.y, longPressRunnable = nil, moved = false, removed = false, isOn = false }
    local handler = luajava.newInstance("android.os.Handler", Looper.getMainLooper())
    container.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", {
        onTouch = function(v, event)
            if btnObj.removed then return false end
            local action = event.getAction()
            if action == MotionEvent.ACTION_DOWN then
                btnObj.startX = event.getRawX(); btnObj.startY = event.getRawY(); btnObj.initX = lp.x; btnObj.initY = lp.y; btnObj.moved = false
                v.animate().scaleX(0.88).scaleY(0.88).setDuration(80).start()
                btnObj.longPressRunnable = luajava.createProxy("java.lang.Runnable", { run = function()
                    if not btnObj.moved then btnObj.removed = true; removeSwitchFloat(switchId) end
                end})
                handler.postDelayed(btnObj.longPressRunnable, 500)
            elseif action == MotionEvent.ACTION_MOVE then
                if math.abs(event.getRawX() - btnObj.startX) > 5 or math.abs(event.getRawY() - btnObj.startY) > 5 then
                    btnObj.moved = true; if btnObj.longPressRunnable then handler.removeCallbacks(btnObj.longPressRunnable); btnObj.longPressRunnable = nil end
                end
                local dx = event.getRawX() - btnObj.startX; local dy = event.getRawY() - btnObj.startY
                lp.x = btnObj.initX + dx; lp.y = btnObj.initY + dy; window.updateViewLayout(v, lp)
            elseif action == MotionEvent.ACTION_UP then
                v.animate().scaleX(1.0).scaleY(1.0).setDuration(200).start()
                if btnObj.longPressRunnable then handler.removeCallbacks(btnObj.longPressRunnable); btnObj.longPressRunnable = nil end
                if not btnObj.moved then
                    btnObj.isOn = not btnObj.isOn
                    updateSwitchFloatState(switchId, btnObj.isOn)
                    local script = string.format("var sw=document.getElementById('%s');if(sw){sw.checked=%s;sw.dispatchEvent(new Event('change'));}", switchId, btnObj.isOn and "true" or "false")
                    _G.web.evaluateJavascript(script, nil)
                end
            elseif action == MotionEvent.ACTION_CANCEL then
                v.animate().scaleX(1.0).scaleY(1.0).setDuration(200).start()
                if btnObj.longPressRunnable then handler.removeCallbacks(btnObj.longPressRunnable); btnObj.longPressRunnable = nil end
            end
            return true
        end
    }))
    window.addView(container, lp); table.insert(floatingButtons, btnObj); switchFloats[switchId] = btnObj
    local item = findMenuItemById(switchId)
    if item and item.default then btnObj.isOn = true; updateSwitchFloatState(switchId, true) end
    return btnObj
end

function removeSwitchFloat(switchId)
    local btnObj = switchFloats[switchId]; if not btnObj then return end
    btnObj.removed = true; if btnObj.anim then btnObj.anim.cancel() end
    activity.runOnUiThread(function() pcall(function() window.removeView(btnObj.view) end) end)
    switchFloats[switchId] = nil
end

function toggleUI()
    if Looper.myLooper() ~= Looper.getMainLooper() then activity.runOnUiThread(toggleUI); return end
    if isToggling then return end
    isToggling = true
    local isVisible = (xfc.getVisibility() == 0)
    if isVisible then
        xfc.animate().scaleX(0.9).scaleY(0.9).alpha(0.0).setDuration(180).setInterpolator(AccelerateDecelerateInterpolator()).start()
        luajava.newInstance("android.os.Handler", Looper.getMainLooper()).postDelayed(luajava.createProxy("java.lang.Runnable", {
            run = function()
                xfc.setVisibility(8); xfc.setScaleX(1.0); xfc.setScaleY(1.0); xfc.setAlpha(1.0)
                if capsule then
                    capsule.setVisibility(0); capsule.setScaleX(0.8); capsule.setScaleY(0.8); capsule.setAlpha(0.0)
                    capsule.animate().scaleX(1.0).scaleY(1.0).alpha(1.0).setDuration(220).setInterpolator(AccelerateDecelerateInterpolator()).start()
                end
                updateTouchFlags(false); isToggling = false
            end
        }), 180)
    else
        if capsule then
            capsule.animate().scaleX(0.8).scaleY(0.8).alpha(0.0).setDuration(150).setInterpolator(AccelerateDecelerateInterpolator()).start()
            luajava.newInstance("android.os.Handler", Looper.getMainLooper()).postDelayed(luajava.createProxy("java.lang.Runnable", {
                run = function()
                    capsule.setVisibility(8); capsule.setScaleX(1.0); capsule.setScaleY(1.0); capsule.setAlpha(1.0)
                    xfc.setVisibility(0); xfc.setScaleX(0.9); xfc.setScaleY(0.9); xfc.setAlpha(0.0)
                    xfc.animate().scaleX(1.0).scaleY(1.0).alpha(1.0).setDuration(260).setInterpolator(AccelerateDecelerateInterpolator()).start()
                    updateTouchFlags(true); isToggling = false
                end
            }), 150)
        else
            xfc.setVisibility(0); xfc.setScaleX(0.9); xfc.setScaleY(0.9); xfc.setAlpha(0.0)
            xfc.animate().scaleX(1.0).scaleY(1.0).alpha(1.0).setDuration(260).setInterpolator(AccelerateDecelerateInterpolator()).start()
            updateTouchFlags(true); isToggling = false
        end
    end
end

function updateTouchFlags(interactive)
    local LP = WindowManager.LayoutParams; local lp = xfc.getLayoutParams()
    if interactive then
        lp.flags = lp.flags | LP.FLAG_WATCH_OUTSIDE_TOUCH; lp.flags = lp.flags & ~LP.FLAG_NOT_TOUCH_MODAL
    else
        lp.flags = lp.flags | LP.FLAG_NOT_TOUCH_MODAL; lp.flags = lp.flags & ~LP.FLAG_WATCH_OUTSIDE_TOUCH
    end
    lp.flags = lp.flags | LP.FLAG_NOT_FOCUSABLE
    window.updateViewLayout(xfc, lp)
end

function getLayoutParams()
    local LP = WindowManager.LayoutParams; local lp = luajava.new(LP)
    lp.type = LP.TYPE_APPLICATION_OVERLAY; lp.format = PixelFormat.RGBA_8888
    lp.flags = LP.FLAG_NOT_FOCUSABLE | LP.FLAG_NOT_TOUCH_MODAL | LP.FLAG_WATCH_OUTSIDE_TOUCH
    lp.gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL
    lp.width = LP.WRAP_CONTENT; lp.height = LP.WRAP_CONTENT
    return lp
end

function showToast(msg, type)
    type = type or "info"
    if _G.web then
        local safeMsg = tostring(msg):gsub("'","\\'"):gsub("\n","\\n")
        activity.runOnUiThread(function() _G.web.evaluateJavascript("showToast('"..safeMsg.."','"..type.."')", nil) end)
    end
end

function showProgress(max, label, id)
    id = id or "default"
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("showProgress("..(max or 100)..",'"..(label or ""):gsub("'","\\'").."','"..id.."')", nil) end) end
end

function updateProgress(current, id)
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("updateProgress("..current..",'"..(id or "default").."')", nil) end) end
end

function showLoading(text)
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("showLoading('"..(text or "加载中..."):gsub("'","\\'").."')", nil) end) end
end

function hideLoading() if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("hideLoading()", nil) end) end end
function showLoadingProgress(max, label)
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("showLoadingProgress("..(max or 100)..",'"..(label or ""):gsub("'","\\'").."')", nil) end) end
end
function updateLoadingProgress(current)
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("updateLoadingProgress("..current..")", nil) end) end
end
function hideLoadingProgress() if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("hideLoading()", nil) end) end end

function updateImage(src, widgetId)
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("updateImage('"..tostring(src):gsub("'","\\'").."','"..widgetId.."')", nil) end) end
end
function updateVideo(src, poster, widgetId)
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("updateVideo('"..(src or ""):gsub("'","\\'").."','"..(poster or ""):gsub("'","\\'").."','"..widgetId.."')", nil) end) end
end
function updateCarousel(slides, widgetId)
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("updateCarousel("..jsonEncode(slides)..",'"..widgetId.."')", nil) end) end
end
function updateBrowser(url, widgetId)
    if _G.web then activity.runOnUiThread(function() _G.web.evaluateJavascript("updateBrowser('"..tostring(url):gsub("'","\\'").."','"..widgetId.."')", nil) end) end
end

------------------------------------------------------------
-- 主UI加载
------------------------------------------------------------
function LoadUI()
    local dm = activity.getResources().getDisplayMetrics()
    local d = dm.density; local sw, sh = dm.widthPixels, dm.heightPixels
    local resources = activity.getResources()
    local statusBarId = resources.getIdentifier("status_bar_height", "dimen", "android")
    local statusBarH = 0
    if statusBarId > 0 then statusBarH = resources.getDimensionPixelSize(statusBarId) end
    local navigationBarId = resources.getIdentifier("navigation_bar_height", "dimen", "android")
    local navigationBarH = 0
    if navigationBarId > 0 then navigationBarH = resources.getDimensionPixelSize(navigationBarId) end
    local usableW = sw; local usableH = sh - statusBarH - navigationBarH
    local baseW, baseH = 650, 360
    local maxW = usableW / d - 24; local maxH = usableH / d - 56
    local scale = math.min(maxW / baseW, maxH / baseH)
    scale = math.min(scale, 1.15); scale = math.max(scale, 0.6)
    local finalW = math.floor(baseW * scale); local finalH = math.floor(baseH * scale)
    local targetW = math.floor(finalW * d + 0.5); local targetH = math.floor(finalH * d)

    xfc = loadlayout({
        LinearLayout,
        { WebView,
            id = "web",
            layout_width = targetW,
            layout_height = targetH,
        },
    })
    _G.web = web
    local ws = web.getSettings()
    ws.setJavaScriptEnabled(true); ws.setDomStorageEnabled(true)
    ws.setBlockNetworkLoads(false); ws.setBlockNetworkImage(false); ws.setMixedContentMode(0)
    web.setBackgroundColor(0x00000000); web.setWebViewClient(WebViewClient()); web.setFocusableInTouchMode(true); web.requestFocus()

    bridge = luajava.new(WebBridge, web)
    actions = buildActions()
    local Handler = import "com.Shizuku.WebBridge$EventHandler"
    bridge.setHandler(Handler {
        onEvent = function(name, data)
            local fn = actions[name]
            if fn then return fn(data) or "" end
            return ""
        end,
    })
    web.addJavascriptInterface(bridge, "NA")

    local html = buildHtml()
    html = html:gsub("{{VIEWPORT_CONTENT}}", "width="..targetW.."px, initial-scale=1.0, user-scalable=no")
    web.loadDataWithBaseURL("file:///android_asset/", html, "text/html", "utf-8", nil)

    xfc.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", {
        onTouch = function(v, event)
            if event.getAction() == MotionEvent.ACTION_OUTSIDE then toggleUI(); return true end
            return false
        end
    }))

    local lp = getLayoutParams()
    lp.y = statusBarH
    window.addView(xfc, lp)

    if capsuleEnabled then createCapsule() end
    activity.runOnUiThread(function() updateTouchFlags(true) end)
    setOnAudioListener(function(status)
        if not volumeKeyUI then return end
        if status == "减少" then if xfc.getVisibility() == 0 then toggleUI() end
        elseif status == "增加" then if xfc.getVisibility() == 8 then toggleUI() end end
    end)
end

Lock.Ui(LoadUI, nil, function(err) print(err); luajava.exit() end)