{*******************************************************************************
  作者: fendou116688@163.com 2016/9/4
  描述: 制卡信息
*******************************************************************************}
unit UFrameBuildCard;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFrameBase, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, StdCtrls, ComCtrls, ExtCtrls, cxSplitter;

type
  TfFrameBuildcard = class(TBaseFrame)
    WorkPanel: TScrollBox;
    Timer1: TTimer;
    cxSplitter1: TcxSplitter;
    RichEdit1: TRichEdit;
    procedure WorkPanelMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    FReceiver: Integer;
    //事件标识
    procedure OnLog(const nStr: string);
    //记录日志
    procedure LoadReaderItems;
    //载入通道
  public
    { Public declarations }
    class function FrameID: integer; override;
    function FrameTitle: string; override;
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    //子类继承
    procedure WriteLog(const nEvent: string; const nColor: TColor = clGreen;
      const nBold: Boolean = False; const nAdjust: Boolean = True);
    //记录日志
  end;

implementation

{$R *.dfm}

uses
  IniFiles, UlibFun, UMgrControl, UFrameBuildCardItem, UMgrMHReader,
  USysGrid, USysLoger, USysConst;

class function TfFrameBuildcard.FrameID: integer;
begin
  Result := cFI_FrameBuildCard;
end;

function TfFrameBuildcard.FrameTitle: string;
begin
  Result := '读卡-制卡';
end;

procedure TfFrameBuildcard.OnCreateFrame;
var nInt: Integer;
    nIni: TIniFile;
begin
  inherited;
  gSysLoger.LogSync := True;
  FReceiver := gSysLoger.AddReceiver(OnLog);

  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    nInt := nIni.ReadInteger(Name, 'MemoLog', 0);
    if nInt > 20 then
      RichEdit1.Height := nInt;
    //xxxxx
  finally
    nIni.Free;
  end;

  gMHReaderManager := TMHReaderManager.Create;
  gMHReaderManager.LoadConfig(gPath + 'Readers_35LT.xml');
  gMHReaderManager.ReaderLog := False;
end;

procedure TfFrameBuildcard.OnDestroyFrame;
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    nIni.WriteInteger(Name, 'MemoLog', RichEdit1.Height);
  finally
    nIni.Free;
  end;

  if Assigned(gSysLoger) then
    gSysLoger.DelReceiver(FReceiver);
  inherited;
end;

procedure TfFrameBuildcard.OnLog(const nStr: string);
begin
  if Pos('FUN:', nStr) < 1 then
    WriteLog(nStr, clBlue, False, False);
  //不记录调用日志
end;

procedure TfFrameBuildcard.WriteLog(const nEvent: string; const nColor: TColor;
  const nBold: Boolean; const nAdjust: Boolean);
var nInt: Integer;
begin
  with RichEdit1 do
  try
    Lines.BeginUpdate;
    if Lines.Count > 200 then
     for nInt:=1 to 50 do
      Lines.Delete(0);
    //清理多余

    if nBold then
         SelAttributes.Style := SelAttributes.Style + [fsBold]
    else SelAttributes.Style := SelAttributes.Style - [fsBold];

    SelStart := GetTextLen;
    SelAttributes.Color := nColor;

    if nAdjust then
         Lines.Add(DateTime2Str(Now) + #9 + nEvent)
    else Lines.Add(nEvent);
  finally
    Lines.EndUpdate;
    Perform(EM_SCROLLCARET,0,0);
    Application.ProcessMessages;
  end;
end;

//------------------------------------------------------------------------------
//Desc: 延时载入通道
procedure TfFrameBuildcard.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  LoadReaderItems;
end;

//Desc: 支持滚轮
procedure TfFrameBuildcard.WorkPanelMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean);
begin
  with WorkPanel do
    VertScrollBar.Position := VertScrollBar.Position - WheelDelta;
  //xxxxx
end;

//Desc: 载入通道
procedure TfFrameBuildcard.LoadReaderItems;
var nIdx: Integer;
    nReader: TMHReader;
begin
  with gMHReaderManager do
  begin
    for nIdx:=Low(Readers) to High(Readers) do
    begin
      nReader := Readers[nIdx];
      //tunnel
      
      with TfFrameReaderItem.Create(Self) do
      begin
        Name := 'fFrameReaderItem' + IntToStr(nIdx);
        Parent := WorkPanel;

        Align := alTop;
        Reader := nReader;
        HintLabel.Caption := nReader.FName;   
      end;
    end;
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameBuildcard, TfFrameBuildcard.FrameID);
end.
