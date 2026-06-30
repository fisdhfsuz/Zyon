function WanJia(gameFuncMenu)
gui.addTextView(gameFuncMenu, [[局内开启]], 11, 0xFFFFFFFF, null)
gui.addLine(gameFuncMenu, 0.5, 0xFFE0E0E0, true)
    addSwitch(gameFuncMenu,"无敌","",function()
        local offsets = main_Chu("PlayerControl", "SetInvincible",1)
        local up = main_Chu("PlayerControl", "Update",1)
        RAM(offsets,"s0",false,false,false,false,false,16,4,4,4,4,4,100000000,false,false,false,false,false,up)
    end,
    function()
        local offsets1 = main_Chu("PlayerControl", "SetInvincible",1)
        local up = main_Chu("PlayerControl", "Update",1)
        RAM(offsets1,false,false,false,false,false,false,4,4,4,4,4,4,0,false,false,false,false,false,up)
    end)

    addSwitch(gameFuncMenu,"骑老虎","",function()
        local offsets = main_Chu("PlayerControl", "StartTigerDrive",1)
        local up = main_Chu("PlayerControl", "Update",1)
        RAM(offsets,"x1",false,false,false,false,false,4,4,4,4,4,4,1,false,false,false,false,false,up)

    end,
    function()
        local up = main_Chu("PlayerControl", "Update",1)
        local offsets1 = main_Chu("PlayerControl", "EndDriverTiger",1)
        RAM(offsets1,false,false,false,false,false,false,4,4,4,4,4,4,false,false,false,false,false,false,up)
    end)

    addButton(gameFuncMenu,"启动磁铁",function()
        local offsets = main_Chu("PlayerControl", "StartMagnet",1)
        local up = main_Chu("PlayerControl", "Update",1)
        RAM(offsets,false,false,false,false,false,false,4,4,4,4,4,4,false,false,false,false,false,false,up)
    end)

    addSwitch(gameFuncMenu,"修改重力","",function()
        local offsets = main_so + main_Chu("PlayerControl", "GetGravity",1)
        zhongli = gg.getValues({
            {address = offsets,flags = 4},
            {address = offsets + 4,flags = 4},
            {address = offsets + 8,flags = 4},
        })
        gg.setValues({
            { address = zhongli[1].address, flags = 4, value = "~A8 LDR	 s0, [PC,#0x8]" },
            { address = zhongli[2].address, flags = 4, value = "~A8 RET" },
            { address = zhongli[3].address, flags = 16, value = 50 },
        })
    end,
    function()
        gg.setValues({
            { address = zhongli[1].address, flags = 4, value = zhongli[1].value },
            { address = zhongli[2].address, flags = 4, value = zhongli[2].value },
            { address = zhongli[3].address, flags = 16, value = zhongli[3].value },
        })
    end)
    addSeekBarInt(gameFuncMenu,"修改移速",2,10,function(txt)
        local offsets = main_so + main_Chu("PlayerControl", "speedMulti",1)
        gg.setValues({
            { address = offsets, flags = 4, value = "~A8 LDR	 s0, [PC,#0x8]" },
            { address = offsets + 4, flags = 4, value = "~A8 RET" },
            { address = offsets + 8, flags = 16, value = txt },
        })
    end)
    addButton(gameFuncMenu,"增加分数",function()
        local up = main_Chu("PlayerControl", "Update",1)
        local offsets = main_Chu("PlayerControl", "AddScore",1)
        RAM(offsets,"x1",false,false,false,false,false,4,4,4,4,4,4,1000000000,false,false,false,false,false,up)
        for i = 1,20 do
            gg.setValues({ { address = Dz + 0xc + 0x350, flags = 4, value = 2 } })
        end
    end)
end