object dlgMain: TdlgMain
  Left = 231
  Top = 121
  Width = 939
  Height = 746
  Caption = #1057#1087#1080#1089#1086#1082' '#1091#1089#1090#1072#1085#1086#1074#1083#1077#1085#1085#1099#1093' '#1091#1089#1090#1088#1086#1081#1089#1090#1074
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 17
  object Splitter1: TSplitter
    Left = 305
    Top = 41
    Width = 4
    Height = 658
  end
  object tvDevices: TTreeView
    Left = 0
    Top = 41
    Width = 305
    Height = 658
    Align = alLeft
    Images = ilDevices
    Indent = 19
    ReadOnly = True
    RowSelect = True
    SortType = stText
    TabOrder = 0
    OnChange = tvDevicesChange
    OnCompare = tvDevicesCompare
  end
  object pnSetting: TPanel
    Left = 0
    Top = 0
    Width = 931
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object cbShowHidden: TCheckBox
      Left = 10
      Top = 10
      Width = 169
      Height = 23
      Caption = 'Show Hidden Devices'
      TabOrder = 0
      OnClick = cbShowHiddenClick
    end
  end
  object lvAdvancedInfo: TListView
    Left = 309
    Top = 41
    Width = 622
    Height = 658
    Align = alClient
    Columns = <
      item
        Caption = 'Name'
        Width = 196
      end
      item
        Caption = 'Data'
        Width = 392
      end>
    ReadOnly = True
    RowSelect = True
    SortType = stText
    TabOrder = 2
    ViewStyle = vsReport
    OnCompare = lvAdvancedInfoCompare
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 699
    Width = 931
    Height = 19
    Panels = <
      item
        Width = 150
      end
      item
        Width = 150
      end
      item
        Width = 150
      end>
  end
  object ilDevices: TImageList
    Left = 16
    Top = 56
  end
end
