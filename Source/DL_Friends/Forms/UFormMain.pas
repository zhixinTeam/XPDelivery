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
    {*菜单事件*}
  private
    { Private declarations }
    FTrayIcon: TTrayIcon;
    {*状态栏图标*}
  protected
    { Private declarations }
    procedure FormLoadConfig;
    procedure FormSaveConfig;
    {*配置信息*}
    procedure SetHintText(const nLabel: TLabel);
    {*提示信息*}
    procedure WMFrameChange(var nMsg: TMessage); message WM_FrameChange;
    procedure DoFrameChange(const nName: string; const nCtrl: TWinControl;
      const nState: TControlChangeState);
    {*组件变动*}
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
  gSysLoger.AddLog(TfMainForm, '系统主模块', nEvent);
end;

//------------------------------------------------------------------------------
//Desc: 测试nConnStr是否有效
function ConnCallBack(const nConnStr: string): Boolean;
begin
  FDM.ADOConn.Close;
  FDM.ADOConn.ConnectionString := nConnStr;
  FDM.ADOConn.Open;
  Result := FDM.ADOConn.Connected;
end;

//------------------------------------------------------------------------------
//Date: 2007-10-15
//Parm: 标签
//Desc: 在nLabel上显示提示信息
procedure TfMainForm.SetHintText(const nLabel: TLabel);
begin
  nLabel.Font.Color := clWhite;
  nLabel.Font.Size := 12;
  nLabel.Font.Style := nLabel.Font.Style + [fsBold];

  nLabel.Caption := gSysParam.FHintText;
  nLabel.Left := 8;
  nLabel.Top := (HintPanel.Height + nLabel.Height - 12) div 2;
end;

//Desc: 载入窗体配置
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

//Desc: 保存窗体配置
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
  //系统对象

  FDM.LoadSystemIcons(gSysParam.FIconFile);
  //载入图标
  FormLoadConfig;
  //载入配置

  nStr := BuildConnectDBStr;

  while nStr = '' do
  begin
    ShowMsg('请输入正确的"数据库"配置参数', sHint);
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
  WriteLog('系统启动');
end;

procedure TfMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  {$IFNDEF debug}
  if not QueryDlg(sCloseQuery, sHint) then
  begin
    Action := caNone; Exit;
  end;
  {$ENDIF}

  ShowWaitForm(Self, '正在退出系统', True);
  try
    FormSaveConfig;          //窗体配置

    WriteLog('系统关闭');
    {$IFNDEF debug}
    Sleep(2200);
    {$ENDIF}
    FreeSystemObject;        //系统对象
  finally
    CloseWaitForm;
  end;
end;

//Desc: 执行nMenuID指定的动作
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

//Desc: 获取nMenu对应的模块索引
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
//Parm: 标识；多页签；是否创建
//Desc: 检索nPage中标识为nTag的页面，不存在则创建
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

//Desc: 处理菜单
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
  if nName = sMenuItem_Close then //退出系统
  begin
    Close;
  end else

  if nName = sMenuItem_NCConnect then //连接NC数据库
  begin
    ShowConnectDBSetupForm(ConnCallBack);

    nStr := BuildConnectDBStr;

    while nStr = '' do
    begin
      ShowMsg('请输入正确的"数据库"配置参数', sHint);
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
    //模块映射项

    if nP.FItemType = mtForm then
         CreateBaseFormItem(nP.FModule, nFull)
    else CreateBaseFrameItem(nP.FModule, GetSheet(nP.FModule, wPage), nFull);
  end else DoFixedMenuActive(nFull);
end;

//------------------------------------------------------------------------------
//Desc: 增减Frame
procedure TfMainForm.DoFrameChange(const nName: string;
  const nCtrl: TWinControl; const nState: TControlChangeState);
var nStr: string;
    nInt: Integer;
    nSheet: TcxTabSheet;
begin
  if csDestroying in ComponentState then Exit;
  //主窗口退出时不处理

  if nCtrl is TBaseFrame then
       nInt := (nCtrl as TBaseFrame).FrameID
  else Exit;

  nSheet := GetSheet(nInt, wPage, False);
  if not Assigned(nSheet) then Exit;

  if nState = fsNew then
  begin
    nSheet.Caption := '启动中...';
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

//Desc: 依据状态设置Page风格
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
