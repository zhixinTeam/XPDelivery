{*******************************************************************************
  ����: dmzn@163.com 2010-3-8
  ����: ϵͳҵ����
*******************************************************************************}
unit USysBusiness;

interface
{$I Link.inc}
uses
  Windows, DB, Classes, Controls, SysUtils,
  UBusinessConst, ULibFun, UAdjustForm, UFormCtrl, UDataModule, UDataReport,
  UFormBase, cxMCListBox, USysConst, USysDB, USysLoger;

//------------------------------------------------------------------------------
function AdjustHintToRead(const nHint: string): string;
//������ʾ����
function GetNCPoundData(nID: string; var nData: string; nFlag: Boolean = False): TDataSet;
//��ȡ������Ϣ

implementation

//Desc: ��¼��־
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(nEvent);
end;

//------------------------------------------------------------------------------
//Desc: ����nHintΪ�׶��ĸ�ʽ
function AdjustHintToRead(const nHint: string): string;
var nIdx: Integer;
    nList: TStrings;
begin
  nList := TStringList.Create;
  try
    nList.Text := nHint;
    for nIdx:=0 to nList.Count - 1 do
      nList[nIdx] := '��.' + nList[nIdx];
    Result := nList.Text;
  finally
    nList.Free;
  end;
end;

//Desc: ��ȡ������Ϣ
function GetNCPoundData(nID: string; var nData: string; nFlag: Boolean = False): TDataSet;
var nStr, nStart: string;
    nSTime: TDateTime;
begin
  nStr := 'Select DISTINCT pb.vbillcode,invcode,invname,invtype, ' +
          'cvehicle,nnet,custcode,custname ' +
          'From meam_poundbill pb ' +
          ' left join meam_bill t1 on pb.vsourcebillcode=t1.VBILLCODE'        +
          ' left join Bd_cumandoc t_cd on t_cd.pk_cumandoc=t1.pk_cumandoc'    +
          ' left join bd_cubasdoc t_cb on t_cb.pk_cubasdoc=t_cd.pk_cubasdoc'  +
          ' left join Bd_invbasdoc t_ib on t_ib.pk_invbasdoc=pb.PK_INVBASDOC' +
          ' Where t1.Vbilltype=''ME25'' and ';

  if nFlag then
       nStr := nStr + ' pb.vbillcode Like ''%%%s%%'''
  else nStr := nStr + ' pb.vbillcode = ''%s''';

  nSTime := Now - gSysParam.FRecMenuMax;
  nStart := ' And dgrossdate >= ''%s''';
  nStart := Format(nStart, [Date2Str(nSTime)]);

  {$IFNDEF DEBUG}
  nStr  := nStr + nStart;
  {$ENDIF}

  nStr := Format(nStr, [nID]);
  //xxxxx

  nData  := '';
  Result := FDM.QueryTemp(nStr);
  if Assigned(Result) and (Result.RecordCount > 0) and (not nFlag) then
  with Result do
  begin
    nData := FieldByName('vbillcode').AsString  + '|' +
             FloatToStr(Float2Float(FieldByName('nnet').AsFloat, 100, False)) + '|' +
             FieldByName('cvehicle').AsString  + '|' +
             FieldByName('invcode').AsString  + '|' +
             FieldByName('invname').AsString  + '|' +
             FieldByName('custcode').AsString  + '|' +
             FieldByName('custname').AsString  + '|' +
             gSysParam.FCompanyID  + '|' +
             gSysParam.FCompanyName; 
  end;

end;


end.
