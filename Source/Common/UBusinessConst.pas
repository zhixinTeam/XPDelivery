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
  end;

  TLadingBillItems = array of TLadingBillItem;
  //交货单列表

procedure AnalyseBillItems(const nData: string; var nItems: TLadingBillItems);
//解析由业务对象返回的交货单数据
function CombineBillItmes(const nItems: TLadingBillItems): string;
//合并交货单数据为业务对象能处理的字符串

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

  sBus_BusinessSaleBill       = 'Bus_BusinessSaleBill'; //交货单相关
  sBus_BusinessCommand        = 'Bus_BusinessCommand';  //业务指令
  sBus_HardwareCommand        = 'Bus_HardwareCommand';  //硬件指令
  sBus_BusinessPurchaseOrder  = 'Bus_BusinessPurchaseOrder'; //采购单相关

  {*client function name*}
  sCLI_ServiceStatus          = 'CLI_ServiceStatus';    //服务状态
  sCLI_GetQueryField          = 'CLI_GetQueryField';    //查询的字段

  sCLI_BusinessSaleBill       = 'CLI_BusinessSaleBill'; //交货单业务
  sCLI_BusinessCommand        = 'CLI_BusinessCommand';  //业务指令
  sCLI_HardwareCommand        = 'CLI_HardwareCommand';  //硬件指令
  sCLI_BusinessPurchaseOrder  = 'CLI_BusinessPurchaseOrder'; //采购单相关

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

end.


