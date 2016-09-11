{*******************************************************************************
  作者: fendou116688@163.com 2016/9/4
  描述: 制卡信息
*******************************************************************************}
unit UFrameBuildCardItem;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UMgrMHReader, UBusinessConst, UFrameBase, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, StdCtrls,
  UTransEdit, ExtCtrls, cxRadioGroup, cxTextEdit, cxMaskEdit,
  cxDropDownEdit, cxLabel, DateUtils, Menus, cxButtons,
  cxButtonEdit;

type
  TfFrameReaderItem = class(TBaseFrame)
    HintLabel: TcxLabel;
    MemoLog: TZnTransMemo;
    Panel1: TPanel;
    cxLabel1: TcxLabel;
    cxLabel3: TcxLabel;
    cxLabel4: TcxLabel;
    cxLabel2: TcxLabel;
    EditSelfID: TcxTextEdit;
    EditTruck: TcxTextEdit;
    EditPPID: TcxButtonEdit;
    EditMID: TcxTextEdit;
    cxLabel8: TcxLabel;
    EditCusID: TcxTextEdit;
    cxLabel7: TcxLabel;
    EditSelfName: TcxTextEdit;
    cxLabel6: TcxLabel;
    EditMName: TcxTextEdit;
    EditTranName: TcxComboBox;
    cxLabel5: TcxLabel;
    cxLabel9: TcxLabel;
    EditCuName: TcxTextEdit;
    cxLabel10: TcxLabel;
    EditValue: TcxTextEdit;
    GroupBox1: TGroupBox;
    BtnWrite: TcxButton;
    BtnClear: TcxButton;
    BtnRead: TcxButton;
    BtnClearCard: TcxButton;
    procedure EditPPIDKeyPress(Sender: TObject; var Key: Char);
    procedure EditPPIDPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnClearClick(Sender: TObject);
    procedure BtnWriteClick(Sender: TObject);
    procedure BtnReadClick(Sender: TObject);
    procedure BtnClearCardClick(Sender: TObject);
  private
    { Private declarations }
    FReader: TMHReader;
    FListA, FListB: TStrings;
    procedure SetUIData(const nReset: Boolean = True; const nData: string = '');
    //界面数据
    procedure WriteLog(nEvent: string);
    //记录日志
  public
    { Public declarations }
    class function FrameID: integer; override;
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    //子类继承
    property Reader: TMHReader  read FReader write FReader;
  end;

implementation

{$R *.dfm}

uses
  ULibFun, UBase64, UFormBase, USysLoger, USysConst, USysBusiness;

class function TfFrameReaderItem.FrameID: integer;
begin
  Result := 0;
end;

procedure TfFrameReaderItem.OnCreateFrame;
begin
  inherited;
  FListA := TStringList.Create;
  FListB := TStringList.Create;

  if FileExists(gPath + 'Transport.txt') then
    FListB.LoadFromFile(gPath + 'Transport.txt');
end;

procedure TfFrameReaderItem.OnDestroyFrame;
begin
  inherited;
  FListB.SaveToFile(gPath + 'Transport.txt');

  FListA.Free;
  FListB.Free;
end;

procedure TfFrameReaderItem.WriteLog(nEvent: string);
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
  gSysLoger.AddLog(TfFrameReaderItem, '制卡业务', nEvent);
end;

//Desc: 重置界面数据
procedure TfFrameReaderItem.SetUIData(const nReset: Boolean; const nData: string);
begin
  if nReset then
  begin
    EditPPID.Text := '';
    EditValue.Text := '';

    EditTruck.Text := '';
    EditTranName.Text := '';

    EditCusID.Text := '';
    EditCuName.Text := '';

    EditMID.Text := '';
    EditMName.Text := '';

    EditSelfID.Text := '';
    EditSelfName.Text := '';
  end;

  EditTranName.Properties.Items.Clear;
  EditTranName.Properties.Items.AddStrings(FListB);
  if EditTranName.Properties.Items.Count > 0 then EditTranName.ItemIndex := -1;

  if Length(nData) < 1 then Exit;

  AnalyseCardItems(nData, FListA);
  EditPPID.Text := FListA.Values[sCard_PoundID];
  EditValue.Text := FListA.Values[sCard_NetValue];

  EditTruck.Text := FListA.Values[sCard_Truck];
  EditTranName.Text := FListA.Values[sCard_Transport];

  EditMID.Text := FListA.Values[sCard_MaterialID];
  EditMName.Text := FListA.Values[sCard_Material];

  EditCusID.Text := FListA.Values[sCard_CustomerID];
  EditCuName.Text := FListA.Values[sCard_Customer];

  EditSelfID.Text := FListA.Values[sCard_CompanyID];
  EditSelfName.Text := FListA.Values[sCard_CompanyName];
end;

procedure TfFrameReaderItem.EditPPIDKeyPress(Sender: TObject;
  var Key: Char);
var nP: TFormCommandParam;
    nData: string;
begin
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;
    if EditPPID.Properties.ReadOnly then Exit;

    EditPPID.Text := Trim(EditPPID.Text);
    GetNCPoundData(EditPPID.Text, nData, False);
    SetUIData(True, nData);
  end;

  if Key = Char(VK_SPACE) then
  begin
    Key := #0;
    if EditPPID.Properties.ReadOnly then Exit;

    nP.FParamA := EditPPID.Text;
    CreateBaseFormItem(cFI_FormGetNCPoundData, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and(nP.FParamA = mrOk) then
      EditPPID.Text := nP.FParamB;

    GetNCPoundData(EditPPID.Text, nData, False);
    SetUIData(True, nData);
  end;
end;

procedure TfFrameReaderItem.EditPPIDPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nKey: Char;
begin
  inherited;
  nKey := Char(VK_SPACE);
  EditPPIDKeyPress(Sender, nKey);
end;

procedure TfFrameReaderItem.BtnClearClick(Sender: TObject);
begin
  inherited;

  SetUIData(True);
end;

procedure TfFrameReaderItem.BtnWriteClick(Sender: TObject);
var nData: string;
begin
  inherited;
  if Trim(EditPPID.Text) = '' then Exit;
  if Trim(EditTruck.Text) = '' then Exit;
  if Trim(EditSelfID.Text) = '' then Exit;
  if Trim(EditMID.Text) = '' then Exit;

  if (Trim(EditTranName.Text) <> '') and
     (FListB.IndexOf(EditTranName.Text) < 0) then
    FListB.Add(EditTranName.Text);
    
  nData := EditPPID.Text + '|' +
           EditValue.Text + '|' +
           EditTruck.Text + '|' +
           EditMID.Text + '|' +
           EditMName.Text + '|' +
           EditCusID.Text + '|' +
           EditCuName.Text + '|' +
           EditSelfID.Text + '|' +
           EditSelfName.Text + '|' +
           EditTranName.Text + '|' +
           'N';     //新增
  if gMHReaderManager.WriteCardData(EncodeBase64(nData), FReader.FID) then
    WriteSysLog('写卡成功: ' + nData);
end;

procedure TfFrameReaderItem.BtnReadClick(Sender: TObject);
var nData: string;
begin
  inherited;
  nData := gMHReaderManager.ReadCardData(FReader.FID);
  SetUIData(True, DecodeBase64(nData));
end;

procedure TfFrameReaderItem.BtnClearCardClick(Sender: TObject);
var nData: string;
begin
  inherited;
  nData := '|||||||||';
  if gMHReaderManager.WriteCardData(EncodeBase64(nData), FReader.FID) then
    WriteSysLog('清卡成功.');
end;

end.


