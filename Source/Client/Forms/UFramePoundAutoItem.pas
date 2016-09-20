{*******************************************************************************
  作者: dmzn@163.com 2014-10-20
  描述: 自动称重通道项
*******************************************************************************}
unit UFramePoundAutoItem;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UMgrPoundTunnels, UBusinessConst, UFrameBase, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, StdCtrls,
  UTransEdit, ExtCtrls, cxRadioGroup, cxTextEdit, cxMaskEdit,
  cxDropDownEdit, cxLabel, ULEDFont;

type
  TfFrameAutoPoundItem = class(TBaseFrame)
    GroupBox1: TGroupBox;
    EditValue: TLEDFontNum;
    GroupBox3: TGroupBox;
    ImageGS: TImage;
    Label16: TLabel;
    Label17: TLabel;
    ImageBT: TImage;
    Label18: TLabel;
    ImageBQ: TImage;
    ImageOff: TImage;
    ImageOn: TImage;
    HintLabel: TcxLabel;
    EditTruck: TcxComboBox;
    EditMID: TcxComboBox;
    EditPID: TcxComboBox;
    EditMValue: TcxTextEdit;
    EditPValue: TcxTextEdit;
    EditJValue: TcxTextEdit;
    Timer1: TTimer;
    EditBill: TcxComboBox;
    EditZValue: TcxTextEdit;
    GroupBox2: TGroupBox;
    RadioPD: TcxRadioButton;
    RadioCC: TcxRadioButton;
    EditMemo: TcxTextEdit;
    EditWValue: TcxTextEdit;
    RadioLS: TcxRadioButton;
    cxLabel1: TcxLabel;
    cxLabel2: TcxLabel;
    cxLabel3: TcxLabel;
    cxLabel4: TcxLabel;
    cxLabel5: TcxLabel;
    cxLabel6: TcxLabel;
    cxLabel7: TcxLabel;
    cxLabel8: TcxLabel;
    cxLabel9: TcxLabel;
    cxLabel10: TcxLabel;
    Timer2: TTimer;
    Timer_ReadCard: TTimer;
    TimerDelay: TTimer;
    MemoLog: TZnTransMemo;
    Timer_SaveFail: TTimer;
    ckCloseAll: TCheckBox;
    BtnSetZero: TcxLabel;
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer_ReadCardTimer(Sender: TObject);
    procedure TimerDelayTimer(Sender: TObject);
    procedure Timer_SaveFailTimer(Sender: TObject);
    procedure ckCloseAllClick(Sender: TObject);
    procedure EditBillKeyPress(Sender: TObject; var Key: Char);
    procedure BtnSetZeroClick(Sender: TObject);
  private
    { Private declarations }
    FIsWeighting, FIsSaving, FHasReaded: Boolean;
    //称重标识,保存标识
    FPoundTunnel: PPTTunnelItem;
    //磅站通道
    FLastGS,FLastBT,FLastBQ: Int64;
    //上次活动
    FBillItems: TLadingBillItems;  
    FUIData,FInnerData: TLadingBillItem;
    //称重数据
    FLastCardDone: Int64;
    FLastCard, FCardTmp: string;
    //上次卡号
    FListA, FListB, FListC: TStrings;
    FSampleIndex: Integer;
    FValueSamples: array of Double;
    //数据采样
    FCardReader: Integer;
    //xxxxx
    FEmptyPoundInit: Int64;
    //空磅计时
    procedure SetUIData(const nReset: Boolean; const nOnlyData: Boolean = False);
    //界面数据
    procedure SetImageStatus(const nImage: TImage; const nOff: Boolean);
    //设置状态
    procedure SetTunnel(const nTunnel: PPTTunnelItem);
    //关联通道
    procedure OnPoundDataEvent(const nValue: Double);
    procedure OnPoundData(const nValue: Double);
    //读取磅重
    procedure LoadBillItems(const nCard: string; nUpdateUI: Boolean = True);
    //读取交货单
    procedure InitSamples;
    procedure AddSample(const nValue: Double);
    function IsValidSamaple: Boolean;
    //处理采样
    function SavePoundData(var nPoundID: string): Boolean;
    //保存称重
    procedure WriteLog(nEvent: string);
    //记录日志
    procedure PlayVoice(const nStrtext: string);
    //播放语音
  public
    { Public declarations }
    class function FrameID: integer; override;
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    //子类继承
    procedure ReadCardSync(const nCardNO: string;
      var nResult: Boolean);
    //异步读卡
    property Additional: TStrings read FListC write FListC;
    property CardReader: Integer read FCardReader write FCardReader;
    property PoundTunnel: PPTTunnelItem read FPoundTunnel write SetTunnel;
    //属性相关
  end;

implementation

{$R *.dfm}

uses
  ULibFun, UFormBase, UDataModule, USysBusiness, UMgrMHReader, UMgrRemoteVoice,
  USysLoger, USysConst, USysDB, UBase64;

const
  cFlag_ON    = 10;
  cFlag_OFF   = 20;

class function TfFrameAutoPoundItem.FrameID: integer;
begin
  Result := 0;
end;

procedure TfFrameAutoPoundItem.OnCreateFrame;
begin
  inherited;
  FPoundTunnel := nil;
  FIsWeighting := False;
  FHasReaded   := False;

  FListA := TStringList.Create;
  FListB := TStringList.Create;
  FListC := TStringList.Create;

  FEmptyPoundInit := 0;
  EditValue.Text := '0.00';
  FLastCardDone   := GetTickCount;

  Timer1.Enabled := True;
  Timer_ReadCard.Enabled := True;
end;

procedure TfFrameAutoPoundItem.OnDestroyFrame;
begin
  gPoundTunnelManager.ClosePort(FPoundTunnel.FID);
  //关闭表头端口

  FListA.Free;
  FListB.Free;
  FListC.Free;
  inherited;
end;

//Desc: 设置运行状态图标
procedure TfFrameAutoPoundItem.SetImageStatus(const nImage: TImage;
  const nOff: Boolean);
begin
  if nOff then
  begin
    if nImage.Tag <> cFlag_OFF then
    begin
      nImage.Tag := cFlag_OFF;
      nImage.Picture.Bitmap := ImageOff.Picture.Bitmap;
    end;
  end else
  begin
    if nImage.Tag <> cFlag_ON then
    begin
      nImage.Tag := cFlag_ON;
      nImage.Picture.Bitmap := ImageOn.Picture.Bitmap;
    end;
  end;
end;

procedure TfFrameAutoPoundItem.WriteLog(nEvent: string);
var nInt: Integer;
begin
  with MemoLog do
  try
    Lines.BeginUpdate;
    if Lines.Count > 20 then
     for nInt:=1 to 10 do
      Lines.Delete(0);
    //清理多余

    Lines.Add(DateTime2Str(Now) + #9 + nEvent);
  finally
    Lines.EndUpdate;
    Perform(EM_SCROLLCARET,0,0);
    Application.ProcessMessages;
  end;
end;

procedure WriteSysLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFrameAutoPoundItem, '自动称重业务', nEvent);
end;

//------------------------------------------------------------------------------
//Desc: 更新运行状态
procedure TfFrameAutoPoundItem.Timer1Timer(Sender: TObject);
begin
  SetImageStatus(ImageGS, GetTickCount - FLastGS > 5 * 1000);
  SetImageStatus(ImageBT, GetTickCount - FLastBT > 5 * 1000);
  SetImageStatus(ImageBQ, GetTickCount - FLastBQ > 5 * 1000);
end;

//Desc: 关闭红绿灯
procedure TfFrameAutoPoundItem.Timer2Timer(Sender: TObject);
begin
  Timer2.Tag := Timer2.Tag + 1;
  if Timer2.Tag < 10 then Exit;

  Timer2.Tag := 0;
  Timer2.Enabled := False;

  RemoteTunnelOC(FPoundTunnel.FProber, sFlag_No);
end;

//Desc: 设置通道
procedure TfFrameAutoPoundItem.SetTunnel(const nTunnel: PPTTunnelItem);
begin
  FPoundTunnel := nTunnel;
  SetUIData(True);

  {$IFDEF DEBUG}
  if not FPoundTunnel.FUserInput then
    gPoundTunnelManager.ActivePort(FPoundTunnel.FID, OnPoundDataEvent, True);
  {$ENDIF} 
end;

//Desc: 重置界面数据
procedure TfFrameAutoPoundItem.SetUIData(const nReset,nOnlyData: Boolean);
var nVal: Double;
    nItem: TLadingBillItem;
begin
  if nReset then
  begin
    FillChar(nItem, SizeOf(nItem), #0);
    //init

    with nItem do
    begin
      FPModel := sFlag_PoundPD;
      FFactory := gSysParam.FFactNum;
    end;

    FUIData := nItem;
    FInnerData := nItem;
    if nOnlyData then Exit;

    SetLength(FBillItems, 0);
    EditBill.Properties.Items.Clear;

    FHasReaded   := False;
    FIsSaving    := False;
    FIsWeighting := False;
    FEmptyPoundInit := 0;

    if FLastCardDone = 0 then
      FLastCardDone   := GetTickCount + 1;
    //防止49.71天后，系统更新为0

    {$IFNDEF DEBUG}
    EditValue.Text := '0.00';
    if not FPoundTunnel.FUserInput then
      gPoundTunnelManager.ClosePort(FPoundTunnel.FID);
    {$ENDIF}  
  end;

  with FUIData do
  begin
    EditBill.Text := FID;
    EditTruck.Text := FTruck;
    EditMID.Text := FStockName;
    EditPID.Text := FCusName;

    EditMValue.Text := Format('%.2f', [FMData.FValue]);
    EditPValue.Text := Format('%.2f', [FPData.FValue]);
    EditZValue.Text := Format('%.2f', [FValue]);

    if (FValue > 0) and (FMData.FValue > 0) and (FPData.FValue > 0) then
    begin
      nVal := FMData.FValue - FPData.FValue;
      EditJValue.Text := Format('%.2f', [nVal]);
      EditWValue.Text := Format('%.2f', [FValue - nVal]);
    end else
    begin
      EditJValue.Text := '0.00';
      EditWValue.Text := '0.00';
    end;

    RadioPD.Checked := FPModel = sFlag_PoundPD;
    RadioCC.Checked := FPModel = sFlag_PoundCC;
    RadioLS.Checked := FPModel = sFlag_PoundLS;

    RadioLS.Enabled := False;
    //已称过重量或销售,禁用临时模式
    RadioCC.Enabled := False;
    //只有销售有出厂模式

    EditBill.Properties.ReadOnly := True;
    EditTruck.Properties.ReadOnly := True;
    EditMID.Properties.ReadOnly := True;
    EditPID.Properties.ReadOnly := True;
    //可输入项调整

    EditMemo.Properties.ReadOnly := True;
    EditMValue.Properties.ReadOnly := not FPoundTunnel.FUserInput;
    EditPValue.Properties.ReadOnly := not FPoundTunnel.FUserInput;
    EditJValue.Properties.ReadOnly := True;
    EditZValue.Properties.ReadOnly := True;
    EditWValue.Properties.ReadOnly := True;
    //可输入量调整

    if FTruck = '' then
    begin
      EditMemo.Text := '';
      Exit;
    end;
  end;

  if FUIData.FNextStatus = sFlag_TruckBFP then
  begin
    RadioCC.Enabled := False;
    EditMemo.Text := '供应称皮重';
  end else
  begin
    RadioCC.Enabled := False;
    EditMemo.Text := '供应称毛重';
  end;
end;

//Date: 2014-09-19
//Parm: 磁卡或交货单号
//Desc: 读取nCard对应的交货单
procedure TfFrameAutoPoundItem.LoadBillItems(const nCard: string;
 nUpdateUI: Boolean);
var nStr: string;
    nLast: Integer;
    nBills: TLadingBillItems;
begin
  nStr := Format('读取到卡号[ %s ],开始执行业务.', [nCard]);
  WriteLog(nStr);

  if not GetCardPoundItem(nCard, nBills) then
  begin
    SetUIData(True);
    Exit;
  end;

  nLast := -1;
  if GetTruckLastTime(nBills[0].FTruck, nLast) and (nLast > 0) and 
     (nLast < FPoundTunnel.FCardInterval) then
  begin
    nStr := '车辆[ %s ]需等待 %d 秒后才能过磅';
    nStr := Format(nStr, [nBills[0].FTruck, FPoundTunnel.FCardInterval - nLast]);

    WriteLog(nStr);

    nStr := Format('磅站[ %s.%s ]: ',[FPoundTunnel.FID,
            FPoundTunnel.FName]) + nStr;
    WriteSysLog(nStr);

    Timer_SaveFail.Enabled := True;
    Exit;
  end;

  FInnerData := nBills[0];
  FUIData := FInnerData; 
  SetUIData(False);

  InitSamples;
  //初始化样本
  FIsWeighting := True;

  {$IFNDEF DEBUG}
  if not FPoundTunnel.FUserInput then
    gPoundTunnelManager.ActivePort(FPoundTunnel.FID, OnPoundDataEvent, True);
  {$ENDIF}  

  if not FPoundTunnel.FPort.FClientActive then
  begin
    ShowMsg('地磅表头未连接', sHint);
    Timer_SaveFail.Enabled := True;
  end;   
end;

//------------------------------------------------------------------------------
//Desc: 由定时读取交货单
procedure TfFrameAutoPoundItem.Timer_ReadCardTimer(Sender: TObject);
var nStr,nCard: string;
    nLast, nDoneTmp: Int64;
begin
  {$IFNDEF VerfiyAutoWeight}
  if gSysParam.FIsManual then Exit;
  {$ENDIF}
  Timer_ReadCard.Tag := Timer_ReadCard.Tag + 1;
  if Timer_ReadCard.Tag < 5 then Exit;

  Timer_ReadCard.Tag := 0;
  if FIsWeighting then Exit;

  try
    WriteLog('正在读取磁卡号.');  Exit;
    nCard := gMHReaderManager.ReadCardData(FPoundTunnel.FID);
    if (nCard = '') or FHasReaded then Exit;

    FHasReaded := True;
    if nCard <> FLastCard then
         nDoneTmp := 0
    else nDoneTmp := FLastCardDone;
    //新卡时重置

    WriteSysLog('读取到新卡信息:::' + nCard + '=>旧卡信息:::' + FLastCard);
    nLast := Trunc((GetTickCount - nDoneTmp) / 1000);
    if (nLast < FPoundTunnel.FCardInterval) And (nDoneTmp <> 0) then
    begin
      nStr := '磁卡[ %s ]需等待 %d 秒后才能过磅';
      nStr := Format(nStr, [nCard, FPoundTunnel.FCardInterval - nLast]);

      WriteLog(nStr);
      //PlayVoice(nStr);

      nStr := Format('磅站[ %s.%s ]: ',[FPoundTunnel.FID,
              FPoundTunnel.FName]) + nStr;
      WriteSysLog(nStr);

      SetUIData(True);
      Exit;
    end;

    FCardTmp := nCard;
    EditBill.Text := DecodeBase64(nCard);
    LoadBillItems(EditBill.Text);
  except
    on E: Exception do
    begin
      nStr := Format('磅站[ %s.%s ]: ',[FPoundTunnel.FID,
              FPoundTunnel.FName]) + E.Message;
      WriteSysLog(nStr);

      SetUIData(True);
      //错误则重置
    end;
  end;
end;

//Desc: 保存业务
function TfFrameAutoPoundItem.SavePoundData(var nPoundID: string): Boolean;
begin
  Result := False;
  //init

  if ((FUIData.FPData.FValue <= 0) and (FUIData.FMData.FValue <= 0)) or
     ((FUIData.FNextStatus = sFlag_TruckBFM) and (FUIData.FMData.FValue <= 0))then
  begin
    ShowMsg('请先称重', sHint);
    Exit;
  end;

  if (FUIData.FPData.FValue > 0) and (FUIData.FMData.FValue > 0) then
  begin
    if FUIData.FPData.FValue > FUIData.FMData.FValue then
    begin
      ShowMsg('皮重应小于毛重', sHint);
      Exit;
    end;
  end;

  SetLength(FBillItems, 1);
  FBillItems[0] := FUIData;
  //复制用户界面数据

  with FBillItems[0] do
  begin
    FFactory := gSysParam.FFactNum;
    //xxxxx

    if FNextStatus = sFlag_TruckBFP then
         FPData.FStation := FPoundTunnel.FID
    else FMData.FStation := FPoundTunnel.FID;
  end;

  Result := SaveTruckPoundItem(FPoundTunnel, FBillItems, nPoundID);
  //保存称重

  if not Result then
  begin
    nPoundID := FPoundTunnel.FName + '过磅失败，请联系司磅员.';
    WriteSysLog(nPoundID);
    PlayVoice(nPoundID);
  end;
end;


//Desc: 读取表头数据
procedure TfFrameAutoPoundItem.OnPoundDataEvent(const nValue: Double);
begin
  try
    if FIsSaving then Exit;
    //正在保存。。。

    OnPoundData(nValue);
  except
    on E: Exception do
    begin
      WriteSysLog(Format('磅站[ %s.%s ]: %s', [FPoundTunnel.FID,
                                               FPoundTunnel.FName, E.Message]));
      SetUIData(True);
    end;
  end;
end;

//Desc: 处理表头数据
procedure TfFrameAutoPoundItem.OnPoundData(const nValue: Double);
var nRet: Boolean;
    nPoundID: string;
begin
  FLastBT := GetTickCount;
  EditValue.Text := Format('%.2f', [nValue]);

  if not FIsWeighting then Exit;
  //不在称重中

  {$IFNDEF VerfiyAutoWeight}
  if gSysParam.FIsManual then Exit;
  //手动时无效
  {$ENDIF}

  if (nValue < 0.02) or
    FloatRelation(nValue, FPoundTunnel.FPort.FMinValue, rtLE, 1000) then //空磅
  begin
    if FEmptyPoundInit = 0 then
      FEmptyPoundInit := GetTickCount;
    if GetTickCount - FEmptyPoundInit < 10 * 1000 then Exit;
    //延迟重置

    FEmptyPoundInit := 0;
    Timer_SaveFail.Enabled := True;
    Exit;
  end else FEmptyPoundInit := 0;

  if FInnerData.FPData.FValue > 0 then
  begin
    if nValue <= FInnerData.FPData.FValue then
    begin
      FUIData.FPData := FInnerData.FMData;
      FUIData.FMData := FInnerData.FPData;

      FUIData.FPData.FValue := nValue;
      FUIData.FNextStatus := sFlag_TruckBFP;
      //切换为称皮重
    end else
    begin
      FUIData.FPData := FInnerData.FPData;
      FUIData.FMData := FInnerData.FMData;

      FUIData.FMData.FValue := nValue;
      FUIData.FNextStatus := sFlag_TruckBFM;
      //切换为称毛重
    end;
  end else FUIData.FPData.FValue := nValue;

  SetUIData(False);
  AddSample(nValue);
  if not IsValidSamaple then Exit;
  //样本验证不通过

  FIsSaving := True;
  if not RemoteTunnelOK(FPoundTunnel.FProber) then
  begin
    nPoundID := '车辆未停到位,请移动车辆.';
    WriteSysLog(nPoundID);
    PlayVoice(nPoundID);

    FIsSaving := False;
    Exit;
  end;  

  nRet := SavePoundData(nPoundID);
  if nRet then
  begin
    FIsWeighting := False;
    TimerDelay.Enabled := True;
  end else Timer_SaveFail.Enabled := True;
end;

procedure TfFrameAutoPoundItem.TimerDelayTimer(Sender: TObject);
begin
  try
    TimerDelay.Enabled := False;
    FLastCardDone := GetTickCount;
    WriteLog(Format('对车辆[ %s ]称重完毕.', [FUIData.FTruck]));

    RemoteTunnelOC(FPoundTunnel.FProber, sFlag_Yes);
    //打开红绿灯
    PlayVoice(#9 + FUIData.FTruck);
    //播放语音
    FLastCard := FCardTmp;
    Timer2.Enabled := True;
    SetUIData(True);
  except
    on E: Exception do
    begin
      WriteSysLog(Format('磅站[ %s.%s ]: %s', [FPoundTunnel.FID,
                                               FPoundTunnel.FName, E.Message]));
      //loged
    end;
  end;
end;

//------------------------------------------------------------------------------
//Desc: 初始化样本
procedure TfFrameAutoPoundItem.InitSamples;
var nIdx: Integer;
begin
  SetLength(FValueSamples, FPoundTunnel.FSampleNum);
  FSampleIndex := Low(FValueSamples);

  for nIdx:=High(FValueSamples) downto FSampleIndex do
    FValueSamples[nIdx] := 0;
  //xxxxx
end;

//Desc: 添加采样
procedure TfFrameAutoPoundItem.AddSample(const nValue: Double);
begin
  FValueSamples[FSampleIndex] := nValue;
  Inc(FSampleIndex);

  if FSampleIndex >= FPoundTunnel.FSampleNum then
    FSampleIndex := Low(FValueSamples);
  //循环索引
end;

//Desc: 验证采样是否稳定
function TfFrameAutoPoundItem.IsValidSamaple: Boolean;
var nIdx: Integer;
    nVal: Integer;
begin
  Result := False;

  for nIdx:=FPoundTunnel.FSampleNum-1 downto 1 do
  begin
    if FValueSamples[nIdx] < FPoundTunnel.FPort.FMinValue then Exit;
    //样本不完整

    nVal := Trunc(FValueSamples[nIdx] * 1000 - FValueSamples[nIdx-1] * 1000);
    if Abs(nVal) >= FPoundTunnel.FSampleFloat then Exit;
    //浮动值过大
  end;

  Result := True;
end;

procedure TfFrameAutoPoundItem.PlayVoice(const nStrtext: string);
begin
  gVoiceHelper.PlayVoice(nStrtext);
end;

procedure TfFrameAutoPoundItem.Timer_SaveFailTimer(Sender: TObject);
begin
  inherited;
  try
    Timer_SaveFail.Enabled := False;
    SetUIData(True);
  except
    on E: Exception do
    begin
      WriteSysLog(Format('磅站[ %s.%s ]: %s', [FPoundTunnel.FID,
                                               FPoundTunnel.FName, E.Message]));
      //loged
    end;
  end;
end;

procedure TfFrameAutoPoundItem.ckCloseAllClick(Sender: TObject);
var nP: TWinControl;
begin
  nP := Parent;

  if ckCloseAll.Checked then
  while Assigned(nP) do
  begin
    if (nP is TBaseFrame) and
       (TBaseFrame(nP).FrameID = cFI_FramePoundAuto) then
    begin
      TBaseFrame(nP).Close();
      Exit;
    end;

    nP := nP.Parent;
  end;
end;

procedure TfFrameAutoPoundItem.EditBillKeyPress(Sender: TObject;
  var Key: Char);
begin
  inherited;
  if Key = #13 then
  begin
    Key := #0;
    if EditBill.Properties.ReadOnly then Exit;

    EditBill.Text := Trim(EditBill.Text);
    LoadBillItems(EditBill.Text);
  end;
end;

procedure TfFrameAutoPoundItem.BtnSetZeroClick(Sender: TObject);
begin
  inherited;
  //gPoundTunnelManager.WriteData(FPoundTunnel.FID, 'Z');
end;

procedure TfFrameAutoPoundItem.ReadCardSync(const nCardNO: string;
  var nResult: Boolean);
var nStr: string;
    nLast, nDoneTmp: Int64;
begin
  nResult := False;

  {$IFNDEF VerfiyAutoWeight}
  if gSysParam.FIsManual then Exit;
  {$ENDIF}
  if FIsWeighting then Exit;

  try
    if nCardNO <> FLastCard then
         nDoneTmp := 0
    else nDoneTmp := FLastCardDone;
    //新卡时重置

    WriteSysLog('读取到新卡信息:::' + nCardNO + '=>旧卡信息:::' + FLastCard);
    nLast := Trunc((GetTickCount - nDoneTmp) / 1000);
    if (nLast < FPoundTunnel.FCardInterval) And (nDoneTmp <> 0) then
    begin
      nStr := '磁卡[ %s ]需等待 %d 秒后才能过磅';
      nStr := Format(nStr, [nCardNO, FPoundTunnel.FCardInterval - nLast]);

      WriteLog(nStr);
      //PlayVoice(nStr);

      nStr := Format('磅站[ %s.%s ]: ',[FPoundTunnel.FID,
              FPoundTunnel.FName]) + nStr;
      WriteSysLog(nStr);

      SetUIData(True);
      Exit;
    end;

    nResult := True;
    FCardTmp := nCardNO;
    EditBill.Text := DecodeBase64(nCardNO);
    LoadBillItems(EditBill.Text);
  except
    on E: Exception do
    begin
      nStr := Format('磅站[ %s.%s ]: ',[FPoundTunnel.FID,
              FPoundTunnel.FName]) + E.Message;
      WriteSysLog(nStr);

      SetUIData(True);
      //错误则重置
    end;
  end;
end;

end.
