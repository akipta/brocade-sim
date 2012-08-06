program Brocade;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, StrUtils, IniFiles, LineEditor in 'LineEditor.pas',
  Console in 'Console.pas';

const
  level1 = '>';
  level2 = '#';
  level3 = '(config)#';
  level4 = '(config-if-e1000-';
  level5 = '(config-vlan-';

  StartupConfigFile = 'startup-config.txt';
  sim_outputFile = 'sim-output.txt';
  ModulesFile = 'modules.txt';

Function check_int(validport : shortstring) : boolean; forward;
Function is_word(check, target : string) : boolean; forward;
Function is_number(check : string) : boolean; forward;
Function is_help(check : string) : boolean; forward;
Procedure splash_screen; forward;
Procedure Get_words; forward;
Procedure Page_display(lines : array of string); forward;
Procedure bad_command(command:string); forward;
Procedure help_match(findword : string; var list : array of string); forward;
Procedure tab_match(findword : string; var list : array of string); forward;
Procedure Read_startup_config; forward;
Procedure read_config; forward;
Procedure init_top_menu; forward;
Procedure init_enable_menu; forward;
Procedure init_ip_menu; forward;
Procedure init_show_menu; forward;
Procedure init_config_term_menu; forward;
Procedure init_interface_menu; forward;
Procedure init_vlan_menu; forward;
Procedure display_help_match(findword : string); forward;
Procedure display_show_arp; forward;
Procedure display_show_boot_pref; forward;
Procedure display_show_clock; forward;
Procedure display_show_cpu; forward;
Procedure display_show_defaults; forward;
Procedure display_show_dot1x; forward;
Procedure display_show_errdisabled_recovery; forward;
Procedure display_show_fdp; forward;
Procedure display_show_int; forward;
Procedure display_show_int_eth(port : shortstring); forward;
Procedure display_show_int_bri; forward;
Procedure display_show_modules; forward;
Procedure display_show_flash; forward;
Procedure display_show_memory; forward;
Procedure display_show_port_security; forward;
Procedure display_show_reload; forward;
Procedure display_show_reserved_vlan; forward;
Procedure display_running_config; forward;
Procedure display_stp_protect; forward;
Procedure display_startup_config; forward;
Procedure display_show_telnet; forward;
Procedure display_show_version; forward;
Procedure display_show_web; forward;
Procedure display_show_who; forward;
Procedure display_show; forward;
Procedure vlan_loop(vlanid :string); forward;
Procedure int_loop(intid : string); forward;
Procedure configure_term_loop; forward;
Procedure enable_loop; forward;
Procedure my_loop; forward;

type
    vlan_records = record
        id : string[4];
        name : string;
        tag : string;
        untag : string;
    end;

Type interface_records = record
        port_no : string[5];
        admin_disable : boolean;
        descript : string;
        no_config : boolean;
        bpdu, root_guard : boolean;
        speed, speed_actual : string;
        priority : shortint;

end;

Var
  Hostname, level : string;
  input : string;
  what_level : integer;
  Code_version : array[1..120] of string;
  Modules : array[1..30] of string;
  chassis : array[1..70] of string;
  flash : array[1..11] of string;
  show_memory : array[1..3] of string;
  show_arp : array[1..30] of string;
  startup_config : array[1..1024] of string;
  running_config : array[1..1024] of string;
  last_line_of_running : integer;
  vlans : array[1..4095] of vlan_records;
  interfaces : array[1..384] of interface_records;
  word_list : array [1..10] of string;
  skip_page_display : boolean;
  port_count : integer;
  out_key :char;

  // vars for the menus
  top_menu            : array[1..7] of string;
  qos_menu            : array[1..7] of string;
  Show_menu           : array[1..80] of string;
  configterm_menu     : array[1..2] of string;
  config_term_menu    : array[1..120] of string;
  enable_menu         : array[1..50] of string;
  ip_menu             : array[1..50] of string;
  Interface_menu      : array[1..69] of string;
  vlan_menu           : array[1..30] of string;
  lldp_menu           : array[1..17] of string;
  mstp_menu           : array[1..17] of string;
  snmp_server_menu    : array[1..14] of string;
  chassis_menu        : array[1..5] of string;
  banner_menu         : array[1..6] of string;
  aaa_menu            : array[1..4] of string;
  access_list_menu    : array[1..3] of string;
  clear_menu          : array[1..28] of string;
  fast_menu           : array[1..3] of string;
  fdp_menu            : array[1..4] of string;
  link_config_menu    : array[1..3] of string;
  link_keepalive_menu : array[1..5] of string;
  logging_menu        : array[1..8] of string;
  mac_authentication_menu : array[1..15] of string;
  rmon_menu           : array[1..4] of string;
  sflow_menu          : array[1..9] of string;
  sntp_menu           : array[1..5] of string;
  snmp_client_menu    : array[1..4] of string;
  web_management_Menu : array[1..16] of string;
  debug_Menu          : array[1..25] of string;
  debug_ip_menu       : array[1..16] of string;
  dm_menu             : array[1..129] of string;
  boot_menu           : array[1..2] of string;
  boot_menu1          : array[1..2] of string;
  boot_menu2          : array[1..3] of string;
  int_eth_menu        : array[1..3] of string;

  Procedure splash_screen;

  Begin
      textcolor(lightgray);
      writeln;
      writeln(' ╔════════════════════════════════════════════════════════════════════════════╗');
      writeln(' ║                                                                            ║');
      writeln(' ║   Brocade-Sim : Version r46                                                ║');
      writeln(' ║                 Dated 6th of August 2012                                   ║');
      writeln(' ║                                                                            ║');
      Writeln(' ║   Coded by    : Michael Schipp And Jiri Kosar                              ║');
      writeln(' ║   Purpose     : To aid network administrators to get to know Brocade       ║');
      writeln(' ║                 FastIron devices and syntax - simulating FSX 1600 7.2.02d  ║');
      writeln(' ║                 To aid people studying for their BCNE                      ║');
      writeln(' ╠════════════════════════════════════════════════════════════════════════════╣');
      writeln(' ║ Keys:                                                                      ║');
      writeln(' ║      Ctrl A - move to start of the line                                    ║');
      writeln(' ║      Ctrl E - move to the end of the line                                  ║');
      writeln(' ║      TAB    - Auto complete                                                ║');
      writeln(' ║      ?      - for help                                                     ║');
      writeln(' ║                                                                            ║');
      writeln(' ║      Left and Right arrow keys to edit                                     ║');
      writeln(' ║      up and down arrow keys for history                                    ║');
      writeln(' ║                                                                            ║');
      writeln(' ║             press any key to continue.... To exit type ''exit''              ║');
      writeln(' ║                                                                            ║');
      write(' ║ ');
      write('Please e-mail comments to');
      textcolor(yellow);
      write(' brocade.sim@gmail.com');
      textcolor(lightgray);
      writeln('                            ║');
      writeln(' ╚════════════════════════════════════════════════════════════════════════════╝');
      gotoxy(79,24);
      readkey;
      clrscr;
      gotoxy(1,25);
  End;

  Function check_int(validport : shortstring) : boolean;

  var
    loop : integer;

  Begin
     check_int := false;
     for loop := 1 to port_count do
         Begin
              if validport = interfaces[loop].port_no then
                 Begin
                      check_int := true;
                      break;
                 End;
         end;
  End;

  Function is_word(check, target : string) : boolean;

  Begin

       is_word := strutils.AnsiContainsStr(target,check);
  end;

  Function is_number(check : string) : boolean;

  var
      a : integer;

  Begin
       a := 0; is_number := false;
       try
          a := strtoint(check);
       except
          on Exception : EConvertError do
              is_number := false;
       end;
       if a <> 0 then
         if a < 4096 then
            is_number := true
         Else
            Begin
              writeln('Error - Invalid input ',check,'. Valid range is between 1 and 4095');
              is_number := false;
            End;
  End;

  Function is_number_inrange(check : string; min,max : integer) : boolean;

  var
      a : integer;

  Begin
       a := 0; is_number_inrange := false;
       try
          a := strtoint(check);
       except
          on Exception : EConvertError do
              is_number_inrange := false;
       end;
       if a >= min then
         if a <= max then
            is_number_inrange := true
         Else
            Begin
//              writeln('Error - Invalid input ',check,'. Valid range is between 1 and 4095');
              is_number_inrange := false;
            End;
  End;

  Function is_help(check : string) : boolean;

  var
      Loop : integer;
  Begin
       is_help := false;
       for loop := 1 to length(check) do
         Begin
              if check[loop] = '?' then
                 is_help := true;
         End
  End;

  Procedure search_run(thisstr : string; var foundat : integer);

  var
    found : boolean;
    loop  : integer;

  Begin
       loop := 0; found := false;
       while found = false do
         Begin
              inc(loop);
              if is_word(thisstr,running_config[loop]) = true then
                 Begin
                     foundat := loop;
                     break;
                 End;
              if running_config[loop] = 'ENDofLINES' then
                 Begin
                    foundat := 0;
                    break;
                 End;
         End;
  End;
  Procedure Get_words;

  var
    a, word_count : integer;
    strlength : integer;

  Begin
        a := 1; word_count := 1;
        strlength := length(input);
        while (input[a] <> '') and (a <= strlength)do
          Begin
               while (input[a] <> ' ') and (a <= strlength)do
                 Begin
                     word_list[word_count] := word_list[word_count] + input[a];
                     if input[a] <> '' then
                        Begin
                            inc(a);
                        End
                     Else
                        break;
                 End;
               inc(a);
               inc(word_count);
          End;
  End;

  Procedure write_memory(lines : array of string);

  var
    count : integer;
    dest : textfile;

  Begin
      assignfile(dest,sim_outputFile);
      rewrite(dest);
      count := 0;
      while (lines[count] <> 'ENDofLINES') do
          Begin
               if lines[count] <> 'DELETED' then
                  writeln(dest,lines[count]);
               inc(count);
          End;
       for count := 1 to port_count do
         Begin
             if interfaces[count].no_config = false then
             Begin
                writeln(dest,'interface eithernet ', interfaces[count].port_no);
                if interfaces[count].descript <> '' then
                   writeln(dest,' port-name ', string(interfaces[count].descript));
                if interfaces[count].admin_disable = true then
                   writeln(dest,' disbaled');
                if interfaces[count].bpdu = true then
                    writeln(dest,' stp-bdpu-guard');
                if interfaces[count].root_guard = true then
                   writeln(dest,' spanning-tree root-protect');
             End
         End;
    writeln(dest,'!');
    writeln(dest,'!');
    writeln(dest,'End');
      close(dest);

  End;

  Procedure Page_display(lines : array of string);

  var
    count : integer;
    key : char;
    goodkey, ctrlc : boolean;
  Begin
      count := 0; goodkey := false; ctrlc := false;
//      key := #255;
      if skip_page_display = false then
      Begin
        while (lines[count] <> 'ENDofLINES') and (ctrlc = false) do
          Begin
               if (count mod 22 = 0) and (count > 21) then
                  Begin
                      if lines[count] <> 'DELETED' then
                         writeln(lines[count]);
                      writeln('--More--, next page: Space, next line: Return key, quit: Control-c');
                      repeat
                        Begin
                            key := readkey;
                            case key of
                              #3  : Begin
                                      ctrlc := true;
                                      goodkey := true;
                                    End;
                              #32 : goodkey := true;
                              #13 : Begin
                                      if lines[count+1] = 'ENDofLINES' then
                                         Begin
                                              ctrlc := true;
                                              goodkey := true;
                                         End
                                      Else
                                      Begin
                                        gotoxy(1,whereY-1);
                                        write('                                                                               ');
                                        gotoxy(1,whereY);
                                        if lines[count] <> 'DELETED' then
                                           writeln(lines[count+1]);
                                        writeln('--More--, next page: Space, next line: Return key, quit: Control-c');
                                        inc(count);
                                      End;
                                    End;
                              'q' : Begin
                                      goodkey := true;
                                      ctrlc := true;
                                    End;
                              'Q' : Begin
                                      goodkey := true;
                                      ctrlc := true;
                                    End;
                            End;
                        End
                      until goodkey = true;
                      inc(count);
                  End
               Else
                 Begin
                     if lines[count] <> 'DELETED' then
                        writeln(lines[count]);
                     inc(count);
                 End;
          End;
      End
    Else
      Begin
           while (lines[count] <> 'ENDofLINES') and (ctrlc = false) do
              Begin
                  writeln(lines[count]);
                  inc(count);
              End;
      End;
  End;

  Procedure bad_command(command:string);

  Begin
    writeln('Invalid input -> ',command);
    writeln('Type ? for a list');
  End;


  Procedure help_match(findword : string; var list : array of string);

  var
    loop, len: integer;
    astring : string;

  Begin
       len := Length(findword)-1;
       for loop := 0 to high(list) do
          Begin
            astring := Copy(list[loop], 3, len) + '?';
            if astring = findword then
              writeln(list[loop]);
          End;
  End;

  Procedure tab_match(findword : string; var list : array of string);

  var
    a, loop, len: integer;
    astring : string;
    tmp_str : string;
    only_one : integer;

  Begin
       len := Length(findword); only_one := 0;
       for loop := 0 to high(list) do
          Begin
            astring := Copy(list[loop], 3, len);
            if astring = findword then
              Begin
                  inc(only_one);
                  if list[loop] <> 'ENDofLINES' then
                     writeln(list[loop]);
                  tmp_str := list[loop];
              End;
          End;
       if only_one = 1 then
          Begin
                a := 3;
                if word_list[2] = '' then
                   input := ''
                Else
                   input := word_list[1] + ' ';
                while (tmp_str[a] <> ' ') do
                   Begin
                       input := input + tmp_str[a];
                       if tmp_str[a] <> '' then
                          inc(a)
                       Else
                          break;
                   End;
               input := input + ' ';
          End;
  End;

  Procedure tab_match2(level : integer; findword : string; var list : array of string);

  var
    a, loop, len: integer;
    astring : string;
    tmp_str : string;
    only_one : integer;

  Begin
       len := Length(findword); only_one := 0;
       for loop := 0 to high(list) do
          Begin
            astring := Copy(list[loop], 3, len);
            if astring = findword then
              Begin
                  inc(only_one);
                  if list[loop] <> 'ENDofLINES' then
                     writeln(list[loop]);
                  tmp_str := list[loop];
              End;
          End;
       if only_one = 1 then
         case level of
            2 : Begin
                  a := 3;
                  if word_list[2] = '' then
                   input := ''
                  Else
                   input := word_list[1] + ' ';
                  while (tmp_str[a] <> ' ') do
                   Begin
                       input := input + tmp_str[a];
                       if tmp_str[a] <> '' then
                          inc(a)
                       Else
                          break;
                   End;
                 input := input + ' ';
                End;
           3 : Begin
                  a := 3;
                  if word_list[3] = '' then
                   input := ''
                  Else
                   input := word_list[1] + ' ' + word_list[2] + ' ';
                  while (tmp_str[a] <> ' ') do
                   Begin
                       input := input + tmp_str[a];
                       if tmp_str[a] <> '' then
                          inc(a)
                       Else
                          break;
                   End;
                 input := input + ' ';
                End;
           4 : Begin
                  a := 3;
                  if word_list[4] = '' then
                   input := ''
                  Else
                   input := word_list[1] + ' ' + word_list[2] + ' ' + word_list[3] + ' ';
                  while (tmp_str[a] <> ' ') do
                   Begin
                       input := input + tmp_str[a];
                       if tmp_str[a] <> '' then
                          inc(a)
                       Else
                          break;
                   End;
                 input := input + ' ';
                End;
       end;
  End;

  Procedure Read_startup_config;

  var
      sc : textfile;
      aline : string;
      loop : integer;

  Begin
       loop := 1;
       assignfile(sc,StartupConfigFile);
       reset(sc);
       readln(sc, aline);
       running_config[1] := 'Current configuration:';
       running_config[2] := '!';
       running_config[3] := '07.2.02dT3e2';
       running_config[4] := '!';
       running_config[5] := 'module 1 fi-sx4-24-port-gig-copper-module';
       running_config[6] := 'module 2 fi-sx4-24-port-gig-copper-module';
       running_config[7] := 'module 3 fi-sx4-24-port-gig-copper-module';
       running_config[8] := 'module 4 fi-sx4-24-port-gig-copper-module';
       running_config[9] := 'module 5 fi-sx4-24-port-gig-copper-module';
       running_config[10] := 'module 6 fi-sx4-24-port-gig-copper-module';
       running_config[11] := 'module 7 fi-sx4-24-port-gig-copper-module';
       running_config[12] := 'module 8 fi-sx4-24-port-gig-copper-module';
       running_config[13] := 'module 9 fi-sx-0-port-management-module';
       running_config[14] := 'module 10 fi-sx-0-port-management-module';
       running_config[15] := 'module 11 fi-sx4-24-port-gig-copper-module';
       running_config[16] := 'module 12 fi-sx4-24-port-gig-copper-module';
       running_config[17] := 'module 13 fi-sx4-24-port-gig-copper-module';
       running_config[18] := '';
       running_config[19] := 'module 15 fi-sx4-24-port-gig-copper-module';
       running_config[20] := 'module 16 fi-sx4-24-port-gig-copper-module';
       running_config[21] := 'module 17 fi-sx4-24-port-gig-copper-module';
       running_config[22] := 'module 18 fi-sx4-24-port-gig-copper-module';
       running_config[23] := '!';
       startup_config[loop] := aline;
       running_config[24] := aline;
       inc(loop);
       while not EOF(sc) do
            Begin
//              writeln('-------',aline);   readln;
              readln(sc,aline);
              startup_config[loop] := aline;
              running_config[loop+23] := aline;
              inc(loop);
            End;
       running_config[loop+23] := 'ENDofLINES';
       last_line_of_running := loop +23;
       startup_config[loop+1] := 'end';
       closefile(sc);
  End;

  Procedure read_config;

  var
      sc : textfile;
      aline : string;
      loop, loop2 : integer;
      isend : boolean;
      slot : integer;

  Begin
       isend := false; loop := 1; slot := 1; port_count := 1;
       assignfile(sc,ModulesFile);
       reset(sc);
       readln(sc, aline);
       if aline = 'Insatalled-modules' then
          Begin
              readln(sc,aline);
              modules[1] := aline;
              readln(sc,aline);
              modules[2] := aline;
              readln(sc,aline);
              modules[3] := aline;
              loop := 4;
              repeat
                    readln(sc,aline);
                    if aline = 'END' then
                       isend := true
                    Else
                      Begin
                        modules[loop] := aline;
                        // setup interface ports
                        if (is_word('Management',aline) = false) then
                           Begin
//                                writeln(aline);
                                if is_word('EMPTY',aline) = true then
                                   inc(slot)
                                Else
                                Begin
                                 for loop2 := 1 to 24 do
                                    Begin
                                          interfaces[port_count].no_config := true;
                                          interfaces[port_count].admin_disable := false;
                                          interfaces[port_count].port_no := shortstring(inttostr(slot) + '/' + inttostr(loop2));
                                          interfaces[port_count].descript := '';
                                          interfaces[port_count].speed := 'auto';
                                          interfaces[port_count].speed_actual := '1Gbit';
                                          interfaces[port_count].root_guard := false;
                                          interfaces[port_count].priority := 0;
//                                          writeln(interfaces[port_count].port_no);
                                          inc(port_count);
                                    End;
                                inc(slot);
                                End;
                           End
                        Else
                           Begin
                                inc(slot);
                                readln(sc,aline);
                                inc(loop);
                                modules[loop] := aline;
                           End;
                        inc(loop);
                      End;
              until (isend = true);
              dec(port_count);
          End;

       modules[loop] := 'ENDofMODULES';
       readln(sc,aline); // version
       loop := 1; isend := false;
       repeat
             Begin
                  readln(sc,aline);
                  if aline = 'END' then
                     isend := true
                  Else
                     Begin
                       code_version[loop] := aline;
                       inc(loop);
                     End;
             End;
       until (isend = true);
       code_version[loop] := 'ENDofLINES';
       readln(sc, aline);
       isend := false;    loop := 1;
       if aline = 'FLASH' then
          Begin
              //writeln(aline);
              repeat
                    readln(sc,aline);
                    if aline = 'END' then
                       isend := true
                    Else
                      Begin
                        flash[loop] := aline;
//                        writeln(aline); readln;
                        inc(loop);
                      End;
              until (isend = true);
          End;
       flash[loop] := 'ENDofFLASH';
       isend := false; loop := 1;
       readln(sc,aline);
       if aline = 'CHASIS' then
          Begin
              //writeln(aline);
              repeat
                    readln(sc,aline);
                    if aline = 'END' then
                       isend := true
                    Else
                      Begin
                        chassis[loop] := aline;
//                        writeln(aline);
                        inc(loop);
                      End;
              until (isend = true);
          End;
       chassis[loop] := 'ENDofLINES';
       isend := false; loop := 1;
       readln(sc,aline);
       if aline = 'SHOWMEMORY' then
          Begin
              //writeln(aline);
              repeat
                    readln(sc,aline);
                    if aline = 'END' then
                       isend := true
                    Else
                      Begin
                        show_memory[loop] := aline;
//                        writeln(aline);
                        inc(loop);
                      End;
              until (isend = true);
          End;
          show_Memory[loop] := 'ENDofMEMORY';
       isend := false; loop := 1;
       readln(sc,aline);
       if aline = 'SHOWARP' then
          Begin
              //writeln(aline);
              repeat
                    readln(sc,aline);
                    if aline = 'END' then
                       isend := true
                    Else
                      Begin
                        show_arp[loop] := aline;
//                        writeln(aline);
                        inc(loop);
                      End;
              until (isend = true);
          End;
          show_arp[loop] := 'ENDofARP';
 //      write('******** ',flash[1]);
       closefile(sc);
  //     readln;

  End;

  Procedure init_top_menu;

  Begin
    top_menu[1] := '  enable            Enter Privileged mode                          --> done';
    top_menu[2] := '  exit              Exit from EXEC mode                            --> done';
    top_menu[3] := '  ping              Ping IP node                                   --> done';
    top_menu[4] := '  show              Display system information                     --> done';
    top_menu[5] := '  stop-traceroute   Stop current TraceRoute                        --> done';
    top_menu[6] := '  traceroute        TraceRoute to IP Node                          --> done';
    top_menu[7] := 'ENDofLINES';
  End;

  Procedure init_dm_menu;

  Begin
    dm_menu[1] := '  HEX                           Number';
    dm_menu[2] := '  48gc                          48GC related commands';
    dm_menu[3] := '  802-1w                        show 802-1w internal information';
    dm_menu[4] := '  aging-loop                    Turn off/on system aging loop';
    dm_menu[5] := '  alt-diag                      Test only, off/on';
    dm_menu[6] := '  app_vlan_debug                App VLAN table (shadow)';
    dm_menu[7] := '  auq-resync                    Sync Auq for a device';
    dm_menu[8] := '  auq-status                    show auq status';
    dm_menu[9] := '  auto-dfcdl                    Test Auto DFCDL Function';
    dm_menu[10] := '  badaddr                       Test only, will reboot';
    dm_menu[11] := '  blink                         Show gig link changes due to PHY blink';
    dm_menu[12] := '  clear_boot_count              Clear crash dump';
    dm_menu[13] := '  cpu                           Similiar to show cpu, more info';
    dm_menu[14] := '  cpu-pkt-diag                  Perform CPU Pkt diagnosis';
    dm_menu[15] := '  debug                         Set run-time debug options';
    dm_menu[16] := '  diag                          Test only, off/on';
    dm_menu[17] := '  dis-cpu-process-dev           Disable the CPU processing rx pkts from device';
    dm_menu[18] := '  dis-cpu-process-queue         Disable the CPU processing rx pkts from device';
    dm_menu[19] := '  fa-device                     Prestera device';
    dm_menu[20] := '  fid                           show fid resouce or one fid';
    dm_menu[21] := '  func                          (func_addr, param1, param2, param3, param4)';
    dm_menu[22] := '  gi-buffer-debug               Enable Buffer Debugging';
    dm_menu[23] := '  gi-find-mac                   Find MAC Entry in H/W';
    dm_menu[24] := '  gi-mac-stat                   Device MAC Statistics';
    dm_menu[25] := '  hbeat-mode                    Set the heartbeat mode for SXR';
    dm_menu[26] := '  hitless-debug                 Force Enable Active CLI';
    dm_menu[27] := '  hotswap-cli-allowed           Toggle -Enable/disable - CLI configurations';
    dm_menu[28] := '                                when HotSwap is in progress';
    dm_menu[29] := '  igmp_debug                    IGMP table (shadow)';
    dm_menu[30] := '  l2-debug                      set Debug for L2';
    dm_menu[31] := '  l3-debug                      L3 Sync Debug Options';
    dm_menu[32] := '  l3mcast-hitless               PIM/DVMRP hitless debug';
    dm_menu[33] := '  link-aggregation              display 8023.ad Info';
    dm_menu[34] := '  loop                          Test only, will reboot';
    dm_menu[35] := '  lpd                           Loop Detection (shadow)';
    dm_menu[36] := '  mac-debug                     mac table (shadow)';
    dm_menu[37] := '  mac-flow-add-err              Flow Mac causing Continious Unknown Unicast';
    dm_menu[38] := '  mac-hash-table                Dump Mac hash table';
    dm_menu[39] := '  mac-level                     set mac debug level';
    dm_menu[40] := '  mac-range-filter              mac range filter table (shadow)';
    dm_menu[41] := '  mem-leak                      debug memory leak';
    dm_menu[42] := '  metro-hw-toggle               toggles mrp hardware switching on/off';
    dm_menu[43] := '  metro-hwd                     Enable harware switching of tunneled RHP';
    dm_menu[44] := '  metro-interface               Show metro interface instances';
    dm_menu[45] := '  metro-rhp                     Show rhp session table';
    dm_menu[46] := '  metro-ring                    Show Metro ring debug info';
    dm_menu[47] := '  metro-trace-rhp               Trace the RHP route';
    dm_menu[48] := '  metro-trunk-table             shows mrp trunk table';
    dm_menu[49] := '  mld_debug                     MLD table (shadow)';
    dm_menu[50] := '  monitor-cmd                   Executes Monitor Command';
    dm_menu[51] := '  mstp                          display mstp structure information';
    dm_menu[52] := '  mstp-debug                    mstp table (shadow)';
    dm_menu[53] := '  null-pointer-off              Turn off null pointer check';
    dm_menu[54] := '  null-pointer-on               Turn on null pointer check';
    dm_menu[55] := '  optic                         Dump GBIC/XFP info';
    dm_menu[56] := '  optical-monitor               Change optical monitor timer';
    dm_menu[57] := '  packet                        Packet generator';
    dm_menu[58] := '  parser                        CLI parser';
    dm_menu[59] := '  pci-config-read               Read the configuation space of given PCI device';
    dm_menu[60] := '                                and offset';
    dm_menu[61] := '  pci-config-write              Write into the configuation space of given PCI';
    dm_menu[62] := '                                device and offset';
    dm_menu[63] := '  pci-dump                      Set Debug PCI error dump';
    dm_menu[64] := '  pci-recovery-for-0-port-mgmt';
    dm_menu[65] := '  pci-task                      PCI Recovery task Control';
    dm_menu[66] := '  perf-arm                      Arm Performance Monitor';
    dm_menu[67] := '  perf-print                    Print Performance Log';
    dm_menu[68] := '  perf-trig                     Trigger Performance Monitor';
    dm_menu[69] := '  phy-diag                      Perform PHY diagnosis';
    dm_menu[70] := '  pim_debug                     PIM table (shadow)';
    dm_menu[71] := '  pkt-trace-dev                 set the device to trace packet processing';
    dm_menu[72] := '  pkt-trace-qeueue              set the queue to trace packet processing';
    dm_menu[73] := '  pktsend                       Send Packets from CPU';
    dm_menu[74] := '  poe-device                    PoE Device/Controller/Module';
    dm_menu[75] := '  pool                          Display PSS memory pool statistics';
    dm_menu[76] := '  port_debug                    port table (shadow)';
    dm_menu[77] := '  posix_test                    POSIX compliance test';
    dm_menu[78] := '  pp-app-vlan                   Display Application/Dynamic VLAN Info';
    dm_menu[79] := '  pp-device                     Prestera device';
    dm_menu[80] := '  pp-dump-stuck-bufs            Dump stuck buffers';
    dm_menu[81] := '  pp-find-leak-cpu-buffer       find cpu buffers that are still mark';
    dm_menu[82] := '  pp-hw-ip-cache                Show hardware of ip cache';
    dm_menu[83] := '  pp-hw-mac-index               Display Hw Mac Index Table Info';
    dm_menu[84] := '  pp-hw-route                   Show hardware routes';
    dm_menu[85] := '  pp-interrupts                 Display PP Interrupt cause registers';
    dm_menu[86] := '  pp-ip-debug                   Enable pp L3 UC debug';
    dm_menu[87] := '  pp-lpm-cleanup                Cleanup lpm table';
    dm_menu[88] := '  pp-mark-cpu-buffer            mark cpu buffers to find leak';
    dm_menu[89] := '  pp-port-map                   Get Mappings for Port';
    dm_menu[90] := '  pp-pss-ip-debug               Enable pp L3 UC debug';
    dm_menu[91] := '  pp-settings                   Settings for Prestera devices';
    dm_menu[92] := '  pp-shadow-hw-mac-index        Display Shadow Hw Mac Index Table';
    dm_menu[93] := '  pp-show-lost-cpu-buffer       find cpu buffers that are still mark';
    dm_menu[94] := '  pp-trunk-hash                 Get the exact port for flow across a trunk group';
    dm_menu[95] := '  pp-utility                    hash, DSA decode, ...';
    dm_menu[96] := '  prbs                          Setup PRBS test on all channels';
    dm_menu[97] := '  ps-device                     Power Supply Device/Module';
    dm_menu[98] := '  raw-packet-debugging          Enable/disable raw packet debugging';
    dm_menu[99] := '  redundancy                    Hitless - Redundancy debug commands';
    dm_menu[100] := '  rel-sync                      Debug rel-sync';
    dm_menu[101] := '  reset-module                  Reset the Module at Given Slot';
    dm_menu[102] := '  resource                      Test only';
    dm_menu[103] := '  save_area                     Show crash dump';
    dm_menu[104] := '  show                          Display information on member units';
    dm_menu[105] := '  show-ripc                     show reliable ipc state';
    dm_menu[106] := '  size                          display data struct size';
    dm_menu[107] := '  softcheck                     Test only, will reboot';
    dm_menu[108] := '  spanning-tree                 show stp internal information';
    dm_menu[109] := '  stack                         Show crash dump stack';
    dm_menu[110] := '  statistics                    Test only';
    dm_menu[111] := '  stg                           Spanning Tree Group (shadow)';
    dm_menu[112] := '  stp                           Spanning Tree (shadow)';
    dm_menu[113] := '  sxr-red-state                 Print sxr-red- debug details';
    dm_menu[114] := '  sync-link-state               stby link state from active (shadow)';
    dm_menu[115] := '  sync-mac-range-filter         mac range filter table from active (shadow)';
    dm_menu[116] := '  sync-metro-rhp                Metro Ring Session (shadow)';
    dm_menu[117] := '  sync-port-stp                 port stp state table from active (shadow)';
    dm_menu[118] := '  sync-trunk-table              Trunk table from active (shadow)';
    dm_menu[119] := '  test                          Test Prestera devices';
    dm_menu[120] := '  test-ripc                     testing reliable ipc thru cmds';
    dm_menu[121] := '  toggle-fa-local-switching     Toggle FA Local Switching on SuperX';
    dm_menu[122] := '  trunk_debug                   Trunk table (shadow)';
    dm_menu[123] := '  tu                            Be a test unit, ie, no aging, no port reset,';
    dm_menu[124] := '                                test only';
    dm_menu[125] := '  vlan                          Show vlan masks';
    dm_menu[126] := '  vlan_debug                    VLAN table (shadow)';
    dm_menu[127] := '  xbar-device                   external crossbar device';
    dm_menu[128] := '  <cr>';
    dm_menu[129] := 'ENDofLINES';
  End;
  Procedure init_debug_ip_menu;

  Begin
    debug_ip_menu[1] := '  arp             ARP messages';
    debug_ip_menu[2] := '  dhcp_snooping   DHCP snooping';
    debug_ip_menu[3] := '  hitless         Hitless information';
    debug_ip_menu[4] := '  icmp            ICMP transactions';
    debug_ip_menu[5] := '  igmp            IGMP protocol activity';
    debug_ip_menu[6] := '  msdp            MSDP protocol activity';
    debug_ip_menu[7] := '  rip             RIP protocol transactions';
    debug_ip_menu[8] := '  source_guard    Source Guard';
    debug_ip_menu[9] := '  ssh             SSH information';
    debug_ip_menu[10] := '  sync            Sync message information';
    debug_ip_menu[11] := '  tcp             TCP information';
    debug_ip_menu[12] := '  udp             UDP based transactionstp';
    debug_ip_menu[13] := '  vrrp            VRRP information';
    debug_ip_menu[14] := '  web             WEB HTTP/HTTPS information';
    debug_ip_menu[15] := '  web-ssl         WEB Secured Socket Layer information';
    debug_ip_menu[16] := 'ENDofLINES';
  End;
  Procedure init_debug_menu;

  Begin
    debug_menu[1] :='  48gc                 48GC related commands';
    debug_menu[2] :='  802.1w               RSTP (802.1w) Debug information';
    debug_menu[3] :='  acl                  access-list';
    debug_menu[4] :='  all                  Enable all debugging';
    debug_menu[5] :='  destination          Redirect debug message';
    debug_menu[6] :='  dhcp-client          DHCP Client feature';
    debug_menu[7] :='  dhcp-server          DHCP Server feature';
    debug_menu[8] :='  dot1x                Enable 802.1X debugging';
    debug_menu[9] :='  hw                   Hardware backplane debugging';
    debug_menu[10] :='  ilp                  debug ILP(InLinePower) information';
    debug_menu[11] :='  ip                   Debug trace IP';
    debug_menu[12] :='  ipv6                 Debug trace IPv6';
    debug_menu[13] :='  license              Debug license code';
    debug_menu[14] :='  loop-detect          Debug loop detection';
    debug_menu[15] :='  mac                  Enable MAC Action debugging';
    debug_menu[16] :='  mac-authentication   MAC Authentication per port';
    debug_menu[17] :='  metro-ring           debug metro ring protocol';
    debug_menu[18] :='  mld-snooping         MLD Snooping Debug information';
    debug_menu[19] :='  mstp                 MSTP (802.1s) Debug information';
    debug_menu[20] :='  sflow                debug sflow';
    debug_menu[21] :='  span                 Spanning tree (802.1D) Debug Information';
    debug_menu[22] :='  system               System services and device drivers';
    debug_menu[23] :='  web                  Enable Web related debugging';
    debug_menu[24] :='  webauth              Enable Web Authentication debugging';
    debug_menu[25] :='ENDofLINES';
  End;

Procedure init_enable_menu;

  Begin
    enable_menu[1] := '  alias                     Display configured aliases';
    enable_menu[2] := '  boot                      Boot system from bootp/tftp server/flash image -->';
    enable_menu[3] := '  clear                     Clear table/statistics/keys';
    enable_menu[4] := '  clock                     Set clock';
    enable_menu[5] := '  configure                 Enter configuration mode                 --> done';
    enable_menu[6] := '  copy                      Copy between flash, tftp, config/code';
    enable_menu[7] := '  debug                     Enable debugging functions (see also ''undebug'')';
    enable_menu[8] := '  disable                   Disable a module before removing it';
    enable_menu[9] := '  dot1x                     802.1X';
    enable_menu[10] := '  enable                    Enable a disabled module';
    enable_menu[11] := '  erase                     Erase image/configuration from flash';
    enable_menu[12] := '  execute                   Execute commands in batch';
    enable_menu[13] := '  exit                      Exit Privileged mode';
    enable_menu[14] := '  hitless-reload            Reload the system in hitless manner';
    enable_menu[15] := '  inline                    Inline power (PoE) configuration/operation';
    enable_menu[16] := '  kill                      Kill active CLI session';
    enable_menu[17] := '  license                   Delete licenses';
    enable_menu[18] := '  ncopy                     Copy a file';
    enable_menu[19] := '  page-display              Display data one page at a time         --> done';
    enable_menu[20] := '  phy                       PHY related commands';
    enable_menu[21] := '  ping                      Ping IP node                            --> done';
    enable_menu[22] := '  port                      Port security command';
    enable_menu[23] := '  quit                      Exit to User level                      --> done';
    enable_menu[24] := '  reload                    Halt and perform a warm restart';
    enable_menu[25] := '  show                      Display system information              --> done';
    enable_menu[26] := '  skip-page-display         Enable continuous display               --> done';
    enable_menu[27] := '  sntp                      Simple Network Time Protocol commands';
    enable_menu[28] := '  stop-traceroute           Stop TraceRoute operation';
    enable_menu[29] := '  switch-over-active-role   Switch over the active role to standby mgmt blade';
    enable_menu[30] := '  telnet                    Telnet by name or IP address            --> done';
    enable_menu[31] := '  terminal                  display syslog';
    enable_menu[32] := '  trace-l2                  TraceRoute L2';
    enable_menu[33] := '  traceroute                TraceRoute to IP node';
    enable_menu[34] := '  undebug                   Disable debugging functions (see also ''debug'')';
    enable_menu[35] := '  verify                    Verify object contents';
    enable_menu[36] := '  whois                     WHOIS lookup';
    enable_menu[37] := '  write                     Write running configuration to flash or terminal -->';
    enable_menu[38] := 'ENDofLINES';
  End;

  Procedure init_qos_menu;

  Begin
      qos_menu[1] := '  mechanism         Change mechanism';
      qos_menu[2] := '  name              Change name';
      qos_menu[3] := '  profile           Change bandwidth allocation';
      qos_menu[4] := '  tagged-priority   Change tagged frame priority to profile mapping';
      qos_menu[5] := 'ENDofLINES';
  End;

  Procedure init_access_list_menu;

  Begin
      access_list_menu[1] := '  <1-99>       Standard IP access list';
      access_list_menu[2] := '  <100-199>    Extended IP access list';
      access_list_menu[3] := 'ENDofLINES';
  End;
  Procedure init_chassis_menu;

  Begin
      chassis_menu[1] := '  name        Chassis name';
      chassis_menu[2] := '  poll-time   Change hardware sensors polling interval seconds';
      chassis_menu[3] := '  trap-log';
      chassis_menu[4] := 'ENDofLINES';
  End;

  Procedure init_boot_menu;

  Begin
    boot_menu[1] := '  system';
    boot_menu[2] := 'ENDofLINES';
  End;

  Procedure init_int_eth_menu;

  Begin
    int_eth_menu[1] := '  ethernet';
    int_eth_menu[2] := '  brief';
    int_eth_menu[3] := 'ENDofLINES';
  End;

  Procedure init_boot1_menu;

  Begin
    boot_menu1[1] := '  flash';
    boot_menu1[2] := 'ENDofLINES';
  End;

  Procedure init_boot2_menu;

  Begin
    boot_menu2[1] := '  primary';
    boot_menu2[2] := '  secondary';
    boot_menu2[3] := 'ENDofLINES';
  End;

  Procedure init_configterm_menu;

  Begin
    configterm_menu[1] := '  terminal';
    configterm_menu[2] := 'ENDofLINES';
  End;

  Procedure init_ip_menu;

  Begin
    ip_menu[1] :='  access-list                   Configure named access list';
    ip_menu[2] :='  arp                           Set ARP option';
    ip_menu[3] :='  arp-age                       Set ARP aging period';
    ip_menu[4] :='  bootp-use-intf-ip             Use incoming interface IP as source IP';
    ip_menu[5] :='  broadcast-zero                Enable directed broadcast forwarding';
    ip_menu[6] :='  default-network               Configure default network route';
    ip_menu[7] :='  dhcp                          Set DHCP option';
    ip_menu[8] :='  dhcp-client                   DHCP client options';
    ip_menu[9] :='  dhcp-server                   DHCP Server';
    ip_menu[10] :='  dhcp-valid-check              Check DHCP offer packet for NULL client addr';
    ip_menu[11] :='  directed-broadcast            Enable directed broadcast forwarding';
    ip_menu[12] :='  dns                           Set DNS properties';
    ip_menu[13] :='  forward-protocol              Select protocols to be included in broadcast';
    ip_menu[14] :='                                forwarding';
    ip_menu[15] :='  helper-use-responder-ip       Retain Responders Source IP In Reply';;
    ip_menu[16] :='  icmp                          Control ICMP attacks';
    ip_menu[17] :='  igmp-report-control           Rate limit forwarding IGMP reports to upstream';
    ip_menu[18] :='                                Router';
    ip_menu[19] :='  irdp                          Enable IRDP for dynamic route learning';
    ip_menu[20] :='  load-sharing                  Enable IP load sharing';
    ip_menu[21] :='  mroute                        Configure static multicast route';
    ip_menu[22] :='  multicast                     Set IGMP snooping globally';
    ip_menu[23] :='  pimsm-snooping                Set PIMSM snooping globally';
    ip_menu[24] :='  preserve-acl-user-input-format';
    ip_menu[25] :='  proxy-arp                     Enable router to act as ARP proxy for its';
    ip_menu[26] :='                                subnets';
    ip_menu[27] :='  radius                        Configure RADIUS authentication';
    ip_menu[28] :='  rarp                          Enable RARP protocol on this router';
    ip_menu[29] :='  route                         Define static route';
    ip_menu[30] :='  router-id                     Change the router ID already in use';
    ip_menu[31] :='  show-acl-service-number       Use TCP/UDP service number to display ACL clause';
    ip_menu[32] :='  show-portname                 Display port name for the interface on log';
    ip_menu[33] :='                                messages';
    ip_menu[34] :='  show-service-number-in-log    Use App service number in log display';
    ip_menu[35] :='  show-subnet-length            Change subnet mask display to prefix format';
    ip_menu[36] :='  sntp                          Specify sntp options';
    ip_menu[37] :='  source                        Set source guard option';
    ip_menu[38] :='  source-route                  Process packets with source routing option';
    ip_menu[39] :='  ssh                           Configure Secure Shell';
    ip_menu[40] :='  ssl                           Configure Secure Socket';
    ip_menu[41] :='  syslog                        Specify syslog options';
    ip_menu[42] :='  tacacs                        Configure TACACS authentication';
    ip_menu[43] :='  tcp                           Control TCP SYN attacks';
    ip_menu[44] :='  telnet                        Specify telnet options';
    ip_menu[45] :='  tftp                          Specify tftp options';
    ip_menu[46] :='  ttl                           Set time-to-live for packets on the network';
    ip_menu[48] :='  <cr>';
    ip_menu[49] := 'ENDofLINES';
  End;

  Procedure init_banner_menu;

  Begin
    banner_menu[1] := '  ASCII string   c banner text c, where ''c'' is a delimiting character';
    banner_menu[2] := '  exec           Set EXEC process creation banner';
    banner_menu[3] := '  incoming       Set incoming terminal line banner';
    banner_menu[4] := '  motd           Set Message-of-the-day banner';
    banner_menu[5] := 'ENDofLINES';
  End;

  Procedure init_clear_menu;

  Begin
      clear_menu[1] := '  access-list              Clear ACL counters';
      clear_menu[2] := '  acl-on-arp';
      clear_menu[3] := '  arp                      Arp table';
      clear_menu[4] := '  auth-mac-table           Flush the MAC authentication table';
      clear_menu[5] := '  cable-diagnostics        Clear cable Diagonostics';
      clear_menu[6] := '  dhcp                     dhcp snooped ip-bindings';
      clear_menu[7] := '  dot1x                    802.1X data';
      clear_menu[8] := '  fdp                      Reset CDP/FDP information';
      clear_menu[9] := '  ip                       Clear IP Data';
      clear_menu[10] := '  ipv6';
      clear_menu[11] := '  link-aggregate           802.3ad Link Aggregation tables';
      clear_menu[12] := '  link-keepalive           Link Layer keepalive';
      clear_menu[13] := '  lldp                     Clear LLDP information';
      clear_menu[14] := '  logging                  System log';
      clear_menu[15] := '  loop-detection           Clear statistics, and enabled err-disabled ports';
      clear_menu[16] := '  mac-address              Mac address table';
      clear_menu[17] := '  port                     Clear Port Data';
      clear_menu[18] := '  public-key               remove authorized client public key';
      clear_menu[19] := '  radius                   Clear radius stat/queue';
      clear_menu[20] := '  rate-limit-state         Clear rate-limit';
      clear_menu[21] := '  rmon                     Clear RMON Data';
      clear_menu[22] := '  snmp-server              Clear SNMP Data';
      clear_menu[23] := '  statistics               Clear Statistics';
      clear_menu[24] := '  stp-protect-statistics   Clear stp-protect BPDU drop counter';
      clear_menu[25] := '  vsrp-aware               Clear learnt vsrp aware entries';
      clear_menu[26] := '  web-connection           All web connections';
      clear_menu[27] := '  webauth                  Web Authentication';
      clear_menu[28] := 'ENDofLINES';
  End;

  Procedure init_aaa_menu;

  Begin
    aaa_menu[1] := '  accounting       Accounting configurations parameters';
    aaa_menu[2] := '  authentication   Authentication configurations parameters';
    aaa_menu[3] := '  authorization    Authorization configurations parameters;';
    aaa_menu[4] := 'ENDofLINES';
  End;

  Procedure init_lldp_menu;

  Begin
    lldp_menu[1] := '  advertise                    Control advertising of information';
    lldp_menu[2] := '  enable                       Enable LLDP on interfaces, SNMP notifications';
    lldp_menu[3] := '  max-neighbors-per-port       Specify the maximum number of neighbors per port';
    lldp_menu[4] := '  max-total-neighbors          Specify the maximum number of total neighbors';
    lldp_menu[5] := '  med                          LLDP-MED settings';
    lldp_menu[6] := '  reinit-delay                 Specify the minimum time between port';
    lldp_menu[7] := '                               reinitializations';
    lldp_menu[8] := '  run                          Enable LLDP globally';
    lldp_menu[9] := '  snmp-notification-interval   Specify the minimum time between';
    lldp_menu[10] := '                               lldpRemTablesChange traps';
    lldp_menu[11] := '  tagged-packets               Specify handling for tagged LLDP packets';
    lldp_menu[12] := '  transmit-delay               Specify the minimum time between LLDP';
    lldp_menu[13] := '                               transmissions';
    lldp_menu[14] := '  transmit-hold                Specify the hold time multiplier for transmit TTL';
    lldp_menu[15] := '  transmit-interval            Specify the interval between regular LLDP';
    lldp_menu[16] := '                               transmissions';
    lldp_menu[17] := 'ENDofLINES';
  End;

  Procedure init_show_menu;

//  var
//   lines : array[1..80] of string;

  Begin
    show_menu[1]  := '  802-1w                 Rapid Spanning tree IEEE 802.1w D10 status';
    show_menu[2]  := '  aaa                    Show TACACS+ and RADIUS server statistics';
    show_menu[3]  := '  access-list            Show access list hit statistics';
    show_menu[4]  := '  acl-on-arp             Show ARP ACL filtering';
    show_menu[5]  := '  arp                    Arp table                                 --> done';
    show_menu[6]  := '  auth-mac-addresses     MAC Authentication status';
    show_menu[7]  := '  batch                  Batch commands';
    show_menu[8]  := '  boot-preference        System boot preference                    --> done';
    show_menu[9]  := '  cable-diagnostics      Show Cable Diagnostics';
    show_menu[10] := '  chassis                Power supply/fan/temperature              --> done';
    show_menu[11] := '  clock                  System time and date                      --> done';
    show_menu[12] := '  configuration          Configuration data in startup config file --> done';
    show_menu[13] := '  cpu-utilization        CPU utilization rate                      --> done';
    show_menu[14] := '  debug                  Debug information';
    show_menu[15] := '  default                System default settings                   --> done';
    show_menu[16] := '  dot1x                  dot1x  information                        --> done';
    show_menu[17] := '  errdisable             Errdisable status                         --> done';
    show_menu[18] := '  fdp                    CDP/FDP information                       --> done';
    show_menu[19] := '  flash                  Flash memory contents                     --> done';
    show_menu[20] := '  inline                 inline power information';
    show_menu[21] := '  interfaces             Port status                               --> done';
    show_menu[22] := '  ip                     IP address setting';
    show_menu[23] := '  ipv6                   IP setting';
    show_menu[24] := '  link-aggregate         802.3ad Link Aggregation Information';
    show_menu[25] := '  link-error-disable     Link Debouncing Control';
    show_menu[26] := '  link-keepalive         Link Layer Keepalive';
    show_menu[27] := '  lldp                   Link-Layer Discovery Protocol information';
    show_menu[28] := '  logging                System log';
    show_menu[29] := '  mac-address            MAC address table';
    show_menu[30] := '  media                  1Gig/10G port media type';
    show_menu[31] := '  memory                 System memory usage                       --> done';
    show_menu[32] := '  metro-ring             metro ring protocol information';
    show_menu[33] := '  mirror                 Mirror ports';
    show_menu[34] := '  module                 Module type and status                    --> done';
    show_menu[35] := '  monitor                Monitor ports';
    show_menu[36] := '  mstp                   show MSTP (IEEE 802.1s) information';
    show_menu[37] := '  optic                  Optic Temperature and Power';
    show_menu[38] := '  port                   Show port security';
    show_menu[39] := '  priority-mapping       802.1Q tagged priority setting';
    show_menu[40] := '  processes              Active process statistics';
    show_menu[41] := '  protected-link-group   Show Protected Link Group Details';
    show_menu[42] := '  ptrace                 Global ptrace information';
    show_menu[43] := '  qos-profiles           QOS configuration';
    show_menu[44] := '  qos-tos                IPv4 ToS based QoS';
    show_menu[45] := '  radius                 show radius server debug info';
    show_menu[46] := '  rate-limit             Rate-limiting table and actions';
    show_menu[47] := '  redundancy             Display management redundancy details';
    show_menu[48] := '  relative-utilization   Relative utilization list';
    show_menu[49] := '  reload                 Scheduled system reset                    --> done';
    show_menu[50] := '  reserved-vlan-map      Reserved VLAN map status                  --> done';
    show_menu[51] := '  rmon                   Rmon status';
    show_menu[52] := '  running-config         Current running-config                    --> done';
    show_menu[53] := '  sflow                  sflow information';
    show_menu[54] := '  snmp                   SNMP statistics';
    show_menu[55] := '  sntp                   Show SNTP';
    show_menu[56] := '  span                   Spanning tree status';
    show_menu[57] := '  statistics             Packet statistics';
    show_menu[58] := '  stp-bpdu-guard         Show stp bpdu guard status';
    show_menu[59] := '  stp-group              Spanning Tree Group Membership';
    show_menu[60] := '  stp-protect-ports      Show stp-protect enabled ports and their   ';
    show_menu[61] := '                         BPDU drop counters                        --> done';
    show_menu[62] := '  tech-support           System snap shot for tech support';
    show_menu[63] := '  telnet                 Telnet connection                         --> done';
    show_menu[64] := '  topology-group         Topology Group Membership';
    show_menu[65] := '  traffic-policy         Show traffic policy definition';
    show_menu[66] := '  transmit-counter       Transmit Queue Counters';
    show_menu[67] := '  trunk                  Show trunk status';
    show_menu[68] := '  users                  User accounts';
    show_menu[69] := '  v6-l4-acl-sessions     Show IPv6 software sessions';
    show_menu[70] := '  version                System status                             --> done';
    show_menu[71] := '  vlan                   VLAN status';
    show_menu[72] := '  vlan-group             VLAN Group Membership';
    show_menu[73] := '  voice-vlan             Show voice vlan';
    show_menu[74] := '  vsrp                   Show VSRP commands';
    show_menu[75] := '  web-connection         Current web connections                   --> done';
    show_menu[76] := '  who                    User login                                --> done';
    show_menu[77] := '  |                      Output modifiers';
    show_menu[78] := '  <cr>';
    show_menu[79] := 'ENDofLINES';
  End;

  Procedure init_config_term_menu;

  Begin
    config_term_menu[1] :=   '  aaa                           Define authentication method list      --> 4 ?';
    config_term_menu[2] :=   '  access-list                   Define Access Control List (ACL)       --> 4 ?';
    config_term_menu[3] :=   '  aggregated-vlan               Support for larger Ethernet frames up to 1536';
    config_term_menu[4] :=   '                                bytes';
    config_term_menu[5] :=   '  alias                         Configure alias or display configured alias';
    config_term_menu[6] :=   '  all-client                    Restrict all remote management to a host';
    config_term_menu[7] :=   '  arp                           Enter a static IP ARP entry';
    config_term_menu[8] :=   '  banner                        Define a login banner                  --> 4 ?';
    config_term_menu[9] :=   '  batch                         Define a group of commands';
    config_term_menu[10] :=  '  boot                          Set system boot options                --> done';
    config_term_menu[11] :=  '  bootp-relay-max-hops          Set maximum allowed hop counts for BOOTP';
    config_term_menu[12] :=  '  buffer-sharing-full           Remove buffer allocation limits per port';
    config_term_menu[13] :=  '  cdp                           Global CDP configuration command       --> done';
    config_term_menu[14] :=  '  chassis                       Configure chassis name and polling options-->4?';
    config_term_menu[15] :=  '  clear                         Clear table/statistics/keys            --> 4 ?';
    config_term_menu[16] :=  '  clock                         Set system time and date';
    config_term_menu[17] :=  '  console                       Configure console port';
    config_term_menu[18] :=  '  cpu-limit                     Set limits from each packet processor to CPU';
    config_term_menu[19] :=  '  crypto                        Crypto configuration';
    config_term_menu[20] :=  '  crypto-ssl                    Crypto ssl configuration';
    config_term_menu[21] :=  '  default-vlan-id               Change Id of default VLAN, default is 1';
    config_term_menu[22] :=  '  disable-hw-ip-checksum-check';
    config_term_menu[23] :=  '  dot1x-enable                  Enable dot1x system authentication control';
    config_term_menu[24] :=  '  enable                        Password, page-mode and other options';
    config_term_menu[25] :=  '  End                           End Configuration level and go to Privileged';
    config_term_menu[26] :=  '                                level';
    config_term_menu[27] :=  '  errdisable                    Set Error Disable Attributions';
    config_term_menu[28] :=  '  exit                          Exit current level                     --> done';
    config_term_menu[29] :=  '  extern-config-file            extern configuration file';
    config_term_menu[30] :=  '  fan-speed                     set fan speed';
    config_term_menu[31] :=  '  fan-threshold                 set temperature threshold for fan speed';
    config_term_menu[32] :=  '  fast                          Fast spanning tree options             --> 4 ?';
    config_term_menu[33] :=  '  fdp                           Global FDP configuration subcommands   --> done';
    config_term_menu[34] :=  '  flash-copy-block-size         Configure block size of code flash copy';
    config_term_menu[35] :=  '  flow-control                  Enable 802.3x flow control on full duplex port';
    config_term_menu[36] :=  '  gig-default                   Set Gig port default options';
    config_term_menu[37] :=  '  hash-chain-length             HW hash, 4-16, dflt: 16. High value improves';
    config_term_menu[38] :=  '                                hashing but might affect line rate';
    config_term_menu[39] :=  '  hitless-failover              Enable hitless failover';
    config_term_menu[40] :=  '  hostname                      Rename this switching router           --> done';
    config_term_menu[41] :=  '  inline                        Inline power (PoE) configuration';
    config_term_menu[42] :=  '  interface                     Port commands                          --> done';
    config_term_menu[43] :=  '  ip                            IP settings                            --> 4 ?';
    config_term_menu[44] :=  '  ipv4-subnet-response          Allow ipv4 subnet broadcast';
    config_term_menu[45] :=  '  ipv6                          IPv6 settings';
    config_term_menu[46] :=  '  jumbo                         gig port jumbo frame support (10240 bytes)';
    config_term_menu[47] :=  '  lacp-cfg-det-dis              Disable remote End LACP config remove detection';
    config_term_menu[48] :=  '  legacy-inline-power           set legacy (capacitance-based) PD detection -';
    config_term_menu[49] :=  '                                default';
    config_term_menu[50] :=  '  link-config                   Link Configuration                     --> 4 ?';
    config_term_menu[51] :=  '  link-keepalive                Link Layer Keepalive                   --> 4 ?';
    config_term_menu[52] :=  '  lldp                          Configure Link Layer Discovery Protocol--> done';
    config_term_menu[53] :=  '  local-userdb                  Configure local user database';
    config_term_menu[54] :=  '  lock-address                  Limit number of addresses for a port';
    config_term_menu[55] :=  '  logging                       Event logging settings                 --> done';
    config_term_menu[56] :=  '  loop-detection-interval       set period to send loop-detection packets,';
    config_term_menu[57] :=  '                                unit: 0.1 sec';
    config_term_menu[58] :=  '  mac                           Set up MAC filtering';
    config_term_menu[59] :=  '  mac-age-time                  Set aging period for all MAC interfaces';
    config_term_menu[60] :=  '  mac-authentication            Configure MAC authentication           --> 4 ?';
    config_term_menu[61] :=  '  max-acl-log-num               maximum number of ACL log per minute (0 to';
    config_term_menu[62] :=  '                                4096, default 256)';
    config_term_menu[63] :=  '  mirror-port                   Enable a port to act as mirror-port';
    config_term_menu[64] :=  '  module                        Specify module type';
    config_term_menu[65] :=  '  mstp                          Configure MSTP (IEEE 802.1s)           --> 4 ?';
    config_term_menu[66] :=  '  no                            Undo/disable commands                  --> done';
    config_term_menu[67] :=  '  optical-monitor               Enable optical monitoring with default';
    config_term_menu[68] :=  '                                alarm/warn interval(3 minutes)';
    config_term_menu[69] :=  '  password-change               Restrict access methods with right to change';
    config_term_menu[70] :=  '                                password';
    config_term_menu[71] :=  '  port                          UDP and Port Security Configuration';
    config_term_menu[72] :=  '  privilege                     Augment default privilege profile';
    config_term_menu[73] :=  '  protected-link-group          Define a Group of ports as Protected Links';
    config_term_menu[74] :=  '  pvlan-preference              Unknown unicast/broadcast traffic handling';
    config_term_menu[75] :=  '  qd-descriptor                 Queue depth for traffic class(# of descriptors)';
    config_term_menu[76] :=  '  qos                           Quality of service commands            --> 4 ?';
    config_term_menu[77] :=  '  qos-tos                       IPv4 ToS based QoS settings';
    config_term_menu[78] :=  '  quit                          Exit to User level';
    config_term_menu[79] :=  '  radius-server                 Configure RADIUS server';
    config_term_menu[80] :=  '  rarp                          Enter a static IP RARP entry';
    config_term_menu[81] :=  '  rate-limit-arp                Set limit on received ARP per second';
    config_term_menu[82] :=  '  relative-utilization          Display port utilization relative to selected';
    config_term_menu[83] :=  '                                uplinks';
    config_term_menu[84] :=  '  reserved-vlan-map             Map Reserved vlan Id to some other value not';
    config_term_menu[85] :=  '                                used';
    config_term_menu[86] :=  '  rmon                          Configure RMON settings                --> 4 ?';
    config_term_menu[87] :=  '  router                        Enable routing protocols               --> done';
    config_term_menu[88] :=  '  scale-timer                   Scale timer by factor for documented features';
    config_term_menu[89] :=  '  service                       Set services such as password encryption';
    config_term_menu[90] :=  '  set-active-mgmt               Configure the active mgmt slot';
    config_term_menu[91] :=  '  set-pwr-fan-speed             Power Fan Speed configuratio';
    config_term_menu[92] :=  '  sflow                         Set sflow params                       --> 4 ?';
    config_term_menu[93] :=  '  show                          Show system information                --> 4 ?';
    config_term_menu[94] :=  '  snmp-client                   Restrict SNMP access to a certain IP node';
    config_term_menu[95] :=  '  snmp-server                   Set onboard SNMP server properties     --> done';
    config_term_menu[96] :=  '  sntp                          Set SNTP server and poll interval      --> done';
    config_term_menu[97] :=  '  spanning-tree                 Set spanning tree parameters';
    config_term_menu[98] :=  '  ssh                           Restrict ssh access by ACL';
    config_term_menu[99] :=  '  stp-group                     Spanning Tree Group settings';
    config_term_menu[100] :=  '  system-max                    Configure system-wide maximum values';
    config_term_menu[101] :=  '  tacacs-server                 Configure TACACS server';
    config_term_menu[102] :=  '  tag-type                      Customize value used to identify 802.1Q Tagged';
    config_term_menu[103] :=  '                                Packets';
    config_term_menu[104] :=  '  telnet                        Set telnet access and timeout';
    config_term_menu[105] :=  '  tftp                          Restrict tftp access';
    config_term_menu[106] :=  '  topology-group                configure topology vlan group for L2 protocols';
    config_term_menu[107] :=  '  traffic-policy                Define Traffic Policy (TP)';
    config_term_menu[108] :=  '  transmit-counter              Define Transmit Queue Counter';
    config_term_menu[109] :=  '  trunk                         Trunk group settings';
    config_term_menu[110] :=  '  unalias                       Remove an alias';
    config_term_menu[111] :=  '  username                      Create or update user account';
    config_term_menu[112] :=  '  vlan                          VLAN settings                         --> done';
    config_term_menu[113] := '  vlan-group                    VLAN group settings';
    config_term_menu[114] := '  web                           Restrict web management access to a certain IP';
    config_term_menu[115] := '                                node';
    config_term_menu[116] := '  web-management                Web management options                 --> 4 ?';
    config_term_menu[117] := '  write                         Write running configuration to flash or terminal';
    config_term_menu[118] := '  <cr>';
    config_term_menu[119] := 'ENDofLINES';
  End;

  Procedure init_fast_menu;
  Begin
      fast_menu[1] := '  port-span     Fast spanning tree for end station ports';
      fast_menu[2] := '  uplink-span   Fast spanning tree for uplink ports';
      fast_menu[3] := 'ENDofLINES';
  End;

  Procedure init_fdp_menu;
  Begin
      fdp_menu[1] := '  holdtime   Specify the holdtime (in sec) to be sent in packets';
      fdp_menu[2] := '  run        Enable FDP globally';
      fdp_menu[3] := '  timer      Specify the rate at which FDP packets are sent (in sec)';
      fdp_menu[4] := 'ENDofLINES';
  End;

  Procedure init_link_config_menu;
  Begin
      Link_config_menu[1] := '  gig    GiG Link';
      Link_config_menu[2] := '  x10g   10G Link';
      Link_config_menu[3] := 'ENDofLINES';
  End;

  Procedure init_link_keepalive_menu;
  Begin
      link_keepalive_menu[1] := '  ethernet        Ethernet';
      link_keepalive_menu[2] := '  interval        Keepalive inter-packet interval in 100 milliseconds';
      link_keepalive_menu[3] := '  old-sx-config   Back to old link-keepalive configuration format';
      link_keepalive_menu[4] := '  retries         Keepalive retries allowed';
      link_keepalive_menu[5] := 'ENDofLINES';
  End;

  Procedure init_logging_menu;
  Begin
      logging_menu[1] :='  buffered';
      logging_menu[2] :='  console';
      logging_menu[3] :='  enable';
      logging_menu[4] :='  facility';
      logging_menu[5] :='  host';
      logging_menu[6] :='  on';
      logging_menu[7] :='  persistence';
      logging_menu[8] :='ENDofLINES';
  End;

  Procedure init_mac_authentication_menu;
  Begin
      mac_authentication_menu[1] := '  auth-fail-dot1x-override     Specify to use dot1x VLAN when MAC';
      mac_authentication_menu[2] := '                               authentication fails as restricted';
      mac_authentication_menu[3] := '  auth-fail-vlan-id            Specify Vlan to move the ports, when MAC';
      mac_authentication_menu[4] := '                               authentication fails';
      mac_authentication_menu[5] := '  auth-passwd-format           Set the format to be used for authentication';
      mac_authentication_menu[6] := '                               password and username';
      mac_authentication_menu[7] := '  disable-aging                Disable aging of mac sessions on all interface';
      mac_authentication_menu[8] := '  enable                       Enable MAC authentication feature';
      mac_authentication_menu[9] := '  hw-deny-age                  Set timeout for hardware aging';
      mac_authentication_menu[10] := '  mac-filter                   Specify filters for allowed MAC addresses';
      mac_authentication_menu[11] := '  max-age                      Set timeout for software aging';
      mac_authentication_menu[12] := '  password-override            Specify a password for all mac authentication';
      mac_authentication_menu[13] := '  save-dynamicvlan-to-config   Enable saving mac-authenticated dynamic vlan';
      mac_authentication_menu[14] := '                               memberships into config';
      mac_authentication_menu[15] := 'ENDofLINES';
  End;

  Procedure init_rmon_menu;
  Begin
      rmon_menu[1] := '  alarm     Configure an RMON alarm';
      rmon_menu[2] := '  event     Configure an RMON event';
      rmon_menu[3] := '  history   Configure an RMON history control';
      rmon_menu[4] := 'ENDofLINES';
  End;

  Procedure init_sflow_menu;
  Begin
      sflow_menu[1] := '  agent-ip           specify an sflow agent IP address';
      sflow_menu[2] := '  destination        Set sflow datagrams export destination';
      sflow_menu[3] := '  enable             Enable sflow services';
      sflow_menu[4] := '  export             exporting Foundry specific items';
      sflow_menu[5] := '  max-packet-size    Specify the max packet size (Default is 128, Max is 1300)';
      sflow_menu[6] := '  polling-interval   Set interface counters polling-interval';
      sflow_menu[7] := '  sample             Set sample rate';
      sflow_menu[8] := '  version            select sFlow agent version (default is v5)';
      sflow_menu[9] := 'ENDofLINES';
  End;

  Procedure init_sntp_menu;
  Begin
      sntp_menu[1] := '  broadcast       Enable/disable sntp broadcast client';
      sntp_menu[2] := '  poll-interval   ';
      sntp_menu[3] := '  server          Server IP address';
      sntp_menu[4] := '  server-mode     Enable/disable server-mode';
      sntp_menu[5] := 'ENDofLINES';
  End;

  Procedure init_snmp_server_menu;
  Begin
      snmp_server_menu[1] := '  community     Enable SNMP; set community string and access privs';
      snmp_server_menu[2] := '  contact       Text for mib object sysContact';
      snmp_server_menu[3] := '  enable        Enable SNMP Traps or Informs';
      snmp_server_menu[4] := '  engineid      Configure a local or remote SNMPv3 engine ID';
      snmp_server_menu[5] := '  group         Define a User Security Model group';
      snmp_server_menu[6] := '  host          Specify hosts to receive SNMP notifications';
      snmp_server_menu[7] := '  location      Text for mib object sysLocation';
      snmp_server_menu[8] := '  pw-check      Control password check on file operation mib objects';
      snmp_server_menu[9] := '  trap-source   Assign an interface for the source address of all traps';
      snmp_server_menu[10] := '  user          Define a user who can access the SNMP engine';
      snmp_server_menu[11] := '  view          Define an SNMPv2 MIB view';
      snmp_server_menu[12] := '  <cr>';
      snmp_server_menu[13] := 'ENDofLINES';
  End;

  Procedure init_snmp_client_menu;
  Begin
      snmp_client_menu[1] := '  A.B.C.D   IP address';
      snmp_client_menu[2] := '  any';
      snmp_client_menu[3] := '  ipv6      IPv6 address';
      snmp_client_menu[4] := 'ENDofLINES';
  End;

  Procedure init_web_management_menu;
  Begin
      web_management_Menu[1] := '  allow-no-password            Allow web server to have no password';
      web_management_Menu[2] := '  connection-receive-timeout   Web connection receive timeout';
      web_management_Menu[3] := '  enable                       Enable web management';
      web_management_Menu[4] := '  frame                        Allow to disable or enable a frame';
      web_management_Menu[5] := '  front-panel                  Enable front panel';
      web_management_Menu[6] := '  hp-top-tools                 Enable the support of HP TOP Tools';
      web_management_Menu[7] := '  http                         Enable the support of http server';
      web_management_Menu[8] := '  https                        Enable the support of https server provides';
      web_management_Menu[9] := '                               SSL/TLS Security';
      web_management_Menu[10] := '  list-menu                    Show web menu as a list';
      web_management_Menu[11] := '  page-menu                    Enable page menu';
      web_management_Menu[12] := '  page-size                    Maximum number of entries in a page';
      web_management_Menu[13] := '  refresh                      Page refresh (polling time) in seconds';
      web_management_Menu[14] := '  session-timeout              Web session timeout in second(s)';
      web_management_Menu[15] := '  tcp-port                     Configure TCP port number';
      web_management_Menu[16] := 'ENDofLINES';
  End;

  Procedure init_mstp_menu;

  Begin
    mstp_menu[1] := '  admin-edge-port         Define this port to be an edge port';
    mstp_menu[2] := '  admin-pt2pt-mac         Define this port to be a point-to-point link';
    mstp_menu[3] := '  disable                 Disable MSTP on this interface';
    mstp_menu[4] := '  edge-port-auto-detect   Enable/Disable auto-detect edge port';
    mstp_menu[5] := '  force-migration-check   Trigger port''s migration state machine check';
    mstp_menu[6] := '  force-version           Configure MSTP force version';
    mstp_menu[7] := '  forward-delay           Configure bridge parameter forward-delay';
    mstp_menu[8] := '  hello-time              Configure bridge parameter hello-time';
    mstp_menu[9] := '  instance                Configure MSTP instance VLAN membership';
    mstp_menu[10] := '  max-age                 Configure bridge parameter max-age';
    mstp_menu[11] := '  max-hops                Configure MSTP max-hops';
    mstp_menu[12] := '  name                    Configure MSTP configuration name';
    mstp_menu[13] := '  revision                Configure MSTP revision level';
    mstp_menu[14] := '  scope                   Configure MSTP scope';
    mstp_menu[15] := '  start                   Start/stop MSTP operation';
    mstp_menu[16] := 'ENDofLINES';
  End;

  Procedure init_interface_menu;

  Begin
      interface_menu[1] := '  100-fx                  100 FX Mode';
      interface_menu[2] := '  100-tx                  100 TX Mode';
      interface_menu[3] := '  acl-logging             enable logging of deny acl';
      interface_menu[4] := '  acl-mirror-port         Set acl based inbound mirroring';
      interface_menu[5] := '  arp                     Assign IP ARP option to this interface';
      interface_menu[6] := '  broadcast               Set maximum Layer 2 broadcast packets allowed';
      interface_menu[7] := '                          per second';
      interface_menu[8] := '  cdp                     Configure CDP on interface';
      interface_menu[9] := '  clear                   Clear table/statistics/keys';
      interface_menu[10] := '  dhcp                    Assign IP DHCP Snoop option to this interface';
      interface_menu[11] := '  disable                 Disable the interface                        --> done';
      interface_menu[12] := '  dot1x                   802.1X';
      interface_menu[13] := '  dual-mode               Accept both Tag and Untag traffic';
      interface_menu[14] := '  enable                  Enable the interface                         --> done';
      interface_menu[15] := '  end                     End Configuration level and go to Privileged';
      interface_menu[16] := '                          level';
      interface_menu[17] := '  exit                    Exit current level';
      interface_menu[18] := '  fdp                     Configure FDP on interface';
      interface_menu[19] := '  flow-control            Enable 802.3x flow control on full duplex port';
      interface_menu[20] := '  gig-default             Global Gig port default options';
      interface_menu[21] := '  inline                  inline power configuration';
      interface_menu[22] := '  ip-multicast-disable    Disable PIM, DVMRP and vlan IGMP snooping on';
      interface_menu[23] := '                          this port';
      interface_menu[24] := '  ipg-gmii                1G IPG setting';
      interface_menu[25] := '  ipg-mii                 10/100M IPG setting';
      interface_menu[26] := '  ipg-xgmii               10G IPG setting';
      interface_menu[27] := '  ipv6-multicast-disable  Disable IPv6 PIM and vlan MLD snooping on this';
      interface_menu[28] := '                          port';
      interface_menu[29] := '  link-aggregate          802.3ad Link Aggregation';
      interface_menu[30] := '  link-error-disable      Link Debouncing Control';
      interface_menu[31] := '  load-interval           Configure Load Interval';
      interface_menu[32] := '  loop-detection          shut down this port if receiving packets';
      interface_menu[33] := '                          originated from this port';
      interface_menu[34] := '  mac                     Apply MAC filter';
      interface_menu[35] := '  mac-authentication      Configure MAC Address authentication on';
      interface_menu[36] := '                          interface';
      interface_menu[37] := '  mac-learn-disable       Disable MAC learning on interface';
      interface_menu[38] := '  mdi-mdix                Set to MDI, MDIX or Auto';
      interface_menu[39] := '  monitor                 Set as monitored port';
      interface_menu[40] := '  multicast               Set maximum multicast packets allowed per second';
      interface_menu[41] := '  no                      Undo/disable commands';
      interface_menu[42] := '  optical-monitor         Enable optical monitoring with default';
      interface_menu[43] := '                          alarm/warn interval(3 minutes';
      interface_menu[44] := '  port                    Configure Port Security';
      interface_menu[45] := '  port-name               Assign alphanumeric port name                --> done';
      interface_menu[46] := '  priority                Set QOS priority';
      interface_menu[47] := '  pvst-mode               Interoperate with Cisco PVST+ for';
      interface_menu[48] := '                          multi-spanning tree';
      interface_menu[49] := '  quit                    Exit to User level';
      interface_menu[50] := '  rate-limit              Configure rate limiting to interface';
      interface_menu[51] := '  restart-vsrp-port       Set option to restart the VSRP port when Master';
      interface_menu[52] := '                          becomes Backup';
      interface_menu[53] := '  sflow                   Set sflow interface parameters';
      interface_menu[54] := '  show                    Show system information                      --> done';
      interface_menu[55] := '  snmp-server             Set onboard SNMP server interface properties';
      interface_menu[56] := '  source-guard            Assign IP Source Guard option to this interface';
      interface_menu[57] := '  spanning-tree           Set STP port parameters';
      interface_menu[58] := '  speed-duplex            Set to 100 or 10, half or full               --> done';
      interface_menu[59] := '  stp-bpdu-guard          set the spanning tree bpdu guard on the port --> done';
      interface_menu[60] := '  stp-protect             enable or disable stp-protect';
      interface_menu[61] := '  trust                   Change the trust mode';
      interface_menu[62] := '  unknown-unicast         Set maximum unknown unicast packets allowed per';
      interface_menu[63] := '                          second';
      interface_menu[64] := '  use-radius-server       Configure a radius server to be used on';
      interface_menu[65] := '                          interface';
      interface_menu[66] := '  voice-vlan              voice over IP vlan configuration';
      interface_menu[67] := '  write                   Write running configuration to flash or terminal';
      interface_menu[68] := '  <cr>';
      interface_menu[69] := 'ENDofLINES';
  End;

  Procedure init_vlan_menu;

  Begin
      vlan_menu[1] := '  atalk-proto                   Set AppleTalk protocol VLAN';
      vlan_menu[2] := '  clear                         Clear table/statistics/keys';
      vlan_menu[3] := '  decnet-proto                  Set decnet protocol VLAN';
      vlan_menu[4] := '  end                           End Configuration level and go to Privileged';
      vlan_menu[5] := '                                level';
      vlan_menu[6] := '  exit                          Exit current level';
      vlan_menu[7] := '  ip-proto                      Set IP protocol VLAN';
      vlan_menu[8] := '  ip-subnet                     Set IP subnet VLAN';
      vlan_menu[9] := '  ipv6-proto                    Set IPv6 protocol VLAN';
      vlan_menu[10] := '  ipx-network                   Set IPX network VLAN';
      vlan_menu[11] := '  ipx-proto                     Set IPX protocol VLAN';
      vlan_menu[12] := '  metro-ring                    metro ring configuration mode';
      vlan_menu[13] := '  netbios-proto                 Set netbios protocol VLAN';
      vlan_menu[14] := '  no                            Undo/disable commands';
      vlan_menu[15] := '  other-proto                   Set other protocol VLAN';
      vlan_menu[16] := '  pvlan                         Define private vlan type and mapping';
      vlan_menu[17] := '  quit                          Exit to User level';
      vlan_menu[18] := '  router-interface              Attach router interface for Layer 2 VLAN';
      vlan_menu[19] := '  show                          Show system information';
      vlan_menu[20] := '  spanning-tree                 Set spanning tree for this VLAN';
      vlan_menu[21] := '  static-mac-address            Configure static MAC for this VLAN';
      vlan_menu[22] := '  tagged                        802.1Q tagged port';
      vlan_menu[23] := '  untagged                      Port with only untagged frame in/out';
      vlan_menu[24] := '  uplink-switch                 Define uplink port(s) and enable uplink';
      vlan_menu[25] := '                                switching';
      vlan_menu[26] := '  vsrp                          Configure VSRP';
      vlan_menu[27] := '  vsrp-aware                    Configure VSRP Aware parameters';
      vlan_menu[28] := '  write                         Write running configuration to flash or terminal';
      vlan_menu[29] := '  <cr>';
      vlan_menu[30] := 'ENDofLINES';
  End;

  Procedure display_help_match(findword : string);

  var
    loop, len: integer;
    astring : string;

  Begin
       len := Length(findword)-1;
//       writeln('wordlist, ',findword);
       for loop := 1 to 80 do
          Begin
            astring := Copy(show_menu[loop], 3, len) + '?';
            if astring = findword then
              writeln(show_menu[loop]);
          End;
  End;

  Procedure display_show_arp;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if show_arp[loop] = 'ENDofARP' then
             isend := true
          Else
              Begin
                  writeln(show_arp[loop]);
                  inc(loop)
              End;
    until isend = true;
//    writeln(chassis[loop]);
  End;

  Procedure display_show_boot_pref;

  var
    foundat : integer;

  Begin
    writeln('1 percent busy, from 45 sec ago');
    writeln('Boot system preference(Configured):');
    search_run('boot system flash secondary',foundat);
    if foundat <> 0 then
       writeln('        Boot system flash secondary')
    else
       writeln('        Boot system flash primary');
    writeln('');
    writeln('Boot system preference(Default):');
    writeln('        Boot system flash primary');
    writeln('        Boot system flash secondary');
  End;

  Procedure display_show_clock;

  Begin
    writeln(timetostr(time), ' GMT+10 ',datetostr(date));
  End;

  Procedure display_show_cpu;

  Begin
    writeln('1 percent busy, from 45 sec ago');
    writeln('1   sec avg:  1 percent busy');
    writeln('5   sec avg:  1 percent busy');
    writeln('60  sec avg:  1 percent busy');
    writeln('300 sec avg:  1 percent busy');
  End;

  Procedure display_show_defaults;

  Begin
    writeln('snmp ro community public   spanning tree disabled     fast port span disabled');
writeln('auto sense port speed      port untagged              port flow control on');
writeln('no username assigned       no password assigned       boot sys flash primary');
writeln('system traps enabled       sntp disabled              radius disabled');
writeln('rip disabled               ospf disabled              bgp disabled');
writeln('');
writeln('when ip routing enabled :');
writeln('ip irdp disabled           ip load-sharing enabled    ip proxy arp disabled');
writeln('ip rarp enabled            ip bcast forward disabled');
writeln('dvmrp disabled             pim/dm disabled');
writeln('vrrp disabled              fsrp disabled');
writeln('');
writeln('when rip enabled :');
writeln('rip type:v2 only           rip poison rev enabled');
writeln('');
writeln('ipx disabled               appletalk disabled');

  End;

  Procedure display_show_dot1x;

  Begin
      Writeln('Error - 802.1X  is not enabled');
  End;

  Procedure display_show_errdisabled_recovery;

  Begin
      writeln('ErrDisable Reason       Timer Status');
      writeln('--------------------------------------');
      writeln('all reason               Disabled');
      writeln('bpduguard                Disabled');
      writeln('loopDetection            Disabled');
      writeln('');
      writeln('Timeout Value: 300 seconds');
      writeln('');
      writeln('Interface that will be enabled at the next timeout:');
      writeln('');
      writeln('Interface         Errdisable reason   Time left (sec)');
      writeln('');
      writeln('--------------    -----------------   ---------------');
  End;
  Procedure display_show_fdp;

  Begin
    writeln('Either FDP or CDP is not enabled');
  End;

  Procedure display_show_int;
  // This neends to be changed to show all ethernet port - 360 in theis - e.g. theis need to be split
  // so that the string passed to page_display < then 4096; whcih looks like the max.
  // thinking take a mod numner * 10 and do in blocks.
  var
    lines                  : array[1..2700] of string;
    loop, index, mac_base  : integer;

  Begin
      index := 1; mac_base := 1201;
      for loop := 1 to 100 do
        Begin
            lines[index] := 'GigabitEthernet' + string(interfaces[loop].port_no) +' is down, line protocol is down';
//            writeln(' --> ',lines[index]); readkey;
            inc(index);
            lines[index] := '  Hardware is GigabitEthernet, address is 0012.f2cf.1200 (bia 0012.f2cf.' + inttostr(mac_base);
            inc(index); inc(mac_base);
            lines[index] := '  Configured speed ' + interfaces[loop].speed + ', actual unknown, configured duplex fdx, actual unknown';
            inc(index);
            lines[index] := '  Configured mdi mode AUTO, actual unknown';
            inc(index);
            lines[index] := '  Member of L2 VLAN ID 1, port is untagged, port state is BLOCKING';
            inc(index);
            if interfaces[loop].bpdu = true then
               Begin
                  lines[index] := '  BPDU guard is Enabled, ROOT protect is ';
               End
            Else
               lines[index] := '  BPDU guard is Disabled, ROOT protect is ';
            if interfaces[loop].root_guard = true then
               Begin
                  lines[index] := lines[index]+ 'Enabled';
               End
            Else
               lines[index] := lines[index] + 'Disabled';
            inc(index);
            lines[index] := '  Link Error Dampening is Disabled';
            inc(index);
            lines[index] := '  STP configured to ON, priority is level0';
            inc(index);
            lines[index] := '  Flow Control is config enabled, oper disabled, negotiation disabled';
            inc(index);
            lines[index] := '  Mirror disabled, Monitor disabled';
            inc(index);
            lines[index] := '  Not member of any active trunks';
            inc(index);
            lines[index] := '  Not member of any configured trunks';
            inc(index);
            if interfaces[loop].descript = '' then
               Begin
                  lines[index] := '  No port name';
                  inc(index);
               End
            Else
               Begin
                  lines[index] := '  ' + interfaces[loop].descript;
                  inc(index);
               End;
            lines[index] := '  IPG MII 96 bits-time, IPG GMII 96 bits-time';
            inc(index);
            lines[index] := '  IP MTU 1500 bytes, encapsulation ethernet';
            inc(index);
            lines[index] := '  300 second input rate: 0 bits/sec, 0 packets/sec, 0.00% utilization';
            inc(index);
            lines[index] := '  300 second output rate: 0 bits/sec, 0 packets/sec, 0.00% utilization';
            inc(index);
            lines[index] := '  0 packets input, 0 bytes, 0 no buffer';
            inc(index);
            lines[index] := '  Received 0 broadcasts, 0 multicasts, 0 unicasts';
            inc(index);
            lines[index] := '  0 input errors, 0 CRC, 0 frame, 0 ignored';
            inc(index);
            lines[index] := '  0 runts, 0 giants';
            inc(index);
            lines[index] := '  0 packets output, 0 bytes, 0 underruns';
            inc(index);
            lines[index] := '  Transmitted 0 broadcasts, 0 multicasts, 0 unicasts';
            inc(index);
            lines[index] := '  0 output errors, 0 collisions';
            inc(index);
            lines[index] := '  Relay Agent Information option: Disabled';
            inc(index);
        End;
      lines[index] := 'ENDofLINES';
      page_display(lines);
  End;

  Procedure display_show_int_eth(port : shortstring);

  var
    lines                  : array[1..50] of string;
    loop, index, mac_base  : integer;

  Begin
      index := 1; mac_base := 1201;
      for loop := 1 to 360 do
        if interfaces[loop].port_no = port then
            Begin
            lines[index] := 'GigabitEthernet' + string(interfaces[loop].port_no) +' is down, line protocol is down';
//            writeln(' --> ',lines[index]); readkey;
            inc(index);
            lines[index] := '  Hardware is GigabitEthernet, address is 0012.f2cf.1200 (bia 0012.f2cf.' + inttostr(mac_base);
            inc(index); inc(mac_base);
            lines[index] := '  Configured speed ' + interfaces[loop].speed + ', actual unknown, configured duplex fdx, actual unknown';
            inc(index);
            lines[index] := '  Configured mdi mode AUTO, actual unknown';
            inc(index);
            lines[index] := '  Member of L2 VLAN ID 1, port is untagged, port state is BLOCKING';
            inc(index);
            if interfaces[loop].bpdu = true then
               Begin
                  lines[index] := '  BPDU guard is Enabled, ROOT protect is ';
               End
            Else
               lines[index] := '  BPDU guard is Disabled, ROOT protect is ';
            if interfaces[loop].root_guard = true then
               Begin
                  lines[index] := lines[index]+ 'Enabled';
               End
            Else
               lines[index] := lines[index] + 'Disabled';
            inc(index);
            lines[index] := '  Link Error Dampening is Disabled';
            inc(index);
            lines[index] := '  STP configured to ON, priority is level0';
            inc(index);
            lines[index] := '  Flow Control is config enabled, oper disabled, negotiation disabled';
            inc(index);
            lines[index] := '  Mirror disabled, Monitor disabled';
            inc(index);
            lines[index] := '  Not member of any active trunks';
            inc(index);
            lines[index] := '  Not member of any configured trunks';
            inc(index);
            if interfaces[loop].descript = '' then
               Begin
                  lines[index] := '  No port name';
                  inc(index);
               End
            Else
               Begin
                  lines[index] := '  ' + interfaces[loop].descript;
                  inc(index);
               End;
            lines[index] := '  IPG MII 96 bits-time, IPG GMII 96 bits-time';
            inc(index);
            lines[index] := '  IP MTU 1500 bytes, encapsulation ethernet';
            inc(index);
            lines[index] := '  300 second input rate: 0 bits/sec, 0 packets/sec, 0.00% utilization';
            inc(index);
            lines[index] := '  300 second output rate: 0 bits/sec, 0 packets/sec, 0.00% utilization';
            inc(index);
            lines[index] := '  0 packets input, 0 bytes, 0 no buffer';
            inc(index);
            lines[index] := '  Received 0 broadcasts, 0 multicasts, 0 unicasts';
            inc(index);
            lines[index] := '  0 input errors, 0 CRC, 0 frame, 0 ignored';
            inc(index);
            lines[index] := '  0 runts, 0 giants';
            inc(index);
            lines[index] := '  0 packets output, 0 bytes, 0 underruns';
            inc(index);
            lines[index] := '  Transmitted 0 broadcasts, 0 multicasts, 0 unicasts';
            inc(index);
            lines[index] := '  0 output errors, 0 collisions';
            inc(index);
            lines[index] := '  Relay Agent Information option: Disabled';
            inc(index);
        End;
      lines[index] := 'ENDofLINES';
      page_display(lines);
  End;
  Procedure display_show_int_bri;

  var
    lines : array[1..385] of string;
    loop  : integer;

  Begin
       lines[1] := '';
       lines[2] := 'Port    Link      State  Dupl Speed Trunk Tag Pvid Pri MAC            Name';
       for loop := 1 to port_count do
         Begin
             if length(interfaces[loop].port_no) < 4 then
                lines[loop+2] := string(interfaces[loop].port_no) + '     '
             Else
               if length(interfaces[loop].port_no) < 5 then
                   lines[loop+2] := string(interfaces[loop].port_no) + '    '
               Else
                   lines[loop+2] := string(interfaces[loop].port_no) + '   ';
             if interfaces[loop].admin_disable = true then
                lines[loop+2] := lines[loop+2] + 'Disabled  None   None None  None  No  100  0   0012.f2cf.1200 '
             Else
                lines[loop+2] := lines[loop+2] + 'Down      None   None None  None  No  100  0   0012.f2cf.1200 ';
             //  show intrface brieft will only show the first 8 chars
             lines[loop+2] := lines[loop+2] + leftstr(interfaces[loop].descript,8);
         End;
       lines[loop+1] := 'ENDofLINES';
       page_display(lines);
  End;

  Procedure display_show_modules;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if modules[loop] = 'ENDofMODULES' then
             isend := true
          Else
              Begin
                  writeln(modules[loop]);
                  inc(loop)
              End;
    until isend = true;
  End;

  Procedure display_show_flash;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if flash[loop] = 'ENDofFLASH' then
             isend := true
          Else
              Begin
                  writeln(flash[loop]);
                  inc(loop)
              End;
    until isend = true;
  End;

  Procedure display_show_memory;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if show_memory[loop] = 'ENDofMEMORY' then
             isend := true
          Else
              Begin
                  writeln(show_memory[loop]);
                  inc(loop)
              End;
    until isend = true;
  End;

  Procedure display_show_port_security;

  var
    lines : array[1..360] of string;

  Begin


    lines[1] := 'Port    Security Violation Shutdown-Time Age-Time  Max-MAC';
    lines[2] := '------- -------- --------- ------------- --------- -------';
    lines[3] := '1/1     disabled  shutdown     permanent permanent       1';
    lines[4] := '1/2     disabled  shutdown     permanent permanent       1';
    lines[5] := '1/3     disabled  shutdown     permanent permanent       1';
    lines[6] := '1/4     disabled  shutdown     permanent permanent       1';
    lines[7] := '1/5     disabled  shutdown     permanent permanent       1';
    lines[8] := '1/6     disabled  shutdown     permanent permanent       1';
    lines[9] := '1/7     disabled  shutdown     permanent permanent       1';
    lines[10] := '1/8     disabled  shutdown     permanent permanent       1';
    lines[11] := '1/9     disabled  shutdown     permanent permanent       1';
    lines[12] := '1/10    disabled  shutdown     permanent permanent       1';
    lines[13] := '1/11    disabled  shutdown     permanent permanent       1';
    lines[14] := '1/12    disabled  shutdown     permanent permanent       1';
    lines[15] := '1/13    disabled  shutdown     permanent permanent       1';
    lines[16] := '1/14    disabled  shutdown     permanent permanent       1';
    lines[17] := '1/15    disabled  shutdown     permanent permanent       1';
    lines[18] := '1/16    disabled  shutdown     permanent permanent       1';
    lines[19] := '1/17    disabled  shutdown     permanent permanent       1';
    lines[20] := '1/18    disabled  shutdown     permanent permanent       1';
    lines[21] := '1/19    disabled  shutdown     permanent permanent       1';
    lines[22] := '1/20    disabled  shutdown     permanent permanent       1';
    lines[23] := '1/21    disabled  shutdown     permanent permanent       1';
    lines[24] := '1/22    disabled  shutdown     permanent permanent       1';
    lines[25] := '1/23    disabled  shutdown     permanent permanent       1';
    lines[26] := '1/24    disabled  shutdown     permanent permanent       1';
    lines[27] := '2/1     disabled  shutdown     permanent permanent       1';
    lines[28] := '2/2     disabled  shutdown     permanent permanent       1';
    lines[29] := '2/3     disabled  shutdown     permanent permanent       1';
    lines[30] := '2/4     disabled  shutdown     permanent permanent       1';
    lines[31] := '2/5     disabled  shutdown     permanent permanent       1';
    lines[32] := '2/6     disabled  shutdown     permanent permanent       1';
    lines[33] := '2/7     disabled  shutdown     permanent permanent       1';
    lines[34] := '2/8     disabled  shutdown     permanent permanent       1';
    lines[35] := '2/9     disabled  shutdown     permanent permanent       1';
    lines[36] := '2/10    disabled  shutdown     permanent permanent       1';
    lines[37] := '2/11    disabled  shutdown     permanent permanent       1';
    lines[38] := '2/12    disabled  shutdown     permanent permanent       1';
    lines[39] := '2/13    disabled  shutdown     permanent permanent       1';
    lines[40] := '2/14    disabled  shutdown     permanent permanent       1';
    lines[41] := '2/15    disabled  shutdown     permanent permanent       1';
    lines[42] := '2/16    disabled  shutdown     permanent permanent       1';
    lines[43] := '2/17    disabled  shutdown     permanent permanent       1';
    lines[44] := '2/18    disabled  shutdown     permanent permanent       1';
    lines[45] := '2/19    disabled  shutdown     permanent permanent       1';
    lines[46] := '2/20    disabled  shutdown     permanent permanent       1';
    lines[47] := '2/21    disabled  shutdown     permanent permanent       1';
    lines[48] := '2/22    disabled  shutdown     permanent permanent       1';
    lines[49] := '2/23    disabled  shutdown     permanent permanent       1';
    lines[50] := '2/24    disabled  shutdown     permanent permanent       1';
    lines[51] := '3/1     disabled  shutdown     permanent permanent       1';
    lines[52] := '3/2     disabled  shutdown     permanent permanent       1';
    lines[53] := '3/3     disabled  shutdown     permanent permanent       1';
    lines[54] := '3/4     disabled  shutdown     permanent permanent       1';
    lines[55] := '3/5     disabled  shutdown     permanent permanent       1';
    lines[56] := '3/6     disabled  shutdown     permanent permanent       1';
    lines[57] := '3/7     disabled  shutdown     permanent permanent       1';
    lines[58] := '3/8     disabled  shutdown     permanent permanent       1';
    lines[59] := '3/9     disabled  shutdown     permanent permanent       1';
    lines[60] := '3/10    disabled  shutdown     permanent permanent       1';
    lines[61] := '3/11    disabled  shutdown     permanent permanent       1';
    lines[62] := '3/12    disabled  shutdown     permanent permanent       1';
    lines[63] := '3/13    disabled  shutdown     permanent permanent       1';
    lines[64] := '3/14    disabled  shutdown     permanent permanent       1';
    lines[65] := '3/15    disabled  shutdown     permanent permanent       1';
    lines[66] := '3/16    disabled  shutdown     permanent permanent       1';
    lines[67] := '3/17    disabled  shutdown     permanent permanent       1';
    lines[68] := '3/18    disabled  shutdown     permanent permanent       1';
    lines[69] := '3/19    disabled  shutdown     permanent permanent       1';
    lines[70] := '3/20    disabled  shutdown     permanent permanent       1';
    lines[71] := '3/21    disabled  shutdown     permanent permanent       1';
    lines[72] := '3/22    disabled  shutdown     permanent permanent       1';
    lines[73] := '3/23    disabled  shutdown     permanent permanent       1';
    lines[74] := '3/24    disabled  shutdown     permanent permanent       1';
    lines[75] := '4/1     disabled  shutdown     permanent permanent       1';
    lines[76] := '4/2     disabled  shutdown     permanent permanent       1';
    lines[77] := '4/3     disabled  shutdown     permanent permanent       1';
    lines[78] := '4/4     disabled  shutdown     permanent permanent       1';
    lines[79] := '4/5     disabled  shutdown     permanent permanent       1';
    lines[80] := '4/6     disabled  shutdown     permanent permanent       1';
    lines[81] := '4/7     disabled  shutdown     permanent permanent       1';
    lines[82] := '4/8     disabled  shutdown     permanent permanent       1';
    lines[83] := '4/9     disabled  shutdown     permanent permanent       1';
    lines[84] := '4/10    disabled  shutdown     permanent permanent       1';
    lines[85] := '4/11    disabled  shutdown     permanent permanent       1';
    lines[86] := '4/12    disabled  shutdown     permanent permanent       1';
    lines[87] := '4/13    disabled  shutdown     permanent permanent       1';
    lines[88] := '4/14    disabled  shutdown     permanent permanent       1';
    lines[89] := '4/15    disabled  shutdown     permanent permanent       1';
    lines[90] := '4/16    disabled  shutdown     permanent permanent       1';
    lines[91] := '4/17    disabled  shutdown     permanent permanent       1';
    lines[92] := '4/18    disabled  shutdown     permanent permanent       1';
    lines[93] := '4/19    disabled  shutdown     permanent permanent       1';
    lines[94] := '4/20    disabled  shutdown     permanent permanent       1';
    lines[95] := '4/21    disabled  shutdown     permanent permanent       1';
    lines[96] := '4/22    disabled  shutdown     permanent permanent       1';
    lines[97] := '4/23    disabled  shutdown     permanent permanent       1';
    lines[98] := '4/24    disabled  shutdown     permanent permanent       1';
    lines[99] := '5/1     disabled  shutdown     permanent permanent       1';
    lines[100] := '5/2     disabled  shutdown     permanent permanent       1';
    lines[101] := '5/3     disabled  shutdown     permanent permanent       1';
    lines[102] := '5/4     disabled  shutdown     permanent permanent       1';
    lines[103] := '5/5     disabled  shutdown     permanent permanent       1';
    lines[104] := '5/6     disabled  shutdown     permanent permanent       1';
    lines[105] := '5/7     disabled  shutdown     permanent permanent       1';
    lines[106] := '5/8     disabled  shutdown     permanent permanent       1';
    lines[107] := '5/9     disabled  shutdown     permanent permanent       1';
    lines[108] := '5/10    disabled  shutdown     permanent permanent       1';
    lines[109] := '5/11    disabled  shutdown     permanent permanent       1';
    lines[110] := '5/12    disabled  shutdown     permanent permanent       1';
    lines[111] := '5/13    disabled  shutdown     permanent permanent       1';
    lines[112] := '5/14    disabled  shutdown     permanent permanent       1';
    lines[113] := '5/15    disabled  shutdown     permanent permanent       1';
    lines[114] := '5/16    disabled  shutdown     permanent permanent       1';
    lines[115] := '5/17    disabled  shutdown     permanent permanent       1';
    lines[116] := '5/18    disabled  shutdown     permanent permanent       1';
    lines[117] := '5/19    disabled  shutdown     permanent permanent       1';
    lines[119] := '5/20    disabled  shutdown     permanent permanent       1';
    lines[120] := '5/21    disabled  shutdown     permanent permanent       1';
    lines[121] := '5/22    disabled  shutdown     permanent permanent       1';
    lines[122] := '5/23    disabled  shutdown     permanent permanent       1';
    lines[123] := '5/24    disabled  shutdown     permanent permanent       1';
    lines[124] := '6/1     disabled  shutdown     permanent permanent       1';
    lines[125] := '6/2     disabled  shutdown     permanent permanent       1';
    lines[126] := '6/3     disabled  shutdown     permanent permanent       1';
    lines[127] := '6/4     disabled  shutdown     permanent permanent       1';
    lines[128] := '6/5     disabled  shutdown     permanent permanent       1';
    lines[129] := '6/6     disabled  shutdown     permanent permanent       1';
    lines[130] := '6/7     disabled  shutdown     permanent permanent       1';
    lines[131] := '6/8     disabled  shutdown     permanent permanent       1';
    lines[132] := '6/9     disabled  shutdown     permanent permanent       1';
    lines[133] := '6/10    disabled  shutdown     permanent permanent       1';
    lines[134] := '6/11    disabled  shutdown     permanent permanent       1';
    lines[135] := '6/12    disabled  shutdown     permanent permanent       1';
    lines[136] := '6/13    disabled  shutdown     permanent permanent       1';
    lines[137] := '6/14    disabled  shutdown     permanent permanent       1';
    lines[138] := '6/15    disabled  shutdown     permanent permanent       1';
    lines[139] := '6/16    disabled  shutdown     permanent permanent       1';
    lines[140] := '6/17    disabled  shutdown     permanent permanent       1';
    lines[141] := '6/18    disabled  shutdown     permanent permanent       1';
    lines[142] := '6/19    disabled  shutdown     permanent permanent       1';
    lines[143] := '6/20    disabled  shutdown     permanent permanent       1';
    lines[144] := '6/21    disabled  shutdown     permanent permanent       1';
    lines[145] := '6/22    disabled  shutdown     permanent permanent       1';
    lines[146] := '6/23    disabled  shutdown     permanent permanent       1';
    lines[147] := '6/24    disabled  shutdown     permanent permanent       1';
    lines[148] := '7/1     disabled  shutdown     permanent permanent       1';
    lines[149] := '7/2     disabled  shutdown     permanent permanent       1';
    lines[150] := '7/3     disabled  shutdown     permanent permanent       1';
    lines[151] := '7/4     disabled  shutdown     permanent permanent       1';
    lines[152] := '7/5     disabled  shutdown     permanent permanent       1';
    lines[153] := '7/6     disabled  shutdown     permanent permanent       1';
    lines[154] := '7/7     disabled  shutdown     permanent permanent       1';
    lines[155] := '7/8     disabled  shutdown     permanent permanent       1';
    lines[156] := '7/9     disabled  shutdown     permanent permanent       1';
    lines[157] := '7/10    disabled  shutdown     permanent permanent       1';
    lines[158] := '7/11    disabled  shutdown     permanent permanent       1';
    lines[159] := '7/12    disabled  shutdown     permanent permanent       1';
    lines[160] := '7/13    disabled  shutdown     permanent permanent       1';
    lines[161] := '7/14    disabled  shutdown     permanent permanent       1';
    lines[162] := '7/15    disabled  shutdown     permanent permanent       1';
    lines[163] := '7/16    disabled  shutdown     permanent permanent       1';
    lines[164] := '7/17    disabled  shutdown     permanent permanent       1';
    lines[165] := '7/18    disabled  shutdown     permanent permanent       1';
    lines[166] := '7/19    disabled  shutdown     permanent permanent       1';
    lines[167] := '7/20    disabled  shutdown     permanent permanent       1';
    lines[168] := '7/21    disabled  shutdown     permanent permanent       1';
    lines[169] := '7/22    disabled  shutdown     permanent permanent       1';
    lines[170] := '7/23    disabled  shutdown     permanent permanent       1';
    lines[171] := '7/24    disabled  shutdown     permanent permanent       1';
    lines[172] := '8/1     disabled  shutdown     permanent permanent       1';
    lines[173] := '8/2     disabled  shutdown     permanent permanent       1';
    lines[174] := '8/3     disabled  shutdown     permanent permanent       1';
    lines[175] := '8/4     disabled  shutdown     permanent permanent       1';
    lines[176] := '8/5     disabled  shutdown     permanent permanent       1';
    lines[177] := '8/6     disabled  shutdown     permanent permanent       1';
    lines[178] := '8/7     disabled  shutdown     permanent permanent       1';
    lines[179] := '8/8     disabled  shutdown     permanent permanent       1';
    lines[180] := '8/9     disabled  shutdown     permanent permanent       1';
    lines[181] := '8/10    disabled  shutdown     permanent permanent       1';
    lines[182] := '8/11    disabled  shutdown     permanent permanent       1';
    lines[183] := '8/12    disabled  shutdown     permanent permanent       1';
    lines[184] := '8/13    disabled  shutdown     permanent permanent       1';
    lines[185] := '8/14    disabled  shutdown     permanent permanent       1';
    lines[186] := '8/15    disabled  shutdown     permanent permanent       1';
    lines[187] := '8/16    disabled  shutdown     permanent permanent       1';
    lines[188] := '8/17    disabled  shutdown     permanent permanent       1';
    lines[189] := '8/18    disabled  shutdown     permanent permanent       1';
    lines[190] := '8/19    disabled  shutdown     permanent permanent       1';
    lines[191] := '8/20    disabled  shutdown     permanent permanent       1';
    lines[192] := '8/21    disabled  shutdown     permanent permanent       1';
    lines[193] := '8/22    disabled  shutdown     permanent permanent       1';
    lines[194] := '8/23    disabled  shutdown     permanent permanent       1';
    lines[195] := '8/24    disabled  shutdown     permanent permanent       1';
    lines[196] := '11/1    disabled  shutdown     permanent permanent       1';
    lines[197] := '11/2    disabled  shutdown     permanent permanent       1';
    lines[198] := '11/3    disabled  shutdown     permanent permanent       1';
    lines[199] := '11/4    disabled  shutdown     permanent permanent       1';
    lines[200] := '11/5    disabled  shutdown     permanent permanent       1';
    lines[201] := '11/6    disabled  shutdown     permanent permanent       1';
    lines[202] := '11/7    disabled  shutdown     permanent permanent       1';
    lines[203] := '11/8    disabled  shutdown     permanent permanent       1';
    lines[204] := '11/9    disabled  shutdown     permanent permanent       1';
    lines[205] := '11/10   disabled  shutdown     permanent permanent       1';
    lines[206] := '11/11   disabled  shutdown     permanent permanent       1';
    lines[207] := '11/12   disabled  shutdown     permanent permanent       1';
    lines[208] := '11/13   disabled  shutdown     permanent permanent       1';
    lines[209] := '11/14   disabled  shutdown     permanent permanent       1';
    lines[210] := '11/15   disabled  shutdown     permanent permanent       1';
    lines[211] := '11/16   disabled  shutdown     permanent permanent       1';
    lines[212] := '11/17   disabled  shutdown     permanent permanent       1';
    lines[213] := '11/18   disabled  shutdown     permanent permanent       1';
    lines[214] := '11/19   disabled  shutdown     permanent permanent       1';
    lines[215] := '11/20   disabled  shutdown     permanent permanent       1';
    lines[216] := '11/21   disabled  shutdown     permanent permanent       1';
    lines[217] := '11/22   disabled  shutdown     permanent permanent       1';
    lines[218] := '11/23   disabled  shutdown     permanent permanent       1';
    lines[219] := '11/24   disabled  shutdown     permanent permanent       1';
    lines[210] := '12/1    disabled  shutdown     permanent permanent       1';
    lines[211] := '12/2    disabled  shutdown     permanent permanent       1';
    lines[212] := '12/3    disabled  shutdown     permanent permanent       1';
    lines[213] := '12/4    disabled  shutdown     permanent permanent       1';
    lines[214] := '12/5    disabled  shutdown     permanent permanent       1';
    lines[215] := '12/6    disabled  shutdown     permanent permanent       1';
    lines[216] := '12/7    disabled  shutdown     permanent permanent       1';
    lines[217] := '12/8    disabled  shutdown     permanent permanent       1';
    lines[218] := '12/9    disabled  shutdown     permanent permanent       1';
    lines[219] := '12/10   disabled  shutdown     permanent permanent       1';
    lines[220] := '12/11   disabled  shutdown     permanent permanent       1';
    lines[221] := '12/12   disabled  shutdown     permanent permanent       1';
    lines[222] := '12/13   disabled  shutdown     permanent permanent       1';
    lines[223] := '12/14   disabled  shutdown     permanent permanent       1';
    lines[224] := '12/15   disabled  shutdown     permanent permanent       1';
    lines[225] := '12/16   disabled  shutdown     permanent permanent       1';
    lines[226] := '12/17   disabled  shutdown     permanent permanent       1';
    lines[227] := '12/18   disabled  shutdown     permanent permanent       1';
    lines[228] := '12/19   disabled  shutdown     permanent permanent       1';
    lines[229] := '12/20   disabled  shutdown     permanent permanent       1';
    lines[230] := '12/21   disabled  shutdown     permanent permanent       1';
    lines[231] := '12/22   disabled  shutdown     permanent permanent       1';
    lines[232] := '12/23   disabled  shutdown     permanent permanent       1';
    lines[233] := '12/24   disabled  shutdown     permanent permanent       1';
    lines[234] := '13/1    disabled  shutdown     permanent permanent       1';
    lines[235] := '13/2    disabled  shutdown     permanent permanent       1';
    lines[236] := '13/3    disabled  shutdown     permanent permanent       1';
    lines[237] := '13/4    disabled  shutdown     permanent permanent       1';
    lines[238] := '13/5    disabled  shutdown     permanent permanent       1';
    lines[239] := '13/6    disabled  shutdown     permanent permanent       1';
    lines[240] := '13/7    disabled  shutdown     permanent permanent       1';
    lines[241] := '13/8    disabled  shutdown     permanent permanent       1';
    lines[242] := '13/9    disabled  shutdown     permanent permanent       1';
    lines[243] := '13/10   disabled  shutdown     permanent permanent       1';
    lines[244] := '13/11   disabled  shutdown     permanent permanent       1';
    lines[245] := '13/12   disabled  shutdown     permanent permanent       1';
    lines[246] := '13/13   disabled  shutdown     permanent permanent       1';
    lines[247] := '13/14   disabled  shutdown     permanent permanent       1';
    lines[248] := '13/15   disabled  shutdown     permanent permanent       1';
    lines[249] := '13/16   disabled  shutdown     permanent permanent       1';
    lines[250] := '13/17   disabled  shutdown     permanent permanent       1';
    lines[251] := '13/18   disabled  shutdown     permanent permanent       1';
    lines[252] := '13/19   disabled  shutdown     permanent permanent       1';
    lines[253] := '13/20   disabled  shutdown     permanent permanent       1';
    lines[254] := '13/21   disabled  shutdown     permanent permanent       1';
    lines[255] := '13/22   disabled  shutdown     permanent permanent       1';
    lines[256] := '13/23   disabled  shutdown     permanent permanent       1';
    lines[257] := '13/24   disabled  shutdown     permanent permanent       1';
    lines[258] := '15/1    disabled  shutdown     permanent permanent       1';
    lines[259] := '15/2    disabled  shutdown     permanent permanent       1';
    lines[260] := '15/3    disabled  shutdown     permanent permanent       1';
    lines[261] := '15/4    disabled  shutdown     permanent permanent       1';
    lines[262] := '15/5    disabled  shutdown     permanent permanent       1';
    lines[263] := '15/6    disabled  shutdown     permanent permanent       1';
    lines[264] := '15/7    disabled  shutdown     permanent permanent       1';
    lines[265] := '15/8    disabled  shutdown     permanent permanent       1';
    lines[266] := '15/9    disabled  shutdown     permanent permanent       1';
    lines[267] := '15/10   disabled  shutdown     permanent permanent       1';
    lines[268] := '15/11   disabled  shutdown     permanent permanent       1';
    lines[269] := '15/12   disabled  shutdown     permanent permanent       1';
    lines[270] := '15/13   disabled  shutdown     permanent permanent       1';
    lines[271] := '15/14   disabled  shutdown     permanent permanent       1';
    lines[272] := '15/15   disabled  shutdown     permanent permanent       1';
    lines[273] := '15/16   disabled  shutdown     permanent permanent       1';
    lines[274] := '15/17   disabled  shutdown     permanent permanent       1';
    lines[275] := '15/18   disabled  shutdown     permanent permanent       1';
    lines[276] := '15/19   disabled  shutdown     permanent permanent       1';
    lines[277] := '15/20   disabled  shutdown     permanent permanent       1';
    lines[278] := '15/21   disabled  shutdown     permanent permanent       1';
    lines[279] := '15/22   disabled  shutdown     permanent permanent       1';
    lines[280] := '15/23   disabled  shutdown     permanent permanent       1';
    lines[281] := '15/24   disabled  shutdown     permanent permanent       1';
    lines[282] := '16/1    disabled  shutdown     permanent permanent       1';
    lines[283] := '16/2    disabled  shutdown     permanent permanent       1';
    lines[284] := '16/3    disabled  shutdown     permanent permanent       1';
    lines[285] := '16/4    disabled  shutdown     permanent permanent       1';
    lines[286] := '16/5    disabled  shutdown     permanent permanent       1';
    lines[287] := '16/6    disabled  shutdown     permanent permanent       1';
    lines[288] := '16/7    disabled  shutdown     permanent permanent       1';
    lines[289] := '16/8    disabled  shutdown     permanent permanent       1';
    lines[290] := '16/9    disabled  shutdown     permanent permanent       1';
    lines[291] := '16/10   disabled  shutdown     permanent permanent       1';
    lines[292] := '16/11   disabled  shutdown     permanent permanent       1';
    lines[293] := '16/12   disabled  shutdown     permanent permanent       1';
    lines[294] := '16/13   disabled  shutdown     permanent permanent       1';
    lines[295] := '16/14   disabled  shutdown     permanent permanent       1';
    lines[296] := '16/15   disabled  shutdown     permanent permanent       1';
    lines[297] := '16/16   disabled  shutdown     permanent permanent       1';
    lines[298] := '16/17   disabled  shutdown     permanent permanent       1';
    lines[299] := '16/18   disabled  shutdown     permanent permanent       1';
    lines[300] := '16/19   disabled  shutdown     permanent permanent       1';
    lines[301] := '16/20   disabled  shutdown     permanent permanent       1';
    lines[302] := '16/21   disabled  shutdown     permanent permanent       1';
    lines[303] := '16/22   disabled  shutdown     permanent permanent       1';
    lines[304] := '16/23   disabled  shutdown     permanent permanent       1';
    lines[305] := '16/24   disabled  shutdown     permanent permanent       1';
    lines[306] := '17/1    disabled  shutdown     permanent permanent       1';
    lines[307] := '17/2    disabled  shutdown     permanent permanent       1';
    lines[308] := '17/3    disabled  shutdown     permanent permanent       1';
    lines[309] := '17/4    disabled  shutdown     permanent permanent       1';
    lines[310] := '17/5    disabled  shutdown     permanent permanent       1';
    lines[312] := '17/6    disabled  shutdown     permanent permanent       1';
    lines[313] := '17/7    disabled  shutdown     permanent permanent       1';
    lines[314] := '17/8    disabled  shutdown     permanent permanent       1';
    lines[315] := '17/9    disabled  shutdown     permanent permanent       1';
    lines[316] := '17/10   disabled  shutdown     permanent permanent       1';
    lines[317] := '17/11   disabled  shutdown     permanent permanent       1';
    lines[318] := '17/12   disabled  shutdown     permanent permanent       1';
    lines[319] := '17/13   disabled  shutdown     permanent permanent       1';
    lines[320] := '17/14   disabled  shutdown     permanent permanent       1';
    lines[321] := '17/15   disabled  shutdown     permanent permanent       1';
    lines[322] := '17/16   disabled  shutdown     permanent permanent       1';
    lines[323] := '17/17   disabled  shutdown     permanent permanent       1';
    lines[324] := '17/18   disabled  shutdown     permanent permanent       1';
    lines[325] := '17/19   disabled  shutdown     permanent permanent       1';
    lines[326] := '17/20   disabled  shutdown     permanent permanent       1';
    lines[327] := '17/21   disabled  shutdown     permanent permanent       1';
    lines[328] := '17/22   disabled  shutdown     permanent permanent       1';
    lines[329] := '17/23   disabled  shutdown     permanent permanent       1';
    lines[330] := '17/24   disabled  shutdown     permanent permanent       1';
    lines[331] := '18/1    disabled  shutdown     permanent permanent       1';
    lines[332] := '18/2    disabled  shutdown     permanent permanent       1';
    lines[333] := '18/3    disabled  shutdown     permanent permanent       1';
    lines[334] := '18/4    disabled  shutdown     permanent permanent       1';
    lines[335] := '18/5    disabled  shutdown     permanent permanent       1';
    lines[336] := '18/6    disabled  shutdown     permanent permanent       1';
    lines[337] := '18/7    disabled  shutdown     permanent permanent       1';
    lines[338] := '18/8    disabled  shutdown     permanent permanent       1';
    lines[339] := '18/9    disabled  shutdown     permanent permanent       1';
    lines[340] := '18/10   disabled  shutdown     permanent permanent       1';
    lines[341] := '18/11   disabled  shutdown     permanent permanent       1';
    lines[342] := '18/12   disabled  shutdown     permanent permanent       1';
    lines[343] := '18/13   disabled  shutdown     permanent permanent       1';
    lines[344] := '18/14   disabled  shutdown     permanent permanent       1';
    lines[345] := '18/15   disabled  shutdown     permanent permanent       1';
    lines[346] := '18/16   disabled  shutdown     permanent permanent       1';
    lines[347] := '18/17   disabled  shutdown     permanent permanent       1';
    lines[348] := '18/18   disabled  shutdown     permanent permanent       1';
    lines[349] := '18/19   disabled  shutdown     permanent permanent       1';
    lines[350] := '18/20   disabled  shutdown     permanent permanent       1';
    lines[351] := '18/21   disabled  shutdown     permanent permanent       1';
    lines[352] := '18/22   disabled  shutdown     permanent permanent       1';
    lines[353] := '18/23   disabled  shutdown     permanent permanent       1';
    lines[354] := '18/24   disabled  shutdown     permanent permanent       1';
    lines[355] := 'ENDofLINES';
    page_display(lines);

  End;

  Procedure display_show_reload;

  Begin
    writeln('No scheduled reload');
  End;

  Procedure display_show_reserved_vlan;

  Begin
      Writeln('Reserved Purpose     Default   Re-assign   Current');
      Writeln(' CPU VLAN              4091       4091        4091');
      Writeln(' All Ports VLAN        4092       4092        4092');
  End;

  Procedure display_running_config;

  var
    loop : integer;
    isend : boolean;

  Begin
   { isend := false; loop := 1;
    repeat
          if running_config[loop] = 'End' then
             isend := true
          Else
              Begin
                  writeln(running_config[loop]);
                  inc(loop)
              End;
    until isend = true;
    writeln(running_config[loop]);}
    for loop := 1 to port_count do
         Begin
             if interfaces[loop].no_config = false then
             Begin
                writeln('interface eithernet ', interfaces[loop].port_no);
                if interfaces[loop].descript <> '' then
                   writeln(' port-name ', string(interfaces[loop].descript));
                if interfaces[loop].admin_disable = true then
                   writeln(' disbaled');
                if interfaces[loop].bpdu = true then
                    writeln(' stp-bdpu-guard');
                if interfaces[loop].root_guard = true then
                   writeln(' spanning-tree root-protect');
             End
         End;
    writeln('!');
    writeln('!');
    writeln('End');
  End;

  Procedure display_stp_protect;

  var
    lines        : array[1..385] of string;
    loop, index  : integer;

  Begin
       index := 1;
       lines[index] := '        Port    BPDU Drop Count';
       inc(index);
       for loop := 1 to port_count do
         Begin
             if interfaces[loop].bpdu = true then
              Begin
                if length(interfaces[loop].port_no) < 4 then
                      lines[index] := '        ' + string(interfaces[loop].port_no) + '     0'
                Else
                     if length(interfaces[loop].port_no) < 5 then
                         lines[index] := '        ' + string(interfaces[loop].port_no) + '    0'
                     Else
                         lines[index] := '        ' + string(interfaces[loop].port_no) + '   0';
                inc(index);
              End;
         End;
       lines[index] := 'ENDofLINES';
       page_display(lines);
  End;

  Procedure display_startup_config;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if startup_config[loop] = 'end' then
             isend := true
          Else
              Begin
                  writeln(startup_config[loop]);
                  inc(loop)
              end;
    until isend = true;
    writeln(startup_config[loop]);
  End;


  Procedure display_show_telnet;

  Begin
      writeln('Console connections:');
      writeln('        established, monitor enabled');
      writeln('        78 days 17 hours 4 minutes 48 seconds in idle');
      writeln('Telnet connections (inbound):');
      writeln(' 1      closed');
      writeln(' 2      closed');
      writeln(' 3      closed');
      writeln(' 4      closed');
      writeln(' 5      closed');
      writeln('Telnet connection (outbound):');
      writeln(' 6      closed');
      writeln('SSH connections:');
      writeln('1	closed');
      writeln('2	closed');
      writeln(' 3      closed');
      writeln(' 4      closed');
      writeln(' 5      closed');
  End;

  Procedure display_show_version;

  Begin
    page_display(code_version);
  End;

  Procedure display_show_web;

  Begin
       writeln('No WEB-MANAGEMENT sessions are currently established!');
  End;

  Procedure display_show_who;

  Begin
    writeln('Console connections:');
    writeln('        established, monitor enabled');
    writeln('        60 days 9 hours 11 minutes 2 seconds in idle');
    writeln('Telnet connections (inbound):');
    writeln(' 1      closed');
    writeln(' 2      closed');
    writeln(' 3      closed');
    writeln(' 4      closed');
    writeln(' 5      closed');
    writeln('Telnet connection (outbound):');
    writeln(' 6      closed');
    writeln('SSH connections:');
    writeln(' 1      closed');
    writeln(' 2      closed');
    writeln(' 3      closed');
    writeln(' 4      closed');
    writeln(' 5      closed');
  end;

  Procedure display_show;

  var
     strLength, word_count, a : integer;
     word_list : array[1..10] of string;
     show_input : string;

  Begin
        a := 1; word_count := 1;
        show_input := input;
        strlength := length(show_input);
        while (show_input[a] <> '') and (a <= strlength)do
          Begin
               while (show_input[a] <> ' ') and (a <= strlength)do
                 Begin
                     word_list[word_count] := word_list[word_count] + show_input[a];
                     if show_input[a] <> '' then
                        Begin
                            inc(a);
                        end
                     Else
                        break;
                 End;
               inc(a);
               inc(word_count);
          end;
//        if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'interface') = TRUE)and (word_list[3] ='') and (out_key = #9) then //tab key
//           tab_match2(3,word_list[3],int_eth_menu)
//        Else
        case show_input[1] of
           's' : if (show_input = 'sh') or (show_input = 'sho') or (show_input = 'show') then
                               writeln('Incomplete command.')
                 Else
                 if (show_input = 'sh ?') or (show_input = 'sho ?') or (show_input = 'show ?') then
                    page_Display(show_menu)
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_help(word_list[2]) = TRUE) then
                    Begin
                      display_help_match(word_list[2]);
                    end
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'arp') = TRUE) then
                    display_show_arp
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'boot-preference') = TRUE) then
                    display_show_boot_pref
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'clock') = TRUE) then
                    display_show_clock
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'chassis') = TRUE) then
                    page_display(chassis)
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'cpu-utilization') = TRUE) then
                    display_show_cpu
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'defaults') = TRUE) then
                    display_show_defaults
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'dot1x') = TRUE) then
                    display_show_dot1x
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'errdisable') = TRUE) and (word_list[3] = '') then
                  Writeln('Incomplete command.')
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'errdisable') = TRUE) and (word_list[3] = '?') then
                    Begin
                        Writeln('  recovery   Error disable recovery');
                        Writeln('  summary    Error disable summary')
                    end
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'errdisable') = TRUE) and (is_word(word_list[3],'summary') = TRUE)then
                    writeln
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'errdisable') = TRUE) and (is_word(word_list[3],'recovery') = TRUE)then
                    display_show_errdisabled_recovery
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'fdp') = TRUE) then
                    display_show_fdp
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'flash') = TRUE) then
                    display_show_flash
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'interface') = TRUE) and (is_word(word_list[3],'ethernet') = TRUE)then
                    Begin
                        if check_int(shortstring(word_list[4])) = true then
                           display_show_int_eth(shortstring(word_list[4]))
                        Else
                          Writeln('port not valid');
                    end
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'interfaces') = TRUE) and (is_word(word_list[3],'brief') = TRUE)then
                    display_show_int_bri
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'interfaces') = TRUE) then
                    display_show_int
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'modules') = TRUE) then
                    display_show_modules
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'memory') = TRUE) then
                    display_show_memory
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'port') = TRUE) and (is_word(word_list[3],'security') = TRUE) then
                    display_show_port_security
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'reload') = TRUE) then
                    display_show_reload
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'reserved-vlan-map') = TRUE) then
                    display_show_reserved_vlan
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'configuration') = TRUE) then
                    display_startup_config
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'running-config') = TRUE) then
                    Begin
                        if word_list[2,1] ='r' then
                            begin
                              page_display(running_config);
                              display_running_config;
                            end
                    End
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'stp-protect') = TRUE) then
                    display_stp_protect
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'telnet') = TRUE) then
                    display_show_telnet
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'version') = TRUE) then
                    display_show_version
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'web-connection') = TRUE) then
                    display_show_web
                 Else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'who') = TRUE) then
                    display_show_who
                 Else
                    Begin
                      bad_command(show_input);
                     end;
        End;
  End; // of display_show

  Procedure vlan_loop(vlanid :string);

  var
     end_vlan_loop : boolean;

  Begin
        end_vlan_loop := false;
        input := input;
        Inc(what_level);
        level := level5 + vlanid + ')#';
        repeat
            repeat
                write(hostname, level);
//                input := get_command;
                get_input(input,out_key);
                writeln;
            until input <> '';
            word_list[1] := ''; word_list[2] := ''; word_list[3] := ''; word_list[4] := ''; word_list[5] := '';
            get_words;
            if (is_help(word_list[1]) = true) and (length(word_list[1]) > 1) then
                Begin
                   help_match(word_list[1], vlan_menu)
                End
             Else
             if ((is_word(word_list[1],'tagged')) = true) and (out_key = #9) then //tab key
                //tab_match(word_list[1],vlan_menu)
                writeln('ethernet')
             Else
             if out_key = #9 then //tab key
                tab_match(word_list[1],vlan_menu)
            Else
                case input[1] of
                 '?' : page_display(vlan_menu);
                 'e' : if (input = 'ex') or (input = 'exi') or (input = 'exit')then
                       Begin
                          level := level3;
                          dec(what_level);
                          end_vlan_loop := true;
                       End;
                 's' : if (input = 'sh') or (input = 'sho') or (input = 'show') then
                          writeln('Incomplete command.')
                       Else
                          Begin
                            input := input;
                            display_show;
                          end;
                 't' : if (is_word(word_list[1],'tagged')) = true then
                       Begin
                          if (is_word(word_list[2],'ethernet')) = true then
                            write('TAG ethernet')
                          Else
                            bad_command(input);
                       End;
                 'q' : if (input = 'qu') or (input = 'qui') or (input = 'quit')then
                       Begin
                          level := level3;
                          dec(what_level);
                          end_vlan_loop := true;
                       End;
                 'u' : if (is_word(word_list[1],'untag')) = true then
                       Begin
                          if (is_word(word_list[2],'ethernet')) = true then
                            write('UNTAG ethernet')
                          Else
                            bad_command(input);
                       End;
                 Else
                       Begin
                          bad_command(input);
                       end;
          end;
        until end_vlan_loop = true;
  end; // of vlan_loop



  Procedure int_loop(intid : string);

  var
     find_int     : integer;
     end_int_loop : boolean;

    Procedure remove_config;

    var
       find_int     : integer;

    Begin
            case input[4] of
             '?' : page_display(interface_menu);
             'd' : if (is_word(word_list[1],'disable')) = true then
                      Begin
                           for find_int := 1 to port_count do
                               if interfaces[find_int].port_no = shortstring(intid) then
                                  Begin
                                    interfaces[find_int].admin_disable := true;
                                    interfaces[find_int].no_config := false;
                                  end;
                      end;
             'i' : if (is_word(word_list[1],'interface') = true) and (is_word(word_list[2],'ethernet') = true) then
                      Begin
                           if check_int(shortstring(word_list[3])) = true then
                               intid := word_list[3]
                            Else
                               writeln('port not valid');
                      end;
             'p' : if (is_word(word_list[2],'port-name')) = true then
                      Begin
                           for find_int := 1 to port_count do
                               if interfaces[find_int].port_no = shortstring(intid) then
                                  Begin
                                      interfaces[find_int].no_config := true;
                                  End;
                      end;
             's' : if (input = 'sh') or (input = 'sho') or (input = 'show') then
                                 writeln('Incomplete command.')
                   Else
                    if (is_word(word_list[1],'stp-bpdu-guard')) = true then
                      Begin
                           for find_int := 1 to port_count do
                               if interfaces[find_int].port_no = shortstring(intid) then
                                  Begin
                                    interfaces[find_int].bpdu := true;
                                    interfaces[find_int].no_config := false;
                                  end;
                      end
                    Else
                    if (is_word(word_list[1],'spanning-tree') = true) and (is_word(word_list[2],'root-protect') = true)then
                      Begin
                           for find_int := 1 to port_count do
                               if interfaces[find_int].port_no = shortstring(intid) then
                                  Begin
                                    interfaces[find_int].root_guard := true;
                                    interfaces[find_int].no_config := false;
                                  End;
                      end
                    Else
                     if (is_word(word_list[1],'speed-duplex')) = true then
                        Begin
                             if (is_word(word_list[2],'10-full')) = true then
                                 Begin
                                    for find_int := 1 to port_count do
                                       if interfaces[find_int].port_no = shortstring(intid) then
                                          interfaces[find_int].speed := '10-full';
                                 end;
                             if (is_word(word_list[2],'10-half')) = true then
                                 Begin
                                    for find_int := 1 to port_count do
                                       if interfaces[find_int].port_no = shortstring(intid) then
                                          interfaces[find_int].speed := '10-half';
                                 end;
                             if (is_word(word_list[2],'100-half')) = true then
                                 Begin
                                    for find_int := 1 to port_count do
                                       if interfaces[find_int].port_no = shortstring(intid) then
                                          interfaces[find_int].speed := '100-half';
                                 end;
                             if (is_word(word_list[2],'100-full')) = true then
                                 Begin
                                    for find_int := 1 to port_count do
                                       if interfaces[find_int].port_no = shortstring(intid) then
                                          interfaces[find_int].speed := '100-full';
                                 end;
                             if (is_word(word_list[2],'1000-full-master')) = true then
                                 Begin
                                    for find_int := 1 to port_count do
                                       if interfaces[find_int].port_no = shortstring(intid) then
                                          interfaces[find_int].speed := '1000-full-master';
                                 end;
                             if (is_word(word_list[2],'1000-full-slave')) = true then
                                 Begin
                                    for find_int := 1 to port_count do
                                       if interfaces[find_int].port_no = shortstring(intid) then
                                          interfaces[find_int].speed := '1000-full-slave';
                                 end;
                             if (is_word(word_list[2],'auto')) = true then
                                 Begin
                                    for find_int := 1 to port_count do
                                       if interfaces[find_int].port_no = shortstring(intid) then
                                          interfaces[find_int].speed := 'auto';
                                 end;
                        end
                     Else
                        Begin
                          input := input;
                          display_show;
                        end;
             'n' : if (is_word(word_list[1],'no') = true) and (is_word(word_list[2],'stp-bpdu-guard') = true) then
                      Begin
                           for find_int := 1 to port_count do
                               if interfaces[find_int].port_no = shortstring(intid) then
                                  interfaces[find_int].bpdu := false;
                      end
                   Else
                   if (is_word(word_list[1],'no') = true) and (is_word(word_list[2],'spanning-tree') = true) and (is_word(word_list[3],'root-protect') = true)then
                      Begin
                           for find_int := 1 to port_count do
                               if interfaces[find_int].port_no = shortstring(intid) then
                                  interfaces[find_int].root_guard := false;
                      end;
             'q' : if (input = 'qu') or (input = 'qui') or (input = 'quit')then
                       Begin
                          level := level3;
                          dec(what_level);
                          end_int_loop := true;
                       End;
            'e' : if (input = 'ex') or (input = 'exi') or (input = 'exit')then
                       Begin
                          level := level3;
                          dec(what_level);
                          end_int_loop := true;
                       End
                    Else
                       if (is_word(word_list[1],'enable')) = true then
                          Begin
                             for find_int := 1 to port_count do
                               if interfaces[find_int].port_no = shortstring(intid) then
                                  interfaces[find_int].admin_disable := false
                          end;
            #0 :;
            Else
                      Begin
                        bad_command(input);
                      end;
            end;
    end;

  Begin
        end_int_loop := false;
        input := input;
        Inc(what_level);
        input := #0;
        repeat
          level := level4 + intid + ')#';
          word_list[1] := ''; word_list[2] := ''; word_list[3] := '';
          word_list[4] := ''; word_list[5] := '';
          repeat
            write(hostname, level);
            get_input(input,out_key);
            writeln;
          until input <> '';
          get_words;
          if (is_help(word_list[1]) = true) and (length(word_list[1]) > 1) then
             Begin
                help_match(word_list[1], interface_menu)
             End
          Else
             if out_key = #9 then //tab key
                tab_match(word_list[1],interface_menu)
          Else
          case input[1] of
           '?' : page_display(interface_menu);
           'd' : if (is_word(word_list[1],'disable')) = true then
                    Begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                Begin
                                  interfaces[find_int].admin_disable := true;
                                  interfaces[find_int].no_config := false;
                                end;
                    end;
           'i' : if (is_word(word_list[1],'interface') = true) and (is_word(word_list[2],'ethernet') = true) then
                    Begin
                         if check_int(shortstring(word_list[3])) = true then
                             intid := word_list[3]
                          Else
                             writeln('port not valid');
                    end;
           'p' : if (is_word(word_list[1],'port-name')) = true then
                    Begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                Begin
                                    interfaces[find_int].descript := word_list[2];
                                    interfaces[find_int].no_config := false;
                                End;
                    end;
           's' : if (input = 'sh') or (input = 'sho') or (input = 'show') then
                               writeln('Incomplete command.')
                 Else
                  if (is_word(word_list[1],'stp-bpdu-guard')) = true then
                    Begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                Begin
                                  interfaces[find_int].bpdu := true;
                                  interfaces[find_int].no_config := false;
                                end;
                    end
                  Else
                  if (is_word(word_list[1],'spanning-tree') = true) and (is_word(word_list[2],'root-protect') = true)then
                    Begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                Begin
                                  interfaces[find_int].root_guard := true;
                                  interfaces[find_int].no_config := false;
                                End;
                    end
                  Else
                   if (is_word(word_list[1],'speed-duplex')) = true then
                      Begin
                           if (is_word(word_list[2],'10-full')) = true then
                               Begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '10-full';
                               end;
                           if (is_word(word_list[2],'10-half')) = true then
                               Begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '10-half';
                               end;
                           if (is_word(word_list[2],'100-half')) = true then
                               Begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '100-half';
                               end;
                           if (is_word(word_list[2],'100-full')) = true then
                               Begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '100-full';
                               end;
                           if (is_word(word_list[2],'1000-full-master')) = true then
                               Begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '1000-full-master';
                               end;
                           if (is_word(word_list[2],'1000-full-slave')) = true then
                               Begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '1000-full-slave';
                               end;
                           if (is_word(word_list[2],'auto')) = true then
                               Begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := 'auto';
                               end;
                      end
                   Else
                      Begin
                        input := input;
                        display_show;
                      end;
           'n' : if (is_word(word_list[1],'no') = true) and (is_word(word_list[2],'stp-bpdu-guard') = true) then
                    Begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                interfaces[find_int].bpdu := false;
                    end
                 Else
                 if (is_word(word_list[1],'no') = true) and (is_word(word_list[2],'spanning-tree') = true) and (is_word(word_list[3],'root-protect') = true)then
                    Begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                interfaces[find_int].root_guard := false;
                    end
                 Else
                 if (is_word(word_list[1],'no') = true) then
                    remove_config;
           'q' : if (input = 'qu') or (input = 'qui') or (input = 'quit')then
                     Begin
                        level := level3;
                        dec(what_level);
                        end_int_loop := true;
                     End;
          'e' : if (input = 'ex') or (input = 'exi') or (input = 'exit')then
                     Begin
                        level := level3;
                        dec(what_level);
                        end_int_loop := true;
                     End
                  Else
                     if (is_word(word_list[1],'enable')) = true then
                        Begin
                           for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                interfaces[find_int].admin_disable := false
                        end;
          #0 :;
          Else
                    Begin
                      bad_command(input);
                    end;
          end;
        until end_int_loop = true;
  end;


  Procedure configure_term_loop;

  var
     end_con_term : boolean;
     foundat : integer;

     Procedure looking_for_help;

     Begin
          if is_help(word_list[1]) = true then
             Begin
               writeln('  vlan                          VLAN settings');
               writeln('  vlan-group                    VLAN group settings');
             end
          Else
             if is_help(word_list[2]) = true then
                writeln('Unrecognized command')
             Else
                if is_help(word_list[3]) = true then
                  Begin
                    if length(word_list[3]) = 1 then
                      Begin
                        writeln('  by     VLAN type');
                        writeln('  name   VLAN name');
                        writeln('  <cr>');
                       end
                    Else
                      if (word_list[3] = 'b?') or (word_list[3] = 'by?') then
                         writeln('  by     VLAN type')
                      Else
                         if (word_list[3] = 'n?') or (word_list[3] = 'na?') or (word_list[3] = 'nam?') or (word_list[3] = 'name?') then
                            writeln('  name   VLAN name');
                  End
                Else
                  if (word_list[4]) = '?' then
                     writeln('  ASCII string   VLAN name');
     end; // looking for help

     Procedure remove_config;

     Begin
        case input[4] of
           '?' : page_display(config_term_menu);
           'a' : if (is_word(word_list[1],'aaa') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(aaa_menu)
                 Else
                 if (is_word(word_list[1],'access-list') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(access_list_menu)
                 Else
                    writeln('Incomplete command.');
           'b' : if (is_word(word_list[1],'banner') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(banner_menu)
                 Else
                 if (is_word(word_list[2],'boot') = TRUE) and (is_word(word_list[3],'system') = TRUE) and (is_word(word_list[4],'flash') = TRUE) and (is_word(word_list[5],'primary') = TRUE) then
                    Begin
                       search_run('boot system flash primary',foundat);
                           if foundat <> 0 then
                              Begin
                                   running_config[foundat] := 'DELETED';
                                  // hostname := 'Fastiron';
                              end;
                    end
                 else
                 if (is_word(word_list[2],'boot') = TRUE) and (is_word(word_list[3],'system') = TRUE) and (is_word(word_list[4],'flash') = TRUE) and (is_word(word_list[5],'secondary') = TRUE) then
                    Begin
                       search_run('boot system flash secondary',foundat);
                           if foundat <> 0 then
                              Begin
                                   running_config[foundat] := 'DELETED';
                                  // hostname := 'Fastiron';
                              end;
                    end
                 Else
                    writeln('Incomplete command.');
           'c' : if (is_word(word_list[2],'chassis') = TRUE) and (is_word(word_list[3],'?') = TRUE) then
                    page_display(chassis_menu)
                 Else
                 if (is_word(word_list[2],'clear') = TRUE) and (is_word(word_list[3],'?') = TRUE) then
                    page_display(clear_menu)
                 Else
                 if (is_word(word_list[2],'cdp') = TRUE) and (word_list[3] = '?') then
                    writeln('Run')
                 else
                 if (is_word(word_list[2],'console') = TRUE) and (is_word(word_list[3],'timeout')) then
                    Begin
                       search_run('console timeout',foundat);
                       if foundat <> 0 then
                          Begin
                              running_config[foundat] := 'DELETED';
                          end;
                    end
                 Else
                 if (is_word(word_list[2],'cdp') = TRUE) and (is_word(word_list[3],'run') = TRUE) then
                    Begin
                       search_run('cdp run',foundat);
                           if foundat <> 0 then
                              Begin
                                   running_config[foundat] := 'DELETED';
                                  // hostname := 'Fastiron';
                              end;
                    end
                  Else
                    writeln('Incomplete command.');
           'e' : if is_word(word_list[1], 'exit') = true then
                     Begin
                        level := level2;
                        dec(what_level);
                        End_con_term := true;
                     End;
           'f' : if (is_word(word_list[2],'fast') = TRUE) and (is_word(word_list[3],'?') = TRUE) then
                    page_display(fast_menu)
                 Else
                 if (is_word(word_list[2],'fdp') = TRUE) and (is_word(word_list[3],'?') = TRUE) then
                    page_display(fdp_menu)
                 Else
                 if (is_word(word_list[2],'fdp') = TRUE) and (is_word(word_list[3],'run') = TRUE) then
                    Begin
                          search_run('fdp run',foundat);
                          if foundat <> 0 then
                              Begin
                                   running_config[foundat] := 'DELETED';
                              end;
                    end
                 Else
                    writeln('Incomplete command.');
           'h' :  if (is_word(word_list[2],'hostname') = TRUE) then
                     if word_list[2] <> '' then
                        Begin
                           search_run('hostname',foundat);
                           if foundat <> 0 then
                              Begin
                                   running_config[foundat] := 'DELETED';
                                   hostname := 'Fastiron';
                              end;
                        end
                     Else
                        writeln('Incomplete command.');
           'i' : if (is_word(word_list[1],'interface') = TRUE) and (is_word(word_list[2],'ethernet') = TRUE) then
                     Begin
                          if check_int(shortstring(word_list[3])) = true then
                             int_loop(word_list[3])
                          Else
                             writeln('port not valid');
                     end
                 Else
                 if (is_word(word_list[1],'ip') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(ip_menu)
                 Else
                     writeln('Incomplete command.');
           'l' : if (is_word(word_list[2],'lldp') = TRUE) and (is_word(word_list[3],'?') = TRUE) then
                    page_display(lldp_menu)
                 Else
                 if (is_word(word_list[2],'lldp') = TRUE) and (is_word(word_list[3],'run') = TRUE) then
                    begin
                        search_run('lldp run',foundat);
                        if foundat <> 0 then
                           Begin
                                running_config[foundat] := 'DELETED';
                           end;
                    end
                 Else
                 if (is_word(word_list[2],'link-keepalive') = TRUE) and (is_word(word_list[3],'?') = TRUE) then
                    page_display(link_keepalive_menu)
                 Else
                 if (is_word(word_list[2],'link-config') = TRUE) and ((is_word(word_list[3],'?') = TRUE) or (out_key = #9)) then
                    tab_match2(3,word_list[3],link_config_menu)
                 Else
                 if (is_word(word_list[2],'logging') = TRUE) and ((is_word(word_list[3],'?') = TRUE) or (out_key = #9)) then
                    begin
                          if input[length(input)] = ' ' then
                             tab_match2(3,word_list[3],logging_menu)
                          else
                             if word_list[3] = '?' then
                                page_display(logging_menu)
                             else
                                if (word_list[2] = 'logging') or (word_list[3] <> '') then
                                   tab_match2(3,word_list[3],logging_menu)
                                else
                                    tab_match2(2,word_list[2],config_term_menu)
                    end
                 Else
                 if (is_word(word_list[2],'logging') = TRUE) and (is_word(word_list[3],'host') = TRUE) then
                    begin
                      if word_list[4] <> '' then
                        Begin
                           search_run(concat('logging host ',word_list[4]),foundat);
                           if foundat <> 0 then
                              running_config[foundat] := 'DELETED';
                        end
                    end
                 Else
                 if (is_word(word_list[2],'logging') = TRUE) and (is_word(word_list[3],'persistence') = TRUE) then
                    begin
                         search_run('logging persistence',foundat);
                         if foundat <> 0 then
                            running_config[foundat] := 'DELETED';
                    end
                 Else
                 if (is_word(word_list[2],'logging') = TRUE) and (is_word(word_list[3],'console') = TRUE) then
                    begin
                           search_run('logging console',foundat);
                           if foundat <> 0 then
                              Begin
                                   running_config[foundat] := 'DELETED';
                              end;
                    end
                 Else
                    writeln('Incomplete command.');
           'm' : if (is_word(word_list[1],'mstp') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(mstp_menu)
                 Else
                 if (is_word(word_list[1],'mac-authentication') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(mac_authentication_menu)
                 Else
                    writeln('Incomplete command.');
           'q' : if is_word(word_list[1],'quit') = true then
                     Begin
                        level := level2;
                        dec(what_level);
                        end_con_term := true;
                     End
                 Else
                 if (is_word(word_list[1],'qos') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(qos_menu)
                 Else
                    writeln('Incomplete command.');
           'r' : Begin
                    if (is_word(word_list[2],'rmon') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                        page_display(rmon_menu);
                    if (is_word(word_list[2],'router') = true) and (is_word(word_list[3],'?') = true)then
                       Begin
                           writeln('  rip    Enable rip');
                           writeln('  vrrp   Enable vrrp');
                       End;
                    if (is_word(word_list[3],'router') = true) and (is_word(word_list[3],'rip') = true) and (is_word(word_list[4],'?') = true) then
                       writeln('rip    Enable rip')
                    Else
                    if (is_word(word_list[2],'router') = true) and (is_word(word_list[3],'vrrp') = true) and (is_word(word_list[4],'?') = true) then
                       writeln('vrrp    Enable vrrp')
                    Else
                       if (is_word(word_list[2],'router') = true) and (is_word(word_list[3],'rip') = true) and (word_list[4] = '') then
                         Begin
                           search_run(concat('router rip',word_list[4]),foundat);
                           if foundat <> 0 then
                              Begin
                                   running_config[foundat] := 'DELETED';
                              end;
                         End
                    Else
                       if (is_word(word_list[2],'router') = true) and (is_word(word_list[3],'vrrp') = true) and (word_list[4] = '') then
                         Begin
                           search_run(concat('router vrrp',word_list[4]),foundat);
                           if foundat <> 0 then
                              Begin
                                   running_config[foundat] := 'DELETED';
                              end;
                         End
                    //Else
                    //   bad_command(word_list[3]);
                 End;
           's' : if (is_word(word_list[2],'snmp-server') = TRUE) and ((is_word(word_list[3],'?') = TRUE) or (out_key = #9)) then
                    begin
                          if input[length(input)] = ' ' then
                             tab_match2(3,word_list[3],snmp_server_menu)
                          else
                             if word_list[3] = '?' then
                                page_display(snmp_server_menu)
                             else
                                if (word_list[2] = 'snmp-server') or (word_list[3] <> '') then
                                   tab_match2(3,word_list[3],snmp_server_menu)
                                else
                                    tab_match2(2,word_list[2],config_term_menu)
                    end
                 Else
                 if (is_word(word_list[2],'snmp-server') = TRUE) and (is_word(word_list[3],'host') = TRUE) then
                    if word_list[3] <> '' then
                        Begin
                           search_run(concat('SNMP-Server Host ',word_list[4]),foundat);
                           if foundat <> 0 then
                              Begin
                                   running_config[foundat] := 'DELETED';
                              end;
                        end
                     Else
                        writeln('Incomplete command.')
                 Else
                 if (is_word(word_list[2],'snmp-server') = TRUE) and (is_word(word_list[3],'location') = TRUE) then
                    if word_list[3] <> '' then
                        Begin
                           search_run('SNMP-Server location ',foundat);
                           if foundat <> 0 then
                              Begin
                                   running_config[foundat] := 'DELETED';
                              end;
                        end
                     Else
                        writeln('Incomplete command.')
                 Else
                 if (is_word(word_list[2],'sntp') = TRUE) and ((is_word(word_list[3],'?') = TRUE) or (out_key = #9)) then
                     begin
                          if input[length(input)] = ' ' then
                             tab_match2(3,word_list[3],sntp_menu)
                          else
                             if word_list[3] = '?' then
                                page_display(sntp_menu)
                             else
                                if (word_list[2] = 'sntp') or (word_list[3] <> '') then
                                   tab_match2(3,word_list[3],sntp_menu)
                                else
                                    tab_match2(2,word_list[2],config_term_menu)
                     end
                 else
                 if (is_word(word_list[2],'sntp') = TRUE) and (is_word(word_list[3],'poll-interval') = TRUE) then
                    begin
                         search_run('sntp poll-interval '+word_list[4],foundat);
                         if foundat <> 0 then
                            running_config[foundat] := 'DELETED';
                    end
                 else
                 if (is_word(word_list[2],'sntp') = TRUE) and (is_word(word_list[3],'server') = TRUE) then
                    begin
                         search_run('sntp server '+word_list[4],foundat);
                         if foundat <> 0 then
                            running_config[foundat] := 'DELETED';
                    end
                 Else
                     Begin
                         input := input;
                         display_show;
                     End;
          'v' : ;
          'w' : ;
           Else
                    Begin
                      bad_command(input);
                    End;
         End;
     end;

  Begin //configure_term_loop
        end_con_term := false;
        Inc(what_level);
        level := level3;
        repeat
          word_list[1] := ''; word_list[2] := ''; word_list[3] := ''; word_list[4] := '';
          repeat
            write(hostname, level);
            get_input(input,out_key);
            writeln;
          until input <> '';
         get_words;
         if (is_help(word_list[1]) = true) and (length(word_list[1]) > 1) then
           Begin
                help_match(word_list[1], config_term_menu);
           End;
           if is_word(word_list[1],'boot') and is_word(word_list[2],'system') and is_word(word_list[3],'flash') and (length(word_list[3]) > 1)and (out_key = #9)then
              Begin
                tab_match2(4,word_list[4],boot_menu2)
              End
           Else
           if is_word(word_list[1],'boot') and is_word(word_list[2],'system') and (length(word_list[2]) > 1)and (out_key = #9)then
              Begin
                if word_list[3] <> '' then
                  tab_match2(3,word_list[3],boot_menu1)
                else
                  tab_match2(2,word_list[2],boot_menu)
              End
           Else
           if is_word(word_list[1],'boot') and (length(word_list[1]) > 3) and (out_key = #9)then
              Begin
                tab_match(word_list[2],boot_menu)
              End
           Else
           if (word_list[1] = 'ip' = TRUE) and (length(input) > 2) and (out_key = #9) then //tab key
                    tab_match(word_list[2],ip_menu)
           Else
           if (is_word(word_list[1],'lldp') = TRUE) and (length(input) = 5) and (out_key = #9) then //tab key
                    tab_match(word_list[2],lldp_menu)
           Else
           if (is_word(word_list[1],'lldp') = TRUE) and (length(input) > 5) and (out_key = #9) then //tab key
                    tab_match(word_list[2],lldp_menu)
           Else
           if (is_word(word_list[1],'mstp') = TRUE) and (length(input) = 5) and (out_key = #9) then //tab key
                    tab_match(word_list[2],mstp_menu)
           Else
           if (is_word(word_list[1],'mstp') = TRUE) and (length(input) > 5) and (out_key = #9) then //tab key
                    tab_match(word_list[2],mstp_menu)
           Else
           if (is_word(word_list[1],'sntp') = TRUE) and (length(input) = 5) and (out_key = #9) then //tab key
                    tab_match(word_list[2],sntp_menu)
           Else
           if (is_word(word_list[1],'sntp') = TRUE) and (length(input) > 5) and (out_key = #9) then //tab key
                    tab_match(word_list[2],sntp_menu)
           Else
           if (is_word(word_list[1],'qos') = TRUE) and (length(input) > 3) and (out_key = #9) then //tab key
                    tab_match(word_list[2],qos_menu)
           Else
           if (is_word(word_list[1],'snmp-server') = TRUE) and (length(input) > 6) and (out_key = #9) then //tab key
                    tab_match(word_list[2],snmp_server_menu)
           Else
           if (is_word(word_list[1],'chassis') = TRUE) and (length(word_list[1]) > 3)and (out_key = #9) then //tab key
                    tab_match(word_list[2],chassis_menu)
           Else
           if (is_word(word_list[1],'banner') = TRUE) and (length(word_list[1]) > 3) and (out_key = #9) then //tab key
                    tab_match(word_list[2],banner_menu)
           Else
           if (is_word(word_list[1],'aaa') = TRUE) and (length(word_list[1]) > 2) and (out_key = #9) then //tab key
                    tab_match(word_list[2],aaa_menu)
           Else
           if (is_word(word_list[1],'clear') = true) and (length(word_list[1]) > 3) and (out_key = #9) then //tab key
                    tab_match(word_list[2],clear_menu)
           Else
           if (is_word(word_list[1],'fast') = TRUE) and (length(word_list[1]) > 2) and (out_key = #9) then //tab key
                    tab_match(word_list[2],fast_menu)
           Else
           if (is_word(word_list[1],'fdp') = TRUE) and (length(word_list[1]) > 2) and (out_key = #9) then //tab key
                    tab_match(word_list[2],fdp_menu)
           Else
           if (is_word(word_list[1],'link-config') = TRUE) and (length(word_list[1]) > 6) and (out_key = #9) then //tab key
                    tab_match(word_list[2],link_config_menu)
           Else
           if (is_word(word_list[1],'link-keepalive') = TRUE) and (length(word_list[1]) > 6) and (out_key = #9) then //tab key
                    tab_match(word_list[2],link_keepalive_menu)
           Else
           if (is_word(word_list[1],'logging') = TRUE) and (length(word_list[1]) > 3) and (out_key = #9) then //tab key
                    tab_match(word_list[2],logging_menu)
           Else
           if (is_word(word_list[1],'mac-authentication') = TRUE) and (length(word_list[1]) > 5)and (out_key = #9) then //tab key
                    tab_match(word_list[2],mac_authentication_menu)
           Else
           if (is_word(word_list[1],'rmon') = TRUE) and (length(word_list[1]) > 2) and (out_key = #9) then //tab key
                    tab_match(word_list[2],rmon_menu)
           Else
           if (is_word(word_list[1],'sflow') = TRUE) and (length(word_list[1]) > 2) and (out_key = #9) then //tab key
                    tab_match(word_list[2],sflow_menu)
           Else
           if (is_word(word_list[1],'snmp-client') = TRUE) and (length(word_list[1]) > 6) and (out_key = #9) then //tab key
                    tab_match(word_list[2],snmp_client_menu)
           Else
           if (is_word(word_list[1],'web-management') = TRUE) and (length(word_list[1]) > 2) and (out_key = #9) then //tab key
                    tab_match(word_list[2],web_management_menu)
           Else
           if (is_word(word_list[1],'access-list') = TRUE) and (length(word_list[1]) > 3) and (out_key = #9) then //tab key
                    tab_match(word_list[2],access_list_menu)
           else
           if is_word(word_list[1],'show') and (word_list[2] = 'interfaces') and (out_key = #9) then //tab key
               tab_match2(3,word_list[3],int_eth_menu)
           else
           if is_word(word_list[1],'show') and (out_key = #9) and (word_list[3] = '') then //tab key
               tab_match(word_list[2],show_menu)

           Else
           if (is_word(word_list[1],'cdp') = TRUE) and (length(word_list[1]) > 2) and (length(word_list[1]) < 3) and (out_key = #9) then //tab key
              Begin
                  writeln('Run   Enable CDP in listen mode');
                  input := input + ' ';
                  word_list[1] := word_list[1] + ' ';
              end
           Else
           if (input = 'cdp ') and (out_key = #9) then //tab key
              Begin
                  writeln('Run   Enable CDP in listen mode');
                  input := input + 'run';
                  word_list[1] := word_list[1] + 'run';
              end
           Else
           if (word_list[1] ='show') and (out_key = #9) then //tab key
               tab_match(word_list[2],show_menu)
           else
           if (word_list[1] = 'no') and (out_key = #9) then //tab key
              remove_config
           else
           if out_key = #9 then //tab key
              tab_match(word_list[1],config_term_menu)
         Else
          case input[1] of
           '?' : page_display(config_term_menu);
           'a' : if (is_word(word_list[1],'aaa') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(aaa_menu)
                 Else
                 if (is_word(word_list[1],'access-list') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(access_list_menu)
                 Else
                    writeln('Incomplete command.');
           'b' : if (is_word(word_list[1],'banner') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(banner_menu)
                 Else
                 if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(boot_menu)
                 Else
                 if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'system') = TRUE) and (is_word(word_list[3],'?') = TRUE) then
                    page_display(boot_menu1)
                 Else
                 if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'system') = TRUE) and (is_word(word_list[3],'flash') = TRUE) and (is_word(word_list[4],'?') = TRUE) then
                    page_display(boot_menu2)
                 Else
                 if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'system') = TRUE) and (is_word(word_list[3],'flash') = TRUE) and (is_word(word_list[4],'primary') = TRUE) then
                    //writeln('boot the system from the pri flash on next reload')
                    begin
                      search_run('boot system flash secondary',foundat);
                      if foundat <> 0 then
                         running_config[foundat] := 'DELETED';
                      running_config[last_line_of_running] := 'boot system flash primary';
                      inc(last_line_of_running);
                      running_config[last_line_of_running] := 'ENDofLINES';
                    end
                 Else
                 if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'system') = TRUE) and (is_word(word_list[3],'flash') = TRUE) and (is_word(word_list[4],'secondary') = TRUE) then
                    //writeln('boot the system from the sec flash on next reload')
                    begin
                      search_run('boot system flash primary',foundat);
                           if foundat <> 0 then
                              running_config[foundat] := 'DELETED';
                      running_config[last_line_of_running] := 'boot system flash secondary';
                      inc(last_line_of_running);
                      running_config[last_line_of_running] := 'ENDofLINES';
                    end
                 Else
                 if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'system') = TRUE) and (is_word(word_list[3],'flash') = TRUE) and (is_word(word_list[4],'secondary') = TRUE) then
                    //writeln('boot the system from the sec flash on next reload')
                    begin
                      running_config[last_line_of_running] := 'boot system flash secondary';
                      inc(last_line_of_running);
                      running_config[last_line_of_running] := 'ENDofLINES';
                    end
                 Else
                    writeln('Incomplete command.');
           'c' : if (is_word(word_list[1],'chassis') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(chassis_menu)
                 Else
                 if (is_word(word_list[1],'clear') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(clear_menu)
                 Else
                  if (is_word(word_list[1],'cdp') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                     writeln('Run')
                  Else
                  if (is_word(word_list[1],'cdp') = TRUE) and (is_word(word_list[2],'run') = TRUE) then
                    Begin
                      running_config[last_line_of_running] := 'cdp run';
                      inc(last_line_of_running);
                      running_config[last_line_of_running] := 'ENDofLINES';
                    end
                  else
                  if (is_word(word_list[1],'console') = TRUE) and (is_word(word_list[2],'timeout') = TRUE) then
                      begin
                          if (is_word(word_list[3],'?') = TRUE) then
                              writeln('DECIMAL   in minutes (valid range is 0 to 240).')
                          else
                          begin
                           search_run('console timeout',foundat);
                           if is_number_inrange(word_list[3],0,240) = true then
                             if foundat = 0 then
                               Begin
                                    running_config[last_line_of_running] := 'console timeout '+ word_list[3];;
                                    inc(last_line_of_running);
                                    running_config[last_line_of_running] := 'ENDofLINES';
                               end
                             Else
                               running_config[foundat] := concat('console timeout ',word_list[3])
                           else
                             writeln('valid range is 0 to 240.');
                          end

                    end
                  Else
                    writeln('Incomplete command.');
           'e' : if is_word(word_list[1], 'exit') = true then
                     Begin
                        level := level2;
                        dec(what_level);
                        End_con_term := true;
                     End;
           'f' : if (is_word(word_list[1],'fast') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(fast_menu)
                 Else
                 if (is_word(word_list[1],'fdp') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(fdp_menu)
                 Else
                 if (is_word(word_list[1],'fdp') = TRUE) and (is_word(word_list[2],'run') = TRUE) then
                    Begin
                      running_config[last_line_of_running] := 'fdp run';
                      inc(last_line_of_running);
                      running_config[last_line_of_running] := 'ENDofLINES';
                    end
                 Else
                    writeln('Incomplete command.');
           'h' :  if (is_word(word_list[1],'hostname') = TRUE) then
                     if word_list[2] <> '' then
                        Begin
                          hostname := word_list[2];
                          search_run('hostname',foundat);
                           if foundat = 0 then
                             Begin
                                running_config[last_line_of_running] := concat('hostname ',word_list[2]);
                                inc(last_line_of_running);
                                running_config[last_line_of_running] := 'ENDofLINES';
                             end
                          Else
                             running_config[foundat] := concat('hostname ',word_list[2]);
                        end
                     Else
                        writeln('Incomplete command.');
           'i' : if (is_word(word_list[1],'interface') = TRUE) and (is_word(word_list[2],'ethernet') = TRUE) then
                     Begin
                          if check_int(shortstring(word_list[3])) = true then
                             int_loop(word_list[3])
                          Else
                             writeln('port not valid');
                     end
                 Else
                 if (is_word(word_list[1],'ip') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(ip_menu)
                 Else
                     writeln('Incomplete command.');
           'l' : if (is_word(word_list[1],'lldp') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(lldp_menu)
                 Else
                 if (is_word(word_list[1],'lldp') = TRUE) and (is_word(word_list[2],'run') = TRUE) then
                    begin
                        search_run('lldp run',foundat);
                             if foundat = 0 then
                               Begin
                                  running_config[last_line_of_running] := 'lldp run';
                                  inc(last_line_of_running);
                                  running_config[last_line_of_running] := 'ENDofLINES';
                               end
                    end
                 Else
                 if (is_word(word_list[1],'link-keepalive') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(link_keepalive_menu)
                 Else
                 if (is_word(word_list[1],'link-config') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(link_config_menu)
                 Else
                 if (is_word(word_list[1],'logging') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(logging_menu)
                 Else
                 if (is_word(word_list[1],'logging') = TRUE) and (is_word(word_list[2],'host') = TRUE) then
                    begin
                       if word_list[3] <> '' then
                        Begin
                          running_config[last_line_of_running] := concat('logging host ',word_list[3]);
                          inc(last_line_of_running);
                          running_config[last_line_of_running] := 'ENDofLINES';
                        end
                    end
                 else
                 if (is_word(word_list[1],'logging') = TRUE) and (is_word(word_list[2],'persistence') = TRUE) then
                      Begin
                        search_run('logging persistence',foundat);
                        if foundat = 0 then
                          Begin
                            running_config[last_line_of_running] := 'logging persistence';
                            inc(last_line_of_running);
                            running_config[last_line_of_running] := 'ENDofLINES';
                          End
                      End
                 else
                 if (is_word(word_list[1],'logging') = TRUE) and (is_word(word_list[2],'console') = TRUE) then
                      Begin
                        search_run('logging console',foundat);
                        if foundat = 0 then
                          Begin
                            running_config[last_line_of_running] := 'logging console';
                            inc(last_line_of_running);
                            running_config[last_line_of_running] := 'ENDofLINES';
                          End
                      End
                 Else
                    writeln('Incomplete command.');
           'm' : if (is_word(word_list[1],'mstp') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(mstp_menu)
                 Else
                 if (is_word(word_list[1],'mac-authentication') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(mac_authentication_menu)
                 Else
                    writeln('Incomplete command.');
           'n' : if word_list[1] = 'no' then
                    remove_config;
           'q' : if is_word(word_list[1],'quit') = true then
                     Begin
                        level := level2;
                        dec(what_level);
                        end_con_term := true;
                     End
                 Else
                 if (is_word(word_list[1],'qos') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(qos_menu)
                 Else
                    writeln('Incomplete command.');
           'r' : Begin
                    if (is_word(word_list[1],'rmon') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                        page_display(rmon_menu);
                    if (is_word(word_list[1],'router') = true) and (is_word(word_list[2],'?') = true)then
                       Begin
                           writeln('  rip    Enable rip');
                           writeln('  vrrp   Enable vrrp');
                       End;
                    if (is_word(word_list[1],'router') = true) and (is_word(word_list[2],'rip') = true) and (is_word(word_list[3],'?') = true) then
                       writeln('rip    Enable rip')
                    Else
                    if (is_word(word_list[1],'router') = true) and (is_word(word_list[2],'vrrp') = true) and (is_word(word_list[3],'?') = true) then
                       writeln('vrrp    Enable vrrp')
                    Else
                       if (is_word(word_list[1],'router') = true) and (is_word(word_list[2],'rip') = true) and (word_list[3] = '') then
                         Begin
                             search_run('router rip',foundat);
                             if foundat = 0 then
                               Begin
                                  running_config[last_line_of_running] := 'router rip';
                                  inc(last_line_of_running);
                                  running_config[last_line_of_running] := 'ENDofLINES';
                               end
                         End
                    Else
                       if (is_word(word_list[1],'router') = true) and (is_word(word_list[2],'vrrp') = true) and (word_list[3] = '') then
                         Begin
                             search_run('router vrrp',foundat);
                             if foundat = 0 then
                               Begin
                                  running_config[last_line_of_running] := 'router vrrp';
                                  inc(last_line_of_running);
                                  running_config[last_line_of_running] := 'ENDofLINES';
                               end
                         End
                    //Else
                    //   bad_command(word_list[3]);
                 End;
           's' : if (is_word(word_list[1],'snmp-server') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(snmp_server_menu)
                 Else
                 if (is_word(word_list[1],'snmp-server') = TRUE) and (is_word(word_list[2],'host') = TRUE) then
                    if word_list[2] <> '' then
                        Begin
                          running_config[last_line_of_running] := concat('SNMP-Server Host ',word_list[3]);
                          inc(last_line_of_running);
                          running_config[last_line_of_running] := 'ENDofLINES';
                        end
                     Else
                        writeln('Incomplete command.')
                 else
                 if (is_word(word_list[1],'snmp-server') = TRUE) and (is_word(word_list[2],'location') = TRUE) then
                    if word_list[3] <> '' then
                        Begin
                          running_config[last_line_of_running] := 'SNMP-Server location ' + word_list[3] + ' '
                                                      + word_list[4] + ' ' + word_list[5] + ' ' + word_list[6];
                          inc(last_line_of_running);
                          running_config[last_line_of_running] := 'ENDofLINES';
                        end
                     Else
                        writeln('Incomplete command.')
                 Else
                 if (is_word(word_list[1],'snmp-client') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(snmp_client_menu)
                 Else
                 if (is_word(word_list[1],'sflow') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(sflow_menu)
                 Else
                 if (is_word(word_list[1],'sntp') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(sntp_menu)
                 else
                 if (is_word(word_list[1],'sntp') = TRUE) and (is_word(word_list[2],'server') = TRUE) then
                    begin
                        if (is_word(word_list[3],'?') = TRUE) then
                          begin
                           writeln('  ASCII string   Host Name');
                           writeln('  A.B.C.D        IP address');
                           writeln('  ipv6           IPv6 address');
                          end
                        else
                          begin
                                  running_config[last_line_of_running] := concat('sntp server ',word_list[3]);
                                  inc(last_line_of_running);
                                  running_config[last_line_of_running] := 'ENDofLINES';
                          end
//                             Else
//                               writeln('Maximum of 3 SNTP time servers are supported');
                    end
                 else
                 if (is_word(word_list[1],'sntp') = TRUE) and (is_word(word_list[2],'poll-interval') = TRUE) then
                    begin
                          if (is_word(word_list[3],'?') = TRUE) then
                              writeln('DECIMAL   in secs (valid range is 16 to 131072).')
                          else
                          begin
                           search_run('sntp poll-interval',foundat);
                           if is_number_inrange(word_list[3],16,131072) = true then
                             if foundat = 0 then
                               Begin
                                  running_config[last_line_of_running] := concat('sntp poll-interval ',word_list[3]);
                                  inc(last_line_of_running);
                                  running_config[last_line_of_running] := 'ENDofLINES';
                               end
                             Else
                               running_config[foundat] := concat('sntp poll-interval ',word_list[3])
                           else
                             writeln('valid range is 16 to 131072).');
                          end
                    End
                 Else
                 if (input = 'sh') or (input = 'sho') or (input = 'show') then
                    writeln('Incomplete command.')
                 Else
                     Begin
                         input := input;
                         display_show;
                     End;
          'v' : if (is_help(input) = TRUE) then
                    Begin
                        looking_for_help
                    End
                Else
                  if (is_word(word_list[1],'vlan') = TRUE) then
                    if (is_number(word_list[2]) = TRUE) then
                      Begin
                        vlans[strtoint(word_list[2])].id := shortstring(word_list[2]);
                        vlans[strtoint(word_list[2])].name := word_list[4];
                        vlan_loop(word_list[2]);
                      End
                    Else
                      bad_command(word_list[2]);
          'w' : if (is_word(word_list[1],'web-management') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(web_management_menu)
                 Else
                 if (is_word(word_list[1],'write') = TRUE) and (is_word(word_list[2],'memory') = TRUE) then
                    write_memory(running_config)
                 else
                    bad_command(word_list[2]);
          #0 :;
           Else
                    Begin
                      bad_command(input);
                    End;
         End;
        until End_con_term = true;
  End; // of config_term

  Procedure enable_loop;

  var
     End_enabled : boolean;

  Begin // enable loop
     End_enabled := false;
     repeat
         repeat
            write(hostname, level);
            get_input(input,out_key);
            writeln;
         until input <> '';
         word_list[1] := ''; word_list[2] := ''; word_list[3] := '';
         word_list[4] := ''; word_list[5] := '';
         get_words;
         if (is_help(word_list[1]) = TRUE) and (length(word_list[1]) > 1) then
                    Begin
                      help_match(word_list[1],enable_menu);
                    End
         Else
           if is_word(word_list[1],'boot') and is_word(word_list[2],'system') and is_word(word_list[3],'flash') and (length(word_list[3]) > 1)and (out_key = #9)then
              Begin
                tab_match2(4,word_list[4],boot_menu2)
              End
           Else
           if is_word(word_list[1],'boot') and is_word(word_list[2],'system') and (length(word_list[2]) > 1)and (out_key = #9)then
              Begin
                if word_list[3] <> '' then
                  tab_match2(3,word_list[3],boot_menu1)
                else
                  tab_match2(2,word_list[2],boot_menu)
              End
           Else
           if is_word(word_list[1],'boot') and (length(word_list[1]) > 3) and (out_key = #9)then
              Begin
                tab_match(word_list[2],boot_menu)
              End
           Else
           if (is_word(word_list[1],'debug') = TRUE) and (word_list[2] = 'ip') and (out_key = #9) then //tab key
               tab_match(word_list[3],debug_ip_menu)
           Else
           if (is_word(word_list[1],'debug') = TRUE) and (length(word_list[1]) > 4) and (out_key = #9) then //tab key
               tab_match(word_list[2],debug_menu)
           Else
           if (is_word(word_list[1],'configure') = TRUE) and (length(input) > 2) and (length(input) < 9) and (out_key = #9) then //tab key
               Begin
                   tab_match(word_list[1],enable_menu);
               end
           Else
           if (input = 'configure ') and (out_key = #9) then //tab key
               Begin
                   writeln('  terminal   Configure thru terminal');
                   input := input + 'terminal';
               end
           Else
           if (word_list[1] ='dm') and (length(word_list[2]) >= 1) and (out_key = #9) then //tab key
               tab_match(word_list[2],dm_menu)
           Else
           if (word_list[1] ='dm') and (out_key = #9) then //tab key
               tab_match(word_list[2],dm_menu)
           Else
           if is_word(word_list[1],'show') and (word_list[2] = 'interfaces') and (out_key = #9) then //tab key
               tab_match2(3,word_list[3],int_eth_menu)
           else
           if is_word(word_list[1],'show') and (out_key = #9) and (word_list[3] = '') then //tab key
               tab_match(word_list[2],show_menu)
           else
           if (word_list[1] ='show') and (out_key = #9) then //tab key
               tab_match(word_list[2],show_menu)
           else
           if out_key = #9 then //tab key
              tab_match(word_list[1],enable_menu)
         Else
         case input[1] of
            'a' : ;
            'b' : if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                    page_display(boot_menu)
                 Else
                 if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'system') = TRUE) and (is_word(word_list[3],'?') = TRUE) then
                    page_display(boot_menu1)
                 Else
                 if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'system') = TRUE) and (is_word(word_list[3],'flash') = TRUE) and (is_word(word_list[4],'?') = TRUE) then
                    page_display(boot_menu2)
                 Else
                 if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'system') = TRUE) and (is_word(word_list[3],'flash') = TRUE) and (is_word(word_list[4],'primary') = TRUE) then
                    writeln('boot the system from the pri flash one time only and NOW')
                 Else
                 if (is_word(word_list[1],'boot') = TRUE) and (is_word(word_list[2],'system') = TRUE) and (is_word(word_list[3],'flash') = TRUE) and (is_word(word_list[4],'secondary') = TRUE) then
                    writeln('boot the system from the sec flash one time only and NOW');
            'c' : if (is_word(word_list[1],'configure') = true) and (is_word(word_list[2],'terminal') = true)then
                     Configure_term_loop
                  Else
                     bad_command(input);
            'd' : if (is_word(word_list[1],'dm') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                        page_Display(dm_menu)
                     Else
                  if (is_word(word_list[1],'debug') = true) then
                     page_display(debug_menu);
            'e' : if (is_word(word_list[1],'exit') = true) then
                     Begin
                        level := level1;
                        dec(what_level);
                        End_enabled := true;
                     End;
            'k' : if (is_word(word_list[1],'kill') = true) then
                        writeln('*  Kill not implemented in Brocade-Sim')
                  Else
                     if (input = 'kill ?') then
                        Begin
                          writeln('  console   Console session');
                          writeln('  ssh       SSH session');
                          writeln('  telnet    Telnet session');
                        End;
            'n' : if (is_word(word_list[1],'ncopy') = true) then
                        writeln('*  ncopy not implemented in Brocade-Sim');
            'p' : if (is_word(word_list[1],'ping') = true) then
                        writeln('*  Ping not implemented in Brocade-Sim')
                        Else
                        if (is_word(input,'page-display') = TRUE) then
                            skip_page_display := false;
            'r' : if (input = 're') or (input = 'rel') or (input = 'relo') or (input = 'reloa') or (input = 'reload') then
                     writeln('*  Reload not implemented in Brocade-Sim as yet');
            's' : if (is_word(word_list[1],'skip-page-display') = TRUE) then
                     skip_page_display := true
                  Else
                     if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                        page_Display(show_menu)
                     Else
                        if (is_word(word_list[1],'show') = true) then
                             display_show;
            't' : if (is_word(word_list[1],'telnet') = TRUE) and (word_list[2] = '') then
                     writeln('Incomplete command.')
                  Else
                      if (is_word(word_list[2],'?') = TRUE) then
                         Begin
                             writeln('  ASCII string      Host name');
                             writeln('  A.B.C.D           Host IP address');
                             writeln('  X:X::X:X          Host IP6 address');
                         End
                      Else
                         writeln('Telnet not implemented in Brocade simulate');
            'u' : if (input = 'un') or (input = 'und') or (input = 'unde') or (input = 'undeb') or (input = 'undebug') then
                        writeln('*  Undebug not implemented in Brocade-Sim');
            'v' : if (input = 've') or (input = 'ver') or (input = 'veri') or (input = 'verif') or (input = 'verify') then
                        writeln('*  verify not implemented in Brocade-Sim');
            'w' : if (is_word(word_list[1],'write') = TRUE) and (is_word(word_list[2],'memory') = TRUE) then
                    //writeln('*  Write not implemented in Brocade-Sim as yet')
                    write_memory(running_config)
                  Else
                    if (input = 'wh') or (input = 'who') or (input = 'whoi') or (input = 'whowis') then
                       writeln('*  Whois not implemented in Brocade-Sim as yet');
            'q' : if (input = 'qu') or (input = 'qui') or (input = 'quit')then
                     Begin
                        level := level1;
                        dec(what_level);
                        End_enabled := true;
                     End;
            '?' : page_Display(enable_menu);
            chr(0) : write;
         End;
       until (End_enabled = True);
  End; // of enable_loop

  Procedure my_loop;

  var
     End_program : boolean;

  Begin //my_loop
       End_program := false; what_level := 1;
       Hostname := 'Fastiron'; level := level1;
       repeat
             word_list[1] := ''; word_list[2] := ''; word_list[3] := '';
             repeat
                write(hostname, level);
                get_input(input,out_key);
                writeln;
             until input <> '';
             get_words;
             if (is_help(word_list[1]) = TRUE) and (length(word_list[1]) > 1) then
                    Begin
                      help_match(word_list[1],top_menu);
                    End
             Else
             if is_word(word_list[1],'show') and (word_list[2] = 'interfaces') and (out_key = #9) then //tab key
               tab_match2(3,word_list[3],int_eth_menu)
             else
             if is_word(word_list[1],'show') and (out_key = #9) and (word_list[3] = '') then //tab key
               tab_match(word_list[2],show_menu)

             else
             if out_key = #9 then //tab key
                 tab_match(word_list[1],top_menu)
             Else
             case input[1] of
                'e' : if is_word(word_list[1],'enable') = true then
                         Begin
                            level := level2; inc(what_level);
                            Enable_Loop;
                         End
                      Else
                         if is_word(word_list[1],'exit')then
                            End_program := true
                         Else
                            bad_command(input);
                'p' : if is_word(word_list[1],'ping') then
                        writeln('  Ping not implemented in Brocade-Sim');
                's' : if is_word(word_list[1],'stop-traceroute') then
                                  writeln('  There is no Trace Route Operation in progress!')
                      Else
                         if (is_word(word_list[1],'show') = true) and (is_word(word_list[2],'?') = true) then
                             page_Display(top_menu)
                         Else
                           if (is_word(word_list[1],'show') = true) then
                             display_show;
                't' : if is_word(word_list[1],'traceroute') = true then
                          writeln('  TreaceRoute not implemented in Brocade-Sim');
                '?' : page_Display(top_menu);
                Else
                   bad_command(input);
             End;
       until (End_program = True);
  End; // of my_loop

  Procedure BrocadeExceptionHandler(ExceptObject: TObject; ExceptAddr: Pointer);
  const
    ErrorMessages : array[0..0] of string = ( 'EInOutError' ) ;
  Begin
    case AnsiIndexText(Exception(ExceptObject).Classname,ErrorMessages) of
      0:WriteLn('Brocade-Sim Missing files detected, please check configuration files in the program directory.');
      Else
        WriteLn('Brocade-Sim Exception Occured [' + Exception(ExceptObject).Classname + '] : ' + Exception(ExceptObject).Message);
    End;
    Flush(Output);
    Halt(1);
  End;

  Procedure BrocadeErrorProcedure(ErrorCode: Integer; ErrorAddr: Pointer);
  Begin
    WriteLn('Brocade-Sim Error Procedure Initiated [' + IntToStr(ErrorCode) + ']');
    Flush(Output);
    Halt(2);
  End;

Begin
  ExceptProc := @BrocadeExceptionHandler;
//  ErrorProc := @BrocadeErrorProcedure;
  SetErrorMode(SEM_NOGPFAULTERRORBOX);

  clrscr;
    skip_page_display := false;
    init_int_eth_menu;
    init_boot_menu;
    init_boot1_menu;
    init_boot2_menu;
    init_top_menu;
    init_show_menu;
    init_dm_menu;
    init_debug_menu;
    init_debug_ip_menu;
    init_config_term_menu; // whole menu
    init_configterm_menu; // just the terminal second word of the config term command
    init_enable_menu;
    init_ip_menu;
    init_interface_menu;
    init_vlan_menu;
    init_lldp_menu;
    init_mstp_menu;
    init_qos_menu;
    init_snmp_server_menu;
    init_access_list_menu;
    init_chassis_menu;
    init_banner_menu;
    init_aaa_menu;
    init_clear_menu;
    init_fast_menu;
    init_fdp_menu;
    init_link_config_menu;
    init_link_keepalive_menu;
    init_logging_menu;
    init_mac_authentication_menu;
    init_rmon_menu;
    init_sflow_menu;
    init_sntp_menu;
    init_snmp_client_menu;
    init_web_management_menu;

    // Display the splash screen
    Splash_screen;
    // read from config files
    Read_config;
    read_startup_config; //read in the default Brocade config
    history_pos := 1; // starting possition for CLI history.
    // main loop
    my_loop;
End.

