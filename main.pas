unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes,Graphics,
  Controls, Forms, Dialogs, ComCtrls, StdCtrls,
  Spin, Menus,threadparser,Sythe_utils,RegularExpressions,StrUtils,Generics.Collections;

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    TargetURL: TEdit;
    GroupBox2: TGroupBox;
    PostView: TListView;
    GroupBox3: TGroupBox;
    codetext: TMemo;
    Button2: TButton;
    Label3: TLabel;
    WordsMemo: TMemo;
    Label4: TLabel;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    Label7: TLabel;
    Button1: TButton;
    LogMemo: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PostViewColumnClick(Sender: TObject; Column: TListColumn);
  private
    { Private declarations }
  public
    Procedure StartThreadProcessing(URL: AnsiString);
    Procedure StartPostProcessing;
    function GetNextNumber: integer;
    { Public declarations }
  end;

var
  Form1: TForm1;
  ThreadUrls: TList<AnsiString>;
  TotalPosts,TotalPages: integer;
  PostURLs: TList<AnsiString>;
  Numberi: integer;
    //FSearchingWords: TList<AnsiString>;
    //FPostList: TList<TPost>;
  FWriteLn: TStatusProc;
  PostUrlGrabber: TPagesThreadPool;
  PostParser: TPostsThreadPool;



implementation

{$R *.dfm}
   //uses generics.collections;
Procedure Status(S: AnsiString);
begin
EnterCriticalSection(GeneralCS);
 with form1.logmemo do
  begin
    Lines.Add(s);
  end;
LeaveCriticalSection(GeneralCS);
//DeleteCriticalSection(GeneralCS);
end;
procedure TForm1.Button1Click(Sender: TObject);
var
 info: AnsiString;
 s: ansistring;
begin
 Numberi:=SpinEdit2.Value;
 StartPostProcessing;
//http://www.sythe.org/12147823-post1.html
//http://www.sythe.org/12024930-post82.html
 //info:=GetPage('http://www.sythe.org/12024930-post82.html');
 //s:=ProcessPostText1(info);
end;


procedure TForm1.Button2Click(Sender: TObject);
var
 TSA: TstringArray;
 i: integer;
begin
 TSA:=Explode(';',WordsMemo.Text);
 SearchingWords.Clear;
 for I := 0 to Length(TSA)-1 do
    SearchingWords.Add(TSA[i]);
   if (SearchingWords.Count > 0) then
 // ThreadParser:=TSytheParser.Create(TargetUrl.Text,status);
  StartThreadProcessing(TargetUrl.Text);

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
InitializeCriticalSection(GeneralCS);
//InitializeCriticalSection(ThreadCS);
//InitializeCriticalSection(FCS);
//SearchQueue:= TSearchingQueue.Create;
PagesQueue:= TPostURLQueue.Create;
 //  ThreadUrlQueue:=TUrlQueue.Create;
 PostUrlQueue:= TUrlQueue.Create;
 //FinalList:=TList<TPost>.Create;
  SearchingWords:= TList<AnsiString>.Create;
   ThreadUrls:= TList<AnsiString>.Create;
   PostURLs:= TList<AnsiString>.Create;
   //FPostList:= TList<TPost>.Create;
   //FSearchingWords:= TList<AnsiString>.Create;
   FWriteLn:=Status;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
//DeleteCriticalSection(FCS);
DeleteCriticalSection(GeneralCS);
//DeleteCriticalSection(ThreadCS);
   //SearchQueue.Free;
   PagesQueue.Free;
 //  ThreadUrlQueue.Free;
   PostUrlQueue.Free;
  // FinalList.Free;
   SearchingWords.free;
   ThreadUrls.free;
   PostUrls.free;
end;

function TForm1.GetNextNumber: integer;
begin
 numberi:=numberi+1;
 result:=numberi;
end;

function CustomSortProc(Item1, Item2: TListItem; ParamSort: integer): integer; stdcall;
begin
  if ParamSort=0 then
    Result := CompareText(Item1.Caption,Item2.Caption)
  else
    if Item1.SubItems.Count>ParamSort-1 then
    begin
      if Item2.SubItems.Count>ParamSort-1 then
        Result := CompareText(Item1.SubItems[ParamSort-1],Item2.SubItems[ParamSort-1])
      else
        Result := 1;
    end
    else
      Result:=-1;
end;

function CustomDataSort(Item1, Item2: TListItem; ParamSort: integer): integer; stdcall;
begin
  result := 0;
  if PostDateToDateTime(item1.SubItems[4]) > PostDateToDateTime(item2.SubItems[4]) then
    Result := 1
  else if PostDateToDateTime(item1.SubItems[4]) < PostDateToDateTime(item2.SubItems[4])
    then
    Result := -1;
end;

procedure TForm1.PostViewColumnClick(Sender: TObject; Column: TListColumn);
begin
if not (PostUrlGrabber.GetBusy = 0) and not (PostUrlQueue.getCount = 0) then
  exit;
  PostView.CustomSort(@CustomDataSort, Column.Index);
end;

procedure TForm1.StartPostProcessing;
var
 i: integer;
begin
CodeText.Lines.Clear;
 for i := 0 to PostView.Items.Count-1 do
   begin
   if PostView.Items[i].Checked then
    begin
    CodeText.Lines.Add(IntToStr(Numberi)+')'+#13#10);
    CodeText.Lines.Add('[QUOTE='+PostView.Items[i].Subitems[0]+';'+PostView.Items[i].SubItems[6]+']'+#13#10);

   // CodeText.Lines.Add('From:'+#32+PostView.Items[i].Subitems[0]);
   // Codetext.Lines.Add('Rank:'+#32+PostView.Items[i].SubItems[3]);
    CodeText.Lines.Add(#32+PostView.Items[i].SubItems[5]);GetNextNumber;
   // CodeText.Lines.Add('When:'+#32+PostView.Items[i].SubItems[4]);
    CodeText.Lines.Add('[/QUOTE]'+#13#10);
    end;
   end;
end;

function CheckThreadIsAlive(Thread: TThread): Boolean;
begin

    Result := WaitForSingleObject(Thread.Handle, 0) = WAIT_OBJECT_0;
end;

procedure TForm1.StartThreadProcessing(URL: AnsiString);
var
 Info: AnsiString;
 Counts: integer;
 i: integer;
 Handles: array [0..4] of THandle;
 rWait: integer;
begin
   if Assigned(PostUrlGrabber) then
    PostUrlGrabber.Free;
   if Assigned(PostParser) then
    PostParser.Free;
    PostView.Items.Clear;
    LogMemo.Clear;
    codetext.Clear;
    button1.Enabled:=false;
  // ParsingPages:=false;
   try
   Info:=GetPage(URL);
   if Length(Info) > 0 then
    begin
      Counts:=GetPostCountsFromThread(info);
       if (Counts = -1) then
        begin
        PostUrls:=GetPostUrls(Info);
        Counts:=PostUrls.Count;
        end;
       TotalPosts:=Counts;
       TotalPages:=GetPagesCounts(TotalPosts);
       ThreadUrls:=PreparePagesUrls(URL,TotalPages);
       if Assigned(FWriteLn) then
        FWriteLn('This thread have'+#32+IntToStr(TotalPosts)+#32+'posts'+#32+'and'+#32+inttostr(totalpages)+#32+'pages.');
        for i := 0 to ThreadURLs.Count-1 do
          PagesQueue.Push(ThreadUrls[i]);
        PostUrlGrabber:=TPagesThreadPool.Create(5,FWriteLn);
        while (PostUrlGrabber.GetBusy <> 0) do
         begin
          Application.ProcessMessages;
          sleep(10);
         end;

         PostUrlGrabber.Remove(5);


         PostParser:= TPostsThreadPool.Create(5,fwriteln);

         while (PostUrlQueue.getCount <> 0) do
         begin
          Application.ProcessMessages;
          sleep(10);
         end;
         Button1.Enabled:=true;
         //PostParser.Remove(5);
    end;
   except
     raise Exception.Create(SysErrorMessage(GetLastError));
   end;
end;

end.
