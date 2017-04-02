{*******************************************************************************
  作者: dmzn@163.com 2014-06-10
  描述: 手动称重通道项
*******************************************************************************}
unit UFramePoundManualItem;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UMgrPoundTunnels, UBusinessConst, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, Menus, ExtCtrls, cxCheckBox,
  StdCtrls, cxButtons, cxTextEdit, cxMaskEdit, cxDropDownEdit, cxLabel,
  ULEDFont, cxRadioGroup, UFrameBase, Buttons;

type
  TfFrameManualPoundItem = class(TBaseFrame)
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
    BtnReadNumber: TcxButton;
    BtnReadCard: TcxButton;
    BtnSave: TcxButton;
    BtnNext: TcxButton;
    Timer1: TTimer;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
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
    CheckZD: TcxCheckBox;
    CheckSound: TcxCheckBox;
    Timer_Savefail: TTimer;
    Timer_SaveSuc: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure BtnNextClick(Sender: TObject);
    procedure EditBillKeyPress(Sender: TObject; var Key: Char);
    procedure EditBillPropertiesEditValueChanged(Sender: TObject);
    procedure BtnReadNumberClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure RadioPDClick(Sender: TObject);
    procedure EditTruckKeyPress(Sender: TObject; var Key: Char);
    procedure EditMValuePropertiesEditValueChanged(Sender: TObject);
    procedure EditMIDPropertiesChange(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure BtnReadCardClick(Sender: TObject);
    procedure EditPIDKeyPress(Sender: TObject; var Key: Char);
    procedure HintLabelClick(Sender: TObject);
    procedure CheckZDClick(Sender: TObject);
    procedure Timer_SavefailTimer(Sender: TObject);
    procedure Timer_SaveSucTimer(Sender: TObject);
  private
    { Private declarations }
    FPoundTunnel: PPTTunnelItem;
    //磅站通道
    FLastGS,FLastBT,FLastBQ: Int64;
    //上次活动
    FBillItems: TLadingBillItems;
    FUIData,FInnerData: TLadingBillItem;
    //称重数据
    FListA,FListB,FListC: TStrings;
    //数据列表
    FTitleHeight: Integer;
    FPanelHeight: Integer;
    //折叠参数
    FCardReader: Integer;
    //xxxxx
    FPoundID, FFromCard: string;
    //磅单编号
    procedure InitUIData;
    procedure SetUIData(const nReset: Boolean; const nOnlyData: Boolean = False);
    //界面数据
    procedure SetImageStatus(const nImage: TImage; const nOff: Boolean);
    //设置状态
    procedure SetTunnel(const nTunnel: PPTTunnelItem);
    //关联通道
    procedure OnPoundData(const nValue: Double);
    //读取磅重
    procedure LoadBillItems(const nCard: string; nUpdateUI: Boolean = True);
    //读取交货单
    procedure LoadTruckPoundItem(const nTruck: string);
    //读取车辆称重
    function SavePoundData(var nPoundID: string): Boolean;
    //保存称重
    procedure PlayVoice(const nStrtext: string);
    //播发语音
    procedure PlaySoundWhenCardArrived;
    //播放声音
    procedure CollapsePanel(const nCollapse: Boolean; const nAuto: Boolean = True);
    //折叠面板
  public
    { Public declarations }
    class function FrameID: integer; override;
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    //子类继承
    function ReDrawReadCardButton: Boolean;
    procedure ReadCardSync(const nCardNO: string;
      var nResult: Boolean);
    //异步读卡
    procedure LoadCollapseConfig(const nCollapse: Boolean);
    //折叠配置
    property Additional: TStrings read FListC write FListC;
    property CardReader: Integer read FCardReader write FCardReader;
    property PoundTunnel: PPTTunnelItem read FPoundTunnel write SetTunnel;
    //属性相关
  end;

implementation

{$R *.dfm}

uses
  ULibFun, UAdjustForm, UFormBase, UFormWait, UDataModule, UMgrRemoteVoice,
  USysBusiness, UBase64, USysConst, USysDB, UPoundCardReader,
  IniFiles, UMgrSndPlay;

const
  cFlag_ON    = 10;
  cFlag_OFF   = 20;

class function TfFrameManualPoundItem.FrameID: integer;
begin
  Result := 0;
end;

procedure TfFrameManualPoundItem.OnCreateFrame;
begin
  inherited;
  FPanelHeight := Height;
  FTitleHeight := HintLabel.Height + 1;

  FListA := TStringList.Create;
  FListB := TStringList.Create;
  FListC := TStringList.Create;

  FPoundTunnel := nil;
  InitUIData;
end;

procedure TfFrameManualPoundItem.OnDestroyFrame;
begin
  gPoundTunnelManager.ClosePort(FPoundTunnel.FID);
  //关闭表头端口

  gPoundCardReader.DelCardReader(FCardReader);
  //删除读卡通道

  AdjustStringsItem(EditMID.Properties.Items, True);
  AdjustStringsItem(EditPID.Properties.Items, True);

  FListA.Free;
  FListB.Free;
  FListC.Free;
  inherited;
end;

//Desc: 设置运行状态图标
procedure TfFrameManualPoundItem.SetImageStatus(const nImage: TImage;
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

//Desc: 折叠或展开面板
procedure TfFrameManualPoundItem.CollapsePanel(const nCollapse,nAuto: Boolean);
var nCol: Boolean;
begin
  if nAuto then
       nCol := Height > FTitleHeight
  else nCol := nCollapse;

  if nCol then
       Height := FTitleHeight
  else Height := FPanelHeight;
end;

//------------------------------------------------------------------------------
//Desc: 初始化界面
procedure TfFrameManualPoundItem.InitUIData;
var nStr: string;
    nEx: TDynamicStrArray;
begin
  SetLength(nEx, 1);
  nStr := 'M_ID=Select M_ID,M_Name From %s Order By M_ID ASC';
  nStr := Format(nStr, [sTable_Materails]);

  nEx[0] := 'M_ID';
  FDM.FillStringsData(EditMID.Properties.Items, nStr, 0, '', nEx);
  AdjustCXComboBoxItem(EditMID, False);

  nStr := 'P_ID=Select P_ID,P_Name From %s Order By P_ID ASC';
  nStr := Format(nStr, [sTable_Provider]);
  
  nEx[0] := 'P_ID';
  FDM.FillStringsData(EditPID.Properties.Items, nStr, 0, '', nEx);
  AdjustCXComboBoxItem(EditPID, False);

  Timer1.Enabled := True;
  EditValue.Text := '0.00';
end;

//Desc: 重置界面数据
procedure TfFrameManualPoundItem.SetUIData(const nReset,nOnlyData: Boolean);
var nVal: Double;
    nItem: TLadingBillItem;
begin
  if nReset then
  begin
    FFromCard := sFlag_No;
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

    EditBill.Properties.Items.Clear;

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

    BtnSave.Enabled := FTruck <> '';
    BtnReadCard.Enabled := FTruck = '';
    BtnReadNumber.Enabled := FTruck <> '';

    RadioLS.Enabled := (FPoundID = '') and (FID = '');
    //已称过重量或销售,禁用临时模式

    EditBill.Properties.ReadOnly := FID <> '';
    EditMID.Properties.ReadOnly  := FID <> '';
    EditPID.Properties.ReadOnly  := FID <> '';
    EditTruck.Properties.ReadOnly := FTruck <> '';
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

  if FFromCard = sFlag_Yes then
  begin
    if FUIData.FNextStatus = sFlag_TruckBFP then
         EditMemo.Text := '供应称皮重'
    else EditMemo.Text := '供应称毛重';
  end else
  begin
    if RadioLS.Checked then
      EditMemo.Text := '车辆临时称重';
    //xxxxx

    if RadioPD.Checked then
      EditMemo.Text := '车辆配对称重';
    //xxxxx
  end;
end;

//Date: 2014-09-19
//Parm: 磁卡或交货单号
//Desc: 读取nCard对应的交货单
procedure TfFrameManualPoundItem.LoadBillItems(const nCard: string;
 nUpdateUI: Boolean);
var nBills: TLadingBillItems;
begin
  if nCard = '' then
  begin
    EditBill.SetFocus;
    EditBill.SelectAll;
    ShowMsg('请输入IC卡信息', sHint); Exit;
  end;

  if not GetCardPoundItem(nCard, nBills) then
  begin
    SetUIData(True);
    Exit;
  end;

  FInnerData := nBills[0];
  FFromCard := sFlag_Yes;
  FUIData := FInnerData; 
  SetUIData(False);

  {$IFNDEF DEBUG}
  if not FPoundTunnel.FUserInput then
    gPoundTunnelManager.ActivePort(FPoundTunnel.FID, OnPoundData, True);
  {$ENDIF}
end;

//Date: 2014-09-25
//Parm: 车牌号
//Desc: 读取nTruck的称重信息
procedure TfFrameManualPoundItem.LoadTruckPoundItem(const nTruck: string);
var nData: TLadingBillItems;
begin
  if nTruck = '' then
  begin
    EditTruck.SetFocus;
    EditTruck.SelectAll;
    ShowMsg('请输入车牌号', sHint); Exit;
  end;

  if not GetTruckPoundItem(nTruck, nData) then
  begin
    SetUIData(True);
    Exit;
  end;

  FInnerData := nData[0];
  FUIData := FInnerData;
  SetUIData(False);

  {$IFNDEF DEBUG}
  if not FPoundTunnel.FUserInput then
    gPoundTunnelManager.ActivePort(FPoundTunnel.FID, OnPoundData, True);
  {$ENDIF}
end;

//------------------------------------------------------------------------------
//Desc: 更新运行状态
procedure TfFrameManualPoundItem.Timer1Timer(Sender: TObject);
begin
  SetImageStatus(ImageGS, GetTickCount - FLastGS > 5 * 1000);
  SetImageStatus(ImageBT, GetTickCount - FLastBT > 5 * 1000);
  SetImageStatus(ImageBQ, GetTickCount - FLastBQ > 5 * 1000);
end;

//Desc: 关闭红绿灯
procedure TfFrameManualPoundItem.Timer2Timer(Sender: TObject);
begin
  Timer2.Tag := Timer2.Tag + 1;
  if Timer2.Tag < 10 then Exit;

  Timer2.Tag := 0;
  Timer2.Enabled := False;

  RemoteTunnelOC(FPoundTunnel.FProber, sFlag_No);
end;

//Desc: 折叠面板
procedure TfFrameManualPoundItem.HintLabelClick(Sender: TObject);
begin
  CollapsePanel(True);
end;

//Desc: 保存配置
procedure TfFrameManualPoundItem.CheckZDClick(Sender: TObject);
var nIni: TIniFile;
begin
  if not (CheckZD.Focused or CheckSound.Focused) then Exit;
  //只处理用户动作

  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    if CheckZD.Checked then
         nIni.WriteString(Name, 'AutoCollapse', 'Y')
    else nIni.WriteString(Name, 'AutoCollapse', 'N');

    if CheckSound.Checked then
         nIni.WriteString(Name, 'PlaySound', 'Y')
    else nIni.WriteString(Name, 'PlaySound', 'N');
  finally
    nIni.Free;
  end;
end;

//Desc: 读取折叠配置
procedure TfFrameManualPoundItem.LoadCollapseConfig(const nCollapse: Boolean);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    CheckSound.Checked := nIni.ReadString(Name, 'PlaySound', 'Y') = 'Y';
    CheckZD.Checked := nIni.ReadString(Name, 'AutoCollapse', 'N') = 'Y';

    if nCollapse and CheckZD.Checked then
      CollapsePanel(True);
    //折叠面板
  finally
    nIni.Free;
  end;
end;

//------------------------------------------------------------------------------
//Desc: 表头数据
procedure TfFrameManualPoundItem.OnPoundData(const nValue: Double);
begin
  FLastBT := GetTickCount;
  EditValue.Text := Format('%.2f', [nValue]);
end;

//Desc: 设置通道
procedure TfFrameManualPoundItem.SetTunnel(const nTunnel: PPTTunnelItem);
begin
  FPoundTunnel := nTunnel;
  SetUIData(True);

  {$IFDEF DEBUG}
  if not FPoundTunnel.FUserInput then
    gPoundTunnelManager.ActivePort(FPoundTunnel.FID, OnPoundData, True);
  //设置通道时，打开地磅表头
  {$ENDIF}  
end;

//Desc: 控制红绿灯
procedure TfFrameManualPoundItem.N1Click(Sender: TObject);
begin
  N1.Checked := not N1.Checked;
  //status change

  if N1.Checked then
       RemoteTunnelOC(FPoundTunnel.FProber, sFlag_Yes)
  else RemoteTunnelOC(FPoundTunnel.FProber, sFlag_No);
end;

//Desc: 关闭称重页面
procedure TfFrameManualPoundItem.N3Click(Sender: TObject);
var nP: TWinControl;
begin
  nP := Parent;
  while Assigned(nP) do
  begin
    if (nP is TBaseFrame) and
       (TBaseFrame(nP).FrameID = cFI_FramePoundManual) then
    begin
      TBaseFrame(nP).Close();
      Exit;
    end;

    nP := nP.Parent;
  end;
end;

//Desc: 继续按钮
procedure TfFrameManualPoundItem.BtnNextClick(Sender: TObject);
begin
  SetUIData(True);
end;

procedure TfFrameManualPoundItem.EditBillKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    if EditBill.Properties.ReadOnly then Exit;

    EditBill.Text := Trim(EditBill.Text);
    LoadBillItems(EditBill.Text);
  end;
end;

//Desc: 选择客户
procedure TfFrameManualPoundItem.EditPIDKeyPress(Sender: TObject;
  var Key: Char);
var nStr: string;
begin
  if Key = #13 then
  begin
    Key := #0;
    if EditPID.Properties.ReadOnly then Exit;

    if EditPID.ItemIndex >= 0 then
    begin
      nStr := EditPID.Properties.Items[EditPID.ItemIndex];
      if nStr = EditPID.Text then
      begin
        EditMIDPropertiesChange(EditPID);
        Exit; //重新加载供应订单
      end;
    end;
  end;
end;

procedure TfFrameManualPoundItem.EditTruckKeyPress(Sender: TObject;
  var Key: Char);
var nP: TFormCommandParam;
begin
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;
    if EditTruck.Properties.ReadOnly then Exit;
    EditTruck.Text := Trim(EditTruck.Text);

    LoadTruckPoundItem(EditTruck.Text);
  end;

  if Key = Char(VK_SPACE) then
  begin
    Key := #0;
    if EditTruck.Properties.ReadOnly then Exit;

    nP.FParamA := EditTruck.Text;
    CreateBaseFormItem(cFI_FormGetTruck, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and(nP.FParamA = mrOk) then
      EditTruck.Text := nP.FParamB;
    EditTruck.SelectAll;
  end;
end;

procedure TfFrameManualPoundItem.EditBillPropertiesEditValueChanged(
  Sender: TObject);
begin
  if EditBill.Properties.Items.Count > 0 then
  begin
    if EditBill.ItemIndex < 0 then
    begin
      EditBill.Text := FUIData.FID;
      Exit;
    end;

    SetUIData(False);
    //ui
  end;
end;

//Desc: 读数
procedure TfFrameManualPoundItem.BtnReadNumberClick(Sender: TObject);
var nVal: Double;
begin
  if not IsNumber(EditValue.Text, True) then Exit;
  nVal := StrToFloat(EditValue.Text);
  if FloatRelation(nVal, FPoundTunnel.FPort.FMinValue, rtLE, 1000) then Exit;
  //读数小于过磅最低值时,退出

  if not RemoteTunnelOK(FPoundTunnel.FProber) then
  begin
    ShowMsg('车辆未停到位,请移动车辆', sHint);
    Exit;
  end;  

  if FInnerData.FPData.FValue > 0 then
  begin
    if nVal <= FInnerData.FPData.FValue then
    begin
      FUIData.FPData := FInnerData.FMData;
      FUIData.FMData := FInnerData.FPData;

      FUIData.FPData.FValue := nVal;
      FUIData.FNextStatus := sFlag_TruckBFP;
      //切换为称皮重
    end else
    begin
      FUIData.FPData := FInnerData.FPData;
      FUIData.FMData := FInnerData.FMData;

      FUIData.FMData.FValue := nVal;
      FUIData.FNextStatus := sFlag_TruckBFM;
      //切换为称毛重
    end;
  end else FUIData.FPData.FValue := nVal;

  SetUIData(False);
end;

//Desc: 由读头指定交货单
procedure TfFrameManualPoundItem.BtnReadCardClick(Sender: TObject);
var nChar: Char;
    nInit: Int64;
    nStr, nCard: string;
begin
  nCard := '';

  try
    BtnReadCard.Enabled := False;

    nInit := GetTickCount;
    while GetTickCount - nInit < 5 * 1000 do
    begin
      ShowWaitForm(ParentForm, '正在读卡', False);

      if Assigned(gPoundCardReader) then
        nStr := gPoundCardReader.GetCardNOSync(FCardReader);

      if nStr <> '' then
      begin
        nCard := nStr;
        Break;
      end else Sleep(1000);

      Application.ProcessMessages;
    end;

    if nCard = '' then Exit;
    //卡号为空

    nCard := DecodeBase64(nCard);
    AnalyseCardItems(nCard, FListA);
    if (FListA.Values[sCard_PoundID] = '') or
       (FListA.Values[sCard_CompanyID] = '') then
    begin
      nCard := '';
      Exit;
    end;

    nChar := #13;
    EditBill.Text := nCard;
    EditBillKeyPress(nil, nChar);
  finally
    CloseWaitForm;
    if nCard = '' then
    begin
      BtnReadCard.Enabled := True;
      ShowMsg('没有读取成功,请重试', sHint);
    end;
  end;
end;

procedure TfFrameManualPoundItem.RadioPDClick(Sender: TObject);
begin
  if RadioPD.Checked then
    FUIData.FPModel := sFlag_PoundPD;
  if RadioCC.Checked then
    FUIData.FPModel := sFlag_PoundCC;
  if RadioLS.Checked then
    FUIData.FPModel := sFlag_PoundLS;
  //切换模式

  SetUIData(False);
end;

procedure TfFrameManualPoundItem.EditMValuePropertiesEditValueChanged(
  Sender: TObject);
var nVal: Double;
    nEdit: TcxTextEdit;
begin
  nEdit := Sender as TcxTextEdit;
  if not IsNumber(nEdit.Text, True) then Exit;
  nVal := StrToFloat(nEdit.Text);

  if Sender = EditPValue then
    FUIData.FPData.FValue := nVal;
  //xxxxx

  if Sender = EditMValue then
    FUIData.FMData.FValue := nVal;
  SetUIData(False);
end;

procedure TfFrameManualPoundItem.EditMIDPropertiesChange(Sender: TObject);
begin
  if Sender = EditTruck then
  begin
    if not EditTruck.Focused then Exit;
    //非操作人员调整
    EditTruck.Text := Trim(EditTruck.Text);
    FUIData.FTruck := EditTruck.Text;
  end else

  if Sender = EditMID then
  begin
    if not EditMID.Focused then Exit;
    //非操作人员调整
    EditMID.Text := Trim(EditMID.Text);

    if EditMID.ItemIndex < 0 then
    begin
      FUIData.FStockNo := '';
      FUIData.FStockName := EditMID.Text;
    end else
    begin
      FUIData.FStockNo := GetCtrlData(EditMID);
      FUIData.FStockName := EditMID.Text;
    end;
  end else

  if Sender = EditPID then
  begin
    if not EditPID.Focused then Exit;
    //非操作人员调整
    EditPID.Text := Trim(EditPID.Text);

    if EditPID.ItemIndex < 0 then
    begin
      FUIData.FCusID := '';
      FUIData.FCusName := EditPID.Text;
    end else
    begin
      FUIData.FCusID := GetCtrlData(EditPID);
      FUIData.FCusName := EditPID.Text;
    end;

    if FUIData.FCusID = '' then Exit;
    if BtnSave.Enabled then Exit;
    //业务已开始

    if FUIData.FCusName <> EditPID.Properties.Items[EditPID.ItemIndex] then
      Exit;
    //用户手工输入
  end;
end;

//------------------------------------------------------------------------------
//Desc: 原材料或临时
function TfFrameManualPoundItem.SavePoundData(var nPoundID: string): Boolean;
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
    FPrinter := Additional.Values['Printer'];
    //xxxxx

    if FNextStatus = sFlag_TruckBFM then
         FMData.FStation := FPoundTunnel.FID
    else FPData.FStation := FPoundTunnel.FID;
  end;

  Result := SaveTruckPoundItem(FPoundTunnel, FBillItems, nPoundID);
  //保存称重
end;

//Desc: 保存称重
procedure TfFrameManualPoundItem.BtnSaveClick(Sender: TObject);
var nBool: Boolean;
begin
  nBool := False;
  try
    BtnSave.Enabled := False;
    ShowWaitForm(ParentForm, '正在保存称重', True);

    nBool := SavePoundData(FPoundID);
    if nBool then
         Timer_SaveSuc.Enabled  := True
    else Timer_Savefail.Enabled := True;
  finally
    BtnSave.Enabled := not nBool;
    CloseWaitForm;
  end;
end;

procedure TfFrameManualPoundItem.PlaySoundWhenCardArrived;
begin
  if CheckSound.Checked and (Height = FTitleHeight) then
    gSoundPlayManager.PlaySound(gPath + 'sound.wav');
  //xxxxx
end;

function TfFrameManualPoundItem.ReDrawReadCardButton: Boolean;
var
  nRect: TRect;
  nCanvas: TCanvas;
begin
  Result := False;
  if not BtnReadCard.Enabled then Exit;

  PlaySoundWhenCardArrived;
  //播放声音
  CollapsePanel(False, False);
  //展开面板

  nCanvas := TCanvas.Create;
  try
    nRect := GetControlRect(BtnReadCard);
    nCanvas.Handle := GetDC(BtnReadCard.Handle);

    nCanvas.Pen.Color := clRed;
    nCanvas.Pen.Width := 10;
    nCanvas.Brush.Style := bsClear;
    nCanvas.Rectangle(nRect);
  finally
    nCanvas.Free;
  end;

  Result := True;
end;

procedure TfFrameManualPoundItem.ReadCardSync(const nCardNO: string;
  var nResult: Boolean);
begin
  nResult := ReDrawReadCardButton;
end;

procedure TfFrameManualPoundItem.PlayVoice(const nStrtext: string);
begin
  gVoiceHelper.PlayVoice(nStrtext);
end;

procedure TfFrameManualPoundItem.Timer_SavefailTimer(Sender: TObject);
begin
  inherited;
  try
    Timer_SaveFail.Enabled := False;
    SetUIData(True);
  except
    raise;
  end;
end;

procedure TfFrameManualPoundItem.Timer_SaveSucTimer(Sender: TObject);
var nStr: string;
    nKey: Char;
begin
  inherited;
  try
    Timer_SaveSuc.Enabled := False;
    //停止定时器

    {
    if (FUIData.FPoundID <> '') or RadioCC.Checked then
      PrintPoundReport(FPoundID, True);
    //原料或出厂模式  }

    if (FUIData.FPoundID <> '') and (FFromCard = sFlag_Yes) then
    begin
      FListB.Clear;
      //xxxxx

      nStr := '本次为进厂[ %s.%s ]二次过磅';
      nStr := Format(nStr, [FUIData.FTruck, FUIData.FStockName]);
      FListB.Add(nStr);

      nStr := '皮重 [ %.2f ]';
      nStr := Format(nStr, [FUIData.FPData.FValue]);
      FListB.Add(nStr);

      nStr := '请确认是否采用本次皮重拉煤?';
      FListB.Add(nStr);

      nStr := AdjustHintToRead(FListB.Text);
      if QueryDlg(nStr, sHint) then
      begin
        SetLength(FBillItems, 1);
        FillChar(FBillItems[0], SizeOf(FBillItems[0]), #0);
        //init

        with FBillItems[0] do
        begin
          FSelected := True;
          FTruck := FUIData.FTruck;

          FPModel := sFlag_PoundPD;
          FFactory := gSysParam.FFactNum;

          with FPData do
          begin
            FStation := FPoundTunnel.FID;
            FValue   := FUIData.FPData.FValue;
          end;  
        end;

        SetUIData(True);
        nKey := Char(VK_RETURN);
        if SaveTruckPoundItem(FPoundTunnel, FBillItems, nStr) then
        begin
          EditTruck.Text := FBillItems[0].FTruck;
          EditTruckKeyPress(nil, nKey);
        end;        

        Exit;
      end;  
    end;
    
    PlayVoice(#9 + FUIData.FTruck);
    //播放语音
    Timer2.Enabled := True;
    RemoteTunnelOC(FPoundTunnel.FProber, sFlag_Yes);
    //开红绿灯

    SetUIData(True);
    BroadcastFrameCommand(Self, cCmd_RefreshData);

    if CheckZD.Checked then
      CollapsePanel(True, False);
    ShowMsg('称重保存完毕', sHint);
  except
    raise;
  end;
end;


end.
