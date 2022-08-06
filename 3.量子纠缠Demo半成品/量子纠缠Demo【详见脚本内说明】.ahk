/*
以下演示的是，将摄像头里的面部截图出来，在电脑上显示效果。
目前SDK的传入内存图片还没研究明白，所以还没法同步到ElectronBot的脸上。

使用方法：
将 此脚本 和 "haarcascade_frontalface_default.xml" 放在到 "ElectronBotSDK" 目录后，
运行此脚本即可查看测试。【需要确保摄像头画面中有面部可识别】
*/
#SingleInstance Force
SetBatchLines -1
SetWorkingDir %A_ScriptDir%

hOpencv := DllCall("LoadLibrary", "Str", "opencv_world455.dll", "Ptr")
hOpencvCom := DllCall("LoadLibrary", "Str", "autoit_opencv_com455.dll", "Ptr") 
DllCall("autoit_opencv_com455.dll\DllInstall", "Int", 1, "WStr", A_IsAdmin = 0 ? "user" : "", "cdecl")

CV := ComObjCreate("OpenCV.CV")
Cap := ComObjCreate("OpenCV.CV.VideoCapture")
Frame := ComObjCreate("OpenCV.CV.MAT")
Cap.open(0)  ; 调用第几个摄像头，从0开始

faceCascade := ComObjCreate("Opencv.cv.CascadeClassifier")
faceCascade.load("haarcascade_frontalface_default.xml")  ; 加载人脸识别判断

Loop {  
    Ret := Cap.read(Frame)

    frame := cv.rotate(frame, 2)  ; 适配ElectronBot使用画面旋转，如果不是ElectronBot需要删除此行才有图像

    faces := faceCascade.detectMultiScale(Frame, 1.1+0, 10+0)

    ; 纯人脸识别完整显示
    ; Loop % faces.MaxIndex()+1
    ;     CV.rectangle(Frame, faces[A_Index-1], ComArrayMake([255, 0, 255]), 3)
    ; CV.imshow("Live", Frame)

    ; 识别面部并裁剪显示【如果没有图像，尝试删除cv.rotate或者使用上面这段"纯人脸识别完整显示"获取】
    if (faces.MaxIndex()>-1)
        Frame := Crop(Frame, faces[0])
        , CV.imshow("Live", Frame)
    ;   else
    ;     CV.destroyAllWindows()

    ; CV.WaitKey(5)
    ; if !WinExist("Live") {
    ;     CV.destroyAllWindows()
    ;     Break
    ; }
}

; 裁剪图像方法
; Frame := Crop(Frame, ComArrayMake([100, 100, 100, 100]))

Crop(Img, Pos) {
    x := Pos[0]
    , y := Pos[1]
    , Width := Pos[2]
    , Height := Pos[3]
    , Row_Array := Array()
    , Col_Array := Array()

    CV := ComObjCreate("OpenCV.CV")
    , Mat := ComObjCreate("OpenCV.CV.MAT")

    Loop % Height - 1
        Row_Array.Push(Img.Row(y++))
    
    Img := CV.vconcat(ComArrayMake(Row_Array))

    Loop % Width - 1
        Col_Array.Push(Img.Col(x++))

    Img := CV.hconcat(ComArrayMake(Col_Array))
    Return Img
}


ComArrayMake(InputArray) {
    Arr := ComObjArray(VT_VARIANT:=12, InputArray.Length())

    Loop % InputArray.Length()
        Arr[A_Index-1] := InputArray[A_Index]

    Return Arr
}