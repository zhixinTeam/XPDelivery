{*******************************************************************************
  ����: dmzn@163.com 2013-12-04
  ����: ģ��ҵ�����
*******************************************************************************}
unit UWorkerBusiness;

{$I Link.Inc}
interface

uses
  Windows, Classes, Controls, DB, SysUtils, UBusinessWorker, UBusinessPacker,
  UBusinessConst, UMgrDBConn, UMgrParam, ZnMD5, ULibFun, UFormCtrl, USysLoger,
  USysDB, UMITConst, UBase64{$IFDEF HardMon}, UWorkerHardware{$ENDIF};

type
  TOrderItem = record
    FOrder: string;         //������
    FBill: string;
    FCusID: string;         //�ͻ���
    FCusName: string;       //�ͻ���
    FCusCode: string;       //�ͻ�����
    FStockID: string;       //Ʒ�ֺ�
    FStockName: string;     //Ʒ����
    FStockType: string;     //����
    FMaxValue: Double;      //������
    FKDValue: Double;       //������
  end;

  TOrderItems = array of TOrderItem;

  TBusWorkerQueryField = class(TBusinessWorkerBase)
  private
    FIn: TWorkerQueryFieldData;
    FOut: TWorkerQueryFieldData;
  public
    class function FunctionName: string; override;
    function GetFlagStr(const nFlag: Integer): string; override;
    function DoWork(var nData: string): Boolean; override;
    //ִ��ҵ��
  end;

  TMITDBWorker = class(TBusinessWorkerBase)
  protected
    FErrNum: Integer;
    //������
    FDBConn: PDBWorker;
    //����ͨ��
    FDataIn,FDataOut: PBWDataBase;
    //��γ���
    FDataOutNeedUnPack: Boolean;
    //��Ҫ���
    procedure GetInOutData(var nIn,nOut: PBWDataBase); virtual; abstract;
    //�������
    function VerifyParamIn(var nData: string): Boolean; virtual;
    //��֤���
    function DoDBWork(var nData: string): Boolean; virtual; abstract;
    function DoAfterDBWork(var nData: string; nResult: Boolean): Boolean; virtual;
    //����ҵ��
  public
    function DoWork(var nData: string): Boolean; override;
    //ִ��ҵ��
    procedure WriteLog(const nEvent: string);
    //��¼��־
  end;

  TWorkerBusinessCommander = class(TMITDBWorker)
  private
    FListA,FListB,FListC: TStrings;
    //list
    FOrderItems: TOrderItems;
    //�����б�
    FIn: TWorkerBusinessCommand;
    FOut: TWorkerBusinessCommand;
  protected
    procedure GetInOutData(var nIn,nOut: PBWDataBase); override;
    function DoDBWork(var nData: string): Boolean; override;
    //base funciton
    function GetServerNow(var nData: string): Boolean;
    //��ȡ������ʱ��
    function GetSerailID(var nData: string): Boolean;
    //��ȡ����
    function IsSystemExpired(var nData: string): Boolean;
    //ϵͳ�Ƿ��ѹ���
    function SaveTruck(var nData: string): Boolean;
    function UpdateTruck(var nData: string): Boolean;
    //���泵����Truck��
    function GetTruckPoundData(var nData: string): Boolean;
    function SaveTruckPoundData(var nData: string): Boolean;
    //��ȡ������������
    function GetCardPoundData(var nData: string): Boolean;
    //��ȡIC����������

    function GetSQLQueryOrder(var nData: string): Boolean;
    //��ȡ������ѯ���
    function GetSQLQueryDispatch(var nData: string): Boolean;
    //��ȡ������ѯ���
    function GetSQLQueryCustomer(var nData: string): Boolean;
    //��ȡ�ͻ���ѯ���
    function GetOrderGYValue(var nData: string): Boolean;
    //��ȡ�����ѷ�����
    function SyncNC_ME03(var nData: string): Boolean;
    //��Ӧ��������
  public
    constructor Create; override;
    destructor destroy; override;
    //new free
    function GetFlagStr(const nFlag: Integer): string; override;
    class function FunctionName: string; override;
    //base function
    class function CallMe(const nCmd: Integer; const nData,nExt: string;
      const nOut: PWorkerBusinessCommand): Boolean;
    //local call
  end;

implementation

class function TBusWorkerQueryField.FunctionName: string;
begin
  Result := sBus_GetQueryField;
end;

function TBusWorkerQueryField.GetFlagStr(const nFlag: Integer): string;
begin
  inherited GetFlagStr(nFlag);

  case nFlag of
   cWorker_GetPackerName : Result := sBus_GetQueryField;
  end;
end;

function TBusWorkerQueryField.DoWork(var nData: string): Boolean;
begin
  FOut.FData := '*';
  FPacker.UnPackIn(nData, @FIn);

  case FIn.FType of
   cQF_Bill: 
    FOut.FData := '*';
  end;

  Result := True;
  FOut.FBase.FResult := True;
  nData := FPacker.PackOut(@FOut);
end;

//------------------------------------------------------------------------------
//Date: 2012-3-13
//Parm: ���������
//Desc: ��ȡ�������ݿ��������Դ
function TMITDBWorker.DoWork(var nData: string): Boolean;
begin
  Result := False;
  FDBConn := nil;

  with gParamManager.ActiveParam^ do
  try
    FDBConn := gDBConnManager.GetConnection(FDB.FID, FErrNum);
    if not Assigned(FDBConn) then
    begin
      nData := '�������ݿ�ʧ��(DBConn Is Null).';
      Exit;
    end;

    if not FDBConn.FConn.Connected then
      FDBConn.FConn.Connected := True;
    //conn db

    FDataOutNeedUnPack := True;
    GetInOutData(FDataIn, FDataOut);
    FPacker.UnPackIn(nData, FDataIn);

    with FDataIn.FVia do
    begin
      FUser   := gSysParam.FAppFlag;
      FIP     := gSysParam.FLocalIP;
      FMAC    := gSysParam.FLocalMAC;
      FTime   := FWorkTime;
      FKpLong := FWorkTimeInit;
    end;

    {$IFDEF DEBUG}
    WriteLog('Fun: '+FunctionName+' InData:'+ FPacker.PackIn(FDataIn, False));
    {$ENDIF}
    if not VerifyParamIn(nData) then Exit;
    //invalid input parameter

    FPacker.InitData(FDataOut, False, True, False);
    //init exclude base
    FDataOut^ := FDataIn^;

    Result := DoDBWork(nData);
    //execute worker

    if Result then
    begin
      if FDataOutNeedUnPack then
        FPacker.UnPackOut(nData, FDataOut);
      //xxxxx

      Result := DoAfterDBWork(nData, True);
      if not Result then Exit;

      with FDataOut.FVia do
        FKpLong := GetTickCount - FWorkTimeInit;
      nData := FPacker.PackOut(FDataOut);

      {$IFDEF DEBUG}
      WriteLog('Fun: '+FunctionName+' OutData:'+ FPacker.PackOut(FDataOut, False));
      {$ENDIF}
    end else DoAfterDBWork(nData, False);
  finally
    gDBConnManager.ReleaseConnection(FDBConn);
  end;
end;

//Date: 2012-3-22
//Parm: �������;���
//Desc: ����ҵ��ִ����Ϻ����β����
function TMITDBWorker.DoAfterDBWork(var nData: string; nResult: Boolean): Boolean;
begin
  Result := True;
end;

//Date: 2012-3-18
//Parm: �������
//Desc: ��֤��������Ƿ���Ч
function TMITDBWorker.VerifyParamIn(var nData: string): Boolean;
begin
  Result := True;
end;

//Desc: ��¼nEvent��־
procedure TMITDBWorker.WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TMITDBWorker, FunctionName, nEvent);
end;

//------------------------------------------------------------------------------
class function TWorkerBusinessCommander.FunctionName: string;
begin
  Result := sBus_BusinessCommand;
end;

constructor TWorkerBusinessCommander.Create;
begin
  FListA := TStringList.Create;
  FListB := TStringList.Create;
  FListC := TStringList.Create;
  inherited;
end;

destructor TWorkerBusinessCommander.destroy;
begin
  FreeAndNil(FListA);
  FreeAndNil(FListB);
  FreeAndNil(FListC);
  inherited;
end;

function TWorkerBusinessCommander.GetFlagStr(const nFlag: Integer): string;
begin
  Result := inherited GetFlagStr(nFlag);

  case nFlag of
   cWorker_GetPackerName : Result := sBus_BusinessCommand;
  end;
end;

procedure TWorkerBusinessCommander.GetInOutData(var nIn,nOut: PBWDataBase);
begin
  nIn := @FIn;
  nOut := @FOut;
  FDataOutNeedUnPack := False;
end;

//Date: 2014-09-15
//Parm: ����;����;����;���
//Desc: ���ص���ҵ�����
class function TWorkerBusinessCommander.CallMe(const nCmd: Integer;
  const nData, nExt: string; const nOut: PWorkerBusinessCommand): Boolean;
var nStr: string;
    nIn: TWorkerBusinessCommand;
    nPacker: TBusinessPackerBase;
    nWorker: TBusinessWorkerBase;
begin
  nPacker := nil;
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;

    nPacker := gBusinessPackerManager.LockPacker(sBus_BusinessCommand);
    nPacker.InitData(@nIn, True, False);
    //init
    
    nStr := nPacker.PackIn(@nIn);
    nWorker := gBusinessWorkerManager.LockWorker(FunctionName);
    //get worker

    Result := nWorker.WorkActive(nStr);
    if Result then
         nPacker.UnPackOut(nStr, nOut)
    else nOut.FData := nStr;
  finally
    gBusinessPackerManager.RelasePacker(nPacker);
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2012-3-22
//Parm: ��������
//Desc: ִ��nDataҵ��ָ��
function TWorkerBusinessCommander.DoDBWork(var nData: string): Boolean;
begin
  with FOut.FBase do
  begin
    FResult := True;
    FErrCode := 'S.00';
    FErrDesc := 'ҵ��ִ�гɹ�.';
  end;

  case FIn.FCommand of
   cBC_ServerNow           : Result := GetServerNow(nData);
   cBC_GetSerialNO         : Result := GetSerailID(nData);
   cBC_IsSystemExpired     : Result := IsSystemExpired(nData);

   cBC_SaveTruckInfo       : Result := SaveTruck(nData);
   cBC_UpdateTruckInfo     : Result := UpdateTruck(nData);
   cBC_GetCardPoundData    : Result := GetCardPoundData(nData);
   cBC_GetTruckPoundData   : Result := GetTruckPoundData(nData);
   cBC_SaveTruckPoundData  : Result := SaveTruckPoundData(nData);

   cBC_SyncME03            : Result := SyncNC_ME03(nData);
   cBC_GetOrderGYValue     : Result := GetOrderGYValue(nData);
   cBC_GetSQLQueryOrder    : Result := GetSQLQueryOrder(nData);
   cBC_GetSQLQueryDispatch : Result := GetSQLQueryDispatch(nData);
   cBC_GetSQLQueryCustomer : Result := GetSQLQueryCustomer(nData);
   else
    begin
      Result := False;
      nData := '��Ч��ҵ�����(Invalid Command).';
    end;
  end;
end;

//Date: 2014-09-05
//Desc: ��ȡ��������ǰʱ��
function TWorkerBusinessCommander.GetServerNow(var nData: string): Boolean;
var nStr: string;
begin
  nStr := 'Select ' + sField_SQLServer_Now;
  //sql

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    FOut.FData := DateTime2Str(Fields[0].AsDateTime);
    Result := True;
  end;
end;

//Date: 2012-3-25
//Desc: �������������б��
function TWorkerBusinessCommander.GetSerailID(var nData: string): Boolean;
var nInt: Integer;
    nStr,nP,nB: string;
begin
  FDBConn.FConn.BeginTrans;
  try
    Result := False;
    FListA.Text := FIn.FData;
    //param list

    nStr := 'Update %s Set B_Base=B_Base+1 ' +
            'Where B_Group=''%s'' And B_Object=''%s''';
    nStr := Format(nStr, [sTable_SerialBase, FListA.Values['Group'],
            FListA.Values['Object']]);
    gDBConnManager.WorkerExec(FDBConn, nStr);

    nStr := 'Select B_Prefix,B_IDLen,B_Base,B_Date,%s as B_Now From %s ' +
            'Where B_Group=''%s'' And B_Object=''%s''';
    nStr := Format(nStr, [sField_SQLServer_Now, sTable_SerialBase,
            FListA.Values['Group'], FListA.Values['Object']]);
    //xxxxx

    with gDBConnManager.WorkerQuery(FDBConn, nStr) do
    begin
      if RecordCount < 1 then
      begin
        nData := 'û��[ %s.%s ]�ı�������.';
        nData := Format(nData, [FListA.Values['Group'], FListA.Values['Object']]);

        FDBConn.FConn.RollbackTrans;
        Exit;
      end;

      nP := FieldByName('B_Prefix').AsString;
      nB := FieldByName('B_Base').AsString;
      nInt := FieldByName('B_IDLen').AsInteger;

      if FIn.FExtParam = sFlag_Yes then //�����ڱ���
      begin
        nStr := Date2Str(FieldByName('B_Date').AsDateTime, False);
        //old date

        if (nStr <> Date2Str(FieldByName('B_Now').AsDateTime, False)) and
           (FieldByName('B_Now').AsDateTime > FieldByName('B_Date').AsDateTime) then
        begin
          nStr := 'Update %s Set B_Base=1,B_Date=%s ' +
                  'Where B_Group=''%s'' And B_Object=''%s''';
          nStr := Format(nStr, [sTable_SerialBase, sField_SQLServer_Now,
                  FListA.Values['Group'], FListA.Values['Object']]);
          gDBConnManager.WorkerExec(FDBConn, nStr);

          nB := '1';
          nStr := Date2Str(FieldByName('B_Now').AsDateTime, False);
          //now date
        end;

        System.Delete(nStr, 1, 2);
        //yymmdd
        nInt := nInt - Length(nP) - Length(nStr) - Length(nB);
        FOut.FData := nP + nStr + StringOfChar('0', nInt) + nB;
      end else
      begin
        nInt := nInt - Length(nP) - Length(nB);
        nStr := StringOfChar('0', nInt);
        FOut.FData := nP + nStr + nB;
      end;
    end;

    FDBConn.FConn.CommitTrans;
    Result := True;
  except
    FDBConn.FConn.RollbackTrans;
    raise;
  end;
end;

//Date: 2014-09-05
//Desc: ��֤ϵͳ�Ƿ��ѹ���
function TWorkerBusinessCommander.IsSystemExpired(var nData: string): Boolean;
var nStr: string;
    nDate: TDate;
    nInt: Integer;
begin
  nDate := Date();
  //server now

  nStr := 'Select D_Value,D_ParamB From %s ' +
          'Where D_Name=''%s'' and D_Memo=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_SysParam, sFlag_ValidDate]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if RecordCount > 0 then
  begin
    nStr := 'dmzn_stock_' + Fields[0].AsString;
    nStr := MD5Print(MD5String(nStr));

    if nStr = Fields[1].AsString then
      nDate := Str2Date(Fields[0].AsString);
    //xxxxx
  end;

  nInt := Trunc(nDate - Date());
  Result := nInt > 0;

  if nInt <= 0 then
  begin
    nStr := 'ϵͳ�ѹ��� %d ��,����ϵ����Ա!!';
    nData := Format(nStr, [-nInt]);
    Exit;
  end;

  FOut.FData := IntToStr(nInt);
  //last days

  if nInt <= 7 then
  begin
    nStr := Format('ϵͳ�� %d ������', [nInt]);
    FOut.FBase.FErrDesc := nStr;
    FOut.FBase.FErrCode := sFlag_ForceHint;
  end;
end;

//Date: 2014-10-02
//Parm: ���ƺ�[FIn.FData];
//Desc: ���泵����sTable_Truck��
function TWorkerBusinessCommander.SaveTruck(var nData: string): Boolean;
var nStr: string;
begin
  Result := True;
  FIn.FData := UpperCase(FIn.FData);
  
  nStr := 'Select Count(*) From %s Where T_Truck=''%s''';
  nStr := Format(nStr, [sTable_Truck, FIn.FData]);
  //xxxxx

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if Fields[0].AsInteger < 1 then
  begin
    nStr := 'Insert Into %s(T_Truck, T_PY) Values(''%s'', ''%s'')';
    nStr := Format(nStr, [sTable_Truck, FIn.FData, GetPinYinOfStr(FIn.FData)]);
    gDBConnManager.WorkerExec(FDBConn, nStr);
  end;
end;

//Date: 2016-02-16
//Parm: ���ƺ�(Truck); ���ֶ���(Field);����ֵ(Value)
//Desc: ���³�����Ϣ��sTable_Truck��
function TWorkerBusinessCommander.UpdateTruck(var nData: string): Boolean;
var nStr: string;
    nValInt: Integer;
    nValFloat: Double;
begin
  Result := True;
  FListA.Text := FIn.FData;

  if FListA.Values['Field'] = 'T_PValue' then
  begin
    nStr := 'Select T_PValue, T_PTime From %s Where T_Truck=''%s''';
    nStr := Format(nStr, [sTable_Truck, FListA.Values['Truck']]);

    with gDBConnManager.WorkerQuery(FDBConn, nStr) do
    if RecordCount > 0 then
    begin
      nValInt := Fields[1].AsInteger;
      nValFloat := Fields[0].AsFloat;
    end else Exit;

    nValFloat := nValFloat * nValInt + StrToFloatDef(FListA.Values['Value'], 0);
    nValFloat := nValFloat / (nValInt + 1);
    nValFloat := Float2Float(nValFloat, cPrecision);

    nStr := 'Update %s Set T_PValue=%.2f, T_PTime=T_PTime+1 Where T_Truck=''%s''';
    nStr := Format(nStr, [sTable_Truck, nValFloat, FListA.Values['Truck']]);
    gDBConnManager.WorkerExec(FDBConn, nStr);
    //������ЧƤ��

    nValFloat := Float2Float(StrToFloatDef(FListA.Values['Value'], 0), cPrecision);
    nStr := 'Update %s Set T_LPValue=%.2f Where T_Truck=''%s''';
    nStr := Format(nStr, [sTable_Truck, nValFloat, FListA.Values['Truck']]);
    gDBConnManager.WorkerExec(FDBConn, nStr);
    //�����ϴ�Ƥ��
  end;
end;

//Date: 2014-09-25
//Parm: ���ƺ�[FIn.FData]
//Desc: ��ȡָ�����ƺŵĳ�Ƥ����(ʹ�����ģʽ,δ����)
function TWorkerBusinessCommander.GetTruckPoundData(var nData: string): Boolean;
var nStr: string;
    nPound: TLadingBillItems;
begin
  SetLength(nPound, 1);
  FillChar(nPound[0], SizeOf(TLadingBillItem), #0);

  nStr := 'Select * From %s Where P_Truck=''%s'' And ' +
          'P_MValue Is Null And P_PModel=''%s''';
  nStr := Format(nStr, [sTable_PoundLog, FIn.FData, sFlag_PoundPD]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr),nPound[0] do
  begin
    if RecordCount > 0 then
    begin
      FCusID      := FieldByName('P_CusID').AsString;
      FCusName    := FieldByName('P_CusName').AsString;
      FTruck      := FieldByName('P_Truck').AsString;

      FType       := FieldByName('P_MType').AsString;
      FStockNo    := FieldByName('P_MID').AsString;
      FStockName  := FieldByName('P_MName').AsString;

      with FPData do
      begin
        FStation  := FieldByName('P_PStation').AsString;
        FValue    := FieldByName('P_PValue').AsFloat;
        FDate     := FieldByName('P_PDate').AsDateTime;
        FOperator := FieldByName('P_PMan').AsString;
      end;  

      FFactory    := FieldByName('P_FactID').AsString;
      FPModel     := FieldByName('P_PModel').AsString;
      FPType      := FieldByName('P_Type').AsString;
      FPoundID    := FieldByName('P_ID').AsString;

      FStatus     := sFlag_TruckBFP;
      FNextStatus := sFlag_TruckBFM;
      FSelected   := True;
    end else
    begin
      FTruck      := FIn.FData;
      FPModel     := sFlag_PoundPD;

      FStatus     := '';
      FNextStatus := sFlag_TruckBFP;
      FSelected   := True;
    end;
  end;

  FOut.FData := CombineBillItmes(nPound);
  Result := True;
end;

//Date: 2014-09-25
//Parm: ��������[FIn.FData]
//Desc: ��ȡָ�����ƺŵĳ�Ƥ����(ʹ�����ģʽ,δ����)
function TWorkerBusinessCommander.SaveTruckPoundData(var nData: string): Boolean;
var nProvide: Boolean;
    nStr,nSQL: string;
    nPound: TLadingBillItems;
    nOut: TWorkerBusinessCommand;
begin
  Result := False;
  AnalyseBillItems(FIn.FData, nPound);
  //��������

  with nPound[0] do
  begin
    if (FPoundID = '') or (FPModel = sFlag_PoundLS) then
    begin //�״ι��� or ��ʱ����
      TWorkerBusinessCommander.CallMe(cBC_SaveTruckInfo, FTruck, '', @nOut);
      //���泵�ƺ�

      FListC.Clear;
      FListC.Values['Group'] := sFlag_BusGroup;
      FListC.Values['Object'] := sFlag_PoundID;

      if not CallMe(cBC_GetSerialNO,
            FListC.Text, sFlag_Yes, @nOut) then
        raise Exception.Create(nOut.FData);
      //xxxxx

      FPoundID := nOut.FData;
      //new id

      if FPModel = sFlag_PoundLS then
           nStr := sFlag_Other
      else nStr := sFlag_Provide;

      nSQL := MakeSQLByStr([
              SF('P_ID', FPoundID),
              SF('P_Type', nStr),
              SF('P_Truck', FTruck),
              SF('P_CusID', FCusID),
              SF('P_CusName', FCusName),
              SF('P_MID', FStockNo),
              SF('P_MName', FStockName),
              SF('P_MType', sFlag_San),
              SF('P_LimValue', FValue, sfVal),
              SF('P_PValue', FPData.FValue, sfVal),
              SF('P_PDate', sField_SQLServer_Now, sfVal),
              SF('P_PMan', FIn.FBase.FFrom.FUser),
              SF('P_FactID', FFactory),
              SF('P_PStation', FPData.FStation),
              SF('P_Direction', '����'),
              SF('P_PModel', FPModel),
              SF('P_Status', sFlag_TruckBFP),
              SF('P_Valid', sFlag_Yes),
              SF('P_SrcPoundID', FMemo),
              SF('P_Transport', FYSValid),
              SF('P_PrintNum', 0, sfVal)
              ], sTable_PoundLog, '', True);
      gDBConnManager.WorkerExec(FDBConn, nSQL);

      nSQL := MakeSQLByStr([SF('T_LastTime', sField_SQLServer_Now, sfVal)
              ], sTable_Truck, SF('T_Truck', FTruck), False);
      gDBConnManager.WorkerExec(FDBConn, nSQL);
    end else
    begin
      nStr := SF('P_ID', FPoundID);
      //where

      if FNextStatus = sFlag_TruckBFP then
      begin
        nSQL := MakeSQLByStr([
                SF('P_CusID', FCusID),
                SF('P_CusName', FCusName),
                SF('P_MID', FStockNo),
                SF('P_MName', FStockName),
                SF('P_MType', sFlag_San),
                
                SF('P_PValue', FPData.FValue, sfVal),
                SF('P_PDate', sField_SQLServer_Now, sfVal),
                SF('P_PMan', FIn.FBase.FFrom.FUser),
                SF('P_PStation', FPData.FStation),
                SF('P_MValue', FMData.FValue, sfVal),
                SF('P_MDate', DateTime2Str(FMData.FDate)),
                SF('P_MMan', FMData.FOperator),
                SF('P_MStation', FMData.FStation)
                ], sTable_PoundLog, nStr, False);
        //����ʱ,����Ƥ�ش�,����Ƥë������
      end else
      begin
        nSQL := MakeSQLByStr([
                SF('P_CusID', FCusID),
                SF('P_CusName', FCusName),
                SF('P_MID', FStockNo),
                SF('P_MName', FStockName),
                SF('P_MType', sFlag_San),

                SF('P_MValue', FMData.FValue, sfVal),
                SF('P_MDate', sField_SQLServer_Now, sfVal),
                SF('P_MMan', FIn.FBase.FFrom.FUser),
                SF('P_MStation', FMData.FStation)
                ], sTable_PoundLog, nStr, False);
        //xxxxx
      end;

      gDBConnManager.WorkerExec(FDBConn, nSQL);
      //���°���״̬

      try
        nSQL := MacroValue(sQuery_SysDict, [
                MI('$Table', sTable_SysDict),
                MI('$Name', sFlag_SyncMaterail)]);
                
        with gDBConnManager.WorkerQuery(FDBConn, nSQL) do
        if RecordCount > 0 then
        begin
          First;

          while not Eof do
          begin
            nStr := Trim(FieldByName('D_Value').AsString);
            if (nStr <> '') and (FListA.IndexOf(nStr) < 0) then
              FListA.Add(nStr);

            Next;
          end;  
        end;  

        nProvide := (FListA.Count > 0) and (FListA.IndexOf(FStockNo) >= 0);
        if nProvide and (not CallMe(cBC_SyncME03, FPoundID, '', @nOut)) then
          raise Exception.Create(nOut.FData);
        //ͬ����Ӧ��NC
      except
        on nErr: Exception do
        begin
          if FNextStatus = sFlag_TruckBFP then
                nStr := 'P_PValue=P_MValue'
          else  nStr := 'P_PValue=P_PValue';

          nSQL := 'Update %s Set %s,P_MValue=Null,P_MDate=Null Where P_ID=''%s''';
          nSQL := Format(nSQL, [sTable_PoundLog,nStr,FPoundID]);
          gDBConnManager.WorkerExec(FDBConn, nSQL);

          nData := nErr.Message;
          Exit;
        end;
      end;

      {$IFDEF HardMon}
      if not THardwareCommander.CallMe(cBC_RemotePrint, FPoundID, '', @nOut) then
        WriteLog(nOut.FData);
      {$ENDIF}
    end;

    FOut.FData := FPoundID;
    Result := True;
  end;
end;

//Date: 2014-09-25
//Parm: ���ƺ�[FIn.FData]
//Desc: ��ȡָ�����ƺŵĳ�Ƥ����(ʹ�����ģʽ,δ����)
function TWorkerBusinessCommander.GetCardPoundData(var nData: string): Boolean;
var nStr: string;
    nPound: TLadingBillItems;
begin
  Result := False;
  AnalyseCardItems(FIn.FData, FListA);  

  SetLength(nPound, 1); 
  FillChar(nPound[0], SizeOf(TLadingBillItem), #0);

  nStr := 'Select * From %s Where P_SrcPoundID=''%s'' And ' +
          'P_CusID=''%s'' And P_PModel=''%s''';
  nStr := Format(nStr, [sTable_PoundLog, FListA.Values[sCard_PoundID],
  FListA.Values[sCard_CompanyID],sFlag_PoundPD]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr),nPound[0] do
  begin
    if RecordCount > 0 then
    begin
      if FieldByName('P_MDate').AsString <> '' then
      begin
        nData := '[ %s.%s ]����ɹ���,�ÿ��޷��ظ�����.';
        nData := Format(nData, [FListA.Values[sCard_CompanyName],
                 FListA.Values[sCard_PoundID]]);
        Exit;         
      end;

      FCusID      := FieldByName('P_CusID').AsString;
      FCusName    := FieldByName('P_CusName').AsString;

      FTruck      := FieldByName('P_Truck').AsString;
      FValue      := FieldByName('P_LimValue').AsFloat;

      FType       := FieldByName('P_MType').AsString;
      FStockNo    := FieldByName('P_MID').AsString;
      FStockName  := FieldByName('P_MName').AsString;

      with FPData do
      begin
        FStation  := FieldByName('P_PStation').AsString;
        FValue    := FieldByName('P_PValue').AsFloat;
        FDate     := FieldByName('P_PDate').AsDateTime;
        FOperator := FieldByName('P_PMan').AsString;
      end;  

      FFactory    := FieldByName('P_FactID').AsString;
      FPModel     := FieldByName('P_PModel').AsString;
      FPType      := FieldByName('P_Type').AsString;
      FPoundID    := FieldByName('P_ID').AsString;

      FStatus     := sFlag_TruckBFP;
      FNextStatus := sFlag_TruckBFM;
      FSelected   := True;
    end else
    begin
      FPModel     := sFlag_PoundPD;
      FYSValid    := FListA.Values[sCard_Transport];
      FMemo       := FListA.Values[sCard_PoundID];
      FTruck      := FListA.Values[sCard_Truck];

      FType       := sFlag_San;
      FStockNo    := FListA.Values[sCard_MaterialID];
      FStockName  := FListA.Values[sCard_Material];

      FCusID      := FListA.Values[sCard_CompanyID];
      FCusName    := FListA.Values[sCard_CompanyName];
      FValue      := StrToFloat(FListA.Values[sCard_NetValue]);

      FStatus     := '';
      FNextStatus := sFlag_TruckBFP;
      FSelected   := True;
    end;
  end;

  FOut.FData := CombineBillItmes(nPound);
  Result := True;
end;

//Date: 2014-12-16
//Parm: ��ѯ����[FIn.FData];��ѯ����[FIn.FExtParam]
//Desc: ���ݲ�ѯ����,����ָ�����Ͷ�����SQL��ѯ���
function TWorkerBusinessCommander.GetSQLQueryOrder(var nData: string): Boolean;
var nStr,nType,nPB,nFactNum: string;
    nCorp,nWHGroup,nWHID:string;
begin
  Result := False;
  FListA.Text := DecodeBase64(FIn.FExtParam);

  nStr := 'Select D_Value,D_Memo,D_ParamB From %s Where D_Name=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_OrderInFact]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount < 1 then
    begin
      nData := '��������[ OrderInFact ]�ֵ���';
      Exit;
    end;

    First;
    nFactNum := UpperCase(FListA.Values['FactoryID']);
    while not Eof do
    begin
      nStr := Fields[1].AsString;
      nPB  := UpperCase(Fields[2].AsString);

      if (nFactNum = '') or (nPB = nFactNum) then
      begin
        if (nStr = sFlag_InFact) then
          nCorp := Fields[0].AsString;
        //xxxxx

        if nStr = sFlag_InWHouse then
          nWHGroup := Fields[0].AsString;
        //xxxxx

        if nStr = sFlag_InWHID then
          nWHID := Fields[0].AsString;
        //xxxxx
      end;

      Next;
    end;
  end;

  if FIn.FData = '101' then           //���۶���
    nType := SF('VBILLTYPE', 'ME25')
  else if FIn.FData = '102' then      //�������뵥
    nType := SF('VBILLTYPE', 'ME25')
  else if FIn.FData = '103' then      //���۶��������뵥
    nType := SF('VBILLTYPE', 'ME25')

  else if FIn.FData = '201' then      //�ɹ�����
    nType := SF('VBILLTYPE', 'ME03')
  else if FIn.FData = '202' then      //�ɹ����뵥
    nType := SF('VBILLTYPE', 'ME03')
  else if FIn.FData = '203' then      //�ɹ����������뵥
       nType := SF('VBILLTYPE', 'ME03')
  else nType := '';

  if nType = '' then
  begin
    nData := Format('��Ч�Ķ�����ѯ����( %s ).', [FIn.FData]);
    Exit;
  end;

  FOut.FData := 'select ' +
     'pk_meambill_b as pk_meambill,VBILLCODE,VBILLTYPE,COPERATOR,user_name,' +  //������ͷ
     'TMAKETIME,NPLANNUM,cvehicle,vbatchcode,unitname,areaclname,t1.vdef10,' +  //��������(t1.vdef10:���)
     't1.vdef2,t1.vdef5,t1.pk_cumandoc,custcode,cmnecode,custname,t_cd.def30,'+ //������Ϣ(t1.vdef5:Ʒ��;t1.vdef2:��������)
     'invcode,invname,invtype ' +                                               //����
     'from meam_bill t1 ' +
     '  left join sm_user t_su on t_su.cuserid=t1.coperator ' +
     '  left join meam_bill_b t2 on t2.PK_MEAMBILL=t1.PK_MEAMBILL' +
     '  left join Bd_cumandoc t_cd on t_cd.pk_cumandoc=t1.pk_cumandoc' +
     '  left join bd_cubasdoc t_cb on t_cb.pk_cubasdoc=t_cd.pk_cubasdoc' +
     '  left join Bd_invbasdoc t_ib on t_ib.pk_invbasdoc=t2.PK_INVBASDOC' +
     '  left join bd_corp t_cp on t_cp.pk_corp=t1.pk_corp' +
     '  left join bd_areacl t_al on t_al.pk_areacl=t1.vdef1' +
     ' Where ';
  //xxxxx

  Result := True;
  //xxxxx

  nStr := FListA.Values['BillCode'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + Format('VBILLCODE Like ''%%%s%%''', [nStr]);
    Exit; //�����Ų�ѯ
  end;

  nStr := FListA.Values['MeamKeys'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + Format('pk_meambill_b In (%s)', [nStr]);
    Exit; //�����Ų�ѯ
  end;

  nStr := FListA.Values['NoDate'];
  if nStr = '' then
  begin
    nStr := '(TMAKETIME>=''%s'' And TMAKETIME<''%s'')';
    FOut.FData := FOut.FData + Format(nStr, [
                  FListA.Values['DateStart'],
                  FListA.Values['DateEnd']]);
    //��������

    FOut.FData := FOut.FData + ' And ';
    //ƴ����������
  end;

  if Pos('10', FIn.FData) = 1 then   //���ۿ��Ʒ��������Ϳ����֯
  begin
    nStr := AdjustListStrFormat(nWHGroup, '''', True, ',');
    if nStr<>'' then
      FOut.FData := FOut.FData + '(t2.pk_callbody_from In (' + nStr + ')) And ';
    //�����֯����

    nStr := AdjustListStrFormat(nWHID, '''', True, ',');
    if nStr<>'' then
      FOut.FData := FOut.FData + '(t2.pk_warehouse_from In (' + nStr + ')) And ';
    //�ֿⷢ������

    nStr := AdjustListStrFormat(nCorp, '''', True, ',');
    if nStr<>'' then
      FOut.FData := FOut.FData + '(t2.pk_corp_from In (' + nStr + ')) And ';
    //���ۿ��Ʒ�������
  end else
  if Pos('20', FIn.FData) = 1 then //�ɹ������ջ������Ϳ����֯
  begin
    nStr := AdjustListStrFormat(nWHGroup, '''', True, ',');
    if nStr<>'' then
      FOut.FData := FOut.FData + '(t2.pk_callbody_main In (' + nStr + ')) And ';
    //�����֯����

    nStr := AdjustListStrFormat(nWHID, '''', True, ',');
    if nStr<>'' then
      FOut.FData := FOut.FData + '(t2.pk_warehouse_main In (' + nStr + ')) And ';
    //�ֿ��ջ�����

    nStr := AdjustListStrFormat(nCorp, '''', True, ',');
    if nStr<>'' then
      FOut.FData := FOut.FData + '(t2.pk_corp_main In (' + nStr + ')) And ';
    //�����ջ�����
  end;

  FOut.FData := FOut.FData + ' (' + nType + ')';
  //��������

  nStr := FListA.Values['QueryAll'];
  if nStr = '' then
  begin
    FOut.FData := FOut.FData + ' And (crowstatus=0 And VBILLSTATUS=1 ' +
                  'And t1.dr=0 And t2.dr=0)';
    //��ǰ��Ч����
  end;

  nStr := FListA.Values['CustomerID'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + Format(' And custcode=''%s''', [nStr]);
    //���ͻ����
  end;

  nStr := FListA.Values['StockNo'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + Format(' And invcode=''%s''', [nStr]);
    //�����ϱ��
  end;

  nStr := FListA.Values['Filter'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + ' And (' + DecodeBase64(nStr) + ')';
    //��ѯ����
  end;

  nStr := FListA.Values['Order'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + ' Order By ' + nStr;
    //��������
  end;
end;

//Date: 2015-01-08
//Parm: ��ѯ����[FIn.FExtParam]
//Desc: ���ݲ�ѯ��������������SQL��ѯ���
function TWorkerBusinessCommander.GetSQLQueryDispatch(var nData: string): Boolean;
var nStr: string;
begin
  FOut.FData := 'select ' +
     'pk_meambill_b as pk_meambill,VBILLCODE,VBILLTYPE,COPERATOR,user_name,' + //������ͷ
     'TMAKETIME,NPLANNUM,cvehicle,vbatchcode,t1.pk_corp_main,unitname,' +      //��������
     'invcode,invname,invtype ' +                                              //����
     'from meam_bill t1 ' +
     '  left join sm_user t_su on t_su.cuserid=t1.coperator ' +
     '  left join meam_bill_b t2 on t2.PK_MEAMBILL=t1.PK_MEAMBILL' +
     '  left join Bd_invbasdoc t_ib on t_ib.pk_invbasdoc=t2.PK_INVBASDOC' +
     '  left join bd_corp t_cp on t_cp.pk_corp=t1.pk_corp_main' +
     ' Where ' ;
  FOut.FData := FOut.FData + SF('VBILLTYPE', 'ME09');

  Result := True;
  FListA.Text := DecodeBase64(FIn.FExtParam);

  nStr := FListA.Values['BillCode'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + Format(' And VBILLCODE Like ''%%%s%%''', [nStr]);
    Exit; //�����Ų�ѯ
  end;

  nStr := FListA.Values['MeamKeys'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + Format(' And pk_meambill_b In (%s)', [nStr]);
    Exit; //�����Ų�ѯ
  end;

  nStr := FListA.Values['NoDate'];
  if nStr = '' then
  begin
    nStr := ' And (TMAKETIME>=''%s'' And TMAKETIME<''%s'')';
    FOut.FData := FOut.FData + Format(nStr, [
                  FListA.Values['DateStart'],
                  FListA.Values['DateEnd']]);
    //��������
  end;

  nStr := FListA.Values['QueryAll'];
  if nStr = '' then
  begin
    FOut.FData := FOut.FData + ' And (crowstatus=0 And VBILLSTATUS=1 ' +
                  'And t1.dr=0 And t2.dr=0)';
    //��ǰ��Ч����
  end;

  nStr := FListA.Values['Customer'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + Format(' And unitname = ''%s''', [nStr]);
    //���ͻ����
  end;
  
  nStr := FListA.Values['StockNo'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + Format(' And invcode=''%s''', [nStr]);
    //�����ϱ��
  end;

  nStr := FListA.Values['Filter'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + ' And (' + DecodeBase64(nStr) + ')';
    //��ѯ����
  end;

  nStr := FListA.Values['Order'];
  if nStr <> '' then
  begin
    FOut.FData := FOut.FData + ' Order By ' + nStr;
    //��������
  end;
end;

//Date: 2014-12-18
//Parm: �ͻ����[FIn.FData];�ͻ�����[FIn.FExtParam];
//Desc: ����ģ����ѯ�ͻ���SQL���
function TWorkerBusinessCommander.GetSQLQueryCustomer(var nData: string): Boolean;
var nStr: string;
begin
  Result := True;
  FOut.FData := 'Select DISTINCT on (custcode) custcode,custname,' +
      'cmnecode from Bd_cumandoc t1 ' +
      '  left join bd_cubasdoc t2 on t2.pk_cubasdoc=t1.pk_cubasdoc' +
      ' where ';
  //xxxxx

  if FIn.FData <> '' then
  begin
    nStr := '(cmnecode=''%s'')';
    FOut.FData := FOut.FData + Format(nStr, [FIn.FData]);
    //�ͻ����ģ��
  end;

  if FIn.FExtParam <> '' then
  begin
    nStr := '(custname like ''%%%s%%'')';
    if FIn.FData <> '' then
      nStr := ' or ' + nStr;
    FOut.FData := FOut.FData + Format(nStr, [FIn.FExtParam]);
    //�ͻ�����ģ��
  end;

  FOut.FData := FOut.FData + ' Group By custcode,custname,cmnecode';
end;

//Date: 2015-01-08
//Parm: ������(���)[FIn.FData]
//Desc: ��ȡ�������ѷ�����
function TWorkerBusinessCommander.GetOrderGYValue(var nData: string): Boolean;
var nStr,nSQL,nID,nOrder: string;
    nInt: Integer;
    nWorker: PDBWorker;
begin
  nSQL := 'select distinct poundb.pk_sourcebill_b norder,sum(COALESCE(poundb.nnet,0)) nnet,' +
     'sum(COALESCE(poundb.nassnum,0)) nassnum from meam_poundbill_b poundb ' +
     '  inner join meam_poundbill poundh on poundb.pk_poundbill = poundh.pk_poundbill' +
     ' where COALESCE(poundb.dr,0)=0' +
     '  and poundh.nstatus = 100' +
     '  and COALESCE(poundh.dr,0)=0';
  //nnet:������;nassnum:������

  FListB.Clear;
  nWorker := nil;
  try
    FListA.Text := DecodeBase64(FIn.FData);
    for nInt:=0 to FListA.Count - 1 do
      FListB.Values[FListA[nInt]] := '0';
    //Ĭ���ѷ�����Ϊ0

    nID := AdjustListStrFormat2(FListA, '''', True, ',', False);
    nStr := ' and pk_sourcebill_b in (%s) group by poundb.pk_sourcebill_b';
    nStr := nSQL + Format(nStr, [nID]);
    //ִ����     

    with gDBConnManager.SQLQuery(nStr, nWorker, sFlag_DB_NC) do
    if RecordCount > 0 then
    begin
      First;

      while not Eof do
      begin
        nOrder := FieldByName('norder').AsString;
        FListB.Values[nOrder] := FieldByName('nnet').AsString;
        //�����ѷ���

        Next;
      end;
    end;
  finally
    gDBConnManager.ReleaseConnection(nWorker);
  end;

  FOut.FData := PackerEncodeStr(FListB.Text);
  Result := True;
end;

//------------------------------------------------------------------------------
//Desc: �����ֶ�����
function MakeField(const nDS: TDataSet; const nName: string; nPos: Integer;
 nField: string = ''): string;
var nStr: string;
begin
  if nPos > 0 then
       nStr := Format('%s_%d', [nName, nPos])
  else nStr := nName;

  if nField = '' then
    nField := nName;
  //xxxxx

  Result := Trim(nDS.FieldByName(nStr).AsString);
  Result := SF(nField, Result);
end;

//Date: 2015-01-08
//Parm: �񵥺�(����)[FIn.FData]
//Desc: ͬ��ԭ�Ϲ������ݵ�NC�����񵥱���
function TWorkerBusinessCommander.SyncNC_ME03(var nData: string): Boolean;
var nDS: TDataSet;
    nStr,nSQL: string;
    nVal, nDec: Double;
    nWorker: PDBWorker;
    nIdx, nInt: Integer;
    nBills: TLadingBillItems;
    nOut: TWorkerBusinessCommand;
begin
  Result := False;
  nStr := 'Select * From %s Where P_ID=''%s''';
  nStr := Format(nStr, [sTable_PoundLog, FIn.FData]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount < 1 then
    begin
      nData := '���ص���[ %s ]��Ϣ�Ѷ�ʧ.';
      nData := Format(nData, [FIn.FData]);
      Exit;
    end;

    SetLength(nBills, 1);
    First;

    with nBills[0] do
    begin
      FStockNo := FieldByName('P_MID').AsString;
      FStockName := FieldByName('P_MName').AsString;

      FCusID   := FieldByName('P_CusID').AsString;
      FCusName := FieldByName('P_CusName').AsString;

      FTruck   := FieldByName('P_Truck').AsString;
      FPoundID := FieldByName('P_ID').AsString;

      with FPData do
      begin
        FValue    := FieldByName('P_PValue').AsFloat;
        FDate     := FieldByName('P_PDate').AsDateTime;
        FOperator := FieldByName('P_PMan').AsString;
      end;

      with FMData do
      begin
        FValue    := FieldByName('P_MValue').AsFloat;
        FDate     := FieldByName('P_MDate').AsDateTime;
        FOperator := FieldByName('P_MMan').AsString;
      end;

      FKZValue := FieldByName('P_KZValue').AsFloat;
      //������

      FValue := Float2Float(FMData.FValue - FPData.FValue - FKZValue,
                cPrecision, False);
      //��Ӧ��
    end;
  end;

  FListC.Values['NoDate'] := sFlag_Yes;
  FListC.Values['CustomerID'] := nBills[0].FCusID;
  FListC.Values['StockNo'] := nBills[0].FStockNo;
  FListC.Values['Order']   := 'TMAKETIME DESC';

  if not CallMe(cBC_GetSQLQueryOrder, '201', PackerEncodeStr(FListC.Text),
    @nOut) then
  begin
    nData := nOut.FData;
    Exit;
  end;

  nWorker := nil;
  try
    with gDBConnManager.SQLQuery(nOut.FData, nWorker, sFlag_DB_NC) do
    begin
      if RecordCount < 1 then
      begin
        nData := '���������������Ķ���: ' + #13#10#13#10 +
                 '������Ϣ:[ %s.%s ]' + #13#10 +
                 '�ͻ���Ϣ:[ %s.%s ]' + #13#10#13#10 +
                 '����NC�в�����.';
        nData := Format(nData, [nBills[0].FStockNo, nBills[0].FStockName,
                 nBills[0].FCusID, nBills[0].FCusName]);
        Exit;
      end;

      SetLength(FOrderItems, RecordCount);
      FListB.Clear;
      nInt := 0;
      First;

      while not Eof do
      begin
        with FOrderItems[nInt] do
        begin
          FOrder := FieldByName('pk_meambill').AsString;
          FBill  := FieldByName('vBillcode').AsString;

          FStockID := FieldByName('invcode').AsString;
          FStockName := FieldByName('invname').AsString;
          FMaxValue := FieldByName('NPLANNUM').AsFloat;
          FKDValue := 0;

          FListB.Add(FOrder);
        end;

        Inc(nInt);
        Next;
      end;
    end;
  finally
    gDBConnManager.ReleaseConnection(nWorker);
  end;

  //----------------------------------------------------------------------------
  if not TWorkerBusinessCommander.CallMe(cBC_GetOrderGYValue,
         PackerEncodeStr(FListB.Text), '', @nOut) then
  begin
    nData := nOut.FData;
    Exit;
  end;

  FListC.Text := PackerDecodeStr(nOut.FData);
  for nIdx:=Low(FOrderItems) to High(FOrderItems) do
  begin
    nSQL := FListC.Values[FOrderItems[nIdx].FOrder];
    if not IsNumber(nSQL, True) then Continue;

    with FOrderItems[nIdx] do
      FMaxValue := FMaxValue - StrToFloat(nSQL);
    //������ = �ƻ��� - �ѷ���
  end;

  //----------------------------------------------------------------------------
  nInt := -1;
  nVal := nBills[0].FValue;
  for nIdx:=Low(FOrderItems) to High(FOrderItems) do
  begin
    nDec := Float2Float(FOrderItems[nIdx].FMaxValue, cPrecision, False);
    //����������

    if nDec >= nVal then
    begin
      FOrderItems[nIdx].FKDValue := nVal;
      nInt := nIdx;
      Break;
    end;
    //����������ֱ�ӿ۳�������
  end;

  if nInt < 0 then
  begin
    nData := '��ǰ�޿��ö����������¿���.';
    Exit;
  end;

  //----------------------------------------------------------------------------
  nStr := 'select t1.*,t2.* from meam_bill t1 ' +
          '  left join meam_bill_b t2 on t2.PK_MEAMBILL=t1.PK_MEAMBILL ' +
          'where pk_meambill_b=''%s''';
  nStr := Format(nStr, [FOrderItems[nInt].FOrder]);

  nWorker := nil;
  try
    nDS := gDBConnManager.SQLQuery(nStr, nWorker, sFlag_DB_NC);
    with nDS do
    begin
      if RecordCount < 1 then
      begin
        nData := 'NC����[ %s ]��Ϣ�Ѷ�ʧ.';
        nData := Format(nData, [FOrderItems[nInt].FOrder]);
        Exit;
      end;

      FListA.Clear;
      nIdx := 0;
      First;

      nSQL := MakeSQLByStr([SF('bbillreturn', 'N'),
              SF('bneedcheckgross', 'N'),
              SF('bneedchecktare', 'N'),
              SF('bnowreturn', 'N'),
              SF('bpackage', 'N'),
              SF('bpushbillstatus', 'N'),
              SF('bsame_ew', 'N'),

              SF('nabatenum', nBills[nIdx].FKZValue, sfVal),
              //SF('nclientabatenum', nBills[nIdx].FPDValue, sfVal),            //��������
              SF('breturn', FieldByName('breplenishflag').AsString),
              SF('cmainunit', FieldByName('cmainunit').AsString),
              SF('coperatorid', FieldByName('coperator').AsString),

              MakeField(nDS, 'pk_callbody_main', 1, 'cincalbodyid'),
              MakeField(nDS, 'pk_corp_main', 1, 'cincorpid'),
              MakeField(nDS, 'pk_warehouse_main', 1, 'cinwarehouseid'),

              SF('cvehicle', nBills[nIdx].FTruck),
              SF('dbizdate', Date2Str(nBills[nIdx].FPData.FDate)),
              SF('dconfirmdate', Date2Str(nBills[nIdx].FPData.FDate)),
              SF('dconfirmtime', DateTime2Str(nBills[nIdx].FPData.FDate)),
              SF('ddelivmaketime', DateTime2Str(nBills[nIdx].FPData.FDate)),
              SF('dgrossdate', Date2Str(nBills[nIdx].FMData.FDate)),
              SF('dgrosstime', DateTime2Str(nBills[nIdx].FMData.FDate)),
              SF('dlastmoditime', DateTime2Str(nBills[nIdx].FPData.FDate)),
              SF('dmaketime', DateTime2Str(nBills[nIdx].FPData.FDate)),
              SF('dr', 0, sfVal),
              SF('dtaredate', Date2Str(nBills[nIdx].FPData.FDate)),
              SF('dtaretime', DateTime2Str(nBills[nIdx].FPData.FDate)),
              SF('ncreatetype', FieldByName('icreatetype').AsInteger, sfVal),
              SF('ndelivbillprintcount', 1, sfVal),
              SF('ngross', nBills[nIdx].FMData.FValue, sfVal),
              SF('nmeammodel', FieldByName('nmeammodel').AsInteger, sfVal),
              SF('nnet', nBills[nIdx].FValue, sfVal),
              SF('nplannum', FieldByName('nplannum').AsFloat, sfVal),
              SF('nstatus', '100', sfVal),
              SF('ntare', nBills[nIdx].FPData.FValue, sfVal),
              SF('ntareauditstatus', 1, sfVal),
              SF('nweighmodel', '1', sfVal),

              SF('pk_bsmodel', '0001ZA1000000001SIJ7'),
              //MakeField(nDS, 'pk_corp_main', 1, 'pk_corp_main'),
              SF('pk_corp', FieldByName('pk_corp').AsString),

              SF('pk_cumandoc', FieldByName('pk_cumandoc').AsString),
              SF('pk_invbasdoc', FieldByName('pk_invbasdoc').AsString),
              SF('pk_invmandoc', FieldByName('pk_invmandoc').AsString),
              SF('pk_poundbill', nBills[nIdx].FPoundID),
              SF('ts', DateTime2Str(nBills[nIdx].FMData.FDate)),
              SF('vbillcode', nBills[nIdx].FPoundID),
              MakeField(nDS, 'vdef1', 0),
              MakeField(nDS, 'vdef10', 0),
              MakeField(nDS, 'vdef11', 0),
              MakeField(nDS, 'vdef12', 0),
              MakeField(nDS, 'vdef13', 0),
              MakeField(nDS, 'vdef14', 0),
              MakeField(nDS, 'vdef15', 0),
              MakeField(nDS, 'vdef16', 0),
              MakeField(nDS, 'vdef17', 0),
              MakeField(nDS, 'vdef18', 0),
              MakeField(nDS, 'vdef19', 0),
              MakeField(nDS, 'vdef2', 0),
              MakeField(nDS, 'vdef20', 0),
              MakeField(nDS, 'vdef3', 0),
              MakeField(nDS, 'vdef4', 0),
              MakeField(nDS, 'vdef5', 0),
              MakeField(nDS, 'vdef6', 0),
              MakeField(nDS, 'vdef7', 0),
              MakeField(nDS, 'vdef8', 0),
              MakeField(nDS, 'vdef9', 0),
              SF('vsourcebillcode', FieldByName('vbillcode').AsString),
              SF('wayofpoundcorrent', '1')
              ], 'meam_poundbill', '', True);
      FListA.Add(nSQL);

      nSQL := MakeSQLByStr([SF('cassunit', FieldByName('cassunit').AsString),
              SF('dbizdate', Date2Str(nBills[nIdx].FPData.FDate)),
              SF('dr', 0, sfVal),
              SF('nassrate', FieldByName('nassrate').AsFloat, sfVal),
              SF('nassnum', FieldByName('nplanassnum').AsFloat, sfVal),
              SF('nexecnum', FieldByName('nexecnum').AsFloat, sfVal),
              SF('nnet', nBills[nIdx].FValue, sfVal),
              SF('nplannum', FieldByName('nplannum').AsFloat, sfVal),

              SF('pk_poundbill', nBills[nIdx].FPoundID),
              SF('pk_poundbill_b', nBills[nIdx].FPoundID + '_2'),
              SF('pk_sourcebill', FieldByName('pk_meambill').AsString),
              SF('pk_sourcebill_b', FieldByName('pk_meambill_b').AsString),
              SF('ts', DateTime2Str(nBills[nIdx].FMData.FDate)),
              SF('vbatchcode', FieldByName('vbatchcode').AsString),
              MakeField(nDS, 'vdef1', 1),
              MakeField(nDS, 'vdef10', 1),
              MakeField(nDS, 'vdef11', 1),
              MakeField(nDS, 'vdef12', 1),
              MakeField(nDS, 'vdef13', 1),
              MakeField(nDS, 'vdef14', 1),
              MakeField(nDS, 'vdef15', 1),
              MakeField(nDS, 'vdef16', 1),
              MakeField(nDS, 'vdef17', 1),
              MakeField(nDS, 'vdef18', 1),
              MakeField(nDS, 'vdef19', 1),
              MakeField(nDS, 'vdef2', 1),
              MakeField(nDS, 'vdef20', 1),
              MakeField(nDS, 'vdef3', 1),
              MakeField(nDS, 'vdef4', 1),
              MakeField(nDS, 'vdef5', 1),
              MakeField(nDS, 'vdef6', 1),
              MakeField(nDS, 'vdef7', 1),
              MakeField(nDS, 'vdef8', 1),
              MakeField(nDS, 'vdef9', 1),
              SF('vsourcebillcode', FieldByName('vbillcode').AsString)
              ], 'meam_poundbill_b', '', True);
      FListA.Add(nSQL);

      nWorker.FConn.BeginTrans;
      try
        for nIdx:=0 to FListA.Count - 1 do
          gDBConnManager.WorkerExec(nWorker, FListA[nIdx]);
        //xxxxx
        
        nWorker.FConn.CommitTrans;
        Result := True;
      except
        on E:Exception do
        begin
          nWorker.FConn.RollbackTrans;
          nData := 'ͬ��NC�����񵥴���,����: ' + E.Message;
          Exit;
        end;
      end;
    end;
  finally
    gDBConnManager.ReleaseConnection(nWorker);
  end;

  with FOrderItems[nInt] do
  begin
    nSQL := MakeSQLByStr([
            SF('P_Order', FOrder),
            SF('P_Bill', FBill)
            ], sTable_PoundLog, SF('P_ID', nBills[0].FPoundID), False);
    gDBConnManager.WorkerExec(FDBConn, nSQL);

    nSQL := MakeSQLByStr([SF('T_LastTime', sField_SQLServer_Now, sfVal)
            ], sTable_Truck, SF('T_Truck', nBills[0].FTruck), False);
    gDBConnManager.WorkerExec(FDBConn, nSQL);
  end;
  //���°���NC����
end;

initialization
  gBusinessWorkerManager.RegisteWorker(TBusWorkerQueryField, sPlug_ModuleBus);
  gBusinessWorkerManager.RegisteWorker(TWorkerBusinessCommander, sPlug_ModuleBus);
end.
