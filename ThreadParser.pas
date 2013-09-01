unit ThreadParser;

interface
  uses Classes,Sysutils,Generics.Collections,Windows,IdHttp,Dialogs,SyncObjs,sythe_Utils;
 type

    TPostURLQueue = class(TList<AnsiString>)
  private
    FCS: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function GetCount: integer;
    procedure Push(APost: AnsiString);
    function Pop: AnsiString;
  end;

 TSearchingQueue = class(TList<TPost>)
  private
    FCS: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(APost: TPost);
    function Pop: TPost;
  end;

   TURLQueue = class(TList<AnsiString>)
  private
    FCS: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function getCount: integer;
    procedure Push(APost: AnsiString);
    function Pop: AnsiString;
  end;

 TThreadUrlWorker = class;

 TUrlWorker = class;

 TPostsThreadPool = class;

 TPagesThreadPool = class;

 //TSearchWorker = class;

TThreadUrlWorker = class(TThread)
private
// FPostParser: TUrlWorker;
  FBusy: boolean;
  //i : integer;
  FWriteLn: TStatusProc;
  Msg: AnsiString;
 // FHttp: TIdHttp;
  procedure ProcessThreadUrl(Url: AnsiString);
  //function GetPage(URL: AnsiString): AnsiString;
public
  constructor Create(Status: TStatusProc);overload;
  destructor Destroy();override;
  procedure Execute; override;
  property busy: boolean read fbusy;
end;

TPagesThreadPool = class(TList<TObject>)
private
 FWriteLn: TStatusProc;
public
  procedure AddThreads(n:Integer);
  procedure Remove(n:Integer);
  function GetBusy: integer;
  Constructor Create(n: integer;Status: TStatusProc);overload;
  destructor Destroy; override;
end;

TUrlWorker = class(TThread)
private
  FList: TList<TPost>;
  FWriteLn: TStatusProc;
  //FHttp: TIdHttp;
  fbusy: boolean;
  procedure ProcessUrl(Url: AnsiString);
  procedure ProcessPost(APost: TPost);
 // function GetPage(URL: AnsiString): AnsiString;
public
  procedure Execute; override;
  constructor Create(Status: TStatusProc);
  property busy: boolean read fbusy;
end;

TPostsThreadPool = class(TList<TObject>)
private
 FWriteLn: TStatusProc;

public
  procedure AddThreads(n:Integer);
  procedure Remove(n:Integer);
  Constructor Create(n: integer;Status: TStatusProc);overload;
  destructor Destroy; override;
  function getbusy: integer;

end;



 var
  //SearchQueue: TSearchingQueue;
  PostUrlQueue: TUrlQueue;
  PagesQueue: TPostURLQueue;
  GeneralCS: TRTLCriticalSection;
  ThreadCS: TRTLCriticalSection;
  //FinalList: TList<Tpost>;
  SearchingWords: TList<AnsiString>;
  PagesSemaphore: THandle;
  //FCS: TRTLCriticalSection;
implementation
{ TSearchingQueue }
 uses Main,ComCtrls;

Procedure PostToListView(APost: TPost);
var
 LV: TListItem;
 begin
   EnterCriticalSection(GeneralCS);
   Form1.PostView.Items.BeginUpdate;
   LV:=Form1.PostView.Items.Add;
   with lv do
    begin
     Caption:=Apost.Id;
     Subitems.Add(Apost.User.Nickname);
     Subitems.Add(APost.User.JoinDate);
     Subitems.Add(APost.User.PostCount);
     SubItems.Add(Apost.User.Rank);
     SubItems.Add(Apost.Date);
     SubItems.Add(Apost.Text);
    end;
    Form1.PostView.Items.EndUpdate;
   LeaveCriticalSection(GeneralCS);
 end;

constructor TSearchingQueue.Create;
begin
 inherited Create;
 InitializeCriticalSection(FCS);
end;

destructor TSearchingQueue.Destroy;
begin
  DeleteCriticalSection(FCS);
  inherited;
end;

function TSearchingQueue.Pop: TPost;
begin
 EnterCriticalSection(FCS);
  if Count > 0 then
  begin
    Result := Items[0];

    Delete(0);
  end;
 //lse
  //Result := nil;
  LeaveCriticalSection(FCS);
end;

procedure TSearchingQueue.Push(APost: TPost);
begin
  EnterCriticalSection(FCS);
  Add(APost);
  LeaveCriticalSection(FCS);
end;



{ TURLQueue }

constructor TURLQueue.Create;
begin
  inherited Create;
   InitializeCriticalSection(FCS);
end;

destructor TURLQueue.Destroy;
begin
 DeleteCriticalSection(FCS);
  inherited;
end;

function TURLQueue.getCount: integer;
begin
 EnterCriticalSection(FCS);
  Result:=count;
 LeaveCriticalSection(FCS);
end;

function TURLQueue.Pop: AnsiString;
begin
  EnterCriticalSection(FCS);
  if (Count > 0) then
  begin
    Result := Items[0];

    Delete(0);
  end
  else
    Result := '';
  LeaveCriticalSection(FCS);
end;

procedure TURLQueue.Push(APost: AnsiString);
begin
  EnterCriticalSection(FCS);
  Add(APost);
  LeaveCriticalSection(FCS);
end;

{ TThreadUrlWorker }

constructor TThreadUrlWorker.Create(Status: TStatusProc);
begin
 inherited Create(false);
 //FUnprocessedUrls:=UrlList;
 //FUnprocessedUrls:=TList<AnsiString>.Create;
 //FHttp:=TidHttp.Create(nil);
// Fhttp.Request.UserAgent:='Opera/9.80 (Windows NT 6.0) Presto/2.12.388 Version/12.14';
 FWriteLn:=Status;
end;

destructor TThreadUrlWorker.Destroy;
begin
 // FHttp.Free;
  inherited;
end;

procedure TThreadUrlWorker.Execute;
var
 cnt: integer;
 item: AnsiString;
begin
  //inherited;
  while not Terminated do
  begin
  //EnterCriticalSection(GeneralCS);
  cnt:=PagesQueue.getCount;
 // LeaveCriticalSection(GeneralCS);
  if (cnt > 0) then
   begin
   Fbusy:=true;
   item:=PagesQueue.Pop;
   if not eq(Item,'Empty!') and not eq(Item,'') then
   ProcessThreadUrl(item);

   end else
      fbusy:=false;
  end;
      //FPostParser:=TUrlWorker.Create(FWriteLn);
   //FPostParser:= TPostsThreadPool.Create(2,FWriteLn);
end;



procedure TThreadUrlWorker.ProcessThreadUrl(Url: AnsiString);
var
 info: ansistring;
 GotUrls: TList<ansistring>;
 i: integer;
begin
 info:=GetPAge(Url);
 if Assigned(FWriteLn) then
   FWriteLn('Grab links from:'+#32+Url);
 try
 if (Length(info) > 0) then
  begin
    GotUrls:=GetPostUrls(info);
     if Assigned(GotUrls) then
     for I := 0 to GotUrls.Count-1 do
       begin
         FWriteLn('We add to post queue:' + GotUrls[i]);
         PostUrlQueue.Push(GotUrls[i]);
        end;
  end;
 finally
   if Assigned(GotUrls) then
    GotUrls.Free;
 end;

end;


{ TUrlWorker }

constructor TUrlWorker.Create(Status: TStatusProc);
begin
 inherited create(false);
 FWriteLn:=status;
 //FHttp:=TidHttp.Create(nil);
 //Fhttp.Request.UserAgent:='Opera/9.80 (Windows NT 6.0) Presto/2.12.388 Version/12.14';
end;

procedure TUrlWorker.Execute;
var
 item: AnsiString;
 i: integer;
begin
  //inherited;
 while not Terminated do
  begin
 // EnterCriticalSection(GeneralCS);
  i:= PostUrlqueue.getCount;
 // LeaveCriticalSection(GeneralCS);
  if (i > 0) then
  begin
    fbusy:=true;
    Item:=PostUrlQueue.Pop;
    if not eq(Item,'Empty!') and not eq(Item,'') then
      begin
       processUrl('http://'+Item);
       end;
    end else fbusy:=false;
  end;
  //until Terminated;
end;



procedure TUrlWorker.ProcessPost(APost: TPost);
begin
 EnterCriticalSection(GeneralCS);
  if SearchInText(SearchingWords,Apost.Text)  then
   begin
    LeaveCriticalSection(GeneralCS);
   // FinalList.Add(APost);
   // FWriteLn('We add item to final list:'+ Apost.Text);
    PostToListView(APost);
   end;

end;

procedure TUrlWorker.ProcessUrl(Url: AnsiString);
var
 Post: TPost;
 info,userInfo: AnsiString;
 //item: string;
begin
 if Assigned(FWriteLn) then
  FWriteLn('Processing: '+#32+Url);
 info:=GetPage(Url);
 if Length(info) > 0 then
  begin
 userInfo:=GetPAge(GetUserUrl(info));
 //FWriteLn(GetUserUrl('http://www.sythe.org/12697875-post19.html'));
 Post.User.Nickname:=GetSytheUsername(userInfo);
 Post.User.Rank:=GetSytheRank(userInfo);
 Post.User.JoinDate:=GetUserJoinDate(userInfo);
 Post.User.PostCount:=GetSytheUserPostCount(userInfo);
 Post.Date:=GetPostDate(info);
 Post.Id:=GetPostId(info);
 if Assigned(FWriteLn) then
  FWriteLn('Got message from user: '+#32+Post.User.Nickname+';'+#32+Post.User.Rank+';'+#32+Post.User.JoinDate+#32+';'+#32+Post.User.PostCount+';');
 Post.Text:=ProcessPostText(info);

 FwriteLn(Post.Text);
 post.MustBeAdded:=false;
 ProcessPost(Post);
 //FList.Add(Post);
  end;// else exit;
end;

{ TPostsThreadPool }

procedure TPostsThreadPool.AddThreads(n: Integer);
var
i: Integer;
begin
for i := 1 to n do
 begin
  inherited Add(TURLWorker.Create(FWriteLn));
 end;
 // if assigned(FWriteLn) then
   // FWriteLn('We add '+#32+'post workers');
end;

constructor TPostsThreadPool.Create(n: integer; Status: TStatusProc);
begin
 inherited Create;
 FWriteLn:=status;
 AddThreads(n);

end;

destructor TPostsThreadPool.Destroy;
begin
  Remove(Count);
 inherited;
end;

function TPostsThreadPool.getbusy: integer;
 var
  i: integer;
begin
  result:=0;
  for i:=0 to count -1 do
   if TUrlWorker(Items[i]).busy then
    inc(result);
end;

procedure TPostsThreadPool.Remove(n: Integer);
var
i: Integer;
begin
for i := n-1 downto 0 do begin
  with TThread(Items[i]) do begin
    Terminate;
    WaitFor;
  end;
  Delete(i);
end;
end;

//initialization

  // InitializeCriticalSection(GeneralCS);
//finalization

{ TPostURLQueue }

constructor TPostURLQueue.Create;
begin
    inherited Create;
   InitializeCriticalSection(FCS);
end;

destructor TPostURLQueue.Destroy;
begin
  DeleteCriticalSection(FCS);
  inherited;
end;

function TPostURLQueue.GetCount: integer;
begin
  EnterCriticalSection(FCS);
  Result:=count;
 LeaveCriticalSection(FCS);
end;

function TPostURLQueue.Pop: AnsiString;
begin
   EnterCriticalSection(FCS);
  if (Count > 0) then
  begin
    Result := Items[0];

    Delete(0);
  end
  else
    Result := '';
  LeaveCriticalSection(FCS);
end;

procedure TPostURLQueue.Push(APost: AnsiString);
begin
 EnterCriticalSection(FCS);
  Add(APost);
 LeaveCriticalSection(FCS);
end;

{ TPagesThreadPool }

procedure TPagesThreadPool.AddThreads(n: Integer);
var
i: Integer;
begin
for i := 1 to n do
 begin
  inherited Add(TThreadUrlWorker.Create(FWriteLn));
 end;
 // if assigned(FWriteLn) then
   // FWriteLn('We add '+#32+'post workers');
end;

constructor TPagesThreadPool.Create(n: integer; Status: TStatusProc);
begin
 inherited Create;
 FWriteLn:=status;
 AddThreads(n);

end;

destructor TPagesThreadPool.Destroy;
begin
  Remove(Count);
 inherited;
end;

function TPagesThreadPool.GetBusy: integer;
 var
  i: integer;
begin
  result:=0;
  for i:=0 to count -1 do
   if TThreadUrlWorker(Items[i]).busy then
    inc(result);
end;

procedure TPagesThreadPool.Remove(n: Integer);
var
i: Integer;
begin
for i := n-1 downto 0 do begin
  with TThread(Items[i]) do begin
    Terminate;
    WaitFor;
  end;
  Delete(i);
end;
end;




end.
