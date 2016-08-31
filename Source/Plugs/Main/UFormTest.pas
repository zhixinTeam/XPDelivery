unit UFormTest;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormBase, StdCtrls, ExtCtrls;

type
  TBaseForm1 = class(TBaseForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    Edit1: TEdit;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FListA,FListB: TStrings;
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TFormCreateResult; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  UBusinessWorker, UBusinessPacker, UBusinessConst, UMgrControl, UMgrDBConn,
  USysDB, ULibFun;

var
  gForm: TBaseForm1 = nil;

class function TBaseForm1.CreateForm(const nPopedom: string;
  const nParam: Pointer): TFormCreateResult;
begin
  if not Assigned(gForm) then
    gForm := TBaseForm1.Create(Application);
  //xxxxx
  
  Result.FFormItem := gForm;
  gForm.Show;
end;

class function TBaseForm1.FormID: integer;
begin
  Result := 11;
end;

procedure TBaseForm1.FormCreate(Sender: TObject);
begin
  FListA := TStringList.Create;
  FListB := TStringList.Create;
end;

procedure TBaseForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  gForm := nil;
  FListA.Free;
  FListB.Free;
end;

function CallBusinessCommand(const nCmd: Integer; const nData,nParma: string;
  const nOut: PWorkerBusinessCommand): Boolean;
var nStr: string;
    nIn: TWorkerBusinessCommand;
    nPack: TBusinessPackerBase;
    nWorker: TBusinessWorkerBase;
begin
  nPack := nil;
  nWorker := nil;
  try
    nPack := gBusinessPackerManager.LockPacker(sBus_BusinessCommand);
    nWorker := gBusinessWorkerManager.LockWorker(sBus_BusinessCommand);

    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nParma;
    nStr := nPack.PackIn(@nIn);

    Result := nWorker.WorkActive(nStr);
    if not Result then
    begin
      ShowDlg(nStr, '');
      Exit;
    end;

    nPack.UnPackOut(nStr, nOut);
  finally
    gBusinessPackerManager.RelasePacker(nPack);
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//------------------------------------------------------------------------------
procedure TBaseForm1.Button1Click(Sender: TObject);
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_CheckStockValid, edit1.Text, '', @nOut) then
  begin
    Memo1.lines.Add('done')
  end;
end;

initialization
  gControlManager.RegCtrl(TBaseForm1, TBaseForm1.FormID);
end.
