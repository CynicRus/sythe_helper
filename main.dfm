object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Sythe helper for Yohojo by Cynic.[Beta]'
  ClientHeight = 760
  ClientWidth = 720
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 721
    Height = 208
    Caption = 'Thread:'
    TabOrder = 0
    object Label1: TLabel
      Left = 3
      Top = 16
      Width = 56
      Height = 13
      Caption = 'Thread link:'
    end
    object Label3: TLabel
      Left = 160
      Top = 62
      Width = 51
      Height = 13
      Caption = 'Words list:'
    end
    object Label4: TLabel
      Left = 28
      Top = 68
      Width = 52
      Height = 13
      Caption = 'From post:'
    end
    object Label7: TLabel
      Left = 32
      Top = 120
      Width = 79
      Height = 13
      Caption = 'Numberize from:'
    end
    object TargetURL: TEdit
      Left = 3
      Top = 35
      Width = 638
      Height = 21
      TabOrder = 0
    end
    object Button2: TButton
      Left = 647
      Top = 33
      Width = 58
      Height = 25
      Caption = 'Get info'
      TabOrder = 1
      OnClick = Button2Click
    end
    object WordsMemo: TMemo
      Left = 160
      Top = 81
      Width = 406
      Height = 127
      Lines.Strings = (
        'Vouch;Vouches;Thanks')
      TabOrder = 2
    end
    object SpinEdit1: TSpinEdit
      Left = 28
      Top = 87
      Width = 121
      Height = 22
      Enabled = False
      MaxValue = 0
      MinValue = 0
      TabOrder = 3
      Value = 0
    end
    object SpinEdit2: TSpinEdit
      Left = 28
      Top = 152
      Width = 121
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 4
      Value = 0
    end
    object Button1: TButton
      Left = 587
      Top = 81
      Width = 118
      Height = 127
      Caption = 'Start processing!'
      Enabled = False
      TabOrder = 5
      OnClick = Button1Click
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 203
    Width = 721
    Height = 205
    Caption = 'Post list:'
    TabOrder = 1
    object PostView: TListView
      Left = 3
      Top = 11
      Width = 715
      Height = 191
      Checkboxes = True
      Columns = <
        item
          Caption = 'Id'
        end
        item
          Caption = 'Author'
        end
        item
          Caption = 'Join date'
        end
        item
          Caption = 'Total Posts'
        end
        item
          Caption = 'Rank'
        end
        item
          Caption = 'Post Date'
        end
        item
          Caption = 'Message'
        end>
      ReadOnly = True
      TabOrder = 0
      ViewStyle = vsReport
      OnColumnClick = PostViewColumnClick
    end
  end
  object GroupBox3: TGroupBox
    Left = 0
    Top = 399
    Width = 721
    Height = 225
    Caption = 'Generated code:'
    TabOrder = 2
    object codetext: TMemo
      Left = 3
      Top = 15
      Width = 715
      Height = 207
      Lines.Strings = (
        '')
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object LogMemo: TMemo
    Left = 0
    Top = 627
    Width = 718
    Height = 131
    Lines.Strings = (
      '')
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object MainMenu1: TMainMenu
    Left = 696
    Top = 432
    object File1: TMenuItem
      Caption = 'File'
      object Exit1: TMenuItem
        Caption = 'Exit'
      end
    end
  end
end
