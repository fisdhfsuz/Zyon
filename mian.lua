you = {
    "王牌竞速",
    "极道无赖",
    "道场护身术",
    "苍翼混沌效应",
    "重生细胞",
    "魔法工艺",
'测试'
}
url = "https://cdn.jsdmirror.com/gh/fisdhfsuz/Zyon@main/游戏项目/"
BASE_PATH = "/storage/emulated/0/Android/"
r = io.open(BASE_PATH .. "我的游戏","r+")
function xx()
    local ui = gg.choice({
        "全部游戏",
        "创建游戏",
        "我的游戏",
        "删除游戏",
        "退出",
    })

    k = {
        function()
            local u = gg.choice(you)
            if u then
                local ur = url .. you[ui] .. ".lua"
                local a = gg.makeRequest(ur).content
                load(a)()
              else
                xx()
            end
        end,

        function()
            local u = gg.choice(you)
            if u then
                local ok,v = pcall(function()
                    dofile(BASE_PATH .. "我的游戏")
                    table.insert(QY,you[u])
                    io.open(BASE_PATH .. "我的游戏","w"):write("QY = " .. tostring(QY))
                    gg.alert("创建成功 返回上一页点击 [我的游戏] 查看")
                    xx()
                end)
                if not ok then
                    r:write("QY = {}")
                end
              else
                gg.alert("未创建游戏")
                xx()
            end
        end,

        function()
            dofile(BASE_PATH .. "我的游戏")
            local u = gg.choice(QY)
            if u then
                local ur = url .. QY[u] .. ".lua"
                local a = gg.makeRequest(ur).content
                load(a)()
              else
                xx()
            end
        end,

        function()
            dofile(BASE_PATH .. "我的游戏")
            local u = gg.choice(QY,nil,"选择删除的游戏")
            if u then
                table.remove(QY,u)
                io.open(BASE_PATH .. "我的游戏","w"):write("QY = " .. tostring(QY))
                gg.alert("删除完成 返回 [我的游戏] 查看")
                xx()
            end
        end,
        function()
            os.exit(print("感谢支持"))
        end,
    }
    if ui then
        k[ui]()
      else
        xx()
    end

end
xx()