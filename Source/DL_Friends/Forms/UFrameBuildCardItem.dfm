inherited fFrameReaderItem: TfFrameReaderItem
  Width = 1026
  Height = 349
  HorzScrollBar.Visible = False
  Font.Height = -15
  object HintLabel: TcxLabel
    Left = 0
    Top = 0
    Align = alTop
    AutoSize = False
    Caption = '1'#21495#35835#21345#22120
    ParentFont = False
    Style.BorderColor = clBlack
    Style.BorderStyle = ebsOffice11
    Style.Edges = [bLeft, bTop, bRight, bBottom]
    Style.Font.Charset = GB2312_CHARSET
    Style.Font.Color = clGreen
    Style.Font.Height = -18
    Style.Font.Name = #23435#20307
    Style.Font.Style = [fsBold]
    Style.LookAndFeel.Kind = lfOffice11
    Style.LookAndFeel.NativeStyle = True
    Style.LookAndFeel.SkinName = 'UserSkin'
    Style.Shadow = True
    Style.IsFontAssigned = True
    StyleDisabled.LookAndFeel.Kind = lfOffice11
    StyleDisabled.LookAndFeel.NativeStyle = True
    StyleDisabled.LookAndFeel.SkinName = 'UserSkin'
    StyleFocused.LookAndFeel.Kind = lfOffice11
    StyleFocused.LookAndFeel.NativeStyle = True
    StyleFocused.LookAndFeel.SkinName = 'UserSkin'
    StyleHot.LookAndFeel.Kind = lfOffice11
    StyleHot.LookAndFeel.NativeStyle = True
    StyleHot.LookAndFeel.SkinName = 'UserSkin'
    Properties.Alignment.Horz = taCenter
    Properties.Alignment.Vert = taVCenter
    Properties.LabelStyle = cxlsRaised
    Height = 27
    Width = 1026
    AnchorX = 513
    AnchorY = 14
  end
  object MemoLog: TZnTransMemo
    Left = 0
    Top = 282
    Width = 1026
    Height = 67
    Align = alBottom
    BorderStyle = bsNone
    Font.Charset = GB2312_CHARSET
    Font.Color = clGreen
    Font.Height = -15
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object Panel1: TPanel
    Left = 0
    Top = 27
    Width = 1026
    Height = 255
    Align = alClient
    TabOrder = 2
    object cxLabel1: TcxLabel
      Left = 25
      Top = 19
      Caption = #30917#21333#32534#21495':'
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -23
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.TextColor = clBlack
      Style.IsFontAssigned = True
    end
    object cxLabel3: TcxLabel
      Left = 25
      Top = 75
      Caption = #36710#29260#21495#30721':'
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -23
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.TextColor = clBlack
      Style.IsFontAssigned = True
    end
    object cxLabel4: TcxLabel
      Left = 25
      Top = 123
      Caption = #29289#26009#32534#21495':'
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -23
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.TextColor = clBlack
      Style.IsFontAssigned = True
    end
    object cxLabel2: TcxLabel
      Left = 25
      Top = 210
      Caption = #20225#19994#32534#21495':'
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -23
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.TextColor = clBlack
      Style.IsFontAssigned = True
    end
    object EditSelfID: TcxTextEdit
      Left = 142
      Top = 209
      ParentFont = False
      Properties.ReadOnly = True
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -20
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.LookAndFeel.NativeStyle = True
      Style.IsFontAssigned = True
      StyleDisabled.LookAndFeel.NativeStyle = True
      StyleFocused.LookAndFeel.NativeStyle = True
      StyleHot.LookAndFeel.NativeStyle = True
      TabOrder = 4
      Width = 275
    end
    object EditTruck: TcxTextEdit
      Left = 145
      Top = 74
      ParentFont = False
      Properties.ReadOnly = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -20
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.LookAndFeel.NativeStyle = True
      Style.IsFontAssigned = True
      StyleDisabled.LookAndFeel.NativeStyle = True
      StyleFocused.LookAndFeel.NativeStyle = True
      StyleHot.LookAndFeel.NativeStyle = True
      TabOrder = 5
      Width = 272
    end
    object EditPPID: TcxButtonEdit
      Left = 144
      Top = 16
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = EditPPIDPropertiesButtonClick
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -20
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 6
      OnKeyPress = EditPPIDKeyPress
      Width = 273
    end
    object EditMID: TcxTextEdit
      Left = 144
      Top = 121
      ParentFont = False
      Properties.ReadOnly = True
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -20
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.LookAndFeel.NativeStyle = True
      Style.IsFontAssigned = True
      StyleDisabled.LookAndFeel.NativeStyle = True
      StyleFocused.LookAndFeel.NativeStyle = True
      StyleHot.LookAndFeel.NativeStyle = True
      TabOrder = 7
      Width = 273
    end
    object cxLabel7: TcxLabel
      Left = 473
      Top = 214
      Caption = #20225#19994#21517#31216':'
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -23
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.TextColor = clBlack
      Style.IsFontAssigned = True
    end
    object EditSelfName: TcxTextEdit
      Left = 590
      Top = 213
      ParentFont = False
      Properties.ReadOnly = True
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -20
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.LookAndFeel.NativeStyle = True
      Style.IsFontAssigned = True
      StyleDisabled.LookAndFeel.NativeStyle = True
      StyleFocused.LookAndFeel.NativeStyle = True
      StyleHot.LookAndFeel.NativeStyle = True
      TabOrder = 9
      Width = 275
    end
    object cxLabel6: TcxLabel
      Left = 473
      Top = 123
      Caption = #29289#26009#21517#31216':'
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -23
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.TextColor = clBlack
      Style.IsFontAssigned = True
    end
    object EditMName: TcxTextEdit
      Left = 590
      Top = 121
      ParentFont = False
      Properties.ReadOnly = True
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -20
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.LookAndFeel.NativeStyle = True
      Style.IsFontAssigned = True
      StyleDisabled.LookAndFeel.NativeStyle = True
      StyleFocused.LookAndFeel.NativeStyle = True
      StyleHot.LookAndFeel.NativeStyle = True
      TabOrder = 11
      Width = 275
    end
    object EditTranName: TcxComboBox
      Left = 590
      Top = 74
      ParentFont = False
      Properties.DropDownRows = 20
      Properties.ImmediateDropDown = False
      Properties.IncrementalSearch = False
      Properties.ItemHeight = 22
      Properties.ReadOnly = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -20
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.LookAndFeel.NativeStyle = True
      Style.IsFontAssigned = True
      StyleDisabled.LookAndFeel.NativeStyle = True
      StyleFocused.LookAndFeel.NativeStyle = True
      StyleHot.LookAndFeel.NativeStyle = True
      TabOrder = 12
      Width = 275
    end
    object cxLabel5: TcxLabel
      Left = 473
      Top = 75
      Caption = #36816#36755#21333#20301':'
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -23
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.TextColor = clBlack
      Style.IsFontAssigned = True
    end
    object cxLabel9: TcxLabel
      Left = 473
      Top = 170
      Caption = #23458#25143#21517#31216':'
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -23
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.TextColor = clBlack
      Style.IsFontAssigned = True
    end
    object EditCuName: TcxTextEdit
      Left = 590
      Top = 169
      ParentFont = False
      Properties.ReadOnly = True
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -20
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.LookAndFeel.NativeStyle = True
      Style.IsFontAssigned = True
      StyleDisabled.LookAndFeel.NativeStyle = True
      StyleFocused.LookAndFeel.NativeStyle = True
      StyleHot.LookAndFeel.NativeStyle = True
      TabOrder = 15
      Width = 275
    end
    object cxLabel10: TcxLabel
      Left = 473
      Top = 19
      Caption = #20928#37325'('#21544'):'
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -23
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.TextColor = clBlack
      Style.IsFontAssigned = True
    end
    object EditValue: TcxTextEdit
      Left = 590
      Top = 17
      ParentFont = False
      Properties.ReadOnly = True
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -20
      Style.Font.Name = #24188#22278
      Style.Font.Style = []
      Style.LookAndFeel.NativeStyle = True
      Style.IsFontAssigned = True
      StyleDisabled.LookAndFeel.NativeStyle = True
      StyleFocused.LookAndFeel.NativeStyle = True
      StyleHot.LookAndFeel.NativeStyle = True
      TabOrder = 17
      Width = 275
    end
    object GroupBox1: TGroupBox
      Left = 872
      Top = 1
      Width = 153
      Height = 253
      Align = alRight
      Caption = #21345#29255#25805#20316
      TabOrder = 18
      object BtnWrite: TcxButton
        Left = 26
        Top = 30
        Width = 111
        Height = 35
        Caption = #20889#21345
        Font.Charset = GB2312_CHARSET
        Font.Color = clWindowText
        Font.Height = -20
        Font.Name = #23435#20307
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = BtnWriteClick
        LookAndFeel.NativeStyle = False
      end
      object BtnClear: TcxButton
        Left = 26
        Top = 198
        Width = 111
        Height = 35
        Caption = #32487#32493
        Font.Charset = GB2312_CHARSET
        Font.Color = clWindowText
        Font.Height = -20
        Font.Name = #23435#20307
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = BtnClearClick
        LookAndFeel.NativeStyle = False
      end
      object BtnRead: TcxButton
        Left = 26
        Top = 86
        Width = 111
        Height = 35
        Caption = #35835#21345
        Font.Charset = GB2312_CHARSET
        Font.Color = clWindowText
        Font.Height = -20
        Font.Name = #23435#20307
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = BtnReadClick
        LookAndFeel.NativeStyle = False
      end
      object BtnClearCard: TcxButton
        Left = 26
        Top = 142
        Width = 111
        Height = 35
        Caption = #28165#21345
        Font.Charset = GB2312_CHARSET
        Font.Color = clWindowText
        Font.Height = -20
        Font.Name = #23435#20307
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnClick = BtnClearCardClick
        LookAndFeel.NativeStyle = False
      end
    end
  end
  object cxLabel8: TcxLabel
    Left = 25
    Top = 194
    Caption = #23458#25143#32534#21495':'
    ParentFont = False
    Style.Font.Charset = GB2312_CHARSET
    Style.Font.Color = clBlack
    Style.Font.Height = -23
    Style.Font.Name = #24188#22278
    Style.Font.Style = []
    Style.TextColor = clBlack
    Style.IsFontAssigned = True
  end
  object EditCusID: TcxTextEdit
    Left = 142
    Top = 193
    ParentFont = False
    Properties.ReadOnly = True
    Style.Font.Charset = GB2312_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -20
    Style.Font.Name = #24188#22278
    Style.Font.Style = []
    Style.LookAndFeel.NativeStyle = True
    Style.IsFontAssigned = True
    StyleDisabled.LookAndFeel.NativeStyle = True
    StyleFocused.LookAndFeel.NativeStyle = True
    StyleHot.LookAndFeel.NativeStyle = True
    TabOrder = 4
    Width = 275
  end
end
