{*******************************************************************************
  作者: fendou116688@163.com
  描述: 多道磅房读卡器异步读取管理

  备注:
  *.本单元实现了磅房读卡器自动查询管理.
*******************************************************************************}
unit UPoundCardReader;

interface
uses
  Windows, Classes, SysUtils, NativeXml, UMgrSync, UWaitItem, ULibFun,
  USysLoger, UMgrPoundTunnels, SyncObjs, UMgrMHReader;

{$I Link.inc}
const
  ICardReadInterval = 5;//秒
  ICardReadKeepalive = 300; //秒

type
  TOnCardReadEvent = procedure (const nCardNO: string;
    var nResult: Boolean) of object;

  TCardReadIndex = Integer;
  //读卡器索引类型

  PTCardReadRecord = ^TCardReadRecord;
  TCardReadRecord = record
    FID     : TCardReadIndex;
    FEvent  : TOnCardReadEvent;

    FTunnel : string;
    //磅房通道ID

    FCardLast:string;
    FTimeLast:Int64;
    //保存卡号信息
  end;

  TPoundCardReader = class(TThread)
  private
    FWaiter: TWaitObject;
    //等待对象
    FSyncSection: TCriticalSection;
    //事件同步锁
    FCardReadBase:TCardReadIndex;
    FCardReads: TList;
    //读卡事件列表

    FCardReaderUser: Integer;
  protected
    procedure Execute; override;
    //线程体

    procedure ClearCardReader;
    //释放读卡器
  public
    constructor Create;
    destructor Destroy; override;
    //创建释放
    procedure Wakeup;
    procedure StopMe;
    //停止线程

    procedure StartCardReader;
    //启动读卡
    procedure StopCardReader;
    //停止读卡

    function AddCardReader(nEvent: TOnCardReadEvent;nTunnel: string=''):Integer;
    procedure DelCardReader(nCardReadIdx: TCardReadIndex);
    function GetCardNOSync(nCardReadIdx: TCardReadIndex):string;

    property CardReaderUser:Integer read FCardReaderUser;
  end;

var
  gPoundCardReader: TPoundCardReader = nil;
  //全局使用

implementation

uses
  USysDB;

procedure WriteLog(const nEvent: string);
begin
  if Assigned(gSysLoger) then
    gSysLoger.AddLog(TPoundCardReader, '多通道磅站异步读卡', nEvent);
end;
//------------------------------------------------------------------------------
constructor TPoundCardReader.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;

  FCardReadBase:=0;
  FCardReaderUser:=0;
  //用于索引

  FCardReads := TList.Create;
  FSyncSection := TCriticalSection.Create;
  //xxxxxx

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := ICardReadInterval * 100;
end;

destructor TPoundCardReader.Destroy;
begin
  StopCardReader;
  //Close all

  ClearCardReader;
  //释放读卡器

  FSyncSection.Free;
  FCardReads.Free;

  FWaiter.Free;
  inherited;
end;

//Desc: 释放线程
procedure TPoundCardReader.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
end;

//Desc: 唤醒线程
procedure TPoundCardReader.Wakeup;
begin
  FWaiter.Wakeup;
end;

procedure TPoundCardReader.StartCardReader;
begin
  Resume;
end;

procedure TPoundCardReader.StopCardReader;
begin
  StopMe;
end;

procedure TPoundCardReader.Execute;
var nIdx: Integer;
    nRet: Boolean;
    nReadCard: string;
    nPItem: PTCardReadRecord; 
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    nReadCard := '';
    FSyncSection.Enter;
    try
      for nIdx:=0 to FCardReads.Count-1 do
      begin
        nPItem := FCardReads[nIdx];

        with nPItem^ do
        begin
          if Assigned(gMHReaderManager) then
            nReadCard := gMHReaderManager.ReadCardData(FTunnel);

          if (nReadCard <> FCardLast) or
          (GetTickCount-FTimeLast > ICardReadKeepalive * 1000) then
          begin
            nRet := True;
            if Assigned(FEvent) and (nReadCard <> '') then
              FEvent(nReadCard, nRet);

            FCardLast := nReadCard;
            if nRet then FTimeLast := GetTickCount;
          end;
        end;
      end;  
    finally
      FSyncSection.Leave;
    end;
  except
    On E:Exception do
    begin
      WriteLog(Format('异常%s', [E.Message]));
    end;
  end;
end;

function TPoundCardReader.AddCardReader(nEvent: TOnCardReadEvent;
  nTunnel:string=''):Integer;
var nPItem: PTCardReadRecord;
begin
  FSyncSection.Enter;
  try
    Inc(FCardReadBase);
    Inc(FCardReaderUser);
    Result := FCardReadBase;

    New(nPItem);
    FCardReads.Add(nPItem);

    with nPItem^ do
    begin
      FID    := FCardReadBase;
      FEvent := nEvent;

      FTunnel:= nTunnel;
    end;  
  finally
    FSyncSection.Leave;
  end;
end;

procedure TPoundCardReader.DelCardReader(nCardReadIdx: TCardReadIndex);
var nIdx: Integer;
    nPItem: PTCardReadRecord;
begin
  FSyncSection.Enter;
  try
    if FCardReads.Count<1 then Exit;

    for nIdx:=FCardReads.Count - 1 downto 0 do
    begin
      nPItem := FCardReads[nIdx];
      if nPItem.FID <> nCardReadIdx then continue;

      Dispose(nPItem);
      FCardReads.Delete(nIdx);

      Dec(FCardReaderUser);
    end;
  finally
    FSyncSection.Leave;
  end;
end;

procedure TPoundCardReader.ClearCardReader;
var nIdx: Integer;
    nPItem: PTCardReadRecord;
begin
  FSyncSection.Enter;
  try
    if FCardReads.Count<1 then Exit;

    for nIdx:=FCardReads.Count - 1 downto 0 do
    begin
      nPItem := FCardReads[nIdx];

      Dispose(nPItem);
      FCardReads.Delete(nIdx);

      Dec(FCardReaderUser);
    end;
  finally
    FSyncSection.Leave;
  end;
end;

function TPoundCardReader.GetCardNOSync(nCardReadIdx: TCardReadIndex):string;
var nIdx: Integer;
    nPItem: PTCardReadRecord;
begin
  Result := '';
  FSyncSection.Enter;
  try
    if FCardReads.Count<1 then Exit;

    for nIdx:=FCardReads.Count - 1 downto 0 do
    begin
      nPItem := FCardReads[nIdx];

      with nPItem^ do
      if FID=nCardReadIdx then
      begin
        Result := FCardLast;         
        Exit;
      end;
    end;
  finally
    FSyncSection.Leave;
  end;
end;

initialization
  gPoundCardReader := nil;
finalization
  FreeAndNil(gPoundCardReader);
end.
