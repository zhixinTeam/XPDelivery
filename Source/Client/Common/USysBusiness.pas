{*******************************************************************************
  作者: dmzn@163.com 2010-3-8
  描述: 系统业务处理
*******************************************************************************}
unit USysBusiness;

{$I Link.Inc} 
interface

uses
  Windows, DB, Classes, Controls, SysUtils, UBusinessPacker, UBusinessWorker,
  UBusinessConst, ULibFun, UAdjustForm, UFormCtrl, UDataModule, UDataReport,
  UFormBase, cxMCListBox, UMgrPoundTunnels, HKVNetSDK, USysConst, USysDB,
  USysLoger, UBase64, UFormWait, Graphics, ShellAPI;

type
  TOrderItemInfo = record
    FCusID: string;       //客户号
    FCusName: string;     //客户名
    FSaleMan: string;     //业务员
    FStockID: string;     //物料号
    FStockName: string;   //物料名

    FStockBrand: string;  //物料品牌
    FStockArea : string;  //产地，矿点

    FTruck: string;       //车牌号
    FBatchCode: string;   //批次号
    FOrders: string;      //订单号(可多张)
    FValue: Double;       //可用量
  end;
  
//------------------------------------------------------------------------------
function AdjustHintToRead(const nHint: string): string;
//调整提示内容
function WorkPCHasPopedom: Boolean;
//验证主机是否已授权
function GetSysValidDate: Integer;
//获取系统有效期
function GetSerialNo(const nGroup,nObject: string;
 nUseDate: Boolean = True): string;
//获取串行编号

function LoadSysDictItem(const nItem: string; const nList: TStrings): TDataSet;
//读取系统字典项

function GetTruckPoundItem(const nTruck: string;
 var nPoundData: TLadingBillItems): Boolean;
//获取指定车辆的已称皮重信息
function SaveTruckPoundItem(const nTunnel: PPTTunnelItem;
 const nData: TLadingBillItems; var nPoundID: string): Boolean;
//保存车辆过磅记录
procedure CapturePicture(const nTunnel: PPTTunnelItem; const nList: TStrings);
//抓拍指定通道

function GetCardPoundItem(const nCard: string;
 var nPoundData: TLadingBillItems): Boolean;
//获取指定车辆的已称皮重信息
function SaveCardPoundItem(const nTunnel: PPTTunnelItem;
 const nData: TLadingBillItems; var nPoundID: string): Boolean;
//保存车辆过磅记录

function PrintPoundReport(const nPound: string; nAsk: Boolean): Boolean;
//打印榜单
procedure ShowCapturePicture(const nID: string);
//查看抓拍

procedure RemoteTunnelOC(const nID, nOC: string);
//红绿灯控制
function RemoteTunnelOK(const nID: string): Boolean;
//车检控制

function GetTruckLastTime(const nTruck: string; var nLast: Integer): Boolean;
//获取车辆活动间隔
function GetLastTruckP(const nTruck: string;var nList: TStrings): Boolean;
//获取上次过磅皮重

function GetQueryOrderSQL(const nType,nWhere: string): string;
//订单查询SQL语句
function GetQueryDispatchSQL(const nWhere: string): string;
//调拨订单SQL语句
function GetQueryCustomerSQL(const nCusID,nCusName: string): string;
//客户查询SQL语句
function LoadCustomerInfo(const nCID: string; const nList: TcxMCListBox;
 var nHint: string): TDataSet;
//加载客户信息
function BuildOrderInfo(const nItem: TOrderItemInfo): string;
//打包订单信息
procedure AnalyzeOrderInfo(const nOrder: string; var nItem: TOrderItemInfo);
//解析订单信息
function GetOrderFHValue(const nOrders: TStrings;
  const nQueryFreeze: Boolean=True): Boolean;
//获取订单发货量
function GetOrderGYValue(const nOrders: TStrings): Boolean;
//获取订单已供应量

implementation

//Desc: 记录日志
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(nEvent);
end;

//------------------------------------------------------------------------------
//Desc: 调整nHint为易读的格式
function AdjustHintToRead(const nHint: string): string;
var nIdx: Integer;
    nList: TStrings;
begin
  nList := TStringList.Create;
  try
    nList.Text := nHint;
    for nIdx:=0 to nList.Count - 1 do
      nList[nIdx] := '※.' + nList[nIdx];
    Result := nList.Text;
  finally
    nList.Free;
  end;
end;

//Desc: 验证主机是否已授权接入系统
function WorkPCHasPopedom: Boolean;
begin
  Result := gSysParam.FSerialID <> '';
  if not Result then
  begin
    ShowDlg('该功能需要更高权限,请向管理员申请.', sHint);
  end;
end;

//Date: 2014-09-05
//Parm: 命令;数据;参数;输出
//Desc: 调用中间件上的业务命令对象
function CallBusinessCommand(const nCmd: Integer; const nData,nExt: string;
  const nOut: PWorkerBusinessCommand; const nWarn: Boolean = True): Boolean;
var nIn: TWorkerBusinessCommand;
    nWorker: TBusinessWorkerBase;
begin
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;

    if nWarn then
         nIn.FBase.FParam := ''
    else nIn.FBase.FParam := sParam_NoHintOnError;

    if gSysParam.FAutoPound and (not gSysParam.FIsManual) then
      nIn.FBase.FParam := sParam_NoHintOnError;
    //自动称重时不提示

    nWorker := gBusinessWorkerManager.LockWorker(sCLI_BusinessCommand);
    //get worker
    Result := nWorker.WorkActive(@nIn, nOut);

    if not Result then
      WriteLog(nOut.FBase.FErrDesc);
    //xxxxx
  finally
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;


//Date: 2014-10-01
//Parm: 命令;数据;参数;输出
//Desc: 调用中间件上的销售单据对象
function CallBusinessHardware(const nCmd: Integer; const nData,nExt: string;
  const nOut: PWorkerBusinessCommand; const nWarn: Boolean = True): Boolean;
var nIn: TWorkerBusinessCommand;
    nWorker: TBusinessWorkerBase;
begin
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;

    if nWarn then
         nIn.FBase.FParam := ''
    else nIn.FBase.FParam := sParam_NoHintOnError;

    if gSysParam.FAutoPound and (not gSysParam.FIsManual) then
      nIn.FBase.FParam := sParam_NoHintOnError;
    //自动称重时不提示
    
    nWorker := gBusinessWorkerManager.LockWorker(sCLI_HardwareCommand);
    //get worker
    Result := nWorker.WorkActive(@nIn, nOut);

    if not Result then
      WriteLog(nOut.FBase.FErrDesc);
    //xxxxx
  finally
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2014-09-04
//Parm: 分组;对象;使用日期编码模式
//Desc: 依据nGroup.nObject生成串行编号
function GetSerialNo(const nGroup,nObject: string; nUseDate: Boolean): string;
var nStr: string;
    nList: TStrings;
    nOut: TWorkerBusinessCommand;
begin
  Result := '';
  nList := nil;
  try
    nList := TStringList.Create;
    nList.Values['Group'] := nGroup;
    nList.Values['Object'] := nObject;

    if nUseDate then
         nStr := sFlag_Yes
    else nStr := sFlag_No;

    if CallBusinessCommand(cBC_GetSerialNO, nList.Text, nStr, @nOut) then
      Result := nOut.FData;
    //xxxxx
  finally
    nList.Free;
  end;   
end;

//Desc: 获取系统有效期
function GetSysValidDate: Integer;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_IsSystemExpired, '', '', @nOut) then
       Result := StrToInt(nOut.FData)
  else Result := 0;
end;

//------------------------------------------------------------------------------
//Date: 2014-06-19
//Parm: 记录标识;车牌号;图片文件
//Desc: 将nFile存入数据库
procedure SavePicture(const nID, nTruck, nMate, nFile: string);
var nStr: string;
    nRID: Integer;
begin
  FDM.ADOConn.BeginTrans;
  try
    nStr := MakeSQLByStr([
            SF('P_ID', nID),
            SF('P_Name', nTruck),
            SF('P_Mate', nMate),
            SF('P_Date', sField_SQLServer_Now, sfVal)
            ], sTable_Picture, '', True);
    //xxxxx

    if FDM.ExecuteSQL(nStr) < 1 then Exit;
    nRID := FDM.GetFieldMax(sTable_Picture, 'R_ID');

    nStr := 'Select P_Picture From %s Where R_ID=%d';
    nStr := Format(nStr, [sTable_Picture, nRID]);
    FDM.SaveDBImage(FDM.QueryTemp(nStr), 'P_Picture', nFile);

    FDM.ADOConn.CommitTrans;
  except
    FDM.ADOConn.RollbackTrans;
  end;
end;

//Desc: 构建图片路径
function MakePicName: string;
begin
  while True do
  begin
    Result := gSysParam.FPicPath + IntToStr(gSysParam.FPicBase) + '.jpg';
    if not FileExists(Result) then
    begin
      Inc(gSysParam.FPicBase);
      Exit;
    end;

    DeleteFile(Result);
    if FileExists(Result) then Inc(gSysParam.FPicBase)
  end;
end;

//Date: 2014-06-19
//Parm: 通道;列表
//Desc: 抓拍nTunnel的图像
procedure CapturePicture(const nTunnel: PPTTunnelItem; const nList: TStrings);
const
  cRetry = 2;
  //重试次数
var nStr: string;
    nIdx,nInt: Integer;
    nLogin,nErr: Integer;
    nPic: NET_DVR_JPEGPARA;
    nInfo: TNET_DVR_DEVICEINFO;
begin
  nList.Clear;
  if not Assigned(nTunnel.FCamera) then Exit;
  //not camera

  if not DirectoryExists(gSysParam.FPicPath) then
    ForceDirectories(gSysParam.FPicPath);
  //new dir

  if gSysParam.FPicBase >= 100 then
    gSysParam.FPicBase := 0;
  //clear buffer

  nLogin := -1;
  NET_DVR_Init();
  try
    for nIdx:=1 to cRetry do
    begin
      nLogin := NET_DVR_Login(PChar(nTunnel.FCamera.FHost),
                   nTunnel.FCamera.FPort,
                   PChar(nTunnel.FCamera.FUser),
                   PChar(nTunnel.FCamera.FPwd), @nInfo);
      //to login

      nErr := NET_DVR_GetLastError;
      if nErr = 0 then break;

      if nIdx = cRetry then
      begin
        nStr := '登录摄像机[ %s.%d ]失败,错误码: %d';
        nStr := Format(nStr, [nTunnel.FCamera.FHost, nTunnel.FCamera.FPort, nErr]);
        WriteLog(nStr);
        Exit;
      end;
    end;

    nPic.wPicSize := nTunnel.FCamera.FPicSize;
    nPic.wPicQuality := nTunnel.FCamera.FPicQuality;

    for nIdx:=Low(nTunnel.FCameraTunnels) to High(nTunnel.FCameraTunnels) do
    begin
      if nTunnel.FCameraTunnels[nIdx] = MaxByte then continue;
      //invalid

      for nInt:=1 to cRetry do
      begin
        nStr := MakePicName();
        //file path

        NET_DVR_CaptureJPEGPicture(nLogin, nTunnel.FCameraTunnels[nIdx],
                                   @nPic, PChar(nStr));
        //capture pic

        nErr := NET_DVR_GetLastError;
        if nErr = 0 then
        begin
          nList.Add(nStr);
          Break;
        end;

        if nIdx = cRetry then
        begin
          nStr := '抓拍图像[ %s.%d ]失败,错误码: %d';
          nStr := Format(nStr, [nTunnel.FCamera.FHost,
                   nTunnel.FCameraTunnels[nIdx], nErr]);
          WriteLog(nStr);
        end;
      end;
    end;
  finally
    if nLogin > -1 then
      NET_DVR_Logout(nLogin);
    NET_DVR_Cleanup();
  end;
end;

//------------------------------------------------------------------------------
//Date: 2010-4-13
//Parm: 字典项;列表
//Desc: 从SysDict中读取nItem项的内容,存入nList中
function LoadSysDictItem(const nItem: string; const nList: TStrings): TDataSet;
var nStr: string;
begin
  nList.Clear;
  nStr := MacroValue(sQuery_SysDict, [MI('$Table', sTable_SysDict),
                                      MI('$Name', nItem)]);
  Result := FDM.QueryTemp(nStr);

  if Result.RecordCount > 0 then
  with Result do
  begin
    First;

    while not Eof do
    begin
      nList.Add(FieldByName('D_Value').AsString);
      Next;
    end;
  end else Result := nil;
end;

//Date: 2014-09-25
//Parm: 车牌号
//Desc: 获取nTruck的称皮记录
function GetTruckPoundItem(const nTruck: string;
 var nPoundData: TLadingBillItems): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessCommand(cBC_GetTruckPoundData, nTruck, '', @nOut);
  if Result then
    AnalyseBillItems(nOut.FData, nPoundData);
  //xxxxx
end;

//Date: 2014-09-25
//Parm: 称重数据
//Desc: 保存nData称重数据
function SaveTruckPoundItem(const nTunnel: PPTTunnelItem;
 const nData: TLadingBillItems; var nPoundID: string): Boolean;
var nStr: string;
    nIdx: Integer;
    nList: TStrings;
    nOut: TWorkerBusinessCommand;
begin
  nPoundID := '';
  nStr := CombineBillItmes(nData);
  Result := CallBusinessCommand(cBC_SaveTruckPoundData, nStr, '', @nOut);
  if (not Result) or (nOut.FData = '') then Exit;
  nPoundID := nOut.FData;

  {$IFDEF HardMon}
  nList := TStringList.Create;
  try
    CapturePicture(nTunnel, nList);
    //capture file

    for nIdx:=0 to nList.Count - 1 do
      SavePicture(nOut.FData, nData[0].FTruck,
                              nData[0].FStockName, nList[nIdx]);
    //save file
  finally
    nList.Free;
  end;
  {$ENDIF}
end;

//Date: 2012-4-15
//Parm: 过磅单号;是否询问
//Desc: 打印nPound过磅记录
function PrintPoundReport(const nPound: string; nAsk: Boolean): Boolean;
var nStr: string;
    nParam: TReportParamItem;
begin
  Result := False;

  if nAsk then
  begin
    nStr := '是否要打印过磅单?';
    if not QueryDlg(nStr, sAsk) then Exit;
  end;

  nStr := 'Select * From %s Where P_ID=''%s''';
  nStr := Format(nStr, [sTable_PoundLog, nPound]);

  if FDM.QueryTemp(nStr).RecordCount < 1 then
  begin
    nStr := '称重记录[ %s ] 已无效!!';
    nStr := Format(nStr, [nPound]);
    ShowMsg(nStr, sHint); Exit;
  end;

  nStr := gPath + sReportDir + 'Pound.fr3';
  if not FDR.LoadReportFile(nStr) then
  begin
    nStr := '无法正确加载报表文件';
    ShowMsg(nStr, sHint); Exit;
  end;

  nParam.FName := 'UserName';
  nParam.FValue := gSysParam.FUserID;
  FDR.AddParamItem(nParam);

  nParam.FName := 'Company';
  nParam.FValue := gSysParam.FHintText;
  FDR.AddParamItem(nParam);

  FDR.Dataset1.DataSet := FDM.SqlTemp;
  //FDR.ShowReport;
  //Result := FDR.PrintSuccess;
  Result := FDR.PrintReport;

  if Result  then
  begin
    nStr := 'Update %s Set P_PrintNum=P_PrintNum+1 Where P_ID=''%s''';
    nStr := Format(nStr, [sTable_PoundLog, nPound]);
    FDM.ExecuteSQL(nStr);
  end;
end;

//Date: 2016/8/7
//Parm: 记录编号
//Desc: 查看抓拍
procedure ShowCapturePicture(const nID: string);
var nStr,nDir: string;
    nPic: TPicture;
begin
  nDir := gSysParam.FPicPath + nID + '\';

  if DirectoryExists(nDir) then
  begin
    ShellExecute(GetDesktopWindow, 'open', PChar(nDir), nil, nil, SW_SHOWNORMAL);
    Exit;
  end else ForceDirectories(nDir);

  nPic := nil;
  nStr := 'Select * From %s Where P_ID=''%s''';
  nStr := Format(nStr, [sTable_Picture, nID]);

  ShowWaitForm('读取图片', True);
  try
    with FDM.QueryTemp(nStr) do
    begin
      if RecordCount < 1 then
      begin
        ShowMsg('本条记录无抓拍', sHint);
        Exit;
      end;

      nPic := TPicture.Create;
      First;

      While not eof do
      begin
        nStr := nDir + Format('%s_%s.jpg', [FieldByName('P_ID').AsString,
                FieldByName('R_ID').AsString]);
        //xxxxx

        FDM.LoadDBImage(FDM.SqlTemp, 'P_Picture', nPic);
        nPic.SaveToFile(nStr);
        Next;
      end;
    end;

    ShellExecute(GetDesktopWindow, 'open', PChar(nDir), nil, nil, SW_SHOWNORMAL);
    //open dir
  finally
    nPic.Free;
    CloseWaitForm;
    FDM.SqlTemp.Close;
  end;
end;

//Date: 2016/8/7
//Parm: 车牌号;时间间隔
//Desc: 查看车辆保存时间
function GetTruckLastTime(const nTruck: string; var nLast: Integer): Boolean;
var nStr: string;
begin
  Result := False;
  nStr := 'Select %s as T_Now,T_LastTime From %s ' +
          'Where T_Truck=''%s''';
  nStr := Format(nStr, [sField_SQLServer_Now, sTable_Truck, nTruck]);

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    nLast := Trunc((FieldByName('T_Now').AsDateTime -
                    FieldByName('T_LastTime').AsDateTime) * 24 * 60 * 60);
    Result := True;                
  end;
end;

//Date: 2014-09-25
//Parm: 读到的IC卡信息
//Desc: 获取nTruck的称皮记录
function GetCardPoundItem(const nCard: string;
  var nPoundData: TLadingBillItems): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessCommand(cBC_GetCardPoundData, nCard, '', @nOut);
  if Result then
    AnalyseBillItems(nOut.FData, nPoundData);
  //xxxxx
end;

//Date: 2014-09-25
//Parm: 称重数据
//Desc: 保存nData称重数据
function SaveCardPoundItem(const nTunnel: PPTTunnelItem;
 const nData: TLadingBillItems; var nPoundID: string): Boolean;
var nStr: string;
    nIdx: Integer;
    nList: TStrings;
    nOut: TWorkerBusinessCommand;
begin
  nPoundID := '';
  nStr := CombineBillItmes(nData);
  Result := CallBusinessCommand(cBC_SaveCardPoundData, nStr, '', @nOut);
  if (not Result) or (nOut.FData = '') then Exit;
  nPoundID := nOut.FData;

  {$IFDEF HardMon}
  nList := TStringList.Create;
  try
    CapturePicture(nTunnel, nList);
    //capture file

    for nIdx:=0 to nList.Count - 1 do
      SavePicture(nOut.FData, nData[0].FTruck,
                              nData[0].FStockName, nList[nIdx]);
    //save file
  finally
    nList.Free;
  end;
  {$ENDIF}
end;

//Date: 2016/9/8
//Parm: 控制器编号(nID);具体操作(nOC)
//Desc: 打开或者关闭控制器
procedure RemoteTunnelOC(const nID, nOC: string);
var nOut: TWorkerBusinessCommand;
begin
  {$IFDEF HardMon}
  if not CallBusinessHardware(cBC_TunnelOC, nID, nOC, @nOut) then
   WriteLog(nOut.FData);
  {$ENDIF} 
end;

//Date: 2016/9/8
//Parm: 控制器编号(nID)
//Desc: 检测控制器状态
function RemoteTunnelOK(const nID: string): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  {$IFNDEF HardMon}
  Result := True;
  Exit;
  //无硬件支持
  {$ENDIF}

  Result := CallBusinessHardware(cBC_IsTunnelOK, nID, '', @nOut);
  if (not Result) or (nOut.FData = '') then Exit;

  Result := nOut.FData = sFlag_Yes;
end;

//Date: 2014-12-16
//Parm: 订单类型;查询条件
//Desc: 获取nType类型的订单查询语句
function GetQueryOrderSQL(const nType,nWhere: string): string;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_GetSQLQueryOrder, nType, nWhere, @nOut) then
       Result := nOut.FData
  else Result := '';
end;

//Date: 2014-12-16
//Parm: 查询条件
//Desc: 获取调拨订单查询语句
function GetQueryDispatchSQL(const nWhere: string): string;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_GetSQLQueryDispatch, '', nWhere, @nOut) then
       Result := nOut.FData
  else Result := '';
end;

//Date: 2014-12-18
//Parm: 客户编号;客户名称
//Desc: 获取nCusName的模糊查询SQL语句
function GetQueryCustomerSQL(const nCusID,nCusName: string): string;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_GetSQLQueryCustomer, nCusID, nCusName, @nOut) then
       Result := nOut.FData
  else Result := '';
end;

//Desc: 载入nCID客户的信息到nList中,并返回数据集
function LoadCustomerInfo(const nCID: string; const nList: TcxMCListBox;
 var nHint: string): TDataSet;
var nStr: string;
begin
  nStr := 'select custcode,t2.pk_cubasdoc,custname,user_name,' +
          't1.createtime from Bd_cumandoc t1' +
          '  left join bd_cubasdoc t2 on t2.pk_cubasdoc=t1.pk_cubasdoc' +
          '  left join sm_user t_su on t_su.cuserid=t1.creator ' +
          ' where custcode=''%s''';
  nStr := Format(nStr, [nCID]);

  nList.Clear;
  Result := FDM.QueryTemp(nStr, True);

  if Result.RecordCount > 0 then
  with nList.Items,Result do
  begin
    Add('客户编号:' + nList.Delimiter + FieldByName('custcode').AsString);
    Add('客户名称:' + nList.Delimiter + FieldByName('custname').AsString + ' ');
    Add('创 建 人:' + nList.Delimiter + FieldByName('user_name').AsString + ' ');
    Add('创建时间:' + nList.Delimiter + FieldByName('createtime').AsString + ' ');
  end else
  begin
    Result := nil;
    nHint := '客户信息已丢失';
  end;
end;

//Date: 2014-12-23
//Parm: 订单项
//Desc: 将nItem数据打包
function BuildOrderInfo(const nItem: TOrderItemInfo): string;
var nList: TStrings;
begin
  nList := TStringList.Create;
  try
    with nList,nItem do
    begin
      Clear;
      Values['CusID']     := FCusID;
      Values['CusName']   := FCusName;
      Values['SaleMan']   := FSaleMan;

      Values['StockID']   := FStockID;
      Values['StockName'] := FStockName;
      Values['StockArea'] := FStockArea;
      Values['StockBrand']:= FStockBrand;

      Values['Truck']     := FTruck;
      Values['BatchCode'] := FBatchCode;
      Values['Orders']    := PackerEncodeStr(FOrders);
      Values['Value']     := FloatToStr(FValue);
    end;

    Result := EncodeBase64(nList.Text);
    //编码
  finally
    nList.Free;
  end;   
end;

//Date: 2014-12-23
//Parm: 待解析;订单数据
//Desc: 解析nOrder,存入nItem
procedure AnalyzeOrderInfo(const nOrder: string; var nItem: TOrderItemInfo);
var nList: TStrings;
begin
  nList := TStringList.Create;
  try
    with nList,nItem do
    begin
      Text := DecodeBase64(nOrder);
      //解码

      FCusID := Values['CusID'];
      FCusName := Values['CusName'];
      FSaleMan := Values['SaleMan'];

      FStockID := Values['StockID'];
      FStockName := Values['StockName'];
      FStockArea := Values['StockArea'];
      FStockBrand:= Values['StockBrand'];

      FTruck := Values['Truck'];
      FBatchCode := Values['BatchCode'];
      FOrders := PackerDecodeStr(Values['Orders']);
      FValue := StrToFloat(Values['Value']);
    end;
  finally
    nList.Free;
  end;
end;

//Date: 2014-12-24
//Parm: 订单列表
//Desc: 获取指定的发货量
function GetOrderFHValue(const nOrders: TStrings;
  const nQueryFreeze: Boolean=True): Boolean;
var nOut: TWorkerBusinessCommand;
    nFlag: string;
begin
  if nQueryFreeze then
       nFlag := sFlag_Yes
  else nFlag := sFlag_No;

  Result := CallBusinessCommand(cBC_GetOrderFHValue,
             EncodeBase64(nOrders.Text), nFlag, @nOut);
  //xxxxx

  if Result then
    nOrders.Text := DecodeBase64(nOut.FData);
  //xxxxx
end;

//Date: 2015-01-08
//Parm: 订单列表
//Desc: 获取指定的发货量
function GetOrderGYValue(const nOrders: TStrings): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessCommand(cBC_GetOrderGYValue,
             EncodeBase64(nOrders.Text), '', @nOut);
  //xxxxx

  if Result then
    nOrders.Text := DecodeBase64(nOut.FData);
  //xxxxx
end;

function GetLastTruckP(const nTruck: string;var nList: TStrings): Boolean;
var nSQL: string;
begin
  Result := False;
  if nTruck = '' then Exit;
  //init

  nSQL := 'Select Top 1 * From %s ' +
          'Where P_Truck=''%s'' And P_MValue Is not NULL ' +
          'Order By P_ID Desc';
  //最新一次完成两次配对称重的车辆记录        
  nSQL := Format(nSQL, [sTable_PoundLog, nTruck]);
  with FDM.QuerySQL(nSQL) do
  begin
    if RecordCount < 1 then Exit;

    nList.Clear;

    nSQL := '车辆[ %s ]最近一次空车称重信息如下:';
    nSQL := Format(nSQL, [nTruck]);
    nList.Add(nSQL);
    nSQL := '皮重: [ %.2f ]';
    nSQL := Format(nSQL, [FieldByName('P_PValue').AsFloat]);
    nList.Add(nSQL);
    nSQL := '时间: [ %s ]';
    nSQL := Format(nSQL, [FieldByName('P_PDate').AsString]);
    nList.Add(nSQL);
    nSQL := '磅站: [ %s ]';
    nSQL := Format(nSQL, [FieldByName('P_PStation').AsString]);
    nList.Add(nSQL);
    nSQL := '司磅员: [ %s ]';
    nSQL := Format(nSQL, [FieldByName('P_PMan').AsString]);
    nList.Add(nSQL);
    nSQL := '请确认是否采用本次皮重记录?';
    nList.Add(nSQL);

    nSQL := AdjustHintToRead(nList.Text);
    if QueryDlg(nSQL, sHint) then
    begin
      with nList do
      begin
        Clear;

        Values['PValue'] := Format('%.2f', [FieldByName('P_PValue').AsFloat]);
        Values['PStation'] := FieldByName('P_PStation').AsString;
        Values['PDate']  := FieldByName('P_PDate').AsString;
        Values['PMan']   := FieldByName('P_PMan').AsString;
      end;

      Result := True;
    end;
  end;  
end;

end.
