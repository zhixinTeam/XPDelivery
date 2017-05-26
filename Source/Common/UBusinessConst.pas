{*******************************************************************************
  ����: dmzn@163.com 2012-02-03
  ����: ҵ��������

  ��ע:
  *.����In/Out����,��ô���TBWDataBase������,��λ�ڵ�һ��Ԫ��.
*******************************************************************************}
unit UBusinessConst;

interface

uses
  Classes, SysUtils, UBusinessPacker, ULibFun, USysDB;

const
  {*channel type*}
  cBus_Channel_Connection     = $0002;
  cBus_Channel_Business       = $0005;

  {*query field define*}
  cQF_Bill                    = $0001;

  {*business command*}
  cBC_GetSerialNO             = $0001;   //��ȡ���б��
  cBC_ServerNow               = $0002;   //��������ǰʱ��
  cBC_IsSystemExpired         = $0003;   //ϵͳ�Ƿ��ѹ���

  cBC_GetTruckPoundData       = $0011;   //��ȡ������������
  cBC_SaveTruckPoundData      = $0012;   //���泵����������
  cBC_SaveTruckInfo           = $0013;   //���泵����Ϣ
  cBC_UpdateTruckInfo         = $0014;   //���泵����Ϣ
  cBC_GetCardPoundData        = $0015;   //��ȡIC����������
  cBC_SaveCardPoundData       = $0016;   //����IC����������

  cBC_SyncME25                = $0020;   //ͬ�����۵�����
  cBC_SyncME03                = $0021;   //ͬ����Ӧ������
  cBC_GetOrderGYValue         = $0022;   //��ȡ������Ӧ��
  cBC_GetSQLQueryOrder        = $0023;   //��ѯ�������
  cBC_GetSQLQueryCustomer     = $0024;   //��ѯ�ͻ����
  cBC_GetSQLQueryDispatch     = $0025;   //��ѯ��������
  cBC_GetOrderFHValue         = $0026;   //��ȡ����������

  cBC_RemoteExecSQL           = $1011;
  cBC_RemotePrint             = $1012;
  cBC_IsTunnelOK              = $1013;
  cBC_TunnelOC                = $1014;

  {*Reader Index*}
  cReader_PoundID             = 0;
  cReader_NetValue            = 1;
  cReader_Truck               = 2;
  cReader_MID                 = 3;
  cReader_MName               = 4;
  cReader_CusID               = 5;
  cReader_CusName             = 6;
  cReader_SelfID              = 7;
  cReader_SelfName            = 8;
  cReader_TransName           = 9;

  {*Reader name*}
  sCard_PoundID               = 'Card_PoundID';
  sCard_NetValue              = 'Card_NetValue';
  sCard_Truck                 = 'Card_Truck';
  sCard_Transport             = 'Card_Transport';
  sCard_MaterialID            = 'Card_MaterialID';
  sCard_Material              = 'Card_Material';
  sCard_CustomerID            = 'Card_CustomerID';
  sCard_Customer              = 'Card_Customer';
  sCard_CompanyID             = 'Card_CompanyID';
  sCard_CompanyName           = 'Card_CompanyName';

type
  PWorkerQueryFieldData = ^TWorkerQueryFieldData;
  TWorkerQueryFieldData = record
    FBase     : TBWDataBase;
    FType     : Integer;           //����
    FData     : string;            //����
  end;

  PWorkerBusinessCommand = ^TWorkerBusinessCommand;
  TWorkerBusinessCommand = record
    FBase     : TBWDataBase;
    FCommand  : Integer;           //����
    FData     : string;            //����
    FExtParam : string;            //����
  end;

  TPoundStationData = record
    FStation  : string;            //��վ��ʶ
    FValue    : Double;           //Ƥ��
    FDate     : TDateTime;        //��������
    FOperator : string;           //����Ա
  end;

  PLadingBillItem = ^TLadingBillItem;
  TLadingBillItem = record
    FID         : string;          //��������
    FZhiKa      : string;          //ֽ�����
    FCusID      : string;          //�ͻ����
    FCusName    : string;          //�ͻ�����
    FTruck      : string;          //���ƺ���

    FType       : string;          //Ʒ������
    FStockNo    : string;          //Ʒ�ֱ��
    FStockName  : string;          //Ʒ������
    FValue      : Double;          //�����
    FPrice      : Double;          //�������

    FCard       : string;          //�ſ���
    FIsVIP      : string;          //ͨ������
    FStatus     : string;          //��ǰ״̬
    FNextStatus : string;          //��һ״̬

    FPData      : TPoundStationData; //��Ƥ
    FMData      : TPoundStationData; //��ë
    FFactory    : string;          //�������
    FPModel     : string;          //����ģʽ
    FPType      : string;          //ҵ������
    FPoundID    : string;          //���ؼ�¼
    FSelected   : Boolean;         //ѡ��״̬

    FYSValid    : string;          //���ս����Y���ճɹ���N���գ�
    FKZValue    : Double;          //��Ӧ�۳�
    FMemo       : string;          //������ע

    FPrinter    : string;          //��ӡ��,���ݹ���������ָ��
  end;

  TLadingBillItems = array of TLadingBillItem;
  //�������б�

procedure AnalyseBillItems(const nData: string; var nItems: TLadingBillItems);
//������ҵ����󷵻صĽ���������
function CombineBillItmes(const nItems: TLadingBillItems): string;
//�ϲ�����������Ϊҵ������ܴ�����ַ���
procedure AnalyseCardItems(const nData: string; var nList: TStrings);
//����IC������
function CombineCardItems(const nList: TStrings): string;
//�ϲ�IC������

resourcestring
  {*PBWDataBase.FParam*}
  sParam_NoHintOnError        = 'NHE';                  //����ʾ����

  {*plug module id*}
  sPlug_ModuleBus             = '{DF261765-48DC-411D-B6F2-0B37B14E014E}';
                                                        //ҵ��ģ��
  sPlug_ModuleHD              = '{B584DCD6-40E5-413C-B9F3-6DD75AEF1C62}';
                                                        //Ӳ���ػ�
                                                                                                   
  {*common function*}  
  sSys_BasePacker             = 'Sys_BasePacker';       //���������

  {*business mit function name*}
  sBus_ServiceStatus          = 'Bus_ServiceStatus';    //����״̬
  sBus_GetQueryField          = 'Bus_GetQueryField';    //��ѯ���ֶ�

  sBus_BusinessCommand        = 'Bus_BusinessCommand';  //ҵ��ָ��
  sBus_HardwareCommand        = 'Bus_HardwareCommand';  //Ӳ��ָ��

  {*client function name*}
  sCLI_ServiceStatus          = 'CLI_ServiceStatus';    //����״̬
  sCLI_GetQueryField          = 'CLI_GetQueryField';    //��ѯ���ֶ�

  sCLI_BusinessCommand        = 'CLI_BusinessCommand';  //ҵ��ָ��
  sCLI_HardwareCommand        = 'CLI_HardwareCommand';  //Ӳ��ָ��

implementation

//Date: 2014-09-17
//Parm: ����������;�������
//Desc: ����nDataΪ�ṹ���б�����
procedure AnalyseBillItems(const nData: string; var nItems: TLadingBillItems);
var nStr: string;
    nIdx,nInt: Integer;
    nListA,nListB: TStrings;
begin
  nListA := TStringList.Create;
  nListB := TStringList.Create;
  try
    nListA.Text := PackerDecodeStr(nData);
    //bill list
    nInt := 0;
    SetLength(nItems, nListA.Count);

    for nIdx:=0 to nListA.Count - 1 do
    begin
      nListB.Text := PackerDecodeStr(nListA[nIdx]);
      //bill item

      with nListB,nItems[nInt] do
      begin
        FID         := Values['ID'];
        FZhiKa      := Values['ZhiKa'];
        FCusID      := Values['CusID'];
        FCusName    := Values['CusName'];
        FTruck      := Values['Truck'];

        FType       := Values['Type'];
        FStockNo    := Values['StockNo'];
        FStockName  := Values['StockName'];

        FCard       := Values['Card'];
        FIsVIP      := Values['IsVIP'];
        FStatus     := Values['Status'];
        FNextStatus := Values['NextStatus'];

        FFactory    := Values['Factory'];
        FPModel     := Values['PModel'];
        FPType      := Values['PType'];
        FPoundID    := Values['PoundID'];
        FSelected   := Values['Selected'] = sFlag_Yes;

        with FPData do
        begin
          FStation  := Values['PStation'];
          FDate     := Str2DateTime(Values['PDate']);
          FOperator := Values['PMan'];

          nStr := Trim(Values['PValue']);
          if (nStr <> '') and IsNumber(nStr, True) then
               FPData.FValue := StrToFloat(nStr)
          else FPData.FValue := 0;
        end;

        with FMData do
        begin
          FStation  := Values['MStation'];
          FDate     := Str2DateTime(Values['MDate']);
          FOperator := Values['MMan'];

          nStr := Trim(Values['MValue']);
          if (nStr <> '') and IsNumber(nStr, True) then
               FMData.FValue := StrToFloat(nStr)
          else FMData.FValue := 0;
        end;

        nStr := Trim(Values['Value']);
        if (nStr <> '') and IsNumber(nStr, True) then
             FValue := StrToFloat(nStr)
        else FValue := 0;

        nStr := Trim(Values['Price']);
        if (nStr <> '') and IsNumber(nStr, True) then
             FPrice := StrToFloat(nStr)
        else FPrice := 0;

        nStr := Trim(Values['KZValue']);
        if (nStr <> '') and IsNumber(nStr, True) then
             FKZValue := StrToFloat(nStr)
        else FKZValue := 0;

        FYSValid:= Values['YSValid'];
        FMemo := Values['Memo'];
        FPrinter := Values['Printer'];
      end;

      Inc(nInt);
    end;
  finally
    nListB.Free;
    nListA.Free;
  end;   
end;

//Date: 2014-09-18
//Parm: �������б�
//Desc: ��nItems�ϲ�Ϊҵ������ܴ����
function CombineBillItmes(const nItems: TLadingBillItems): string;
var nIdx: Integer;
    nListA,nListB: TStrings;
begin
  nListA := TStringList.Create;
  nListB := TStringList.Create;
  try
    Result := '';
    nListA.Clear;
    nListB.Clear;

    for nIdx:=Low(nItems) to High(nItems) do
    with nItems[nIdx] do
    begin
      if not FSelected then Continue;
      //ignored

      with nListB do
      begin
        Values['ID']         := FID;
        Values['ZhiKa']      := FZhiKa;
        Values['CusID']      := FCusID;
        Values['CusName']    := FCusName;
        Values['Truck']      := FTruck;

        Values['Type']       := FType;
        Values['StockNo']    := FStockNo;
        Values['StockName']  := FStockName;
        Values['Value']      := FloatToStr(FValue);
        Values['Price']      := FloatToStr(FPrice);

        Values['Card']       := FCard;
        Values['IsVIP']      := FIsVIP;
        Values['Status']     := FStatus;
        Values['NextStatus'] := FNextStatus;

        Values['Factory']    := FFactory;
        Values['PModel']     := FPModel;
        Values['PType']      := FPType;
        Values['PoundID']    := FPoundID;

        with FPData do
        begin
          Values['PStation'] := FStation;
          Values['PValue']   := FloatToStr(FPData.FValue);
          Values['PDate']    := DateTime2Str(FDate);
          Values['PMan']     := FOperator;
        end;

        with FMData do
        begin
          Values['MStation'] := FStation;
          Values['MValue']   := FloatToStr(FMData.FValue);
          Values['MDate']    := DateTime2Str(FDate);
          Values['MMan']     := FOperator;
        end;

        if FSelected then
             Values['Selected'] := sFlag_Yes
        else Values['Selected'] := sFlag_No;

        Values['KZValue']    := FloatToStr(FKZValue);
        Values['YSValid']    := FYSValid;
        Values['Memo']       := FMemo;
        Values['Printer']    := FPrinter;
      end;

      nListA.Add(PackerEncodeStr(nListB.Text));
      //add bill
    end;

    Result := PackerEncodeStr(nListA.Text);
    //pack all
  finally
    nListB.Free;
    nListA.Free;
  end;
end;

procedure AnalyseCardItems(const nData: string; var nList: TStrings);
var nIdx: Integer;
    nListA: TStrings;
begin
  if not Assigned(nList) then Exit;
  //�޷���

  if Length(nData) < 1 then Exit;
  //������

  nListA := TStringList.Create;
  try
    nList.Clear;
    nListA.Clear;
    SplitStr(nData, nListA, 0, '|', False);

    for nIdx := 0 to nListA.Count-1 do
    begin
      if nIdx = cReader_PoundID then
         nList.Values[sCard_PoundID] := nListA[nIdx]
      else  if nIdx = cReader_NetValue then
         nList.Values[sCard_NetValue] := nListA[nIdx]
      else  if nIdx = cReader_Truck then
         nList.Values[sCard_Truck] := nListA[nIdx]
      else  if nIdx = cReader_TransName then
         nList.Values[sCard_Transport] := nListA[nIdx]
      else  if nIdx = cReader_MID then
         nList.Values[sCard_MaterialID] := nListA[nIdx]
      else  if nIdx = cReader_MName then
         nList.Values[sCard_Material] := nListA[nIdx]
      else  if nIdx = cReader_CusID then
         nList.Values[sCard_CustomerID] := nListA[nIdx]
      else  if nIdx = cReader_CusName then
         nList.Values[sCard_Customer] := nListA[nIdx]
      else  if nIdx = cReader_SelfID then
         nList.Values[sCard_CompanyID] := nListA[nIdx]
      else  if nIdx = cReader_SelfName then
         nList.Values[sCard_CompanyName] := nListA[nIdx];
    end;
  finally
    nListA.Free;
  end;
end;

function CombineCardItems(const nList: TStrings): string;
begin
  Result := nList.Values[sCard_PoundID] + '|' +              //�������
            nList.Values[sCard_NetValue] + '|' +             //����(��)
            nList.Values[sCard_Truck] + '|' +                //���ƺ���
            nList.Values[sCard_MaterialID] + '|' +           //���ϱ��
            nList.Values[sCard_Material] + '|' +             //��������
            nList.Values[sCard_CustomerID] + '|' +           //�ͻ����
            nList.Values[sCard_Customer] + '|' +             //�ͻ�����
            nList.Values[sCard_CompanyID] + '|' +            //��˾����
            nList.Values[sCard_CompanyName] + '|' +          //��˾����
            nList.Values[sCard_Transport];                   //���䵥λ
end;  

end.


