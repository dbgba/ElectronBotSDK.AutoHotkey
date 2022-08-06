; https://github.com/peng-zhihui/ElectronBot

Global ElectronBotSDKCode  ; 需要将ElectronBotSDKCode设为全局变量才能生效

ElectronBotSDKCode=
(`%
SDK加载连接:

Global 姿势 := New LowLevelSDK(A_ScriptDir "\ElectronBotSDK\ElectronBotSDK-LowLevel.dll")
Global 表情 := New PlayerSDK(A_ScriptDir "\ElectronBotSDK\ElectronBotSDK-Player.dll")
Return

; ================== ElectronBotSDK控制类库 ==================
Class LowLevelSDK {
    ; LowLevel 加载与连接
    __New(FilePath:="ElectronBotSDK-LowLevel.dll") {
        if FileExist(FilePath) {
            if (InStr(FilePath, "\")=0) and (InStr(FilePath, "/")=0)
                FilePath := A_ScriptDir "\" FilePath
            SplitPath, FilePath, 文件名, 文件路径
            DllCall("SetDllDirectory", "Str", 文件路径)  ; 重定向dll加载目录
            DllCall("LoadLibrary", "Str", 文件名)
            this.pLowLevel := DllCall("ElectronBotSDK-LowLevel\AHK_New", "Ptr")
            DllCall("ElectronBotSDK-LowLevel\AHK_Connect", "Ptr", this.pLowLevel, "char")
            DllCall("SetDllDirectory", "Str", A_ScriptDir)
        } else {
            MsgBox 0x10, 没有发现SDK文件！, %FilePath% 文件不存在！`n`n请将此脚本转移到附带的SDK改版目录下，`n再次打开脚本进行调用。
            ExitApp
        }
    }

    ; 断开LowLevel连接
    __Delete() {
        DllCall("ElectronBotSDK-LowLevel\AHK_Disconnect", "Ptr", this.pLowLevel, "char")
    }

    ; LowLevel 连接
    连接() {
        Return DllCall("ElectronBotSDK-LowLevel\AHK_Connect", "Ptr", this.pLowLevel, "char")
    }

    ; 断开LowLevel连接并清理占用
    断开连接() {
        DllCall("ElectronBotSDK-LowLevel\AHK_Disconnect", "Ptr", this.pLowLevel, "char")
        DllCall("ElectronBotSDK-LowLevel\AHK_Delete", "Ptr", this.pLowLevel)
    }

    ; 函数定义与稚晖君的上位机顺序一致：
    ; 参1=头部、参2=身体转向、参3=左臂展开、参4=左臂抬起、参5=右臂展开、参6=右臂抬起，参7可以设置图片路径
    ; 参1=-15~15、参2=-90~90、参3=-30~30、参4=-180~180、参5=-30~30、参6=-180~180。超过限定值则无效
    同步姿势(_j1, _j6, _j2, _j3, _j4, _j5, FilePath:="") {
        ; 原SDK对应：j1=头部、j2=左臂展开、j3=右臂抬起、j4=右臂展开、j5=左臂抬起、j6=身体转向
        DllCall("ElectronBotSDK-LowLevel\AHK_SetJointAngles", "Ptr", this.pLowLevel, "Float", _j1, "Float", _j2, "Float", _j3, "Float", _j4, "Float", _j5, "Float", _j6, "int", True)
        ; 在外部用全局变量设置路径可以让每个动作都调用一张图片，比如：Global LLSDKFilePath := "test.jpg"
        , (LLSDKFilePath!="" && FilePath := LLSDKFilePath)
        if (FilePath!="")
            if FileExist(FilePath)
                DllCall("ElectronBotSDK-LowLevel\AHK_SetImageSrc_Path", "Ptr", this.pLowLevel, "astr", FilePath)
        Return DllCall("ElectronBotSDK-LowLevel\AHK_Sync", "Ptr", this.pLowLevel, "char")  ; 同步上传
    }

    ; 仅设置不同步上传
    设置姿势(_j1, _j6, _j2, _j3, _j4, _j5, Enable:=True) {
        DllCall("ElectronBotSDK-LowLevel\AHK_SetJointAngles", "Ptr", this.pLowLevel, "Float", _j1, "Float", _j2, "Float", _j3, "Float", _j4, "Float", _j5, "Float", _j6, "int", Enable)
    }

    同步() {
        Return DllCall("ElectronBotSDK-LowLevel\AHK_Sync", "Ptr", this.pLowLevel, "char")
    }

    ; AHK_SetImageSrc_Mat 待测试后添加
    设置图像源路径(FilePath) {
        DllCall("ElectronBotSDK-LowLevel\AHK_SetImageSrc_Path", "Ptr", this.pLowLevel, "astr", FilePath)
    }

    ; SetExtraData 与 GetExtraData  待测试后添加
    ; GetJointAngles 与 SetJointAngles   待测试后添加
}


Class PlayerSDK {
    ; Player 加载与连接
    __New(FilePath:="ElectronBotSDK-Player.dll") {
        if FileExist(FilePath) {
            if (InStr(FilePath, "\")=0) and (InStr(FilePath, "/")=0)
                FilePath := A_ScriptDir "\" FilePath
            SplitPath, FilePath, 文件名, 文件路径
            DllCall("SetDllDirectory", "Str", 文件路径)  ; 重定向dll加载目录
            DllCall("LoadLibrary", "Str", 文件名)
            this.pPlayer := DllCall("ElectronBotSDK-Player\AHK_New", "Ptr")
            DllCall("ElectronBotSDK-Player\AHK_Connect", "Ptr", this.pPlayer, "char")
            DllCall("SetDllDirectory", "Str", A_ScriptDir)
        } else {
            MsgBox 0x10, 没有发现SDK文件！, %FilePath% 文件不存在！`n`n请将此脚本转移到附带的SDK改版目录下，`n再次打开脚本进行调用。
            ExitApp
        }
    }

    ; 断开Player连接
    __Delete() {
        DllCall("ElectronBotSDK-Player\AHK_Stop", "Ptr", this.pPlayer)
        DllCall("ElectronBotSDK-Player\AHK_Disconnect", "Ptr", this.pPlayer, "char")
    }

    ; 断开Player连接并清理占用【断开表情似乎有问题，其实也不需要断开表情】
    断开连接() {
        DllCall("ElectronBotSDK-Player\AHK_Stop", "Ptr", this.pPlayer)
        DllCall("ElectronBotSDK-Player\AHK_Disconnect", "Ptr", this.pPlayer, "char")
        DllCall("ElectronBotSDK-Player\AHK_Delete", "Ptr", this.pPlayer)
    }

    ; Player 连接
    连接() {
        Return DllCall("ElectronBotSDK-Player\AHK_Connect", "Ptr", this.pPlayer, "char")
    }

    播放表情(FilePath) {
        if FileExist(FilePath) {
            DllCall("ElectronBotSDK-Player\AHK_Stop", "Ptr", this.pPlayer)
            this.pPlayer := DllCall("ElectronBotSDK-Player\AHK_New", "Ptr")
            DllCall("ElectronBotSDK-Player\AHK_Connect", "Ptr", this.pPlayer, "char")
            Return DllCall("ElectronBotSDK-Player\AHK_Play", "Ptr", this.pPlayer, "astr", FilePath)
        }
    }

    停止表情() {
        DllCall("ElectronBotSDK-Player\AHK_Stop", "Ptr", this.pPlayer)
    }

    设置播放速度(ratio) {
        DllCall("ElectronBotSDK-Player\AHK_SetPlaySpeed", "Ptr", this.pPlayer, "Float", ratio)
    }
}
)