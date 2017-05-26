{*******************************************************************************
  作者: dmzn@163.com 2012-02-03
  描述: 业务常量定义

  备注:
  *.所有In/Out数据,最好带有TBWDataBase基数据,且位于第一个元素.
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
  cBC_GetSerialNO             = $0001;   //获取串行编号
  cBC_ServerNow               = $0002;   //服务器当前时间
  cBC_IsSystemExpired         = $0003;   //系统是否已过期

  cBC_GetTruckPoundData       = $0011;   //获取车辆称重数据
  cBC_SaveTruckPoundData      = $0012;   //保存车辆称重数据
  cBC_SaveTruckInfo           = $0013;   //保存车辆信息
  cBC_UpdateTruckInfo         = $0014;   //保存车辆信息
  cBC_GetCardPoundData        = $0015;   //获取IC卡称重数据
  cBC_SaveCardPoundData       = $0016;   //保存IC卡称重数据

  cBC_SyncME25                = $0020;   //同步销售到磅单
  cBC_SyncME03                = $0021;   //同步供应到磅单
  cBC_GetOrderGYValue         = $0022;   //获取订单供应量
  cBC_GetSQLQueryOrder        = $0023;   //查询订单语句
  cBC_GetSQLQueryCustomer     = $0024;   //查询客户语句
  cBC_GetSQLQueryDispatch     = $0025;   //查询调拨订单
  cBC_GetOrderFHValue         = $0026;   //获取订单发货量

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
    FType     : Integer;           //类型
    FData     : string;            //数据
  end;

  PWorkerBusinessCommand = ^TWorkerBusinessCommand;
  TWorkerBusinessCommand = record
    FBase     : TBWDataBase;
    FCommand  : Integer;           //命令
    FData     : string;            //数据
    FExtParam : string;            //参数
  end;

  TPoundStationData = record
    FStation  : string;            //磅站标识
    FValue    : Double;           //皮重
    FDate     : TDateTime;        //称重日期
    FOperator : string;           //操作员
  end;

  PLadingBillItem = ^TLadingBillItem;
  TLadingBillItem = record
    FID         : string;          //交货单号
    FZhiKa      : string;          //纸卡编号
    FCusID      : string;          //客户编号
    FCusName    : string;          //客户名称
    FTruck      : string;          //车牌号码

    FType       : string;          //品种类型
    FStockNo    : string;          //品种编号
    FStockName  : string;          //品种名称
    FValue      : Double;          //提货量
    FPrice      : Double;          //提货单价

    FCard       : string;          //磁卡号
    FIsVIP      : string;          //通道类型
    FStatus     : string;          //当前状态
    FNextStatus : string;          //下一状态

    FPData      : TPoundStationData; //称皮
    FMData      : TPoundStationData; //称毛
    FFactory    : string;          //工厂编号
    FPModel     : string;          //称重模式
    FPType      : string;          //业务类型
    FPoundID    : string;          //称重记录
    FSelected   : Boolean;         //选中状态

    FYSValid    : string;          //验收结果，Y验收成功；N拒收；
    FKZValue    : Double;          //供应扣除
    FMemo       : string;          //动作备注

    FPrinter    : string;          //打印机,根据过磅读卡器指定
  end;

  TLadingBillItems = array of TLadingBillItem;
  //交货单列表

procedure AnalyseBillItems(const nData: string; var nItems: TLadingBillItems);
//解析由业务对象返回的交货单数据
function CombineBillItmes(const nItems: TLadingBillItems): string;
//合并交货单数据为业务对象能处理的字符串
procedure AnalyseCardItems(const nData: string; var nList: TStrings);
//解析IC卡数据
function CombineCardItems(const nList: TStrings): string;
//合并IC卡数据

resourcestring
  {*PBWDataBase.FParam*}
  sParam_NoHintOnError        = 'NHE';                  //不提示错误

  {*plug module id*}
  sPlug_ModuleBus             = '{DF261765-48DC-411D-B6F2-0B37B14E014E}';
                                                        //业务模块
  sPlug_ModuleHD              = '{B584DCD6-40E5-413C-B9F3-6DD75AEF1C62}';
                                                        //硬件守护
                                                                                                   
  {*common function*}  
  sSys_BasePacker             = 'Sys_BasePacker';       //基本封包器

  {*business mit function name*}
  sBus_ServiceStatus          = 'Bus_ServiceStatus';    //服务状态
  sBus_GetQueryField          = 'Bus_GetQueryField';    //查询的字段

  sBus_BusinessCommand        = 'Bus_BusinessCommand';  //业务指令
  sBus_HardwareCommand        = 'Bus_HardwareCommand';  //硬件指令

  {*client function name*}
  sCLI_ServiceStatus          = 'CLI_ServiceStatus';    //服务状态
  sCLI_GetQueryField          = 'CLI_GetQueryField';    //查询的字段

  sCLI_BusinessCommand        = 'CLI_BusinessCommand';  //业务指令
  sCLI_HardwareCommand        = 'CLI_HardwareCommand';  //硬件指令

implementation

//Date: 2014-09-17
//Parm: 交货单数据;解析结果
//Desc: 解析nData为结构化列表数据
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
//Parm: 交货单列表
//Desc: 将nItems合并为业务对象能处理的
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
  //无返回

  if Length(nData) < 1 then Exit;
  //无数据

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
  Result := nList.Values[sCard_PoundID] + '|' +              //磅单编号
            nList.Values[sCard_NetValue] + '|' +             //净重(吨)
            nList.Values[sCard_Truck] + '|' +                //车牌号码
            nList.Values[sCard_MaterialID] + '|' +           //物料编号
            nList.Values[sCard_Material] + '|' +             //物料名称
            nList.Values[sCard_CustomerID] + '|' +           //客户编号
            nList.Values[sCard_Customer] + '|' +             //客户名称
            nList.Values[sCard_CompanyID] + '|' +            //公司编码
            nList.Values[sCard_CompanyName] + '|' +          //公司名称
            nList.Values[sCard_Transport];                   //运输单位
end;  

end.


