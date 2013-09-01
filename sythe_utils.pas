unit sythe_utils;

interface

 uses
  Classes,Sysutils,StrUtils, Windows,HttpSend,RegularExpressions,Generics.Collections;
 type

 TStatusProc = procedure (CurrentStatus: ansistring);

 TProgressProc = procedure (CurrentProgress: integer);

  type
   TStringArray = TArray<AnsiString>;

   TFoundedPosts = TList<AnsiString>;

   TUser = record
     Nickname,Rank,JoinDate,PostCount: ansistring;
   end;
   PPost = ^TPost;
   TPost = record
    public
      User: TUser;
      Text: AnsiString;
      Id: AnsiString;
      Date: AnsiString;
      MustBeAdded: boolean;
    end;
 function Explode(const Separator, S: string; Limit: Integer = 0): TStringArray;

 Function ExtractBetweenTags(Const Line,TagI,TagF:string):string;

 function Eq(aValue1, aValue2: string): boolean;

 function GetPage(URL: AnsiString): AnsiString;
 //thread routine
 function GetPostUrls(Text: Ansistring): TList<AnsiString>;

 function GetPostCountsFromThread(Text: AnsiString): integer;

 function GetPagesCounts(PostCount:integer): integer;

 function PreparePagesUrls(Url: AnsiString;PagesCount: integer):TList<AnsiString>;
 //user info stuff
 function GetUserUrl(info: AnsiString):AnsiString;

 function GetSytheUserName(info: AnsiString):AnsiString;

 function GetSytheRank(info: AnsiString):AnsiString;

 function GetSytheUserPostCount(info: AnsiString):AnsiString;

 function GetUserJoinDate(info: AnsiString):AnsiString;
 //process post text
 function ProcessPostText(Info: AnsiString):AnsiString;

  function GetPostDate(Info: AnsiString):AnsiString;

  function PostDateToDateTime(Str: AnsiString):TDateTime;

 function GetPostId(Info: AnsiString):AnsiString;

 function ConvertHTML(AInput: AnsiString): AnsiString;


 //text routine

 function SearchInText(Words: TList<AnsiString>;str: AnsiString):boolean;


implementation
  uses ThreadParser,Variants, MSHTML,ActiveX;

function Explode(const Separator, S: string; Limit: Integer = 0): TStringArray;
var
  SepLen: Integer;
  F, P: PChar;
  ALen, Index: Integer;
begin
  SetLength(Result, 0);
  if (S = '') or (Limit < 0) then Exit;
  if Separator = '' then
  begin
    SetLength(Result, 1);
    Result[0] := S;
    Exit;
  end;
  SepLen := Length(Separator);
  ALen := Limit;
  SetLength(Result, ALen);

  Index := 0;
  P := PChar(S);
  while P^ <> #0 do
  begin
    F := P;
    P := AnsiStrPos(P, PChar(Separator));
    if (P = nil) or ((Limit > 0) and (Index = Limit - 1)) then P := StrEnd(F);
    if Index >= ALen then
    begin
      Inc(ALen, 5);
      SetLength(Result, ALen);
    end;
    SetString(Result[Index], F, P - F);
    Inc(Index);
    if P^ <> #0 then Inc(P, SepLen);
  end;
  if Index < ALen then SetLength(Result, Index);
end;



function StripHTMLTags(const strHTML: string): string;
var
  P: PChar;
  InTag: Boolean;
  i, intResultLength: Integer;
begin
  P := PChar(strHTML);
  Result := '';
  if not (pos(strHTML,'>') > 0) then
   begin
     result:=strHTML;
     exit;
   end;
  InTag := False;
  repeat
    case P^ of
      '<': InTag := True;
      '>': InTag := False;
      #13, #10: ; {do nothing}
      else
        if not InTag then
        begin
          if (P^ in [#9, #32]) and ((P+1)^ in [#10, #13, #32, #9, '<']) then
          else
            Result := Result + P^;
        end;
    end;
    Inc(P);
  until (P^ = #0);

  {convert system characters}
  Result := StringReplace(Result, '&quot;', '"',  [rfReplaceAll]);
  Result := StringReplace(Result, '&apos;', '''', [rfReplaceAll]);
  Result := StringReplace(Result, '&gt;',   '>',  [rfReplaceAll]);
  Result := StringReplace(Result, '&lt;',   '<',  [rfReplaceAll]);
  Result := StringReplace(Result, '&amp;',  '&',  [rfReplaceAll]);
  {here you may add another symbols from RFC if you need}
end;

function ConvertHTML(AInput: AnsiString): AnsiString;
var
  Len, WriteLen, ReadPos, OldPos, WritePos: integer;
begin
  Len := Length(AInput);
  if Len = 0 then
    Exit;
  if not (pos(AInput,'>') > 0) then
   begin
     result:=AInput;
     exit;
   end;
  SetLength(Result, Len);
  ReadPos := 1;
  WritePos := 1;
  while ReadPos < Len do
  begin
    OldPos := ReadPos;
    while (AInput[ReadPos] <> AnsiChar('<')) and (ReadPos < Len) do
      Inc(ReadPos);
    WriteLen := ReadPos - OldPos;
    if WriteLen > 0 then
    begin
      Move(AInput[OldPos], Result[WritePos], WriteLen*2);
      Inc(WritePos, WriteLen);
    end;
    while (AInput[ReadPos] <> AnsiChar('>')) and (ReadPos < Len) do
      Inc(ReadPos);
    Inc(ReadPos);
  end;
  SetLength(Result, WritePos - 1);
end;


Function ExtractBetweenTags(Const Line,TagI,TagF:string):string;
var
  i, f : integer;
begin
  i := Pos(TagI, Line);
  f := Pos(TagF, Copy(Line, i+length(TagI), MAXINT));
  if (i > 0) and (f > 0) then
    Result:= Copy(Line, i+length(TagI), f-1);
end;

 function Eq(aValue1, aValue2: string): boolean;
begin
  Result := AnsiCompareText(Trim(aValue1),Trim(aValue2))=0;
end;

function GetPage(URL: AnsiString): AnsiString;
var
  HTTP : THTTPSend;
begin;
//EnterCriticalSection(GeneralCS);
  HTTP := THTTPSend.Create;

  HTTP.UserAgent := 'Opera/9.80 (Windows NT 6.0) Presto/2.12.388 Version/12.14';

  Result := '';
  try
    if HTTP.HTTPMethod('GET', URL) then
    begin
      SetLength(result,HTTP.Document.Size);
      HTTP.Document.Read(result[1],length(result));
    end;
  finally
    HTTP.Free;
  end;
//LeaveCriticalSection(GeneralCS);
end;

function GetPostUrls(Text: Ansistring): TList<AnsiString>;
var
 Reg: TRegEx;
 i:integer;
 M: TMatchCollection;
begin
  result:=TList<AnsiString>.create;
 //<a href="http://www.sythe.org/12400278-post1.html"
 // Reg := TRegEx.Create('<a href=\"(.*?)\"',[roIgnoreCase, roMultiLine]);
   Reg := TRegEx.Create('(www\.sythe\.org)(.)(\d+)(-)(post)(\d+)(.)(?:[a-z][a-z]+)',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(Text) then
  begin
    M:=Reg.Matches(text);
    for i := 0 to M.Count-1 do
       Result.Add(M[i].Value);
  end;
end;

function GetPostCountsFromThread(Text: ansistring): integer;
var
 Reg: TRegEx;
 i:integer;
 M: TMatchCollection;
 s,s1: AnsiString;
begin

   result:= -1;
 //<a href="http://www.sythe.org/12400278-post1.html"
 // Reg := TRegEx.Create('<a href=\"(.*?)\"',[roIgnoreCase, roMultiLine]);
   Reg := TRegEx.Create('(\of \d+\")',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(Text) then
  begin
    M:=Reg.Matches(text);
    for i := 0 to M.Count-1 do
       S:=M[i].Value;
    if (Pos('of',s)>0) then
     begin
       i:=Pos('of',s);
       s1:=Copy(s,i+2,Length(s)-(i+2));
     end;
  result:=StrToInt(s1);
  end else
  begin
   Reg := TRegEx.Create('(\of \d+.\d+\")',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(Text) then
  begin
    M:=Reg.Matches(text);
    for i := 0 to M.Count-1 do
       S:=M[i].Value;
    if (Pos('of',s)>0) then
     begin
       i:=Pos('of',s);
       s1:=Copy(s,i+2,Length(s)-(i+2));
       Delete(s1,pos(',',s1),1);
     end;
     result:=StrToInt(s1);
  end;

end;
end;

function GetPagesCounts(PostCount:integer): integer;
begin
  result:=1;
  if (PostCount > 21) and (PostCount < 29) then
   begin
     result:=trunc(PostCount/10);
   end;
  if (PostCount > 29) then

    result:=Trunc(PostCount/20)+1;
end;

function PreparePagesUrls(Url:AnsiString;PagesCount: integer):TList<AnsiString>;
var
 i,j: integer;
 Str: string;
begin
 Result:=TList<AnsiString>.Create;
 Result.Add(Url);
 j:=Pos('.html',URL);
 if (J > 0) then
  Str:=Copy(Url,0,j-1);
 for I := 2 to (PagesCount+1)-1 do
   begin
     Result.Add(Str+'-'+inttostr(i)+'.html');
   end;
end;

function GetUserUrl(Info: AnsiString): AnsiString;
 var
 Reg: TRegEx;
 i:integer;
 M: TMatchCollection;
 //Info: ansistring;
 S: AnsiString;
 Flags: TReplaceFlags;
begin
  //Info:=GetPage(URL);
  Flags:= [ rfReplaceAll, rfIgnoreCase ];
  Reg := TRegEx.Create('(www\.sythe\.org)(.)(members)(\/)(\d+)(-)((?:[a-z][a-z\.\d\-]+)\.(?:[a-z][a-z\-]+))(?![\w\.])',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(info) then
  begin
    M:=Reg.Matches(info);
    for i := 0 to M.Count-1 do
       result:='http://'+M[0].Value;
  end else
   begin
     Reg := TRegEx.Create('(?si)<a class="bigusername" href="(.*?)"',[roIgnoreCase, roMultiLine]);
     if Reg.IsMatch(info) then
     begin
       M:=Reg.Matches(info);
      for i := 0 to M.Count-1 do
         begin
           s:=M[0].Value;
           s:=StringReplace(s,'<a class="bigusername" href="','',Flags);
           s:=StringReplace(s,'"','',flags);
           result:=s;
         end;
//         result:=M[0].Groups[0].Value;
   end;
   end;
end;

function GetSytheUsername(Info: AnsiString):AnsiString;
var
 Reg: TRegEx;
 i:integer;
 M: TMatchCollection;
begin
 // info:=GetPage(URL);
  Reg := TRegEx.Create('(?si)<div class="bigusername">.*?</div>',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(info) then
  begin
    M:=Reg.Matches(info);
    for i := 0 to M.Count-1 do
       result:=(ExtractBetweenTags(M[i].Value,'<div class="bigusername">','</div>'));
  end;
end;

function GetSytheRank(info: AnsiString):AnsiString;
var
 Reg: TRegEx;
 i:integer;
 M: TMatchCollection;
begin
  //info:=GetPage(Url);
  Reg := TRegEx.Create('(?si)<div class="smallfont">.*?</div>',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(info) then
  begin
    M:=Reg.Matches(info);
    for i := 0 to M.Count-1 do
       result:=(ExtractBetweenTags(M[0].Value,'<div class="smallfont">','</div>'));
  end;
end;

function GetSytheUserPostCount(info: AnsiString):AnsiString;
var
 Reg: TRegEx;
 i:integer;
 M: TMatchCollection;
begin
  //info:=GetPage(Url);
  Reg := TRegEx.Create('(?si)<strong>.\d+</strong>',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(info) then
  begin
    M:=Reg.Matches(info);
    for i := 0 to M.Count-1 do
       result:=(ExtractBetweenTags(M[0].Value,'<strong>','</strong>'));
  end else
   begin
      Reg := TRegEx.Create('(?si)<strong>\d+.\d+</strong>',[roIgnoreCase, roMultiLine]);
      if Reg.IsMatch(info) then
       begin
       M:=Reg.Matches(info);
       for i := 0 to M.Count-1 do
          result:=(ExtractBetweenTags(M[0].Value,'<strong>','</strong>'));
       end;
   end;
end;

function GetUserJoinDate(info: AnsiString):AnsiString;
var
 Reg: TRegEx;
 i:integer;
 M: TMatchCollection;
begin
  //info:=GetPage(Url);
  Reg := TRegEx.Create('(?si)<strong>.\d+.\d+.\d+</strong>',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(info) then
  begin
    M:=Reg.Matches(info);
    for i := 0 to M.Count-1 do
       result:=(ExtractBetweenTags(M[0].Value,'<strong>','</strong>'));
  end;
end;

function Pars(text, a, b: string): string;
var
  I, J: Integer;
begin
  Result := text;
  I := 1;
//  repeat
    I := PosEx(a, text, I);
    if I = 0 then exit;
    J := PosEx(b, text, I+Length(a)-1); // 4 = Length('<!--')
    if J = 0 then exit;
    Delete(text, I, (J+Length(b)-1)); // 3 = Length('-->')
  //until False;
  result:=text;
end;

function ProcessPostText(info: Ansistring): AnsiString;
var
 Reg: TRegEx;
 i,j:integer;
 M: TMatchCollection;
 Flags: TReplaceFlags;
 //s,s1: AnsiString;
  V: OleVariant;
  Doc,ResDoc: IHTMLDocument2;
  DocA: IHTMLElementCollection; //коллекция элементов
  DocElement: IHtmlElement;
  PostHTML: AnsiString;
begin
 EnterCriticalSection(GeneralCS);
  result:='';
  Flags:= [ rfReplaceAll, rfIgnoreCase ];
  Reg := TRegEx.Create('post_message_\d+',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(info) then
  begin
    M:=Reg.Matches(info);
    CoInitializeEx( nil, COINIT_MULTITHREADED);
     Doc := coHTMLDocument.Create as IHTMLDocument2; // create IHTMLDocument2 instance
     V := VarArrayCreate([0,0], varVariant);
     V[0] := Info;
     Doc.Write(PSafeArray(TVarData(v).VArray));
     DocA:=Doc.all.tags('div')as IHTMLElementCollection;
  for i:=0 to DocA.length-1 do
    begin
      DocElement:=DocA.Item(i, 0) as IHtmlElement;//получили элемент коллекции
      //Status(DocElement.getAttribute('style',0));
     if eq(DocElement.getAttribute('id',0),M[0].Value) then
       begin
         PostHTML:=DocElement.innerHtml;
         //Status(PostHTML);
       end;
    end;
  end;
  while (pos('<DIV style="MARGIN: 5px 20px 20px">',PostHtml) > 0) do
    PostHtml:=Pars(PostHtml,'<DIV style="MARGIN: 5px 20px 20px">','</TABLE></DIV>');
  while (pos('<DIV class=smallfont style="MARGIN-BOTTOM: 2px">',PostHtml) > 0) do
    PostHtml:=Pars(PostHtml,'<DIV class=smallfont style="MARGIN-BOTTOM: 2px">','</TBODY></TABLE></DIV>');
  while (pos('<DIV style="FONT-STYLE: italic">',PostHtml) > 0) do
    PostHtml:=Pars(PostHtml,'<DIV style="FONT-STYLE: italic">','</TABLE></DIV>');
  // Status(PostHtml);
     ResDoc := coHTMLDocument.Create as IHTMLDocument2; // create IHTMLDocument2 instance
     V := VarArrayCreate([0,0], varVariant);
     V[0] := '<html><title>Test</title><body>'+PostHTML+'</body></html>';
     ResDoc.Write(PSafeArray(TVarData(v).VArray));
     result:=ResDoc.Body.InnerText;
    // Countitalize();

 LeaveCriticalSection(GeneralCS);
end;

function GetPostDate(Info: AnsiString):AnsiString;
var
 Reg: TRegEx;
 i:integer;
 M: TMatchCollection;
 S: AnsiString;
begin
 EnterCriticalSection(GeneralCS);
  result:='';

  Reg := TRegEx.Create('(?si)<a name="post\d+">',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(info) then
  begin
    M:=Reg.Matches(info);
    for i := 0 to M.Count-1 do
       s:=(ExtractBetweenTags(info,M[0].Value,'</div>'));
  Result:=pars(s,'<','</a>');
 // Result:=S;
  end;
 LeaveCriticalSection(GeneralCS);
end;

function GetPostId(Info: AnsiString):AnsiString;
var
 Reg: TRegEx;
 i:integer;
 M: TMatchCollection;
 S: AnsiString;
begin
 EnterCriticalSection(GeneralCS);
 //info:=GetPage(Url);
  Reg := TRegEx.Create('(?si)<strong>\d+</strong>',[roIgnoreCase, roMultiLine]);
  if Reg.IsMatch(info) then
  begin
    M:=Reg.Matches(info);
    for i := 0 to M.Count-1 do
       result:=(ExtractBetweenTags(M[0].Value,'<strong>','</strong>'));
  end;
 LeaveCriticalSection(GeneralCS);

end;

function PostDateToDateTime(Str: AnsiString):TDateTime;
Var
StrDate : AnsiString;
Fmt     : TFormatSettings;
dt      : TDateTime;
Flag: TReplaceFlags;
begin
Flag:= [ rfReplaceAll, rfIgnoreCase ];
fmt.ShortDateFormat:='mm-dd-yyyy';
fmt.DateSeparator  :='-';
fmt.LongTimeFormat :='hh:mm AM/PM';
fmt.TimeSeparator  :=':';
StrDate:=StringReplace(str,',','',flag);
dt:=StrToDateTime(StrDate,Fmt);
result:= dt;
end;

function SearchInText(Words: TList<AnsiString>;str: AnsiString):boolean;
var
 i,res: integer;
begin
 result:=false;
  for i:=0 to Words.Count-1 do
    begin
     res:=pos(LowerCase(Words[i]),LowerCase(str));
     if res > 0 then
      begin
        result:=true;
        exit;
      end;
    end;
end;


end.
