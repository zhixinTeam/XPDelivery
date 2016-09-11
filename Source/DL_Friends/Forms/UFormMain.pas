unit UFormMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  ExtCtrls, ComCtrls, UBitmapPanel, cxPC, StdCtrls,
  UTrayIcon , UMgrMenu, USysFun, UFrameBase, Menus;

type
  TfMainForm = class(TForm)
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    HintPanel: TPanel;
    Image1: TImage;
    Image2: TImage;
    HintLabel: TLabel;
    wPage: TcxPageControl;
    Sheet1: TcxTabSheet;
    PanelBG: TZnBitmapPanel;
    sBar: TStatusBar;
    Timer1: TTimer;
    NCConnect: TMenuItem;
    SYSCLOSE: TMenuItem;
    MAIN_A01: TMenuItem;
    B00: TMenuItem;
    MAIN_B01: TMenuItem;
    MAIN_A02: TMenuItem;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DoMenuClick(Sender: TObject);
    procedure wPageChange(Sender: TObject);
    procedure wPagePageChanging(Sender: TObject; NewPage: TcxTabSheet;
      var AllowChange: Boolean);
    {*�˵��¼�*}
  private
    { Private declarations }
    FTrayIcon: TTrayIcon;
    {*״̬��ͼ��*}
  protected
    { Private declarations }
    procedure FormLoadConfig;
    procedure FormSaveConfig;
    {*������Ϣ*}
    procedure SetHintText(const nLabel: TLabel);
    {*��ʾ��Ϣ*}
    procedure WMFrameChange(var nMsg: TMessage); message WM_FrameChange;
    procedure DoFrameChange(const nName: string; const nCtrl: TWinControl;
      const nState: TControlChangeState);
    {*����䶯*}
  public
    { Public declarations }
  end;

var
  fMainForm: TfMainForm;

implementation

uses
  ShellAPI, IniFiles, UcxChinese, ULibFun, UMgrControl, UMgrIni,
  USysLoger, USysConst, USysModule, USysMenu, USysPopedom, UFormConn,
  UFormWait, UFormBase, UDataModule;

{$R *.dfm}

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfMainForm, 'ϵͳ��ģ��', nEvent);
end;

//------------------------------------------------------------------------------
//Desc: ����nConnStr�Ƿ���Ч
function ConnCallBack(const nConnStr: string): Boolean;
begin
  FDM.ADOConn.Close;
  FDM.ADOConn.ConnectionString := nConnStr;
  FDM.ADOConn.Open;
  Result := FDM.ADOConn.Connected;
end;

//------------------------------------------------------------------------------
//Date: 2007-10-15
//Parm: ��ǩ
//Desc: ��nLabel����ʾ��ʾ��Ϣ
procedure TfMainForm.SetHintText(const nLabel: TLabel);
begin
  nLabel.Font.Color := clWhite;
  nLabel.Font.Size := 12;
  nLabel.Font.Style := nLabel.Font.Style + [fsBold];

  nLabel.Caption := gSysParam.FHintText;
  nLabel.Left := 8;
  nLabel.Top := (HintPanel.Height + nLabel.Height - 12) div 2;
end;

//Desc: ���봰������
procedure TfMainForm.FormLoadConfig;
var nStr: string;
    nIni: TIniFile;
begin
  HintPanel.DoubleBuffered := True;
  gStatusBar := sBar;
  nStr := Format(sDate, [DateToStr(Now)]);
  StatusBarMsg(nStr, cSBar_Date);

  nStr := Format(sTime, [TimeToStr(Now)]);
  StatusBarMsg(nStr, cSBar_Time);

  SetHintText(HintLabel);
  SetFrameChangeEvent(DoFrameChange);
  PostMessage(Handle, WM_FrameChange, 0, 0);
  
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    LoadFormConfig(Self, nIni);
    
    nStr := nIni.ReadString(Name, 'BgImage', gPath + sImageDir + 'bg.bmp');
    nStr := ReplaceGlobalPath(nStr);
    if FileExists(nStr) then PanelBG.LoadBitmap(nStr);
  finally
    nIni.Free;
  end;
end;

//Desc: ���洰������
procedure TfMainForm.FormSaveConfig;
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    Application.ProcessMessages;

    SaveFormConfig(Self, nIni);
  finally
    nIni.Free;
  end;
end;

//------------------------------------------------------------------------------
procedure TfMainForm.FormCreate(Sender: TObject);
var nStr: string;
begin
  Application.Title := gSysParam.FAppTitle;
  InitGlobalVariant(gPath, gPath + sConfigFile, gPath + sFormConfig, gPath + sDBConfig);

  nStr := GetFileVersionStr(Application.ExeName);
  if nStr <> '' then
  begin
    nStr := Copy(nStr, 1, Pos('.', nStr) - 1);
    Caption := gSysParam.FMainTitle + ' V' + nStr;
  end else Caption := gSysParam.FMainTitle;

  InitSystemObject;
  //ϵͳ����

  FDM.LoadSystemIcons(gSysParam.FIconFile);
  //����ͼ��
  FormLoadConfig;
  //��������

  nStr := BuildConnectDBStr;

  while nStr = '' do
  begin
    ShowMsg('��������ȷ��"���ݿ�"���ò���', sHint);
    if ShowConnectDBSetupForm(ConnCallBack) then
         nStr := BuildConnectDBStr
    else Exit;
  end;

  FDM.ADOConn.Connected := False;
  FDM.ADOConn.ConnectionString := nStr;
  FDM.ADOConn.Connected := True;

  FTrayIcon := TTrayIcon.Create(Self);
  FTrayIcon.Visible := True;

  RunSystemObject;
  //run them
  WriteLog('ϵͳ����');
end;

procedure TfMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  {$IFNDEF debug}
  if not QueryDlg(sCloseQuery, sHint) then
  begin
    Action := caNone; Exit;
  end;
  {$ENDIF}

  ShowWaitForm(Self, '�����˳�ϵͳ', True);
  try
    FormSaveConfig;          //��������

    WriteLog('ϵͳ�ر�');
    {$IFNDEF debug}
    Sleep(2200);
    {$ENDIF}
    FreeSystemObject;        //ϵͳ����
  finally
    CloseWaitForm;
  end;
end;

//Desc: ִ��nMenuIDָ���Ķ���
procedure DoFixedMenuActive(const nMenuID: string);
var nPos: integer;
    nStr,nEntity: string;
    nData: PMenuItemData;
begin
  nPos := Pos(cMenuFlag_NSS, nMenuID);
  nEntity := Copy(nMenuID, 1, nPos - 1);

  nStr := nMenuID;
  System.Delete(nStr, 1, nPos + Length(cMenuFlag_NSS) - 1);

  nData := gMenuManager.GetMenuItem(nEntity, nStr);
  if not Assigned(nData) then Exit;

  if Pos(cMenuFlag_Open, nData.FFlag) > 0 then
  begin
    nStr := StringReplace(nData.FAction, '$Path\', gPath, [rfIgnoreCase]);
    ShellExecute(GetDesktopWindow, nil, PChar(nStr), nil, nil, SW_SHOWNORMAL);
  end;
end;

//Desc: ��ȡnMenu��Ӧ��ģ������
function GetMenuModuleIndex(const nMenu: string; var nIdx: integer): Boolean;
var i,nCount: integer;
    nP: PMenuModuleItem;
begin
  Result := False;
  nCount := gMenuModule.Count - 1;

  for i:=0 to nCount do
  begin
    nP := gMenuModule[i];

    if CompareText(nMenu, nP.FMenuID) = 0 then
    begin
      nIdx := i;
      Result := True; Break;
    end;
  end;
end;

//Date: 2014-06-26
//Parm: ��ʶ����ҳǩ���Ƿ񴴽�
//Desc: ����nPage�б�ʶΪnTag��ҳ�棬�������򴴽�
function GetSheet(const nTag: Integer; const nPage: TcxPageControl;
  const nNew: Boolean = True): TcxTabSheet;
var nIdx: Integer;
begin
  Result := nil;

  for nIdx:=nPage.PageCount - 1 downto 0 do
  if nPage.Pages[nIdx].Tag = nTag then
  begin
    Result := nPage.Pages[nIdx];
    Exit;
  end;

  if not nNew then Exit;
  Result := TcxTabSheet.Create(nPage);
  //new item

  with Result do
  begin
    Tag := nTag;
    PageControl := nPage;
  end;
end;

//Desc: ����˵�
procedure TfMainForm.DoMenuClick(Sender: TObject);
var nPos: integer;
    nP: PMenuModuleItem;
    nFull,nName, nStr: string;
begin
  if Sender is TComponent then
       nFull := TComponent(Sender).Name
  else Exit;

  nName := nFull;
  nPos := Pos(cMenuFlag_NSS, nName);
  System.Delete(nName, 1, nPos + Length(cMenuFlag_NSS) - 1);

  //----------------------------------------------------------------------------
  if nName = sMenuItem_Close then //�˳�ϵͳ
  begin
    Close;
  end else

  if nName = sMenuItem_NCConnect then //����NC���ݿ�
  begin
    ShowConnectDBSetupForm(ConnCallBack);

    nStr := BuildConnectDBStr;

    while nStr = '' do
    begin
      ShowMsg('��������ȷ��"���ݿ�"���ò���', sHint);
      if ShowConnectDBSetupForm(ConnCallBack) then
           nStr := BuildConnectDBStr
      else Exit;
    end;

    FDM.ADOConn.Connected := False;
    FDM.ADOConn.ConnectionString := nStr;
    FDM.ADOConn.Connected := True;
  end else

  if GetMenuModuleIndex(nFull, nPos) then
  begin
    nP := gMenuModule[nPos];
    //ģ��ӳ����

    if nP.FItemType = mtForm then
         CreateBaseFormItem(nP.FModule, nFull)
    else CreateBaseFrameItem(nP.FModule, GetSheet(nP.FModule, wPage), nFull);
  end else DoFixedMenuActive(nFull);
end;

//------------------------------------------------------------------------------
//Desc: ����Frame
procedure TfMainForm.DoFrameChange(const nName: string;
  const nCtrl: TWinControl; const nState: TControlChangeState);
var nStr: string;
    nInt: Integer;
    nSheet: TcxTabSheet;
begin
  if csDestroying in ComponentState then Exit;
  //�������˳�ʱ������

  if nCtrl is TBaseFrame then
       nInt := (nCtrl as TBaseFrame).FrameID
  else Exit;

  nSheet := GetSheet(nInt, wPage, False);
  if not Assigned(nSheet) then Exit;

  if nState = fsNew then
  begin
    nSheet.Caption := '������...';
  end;

  if nState = fsActive then
  begin
    if nSheet.Caption <> nName then
    begin
      nSheet.Caption := nName;
      nStr := TBaseFrame(nCtrl).PopedomItem;
      nSheet.ImageIndex := FDM.IconIndex(nStr);
    end;
    
    wPage.ActivePage := nSheet;
    //active
    Exit;
  end;

  if nState = fsFree then
  begin
    //nothing
  end;

  PostMessage(Handle, WM_FrameChange, 0, 0);
  //update tab status
end;

//Desc: ����״̬����Page���
procedure TfMainForm.WMFrameChange(var nMsg: TMessage);
var nIdx: Integer;
begin
  for nIdx:=wPage.PageCount - 1 downto 0 do
   if wPage.Pages[nIdx].ControlCount < 1 then
    wPage.Pages[nIdx].Free;
  //xxxxx

  if wPage.PageCount > 1 then
  begin
    Sheet1.TabVisible := False;
    wPage.ShowFrame := True;
  end else
  begin
    Sheet1.TabVisible  := False;
    wPage.ShowFrame := False;
    wPage.ActivePage := Sheet1;
  end;
end;

procedure TfMainForm.Timer1Timer(Sender: TObject);
begin
  sBar.Panels[cSBar_Date].Text := Format(sDate, [DateToStr(Now)]);
  sBar.Panels[cSBar_Time].Text := Format(sTime, [TimeToStr(Now)]);
end;   

procedure TfMainForm.wPageChange(Sender: TObject);
begin
  LockWindowUpdate(0);
end;

procedure TfMainForm.wPagePageChanging(Sender: TObject;
  NewPage: TcxTabSheet; var AllowChange: Boolean);
begin
  LockWindowUpdate(Handle);
end;

end.
