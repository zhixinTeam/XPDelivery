{*******************************************************************************
  ����: fendou116688@163.com
  ����: ��������������첽��ȡ����

  ��ע:
  *.����Ԫʵ���˰����������Զ���ѯ����.
*******************************************************************************}
unit UPoundCardReader;

interface
uses
  Windows, Classes, SysUtils, NativeXml, UMgrSync, UWaitItem, ULibFun,
  USysLoger, UMgrPoundTunnels, SyncObjs, UMgrMHReader;

{$I Link.inc}
const
  ICardReadInterval = 5;//��
  ICardReadKeepalive = 300; //��

type
  TOnCardReadEvent = procedure (const nCardNO: string;
    var nResult: Boolean) of object;

  TCardReadIndex = Integer;
  //��������������

  PTCardReadRecord = ^TCardReadRecord;
  TCardReadRecord = record
    FID     : TCardReadIndex;
    FEvent  : TOnCardReadEvent;

    FTunnel : string;
    //����ͨ��ID

    FCardLast:string;
    FTimeLast:Int64;
    //���濨����Ϣ
  end;

  TPoundCardReader = class(TThread)
  private
    FWaiter: TWaitObject;
    //�ȴ�����
    FSyncSection: TCriticalSection;
    //�¼�ͬ����
    FCardReadBase:TCardReadIndex;
    FCardReads: TList;
    //�����¼��б�

    FCardReaderUser: Integer;
  protected
    procedure Execute; override;
    //�߳���

    procedure ClearCardReader;
    //�ͷŶ�����
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure Wakeup;
    procedure StopMe;
    //ֹͣ�߳�

    procedure StartCardReader;
    //��������
    procedure StopCardReader;
    //ֹͣ����

    function AddCardReader(nEvent: TOnCardReadEvent;nTunnel: string=''):Integer;
    procedure DelCardReader(nCardReadIdx: TCardReadIndex);
    function GetCardNOSync(nCardReadIdx: TCardReadIndex):string;

    property CardReaderUser:Integer read FCardReaderUser;
  end;

var
  gPoundCardReader: TPoundCardReader = nil;
  //ȫ��ʹ��

implementation

uses
  USysDB;

procedure WriteLog(const nEvent: string);
begin
  if Assigned(gSysLoger) then
    gSysLoger.AddLog(TPoundCardReader, '��ͨ����վ�첽����', nEvent);
end;
//------------------------------------------------------------------------------
constructor TPoundCardReader.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;

  FCardReadBase:=0;
  FCardReaderUser:=0;
  //��������

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
  //�ͷŶ�����

  FSyncSection.Free;
  FCardReads.Free;

  FWaiter.Free;
  inherited;
end;

//Desc: �ͷ��߳�
procedure TPoundCardReader.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
end;

//Desc: �����߳�
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
      WriteLog(Format('�쳣%s', [E.Message]));
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
