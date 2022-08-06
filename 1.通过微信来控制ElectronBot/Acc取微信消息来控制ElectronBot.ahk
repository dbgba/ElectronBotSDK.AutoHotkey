/*
  大致使用方法：
  1. 退出其它上位机和驱动，确保此SDK能正常操作ElectronBot
  2. 打开微信PC版和此脚本
  3. 按演示图所示，向自己或某人发送自定义命令。如此脚本写好的示例：姿势∶15,0,0,0,30,150
  4. 脚本间隔1秒会获取信息，并反馈到ElectronBot上

  如果能右下角没有接收到微信信息，就是此脚本Acc无法获取的问题。
  如果获取到正确的微信信息，但是ElectronBot没有同步反应。请尝试退出其它上位机和驱动，重新插拔ElectronBot再试一次
  按F3或者F4键可直接测试是否能驱动你的ElectronBot
*/

; 2022.8.3 - 适配当天微信PC版的最新版本：3.7.5.23版本【将微信窗口最小化可以后台接收】
; 理论上自己测试的微信3.4.5.27~3.7.5.23版都可以使用
; 更多用法需要Acc库来完成：https://www.autoahk.com/archives/38723
#SingleInstance Force
SetBatchLines -1
CoordMode ToolTip

Global 姿势 := New LowLevelSDK()

Gosub F1  ; 直接跳到F1流程启动
Return

; 双开关互锁，两个开关只能循环运行其中一个。【运行一个时，另一个会停止】
F1::  ; 按F1键启动流程
F1onoff := !F1onoff, F2onoff := 0
SetTimer F2循环, Off
SetTimer F1循环, % F1onoff=0 ? "Off" : 1000  ; 1000ms=1秒延时后循环
ToolTip
Return

F2::  ; 按F2键启动流程
F2onoff := !F2onoff, F1onoff := 0
SetTimer F1循环, Off
SetTimer F2循环, % F2onoff=0 ? "Off" : 1000  ; 1000ms=1秒延时后循环
ToolTip
Return

; 按F3键为调试模拟读取微信信息后分解同步到ElectronBot
F3::
最后一条信息 := "姿势∶15,0,0,0,30,130"
分割成数组 := StrSplit(最后一条信息, ",")  ; 将参数分割成数组，参1用正则把非数字内容去掉
姿势.同步姿势(RegExReplace(分割成数组[1], "\D"), 分割成数组[2], 分割成数组[3], 分割成数组[4], 分割成数组[5],  分割成数组[6])
Return

; 按F4键为直接调试【如果按F3和F4键ElectronBot都没有反应，那得退出其它上位机和驱动，重新插拔ElectronBot再试一次】
F4::姿势.同步姿势(0,0,0,0,30,0)


F1循环:
WinGet, IDHwnd, ID , 微信 ahk_class WeChatMainWndForPC
if WinExist("ahk_id " IDHwnd) {
	oAcc := AccGet(IDHwnd, "4.1.2.2.2.1.1.1.1.1.1.2.1.1.1") ; 微信用户名
	oAcc2 := AccGet(IDHwnd, "4.1.2.2.2.1.1.1.1.1.1.2.2.1") ; 当前列表的第一个用户的最后一条信息
    微信用户名 := oAcc.accName(oAcc.accChildCount)
    最后一条信息 := oAcc2.accName(oAcc2.accChildCount)
	ToolTip % "微信新消息：`n来自：" 微信用户名 "`n" 最后一条信息, A_ScreenWidth//1.13, A_ScreenHeight//1.13
    if (InStr(最后一条信息, "姿势")!=0) {  ; 判断信息是否包含"姿势"两字，做为自定义命令识别
        分割成数组 := StrSplit(最后一条信息, ",")  ; 将参数分割成数组，参1用正则把非数字内容去掉
        姿势.同步姿势(RegExReplace(分割成数组[1], "\D"), 分割成数组[2], 分割成数组[3], 分割成数组[4], 分割成数组[5],  分割成数组[6])
    }
} else
	ToolTip
Return


F2循环:
WinGet, IDHwnd, ID , 微信 ahk_class WeChatMainWndForPC
if WinExist("ahk_id " IDHwnd) {
	oAcc := AccGet(IDHwnd, "4.1.2.3.1.1.1.1.2.1.1.1") ; 当前聊天对话的最后一条信息
	ToolTip % "当前聊天新消息：`n" oAcc.accName(oAcc.accChildCount) ,A_ScreenWidth//1.13, A_ScreenHeight//1.13
} else
	ToolTip
Return

; ================== Acc获取简易函数 ==================
AccGet(iHwnd, iPath) {  ; By xlivans , Thank Tebayaki 
    Static init
    if !init
		hModule := DllCall("LoadLibrary", "Str", "oleacc.dll", "Ptr")
    if iHwnd
		VarSetCapacity(iGuid, 16)
		, NumPut(0x11CF3C3D618736E0, iGuid, "Int64"), NumPut(0x719B3800AA000C81, iGuid, 8, "Int64")
        , iAccObj := 0
        , DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", iHwnd, "UInt", 0, "Ptr", &iGuid, "Ptr*", iAccObj)
		, iAccObj := ComObject(9, iAccObj, 1)

    Return AccChild(iAccObj, iPath)
}

AccChild(iAccObj, iPath) {
    Loop, Parse, iPath, ".", A_Space
	{
        iChildCount := iAccObj.accChildCount
        , iChild := []
		, VarSetCapacity(iAccRAM, iChildCount * (8 + 2 * A_PtrSize), 0)
        , DllCall("oleacc\AccessibleChildren", "Ptr", ComObjValue(iAccObj), "Int", 0, "Int", iChildCount, "Ptr", &iAccRAM, "Int*", 0)
        Loop %iChildCount%
			Interface := ComObjQuery(NumGet(iAccRAM, (A_Index - 1) * 24 + 8, "UPtr"), "{618736E0-3C3D-11CF-810C-00AA00389B71}")
            , iChild.Push(ComObject(9, Interface, 1))
			, ObjRelease(Interface)

        iAccObj := iChild[A_LoopField]
    }
    Return iAccObj
}

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