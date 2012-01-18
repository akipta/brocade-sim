{                                                                                 }
{ File:       Line_Editor.pas                                                     }
{ Function:   Line_Editor unit, A line editor to replace readln for keyboard imput}
{ Language:   Delphi 9 and above                                                  }
{ Author:     Michael Schipp                                                      }
{ Copyright:  (c) 2012 Michael Schipp                                             }
{ Disclaimer: This code is freeware. All rights are reserved.                     }
{             This code is provided as is, expressly without a warranty           }
{             of any kind. You use it at your own risk.                           }
{                                                                                 }
{             If you use this code, please credit me.                             }
{                                                                                 }

unit LineEditor;

interface

uses
  SysUtils, console;

const
  Ctrl_A      = #1;
  Ctrl_C      = #3;
  Ctrl_E      = #5;
  BkSpace_Key = #8;
  Tab_Key     = #9;
  escape      = 27;
  enter_key   = #13;
  up_key      = #72;
  Left_Key    = #75;
  Right_Key   = #77;
  Down_key    = #80;
  Del_Key     = #83;

 var
     history : array[1..20] of string;
     The_command : array[1..60] of char;
     result : char;
     history_pos, x_Pos,Y_Pos, cursor_loc, location : integer;
     cleanstr, tempstr : string;

function get_command:string;

implementation

 procedure RemoveNullChars(var s: String);
var
  i, j: Integer;
begin
  j := 0;
  for i := 1 to Length(s) do
    if s[i] <> #0 then begin
      Inc(j);
      s[j] := s[i];
    end;
  if j < Length(s) then
    SetLength(s, j);
end;


 function get_command:string;

  var
    ch :char;
    loop : integer;

    procedure backspace;

    var
      loop, loop2 : integer;
      temp_The_command : array[1..60] of char;
    Begin // nackspace
         if location >= 2 then
            Begin
               dec(location);
               tempstr[location] := #91; loop2 := 1;
               for loop := 1 to 60 do
                  begin
                    if tempstr[loop] <> #91 then
                       begin
                          temp_The_command[loop2] := tempstr[loop];
                          inc(loop2);
                       end
                    else
                  end;
               for loop := 1 to 59 do
                  begin
                       tempstr[loop] := temp_The_command[loop];
                  end;
               gotoxy(x_pos,Y_Pos);
               for loop := whereX to 79 - whereX do
                    Write(' ');
               gotoxy(x_pos,y_pos);
               write(tempstr);
               gotoxy(x_pos+location-1,y_pos);
            End;
    End; // of backspace

  begin
       location := 1; cursor_loc := 1;
       x_pos := whereX; y_pos := whereY;
       for loop := 1 to 60 do
         the_command[loop] := #0;
       gotoxy(x_pos,y_pos);
       tempstr := The_command;
       repeat
             ch := readkey;
             if ch = #0 then // Extended key code
                Begin
                    ch := readkey; // get second byte of key code
                    case ch of
{                        Down_Key : begin
                                    if history_pos < 20  then
                                      begin
                                        inc(history_pos);
                                        tempstr := history[history_pos];
                                        for loop := 1 to 60 do
                                            The_command[loop] := tempstr[loop];
                                        tempstr := the_command;
                                        gotoxy(x_pos,y_pos);
                                        for loop := x_pos to 79 do
                                            write(' ');
                                        gotoxy(x_pos,y_pos);
                                        cleanstr := tempstr;
                                        RemoveNullChars (cleanstr);
                                        write(cleanstr);
                                        location := length(history[history_pos])+1;
                                        cursor_loc := location;
                                        gotoxy(x_pos+location-1,y_pos);
                                      end;}
                                     {   inc(history_pos);
                                        tempstr := history[history_pos];
                                        gotoxy(x_pos,y_pos);
                                     for loop := x_pos to 79 do
                                      write(' ');
                                   gotoxy(x_pos,y_pos); write(tempstr);
                                   location := length(tempstr)+1;
                                   cursor_loc := length(tempstr)+1;
                                   gotoxy(x_pos + location-1,y_pos);
//                                   writeln;writeln('His pos ',history_pos, ' history is, ',history[history_pos]);}
                                 //end;
                        Up_Key : begin //up key
                                   if history_pos > 1 then
                                      begin
                                        dec(history_pos);
                                        tempstr := history[history_pos];
                                        for loop := 1 to length(tempstr) do
                                            The_command[loop] := tempstr[loop];
                                        tempstr := the_command;
                                        gotoxy(x_pos,y_pos);
                                        for loop := x_pos to 79 do
                                            write(' ');
                                        gotoxy(x_pos,y_pos);
                                        cleanstr := tempstr;
                                        RemoveNullChars (cleanstr);
                                        write(cleanstr);
                                        location := length(history[history_pos])+1;
                                        cursor_loc := location;
                                        gotoxy(x_pos+location-1,y_pos);
                                      end;
                                 end;
                        Left_Key : begin // left key
                                 if location >= 2 then
                                    begin
                                      dec(location);
                                      gotoxy(x_pos,y_pos); write(tempstr);
                                      gotoxy(x_pos+location-1,y_pos);
                                    end;
                              end;
                        Right_Key : begin // Right Key
                                  if location < cursor_loc then
                                     begin
                                       inc(location);
                                       gotoxy(x_pos,y_pos); write(tempstr);
                                       gotoxy(x_pos+location-1,y_pos);
                                     end;
                              End;
                        Del_Key : begin    // del key
                                   for loop := location to 59 do
                                        tempstr[loop] := tempstr[loop+1];
                                   dec(cursor_loc);
                                   gotoxy(x_pos,y_pos);
                                   for loop := whereX to 79 - whereX do
                                      write(' ');
                                   gotoxy(x_pos,y_pos); tempstr := tempstr; write(tempstr);
                                   gotoxy(x_pos+location-1,y_pos);
                              end
                    {    else
                        write(' .',ord(ch));}
                    End
                end
             else
                case ch of
                        Ctrl_A  : begin  // Ctrl A - go to the start of the line
                                     location := 1;
                                     gotoxy(x_pos,y_pos);
                                  End;
                        Ctrl_C  : begin

                                  end;
                        Ctrl_E  : begin  // Ctrl E - go to the end of the line
                                     location := cursor_loc;
                                     gotoxy(x_pos+location-1,y_pos);
                                  End;
                        enter_key : begin        // Enter Kry
                                      the_command[1] :='a';
                              end;
                        BkSpace_Key : begin   // backspace
                                  backspace;
                              end;
                        Tab_Key  : begin
//                                      writeln('tab');
                                    end;
                        '?' : begin
                                   if location = cursor_loc then // we are at the end of the line
                                  begin
                                    tempstr[location] := ch;
                                    inc(location);
                                    inc(cursor_loc)
                                  end
                                else // insert the char
                                  Begin
                                     for loop := 59 downto location do
                                        tempstr[loop+1] := tempstr[loop];
                                     tempstr[location] := ch;
                                     inc(location);
                                     inc(cursor_loc)
                                  End;
                                tempstr := tempstr;
                                gotoxy(x_pos,y_pos); write(tempstr); gotoxy(x_pos+location-1,y_pos);
                              end
                        else begin
                                if ch <> chr(Escape) then
                                if location = cursor_loc then // we are at the end of the line
                                  begin
                                    tempstr[location] := ch;
                                    inc(location);
                                    inc(cursor_loc)
                                  end
                                 else // insert the char
                                  Begin
                                     for loop := 59 downto location do
                                        tempstr[loop+1] := tempstr[loop];
                                     tempstr[location] := ch;
                                     inc(location);
                                     inc(cursor_loc)
                                  End;
                                //tempstr := tempstr;
                                gotoxy(x_pos,y_pos); write(tempstr); gotoxy(x_pos+location-1,y_pos);
                             End
                    End
       until (ch = '?') or (ch = tab_key) or (ch = Ctrl_C) or (ch = enter_key);
       result := ch;
       RemoveNullChars (tempstr);
       if tempstr <> '' then
          history[history_pos] := tempstr;
       if history_pos < 20 then
         inc(history_pos);
       get_command := tempstr;
  end;

end.
