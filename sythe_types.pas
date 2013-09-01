unit sythe_types;

interface
 uses Classes, Sysutils, Windows,Generics.Collections;

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
      MustBeAdded: boolean;
    end;


implementation

{ TTopic }


end.
