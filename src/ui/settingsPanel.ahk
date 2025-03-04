#Include, <Syscolors>
#Include %A_ScriptDir%\ui\settingsTabs.ahk
DefaultTip(t=False,x=False,y=False,timeout=2000){
    if (!x or !y){
            MouseGetPos, mX, mY
            (x:=mX) , (y:=mY)
        }
    ToolTip, % (t?t:""), % x, % y, 3
    if !t
        return
    SetTimer, DefaultTip, % (timeout*-1)
}
SettingsUpdateFlag(){
    global
    if (!settingupGUI and SettingsShow == true) {
        GuiControl, Show, Unsaved
        GuiControl, Enable, UpdateBtn
        CoordMode, Tooltip, Relative
        if !RegExMatch(A_GuiControl,"Rcheck") and !RegExMatch(A_GuiControl,"Slider"){
            DefaultTip(("Default:" A_GuiControl ": " defaultSettings[A_GuiControl]))
        }
    }
}
SettingsPanelUpdate(){
    WriteLog("Applying new settings...")
    UpdateSettings()
    historyText.delete()
    historyText := new SessionTableLayer(settings)
    gameInfoLayer.delete()
    gameInfoLayer := new GameInfoLayer(settings)
    partyInfoLayer.delete()
    partyInfoLayer := new PartyInfoLayer(settings)
    uiAssistLayer.delete()
    uiAssistLayer := new UIAssistLayer(settings)
    itemLogLayer.delete()
    itemLogLayer := new ItemLogLayer(settings)
    itemCounterLayer.delete()
    itemCounterLayer := new ItemCounterLayer(settings)
    buffBarLayer.delete()
    buffBarLayer := new BuffBarLayer(settings)
    SetupHotKeys(gameWindowId, settings)
    lastlevel := "INVALIDATED"
    mapGuis.setScale(settings)
    unitsGui.setScale(settings)
    mapGuis.setOffsetPosition(settings)
    unitsGui.setOffsetPosition(settings)
    mapShowing := 0
    GuiControl, Hide, Unsaved
    GuiControl, Disable, UpdateBtn
    redrawMap := 1
}
RevertToDefaults(){
    global
    settingupGUI:=True
    settings:=defaultSettings.Clone()
    SettingsPanelValueInit()
    SettingsPanelUpdate()
    settingupGUI:=False
    DefaultTip("All Settings set to Default")
    
}

CreateSettingsGUI() {
    global
    (SettingsWidth:=362) , (SettingsHeight:=482) , (SettingsD2RFontSize:=18) , (SettingFontsize1:=7), (SettingFontsize2:=8) , (SettingFontTabSize := 9) (SettingFontInfoSize:=16)
    local (SettingsAnchorX:=10),(SettingsAnchorY:=59),(SettingsAnchorW:=),(SettingsAnchorH:=),(SettingsAnchorrW:=20),(SettingsAnchorrH:=20)
    Gui, Settings:New, +AlwaysOnTop
    Gui, Settings:Default
    disabledfont:=SySC.Invert(SySC.GetColor(SySC.COLOR_GRAYTEXT)), DetailFontColor:=0xFF8000
    UniqueColor:=0xD1C18C , grey:=0x181818 , EditColor:=0x000000
    ;q  Gui, Color, % SySC.Invert(SySC.GetColor(SySC.COLOR_WINDOW))
    local cWindowcolor:=(settings["CustomSettings"]?SettingDefault("Windowcolor"):defaultsettings["Windowcolor"])
    local cFontColor:=(settings["CustomSettings"]?SettingDefault("FontColor"):defaultsettings["FontColor"])
    if (settings["CustomSettings"] and settings["InvertedColors"]){
        cWindowcolor:=SySC.Invert(cWindowcolor)
        cFontColor:=SySC.Invert(cFontColor)
    }
    Gui, Color, % cWindowcolor
    UniqueColor:=cFontColor
    ;color:=0xFFFFFFF
    ;Gui,Color,% color
    ;Gui,+LastFound
    ;WinSet,Transcolor, % color
    ;;Gui, Font,, ExocetBlizzardMixedCapsOTMedium                           
    ;Gui, Font, % "s" SettingFontsize1 " C" DetailFontColor,  
    Gui, Add, Button, % "x" (SettingsAnchorX) " y" (SettingsAnchorY+394 )" w" 30 " h" 20 " gshowColorPicker", RGB          

    Gui, Add, Text, %  "c" UniqueColor " x" (SettingsAnchorX+120) " y" (SettingsAnchorY+394 ) " w" 100 " h" 17 " +Right vUnsaved Hidden gSettingsUpdateFlag", % localizedStrings["s2"]
    Gui, Add, Button, % "x" (SettingsAnchorX+230) " y" (SettingsAnchorY+386) " w" 115 " h" 30 " gSettingsPanelUpdate vUpdateBtn Disabled", % localizedStrings["s1"]
    Gui, Add, Tab3, % " c" UniqueColor " x" 2 " y" 1 " w" (SettingsWidth-2) " h"( SettingsHeight-42) " vTabList", % TabTitles()
    taboptions:=
    SettingsTabInfo(SettingsAnchorX,SettingsAnchorY)
    SettingsTabGeneral(SettingsAnchorX,SettingsAnchorY)
    SettingsTabMapItems(SettingsAnchorX,SettingsAnchorY)
    SettingsTabGameData(SettingsAnchorX,SettingsAnchorY)
    SettingsTabNPCs(SettingsAnchorX,SettingsAnchorY)
    SettingsTabImmunes(SettingsAnchorX,SettingsAnchorY)
    SettingsTabItemFilter(SettingsAnchorX,SettingsAnchorY)
    SettingsTabOther(SettingsAnchorX,SettingsAnchorY)
    SettingsTabProjectiles(SettingsAnchorX,SettingsAnchorY)
    SettingsTabAdvanced(SettingsAnchorX,SettingsAnchorY)
    SettingsTabHotkeys(SettingsAnchorX,SettingsAnchorY)
    SettingsPanelValueInit()

}

SettingsPanelValueInit(){
    global
    { ;Configure
        settingupGUI := true

        ; because I've renamed tabs but people might have settings saved for an old name
        if (settings["lastActiveGUITab"] == "Monsters" or settings["lastActiveGUITab"] == "Game History") {
            settings["lastActiveGUITab"] := "Info"
        }
        
        ; load settings array into GUI
        local tabtitles := StrReplace(TabTitles(), settings["lastActiveGUITab"], settings["lastActiveGUITab"] "|")
        GuiControl, , TabList, % "|" tabtitles
        
        ;chosen := "Choose" settings["chosenVoice"]
        chosen := "Choose" (chosenVoice:=settings["chosenVoice"])
        GuiControl, , Options, chosenVoice, %chosen%

        locale := settings["locale"]
        localeChoice := LocaleToChoice(locale)
        guiChoice := "Choose" localeChoice
        GuiControl, , Options, localeIdx, %guiChoice%


        for setting,value in settings
        {   
            Local (TL:="TOP_" (Le:="LEFT")) , (TR:="TOP_" (Ri:="RIGHT")), (Ce:="CENTER") , (Di:="|")
            switch (setting){
                case "mapPosition":value:=(value ~= TL)?Di Ce Di TL Di Di TR:((value ~= TR)?Di Ce TL Di TR Di Di: Di Ce Di Di TL Di TR)
                case "historyTextAlignment":value:=(value ~= Le)?Di Le Di Di Ri:Di Le Di Ri Di Di
                case "gameInfoAlignment":value:=(value ~= Le)?Di Le Di Di Ri:Di Le Di Ri Di Di
            }
            GuiControl, , % setting , % value
        }

        if (itemAlertList) {
            GuiControl, , AlertListText, % itemAlertList.toString()
        }
    }
}

ShowSettings(){
    global
    ; open the settings window and a given position
    if (SettingsShow:=!SettingsShow){
       options:="x" ((uix := settings["settingsUIX"])?uix: 100) " y" ((uiy := settings["settingsUIY"])?uiy: 100)
        . " h" SettingsHeight " w" SettingsWidth
        Gui, Settings:Show, % options , % "d2r-mapview settings"
    } else {
        Gui, Settings:hide
    }
}

SettingsClose(){
    ShowSettings()
}

UpdateSettings() {
    Gui, Settings:Default
    ; stupid ahk doesn't let me update the array value directly here
    ; so I have to save to a variable and THEN update the settings array
    ; ugh

    ; this just gets all the values of all the gui elements
    GuiControlGet, localeIdx, ,localeIdx
    locale := LocaleIdxToLocale(localeIdx)
    GuiControlGet, TabList, ,TabList
    GuiControlGet, chosenVoice, ,chosenVoice
    GuiControlGet, baseUrl, ,baseUrl
    WinGetPos, settingsUIX, settingsUIY, , , d2r-mapview settings

    ;save the settings
    for k,v in settings
    {   
        if (!SkipSetting(k)) {
            GuiControlGet, out, , % k
            (settings[k] := out) , (out:=)
        }
    }
    if (!settingsUIX) {
        settingsUIX := defaultSettings["settingsUIX"]
    }
    if (!settingsUIY) {
        settingsUIY := defaultSettings["settingsUIY"]
    }
    if (!padding) {
        padding := defaultSettings["padding"]
    }
    settings["settingsUIX"] := settingsUIX
    settings["settingsUIY"] := settingsUIY
    settings["serverScale"] := defaultSettings["serverScale"]
    settings["lastActiveGUITab"] := TabList
    settings["baseUrl"] := baseUrl
    settings["locale"] := locale
    settings["chosenVoice"] := chosenVoice
    oSPVoice.Voice := oSPVoice.GetVoices().Item(chosenVoice-1)
    saveSettings(settings, defaultSettings)
    
}

saveSettings(settings, defaultSettings) {
    writeIniVar("settingsUIX", settings, defaultsettings)
    writeIniVar("settingsUIY", settings, defaultsettings)
    writeIniVar("lastActiveGUITab", settings, defaultsettings)
    writeIniVar("locale", settings, defaultsettings)
    writeIniVar("chosenVoice", settings, defaultsettings)
    for k,v in settings
    {
        if (!SkipSetting(k)) {
            writeIniVar(k, settings, defaultsettings)
        }
    }
}

writeIniVar(valname, settings, defaultsettings) {
    if (settings[valname] == defaultsettings[valname]) {
        IniDelete, settings.ini, Settings , %valname%
    } else {
        WriteLogDebug("Updating setting '" valname "' with " settings[valname])
        IniWrite, % settings[valname], settings.ini, Settings, %valname%
    }
}

GetVoiceList() {
    nVoices := oSPVoice.GetVoices.Count
    voiceList := ""
    if (nVoices > 1) {
        Loop, % nVoices
        {
            try {
                voiceList := voiceList "" oSPVoice.GetVoices.Item(A_Index-1).GetAttribute("Name") "|"
            } catch e {
                WriteLog("Error loading voices " + e.message)
            }
        }
        StringTrimRight, voiceList, voiceList, 1
    } else {
        voiceList := oSPVoice.GetVoices.Item(0).GetAttribute("Name")
    }
    return voiceList
}

; any setting that doesn't appaer in the UI needs to be listed here
SkipSetting(settingName) {
    switch (settingName) {
        case "SplashImg": return 1
        case "gameWindowId": return 1
        case "padding": return 1
        case "edges": return 1
        case "buffBarX": return 1
        case "buffBarY": return 1
        case "championMobColor": return 1
        case "itemCounterX": return 1
        case "itemCounterY": return 1
        case "minionMobColor": return 1
        
    }
}

LocaleToChoice(locale) {
    ;Convert selection into index
    ;English|中文|Deutsch|español|français|italiano|한국어|polski|español mexicano|日本語|português|Русский|福佬話
    switch (locale) {
        case "enUS": return 1
        case "zhTW": return 2
        case "deDE": return 3
        case "esES": return 4
        case "frFR": return 5
        case "itIT": return 6
        case "koKR": return 7
        case "plPL": return 8
        case "esMX": return 9
        case "jaJP": return 10
        case "ptBR": return 11
        case "ruRU": return 12
        case "zhCN": return 13
    }
}

LocaleIdxToLocale(localeIdx) {
    ;Convert selection into index
    ;English|中文|Deutsch|español|français|italiano|한국어|polski|español mexicano|日本語|português|Русский|福佬話
    switch (localeIdx) {
        case 1: return "enUS"
        case 2: return "zhTW"
        case 3: return "deDE"
        case 4: return "esES"
        case 5: return "frFR"
        case 6: return "itIT"
        case 7: return "koKR"
        case 8: return "plPL"
        case 9: return "esMX"
        case 10: return "jaJP"
        case 11: return "ptBR"
        case 12: return "ruRU"
        case 13: return "zhCN"
    }
}