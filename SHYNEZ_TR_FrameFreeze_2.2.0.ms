--Anime Frame Freeze
--author: shynez.com
--version 2.1
fileIn "SHYNEZ_TR_Util.ms"

if Util_IsScriptUIOpen "SHYNEZ_TR_FrameFreeze" do (
      return print "The script instance is already open."
)
Util_AddScriptUIOpenState "SHYNEZ_TR_FrameFreeze"

escapeEnable = true

affFrameData
affAniRange = ((animationRange.end - animationRange.start) as string) as integer + 1
affFrameFlag = #()

-- function
AffGetSecondIndex
AffGetFrameCountAtCurrentSecond
AffRefreshTimesheet
AffMarkDeleteTimesheet
AffRefreshFlagRange
AffSetRangeKoma
AffCreatePreview

rollout SHYNEZ_TR_FrameFreeze "AniFreezer 2.2.0"
(
	listbox second_index "秒索引" width:120 height:6 items:#("1 | current") selection:1

	multilistbox timesheet_frames "律表：秒" width:120 height:24

	on second_index doubleClicked index do (
		second_index.selection = index
		secIndexItems = #()
		for i = 1 to second_index.items.count where i != index do (
			secIndexItems[i] = i as string
		)
		secIndexItems[index] = (index as string) + " | 当前"
		second_index.items = secIndexItems

		AffRefreshTimesheet index 0
	)

	on timesheet_frames doubleClicked index do (
		secIndex = AffGetSecondIndex()

		affFrameData[index + (secIndex - 1) * 24] = if affFrameData[index + (secIndex - 1) * 24] == 1 then 0 else 1
		
		AffRefreshTimesheet secIndex index
	)

	group "冻结关键帧" (
		button btn_setKey "标记" across:2
		button btn_delKey "删除"
	)
	
	on btn_setKey pressed do (
		AffMarkDeleteTimesheet 1
	)

	on btn_delKey pressed do (
		AffMarkDeleteTimesheet 0
	)

	group "范围标记" (
		label label_Flag "标记范围: (0 - 0)"
		button btn_setFlag "标记" across:2
		button btn_clearFlag "清除"
	)

	on btn_setFlag pressed do (
		secIndex = AffGetSecondIndex()

		for i = 1 to timesheet_frames.selection.count where timesheet_frames.selection[i] == true do (
			appendIfUnique affFrameFlag (i + (secIndex - 1) * 24)
		)

		AffRefreshFlagRange()
	)

	on btn_clearFlag pressed do (
		affFrameFlag = #()

		label_Flag.text = "标记范围: (0 - 0)"
	)
	
	group "快捷冻结" (
		button btn_1k "拍1" across:3 offset:[0,0]
		button btn_2k "拍2" offset:[0,0]
		button btn_3k "拍3" offset:[0,0]
	)

	on btn_1k pressed do (
		AffSetRangeKoma 1
	)

	on btn_2k pressed do (
		AffSetRangeKoma 2
	)

	on btn_3k pressed do (
		AffSetRangeKoma 3
	)

	button btn_createPreview "创建预览" across:2

	on btn_createPreview pressed do (
		AffCreatePreview()
    )
    
    button btn_openVideoFolder "🔍"

    on btn_openVideoFolder pressed do (
        ShellLaunch ((getDir #preview) as string) ""
    )

	Label author "Author" align:#left across:2
	hyperLink authorLink "shynez语出" color:red hoverColor:red visitedColor:green address:"http://shynez.com/" align:#right
    
	on SHYNEZ_TR_FrameFreeze close do (
		affFrameFlag = #()

		Util_DeleteScriptUIOpenState "SHYNEZ_TR_FrameFreeze"
	)
)

-- get Second Index
fn AffGetSecondIndex = (
	secIndex = 1
	for i = 1 to SHYNEZ_TR_FrameFreeze.second_index.items.count where (findString SHYNEZ_TR_FrameFreeze.second_index.items[i] "当前" != undefined) do (
		secIndex = i
	)
	secIndex
)

fn AffGetFrameCountAtCurrentSecond = (
	secIndex = AffGetSecondIndex()
	amin (affAniRange - (secIndex - 1) * 24) 24
)

-- refresh Timesheet items
fn AffRefreshTimesheet secIndex frameIndex = (
	AffFrameIndexItems = #()
	for i = 1 to AffGetFrameCountAtCurrentSecond() do (
		theItemText = (i as string) + " (" + ((i+(secIndex-1)*24) as string) + ")"
		if affFrameData[i+(secIndex-1)*24] == 1 do theItemText += " | 冻结"
		append AffFrameIndexItems theItemText
	)
    SHYNEZ_TR_FrameFreeze.timesheet_frames.items = AffFrameIndexItems
    SHYNEZ_TR_FrameFreeze.timesheet_frames.text = ""
	SHYNEZ_TR_FrameFreeze.timesheet_frames.text = "律表：秒" + secIndex as string
)

-- mark/delete Timesheet items
fn AffMarkDeleteTimesheet option = (
	secIndex = AffGetSecondIndex()

	for i = 1 to AffGetFrameCountAtCurrentSecond() where SHYNEZ_TR_FrameFreeze.timesheet_frames.selection[i] == true do (
		affFrameData[i + (secIndex - 1) * 24] = if option == 1 then 1 else 0
	)
	
	AffRefreshTimesheet secIndex 0
)

fn AffRefreshFlagRange = (
	SHYNEZ_TR_FrameFreeze.label_Flag.text = "标记范围：(" + ((amin affFrameFlag) as string) + " - " + ((amax affFrameFlag) as string) + ")"
)

fn AffSetRangeKoma k = (
	forloopStart = 1
	forloopEnd = affAniRange
	if affFrameFlag.count > 0 then (
		forloopStart = amin affFrameFlag
		forloopEnd = amax affFrameFlag

		if forloopStart == forloopEnd do (
			forloopEnd = affAniRange
		)
	)
	for i = forloopStart to forloopEnd do (
		if mod (i - 1) k == 0 then (
			affFrameData[i] = 1
		) else 
			affFrameData[i] = 0
	)

	secIndex = AffGetSecondIndex()

	AffRefreshTimesheet secIndex 0
)

fn AffCreatePreview = (
    progressStart "冻结帧拍屏预览缓存进度"

	previewName = (getDir #preview)+"/aff_quickpreview.mov"
	viewSize = getViewSize()
	animBmp = bitmap viewSize.x viewSize.y filename:previewName
	sliderTime = animationRange.start
	for t = animationRange.start.frame to animationRange.end.frame do (
		if getProgressCancel() then (
            progressEnd()
            exit
        ) else (
            progressUpdate (t * 100 / animationRange.end.frame)
        )

		if affFrameData[((t - animationRange.start + 1) as string) as integer] == 1 do (
			sliderTime = t
		)
		--print sliderTime

		dib = gw.getViewportDib()
		copy dib animBmp
		save animBmp frame:t

		close dib
	)
    progressEnd()
	close animBmp
	gc()

	--
	ShellLaunch previewName ""
)

---------------------
createDialog SHYNEZ_TR_FrameFreeze width:146 height:620 style:#(#style_titlebar, #style_border, #style_sysmenu)

cui.RegisterDialogBar SHYNEZ_TR_FrameFreeze

if affFrameData == undefined do (
	affFrameData = #()
	for i = 1 to affAniRange do (
		append affFrameData 0
	)
)

secondCount = (affAniRange + 23) / 24
AffSecIndexItems = #()
for i = 1 to secondCount do (
	append AffSecIndexItems (i as string)
)
AffSecIndexItems[1] = "1 | 当前"
SHYNEZ_TR_FrameFreeze.second_index.items = AffSecIndexItems

AffRefreshTimesheet 1 0