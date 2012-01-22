program Brocade;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  StrUtils,
  console,
  LineEditor in 'LineEditor.pas';

const
  level1 = '>';
  level2 = '#';
  level3 = '(config)#';
  level4 = '(config-if-e1000-';
  level5 = '(config-vlan-';

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

end;

Var
  Hostname, level : string;
  input : string;
  what_level : integer;
  Code_version : string;
  Modules : array[1..20] of string;
  chassis : array[1..60] of string;
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

  // menus
  top_menu : array[1..7] of string;
  Show_menu : array[1..80] of string;
  config_term_menu : array[1..106] of string;
  enable_menu : array[1..50] of string;
  Interface_menu : array[1..69] of string;
  vlan_menu : array[1..30] of string;

  procedure splash_screen;

  Begin
      writeln;
      writeln(' ╔════════════════════════════════════════════════════════════════════════════╗');
      writeln(' ║                                                                            ║');
      writeln(' ║   Brocade-Sim : Version r24                                               ║');
      writeln(' ║                 Dated 16/01/2012                                           ║');
      writeln(' ║                                                                            ║');
      Writeln(' ║   Coded by    : Michael Schipp                                             ║');
      writeln(' ║   Purpose     : To aid network administrators to get to know Brocade       ║');
      writeln(' ║                 FastIron and syntax                                        ║');
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
      writeln(' ╚════════════════════════════════════════════════════════════════════════════╝');
      gotoxy(79,24);
      readkey;
      clrscr;
      gotoxy(1,24);
  End;

  function check_int(validport : shortstring) : boolean;

  var
    loop : integer;

  Begin
     check_int := false;
     for loop := 1 to port_count do
         begin
              if validport = interfaces[loop].port_no then
                 begin
                      check_int := true;
                      break;
                 end;
         end;
  End;

  function is_word(check, target : string) : boolean;

  begin

       is_word := strutils.AnsiContainsStr(target,check);
  end;

  function is_number(check : string) : boolean;

  var
      a : integer;

  begin
       a := 0; is_number := false;
//       writeln('check is, ',check);
       try
          a := strtoint(check);
 //         writeln('The value of a is, ',a);
       except
          on Exception : EConvertError do
              is_number := false;
       end;
       if a <> 0 then
         if a < 4096 then
            is_number := true
         else
            Begin
              writeln('Error - Invalid input ',check,'. Valid range is between 1 and 4095');
              is_number := false;
            End;
  end;


  function is_help(check : string) : boolean;

  var
      Loop : integer;
  begin
       is_help := false;
       for loop := 1 to length(check) do
         begin
              if check[loop] = '?' then
                 is_help := true;
         end
  end;

  procedure Get_words;

  var
    a, word_count : integer;
    strlength : integer;

  begin
        a := 1; word_count := 1;
        strlength := length(input);
        while (input[a] <> '') and (a <= strlength)do
          begin
               while (input[a] <> ' ') and (a <= strlength)do
                 Begin
                     word_list[word_count] := word_list[word_count] + input[a];
                     if input[a] <> '' then
                        begin
                            inc(a);
//                            write(input[a]);
                        end
                     else
                        break;
                 End;
               inc(a);
               inc(word_count);
          end;
  end;

  procedure Page_display(lines : array of string);

  var
    count : integer;
    key : char;
    goodkey, ctrlc : boolean;
  begin
      count := 0; goodkey := false; ctrlc := false;
//      key := #255;
      if skip_page_display = false then
      Begin
        while (lines[count] <> 'ENDofLINES') and (ctrlc = false) do
          begin
               if (count mod 22 = 0) and (count > 21) then
                  begin
                      writeln(lines[count]);
                      writeln('--More--, next page: Space, next line: Return key, quit: Control-c');
                      repeat
                        begin
                            key := readkey;
                            case key of
                              #3  : begin
                                      ctrlc := true;
                                      goodkey := true;
                                    end;
                              #32 : goodkey := true;
                              #13 : begin
                                      if lines[count+1] = 'ENDofLINES' then
                                         begin
                                              ctrlc := true;
                                              goodkey := true;
                                         end
                                      else
                                      begin
                                        gotoxy(1,whereY-1);
                                        write('                                                                               ');
                                        gotoxy(1,whereY);
                                        //inc(count);
                                        writeln(lines[count+1]);
                                        writeln('--More--, next page: Space, next line: Return key, quit: Control-c');
                                        inc(count);
                                      end;
                                    end;
                              'q' : begin
                                      goodkey := true;
                                      ctrlc := true;
                                    end;
                              'Q' : begin
                                      goodkey := true;
                                      ctrlc := true;
                                    end;
                            end;
                        end
                      until goodkey = true;
                      inc(count);
                  end
               else
                 begin
                     writeln(lines[count]);
                     inc(count);
                 end;
          end;
      End
    else
      Begin
           while (lines[count] <> 'ENDofLINES') and (ctrlc = false) do
              begin
                  writeln(lines[count]);
                  inc(count);
              end;
      End;
  end;

  procedure bad_command(command:string);

  begin
    writeln('Invalid input -> ',command);
    writeln('Type ? for a list');
  end;


  procedure help_match(findword : string; var list : array of string);

  var
    loop, len: integer;
    astring : string;

  Begin
       len := Length(findword)-1;
//       writeln('wordlist, ',findword);
       for loop := 0 to high(list) do
          begin
            astring := Copy(list[loop], 3, len) + '?';
            if astring = findword then
              writeln(list[loop]);
          end;
  End;

  procedure tab_match(findword : string; var list : array of string);

  var
    a, strlength, loop, len: integer;
    astring : string;
    tmp_str : string;
    only_one : integer;

  Begin
       len := Length(findword); only_one := 0;
//       writeln('wordlist, ',findword);
       for loop := 0 to high(list) do
          begin
            astring := Copy(list[loop], 3, len);
            if astring = findword then
              begin
                  inc(only_one);
                  writeln(list[loop]);
                  tmp_str := list[loop];
              end;
          end;
       if only_one = 1 then
          begin
                a := 3; input := '';
                strlength := length(tmp_str);
                while (tmp_str[a] <> ' ') do
                   Begin
                       input := input + tmp_str[a];
                       if tmp_str[a] <> '' then
                          begin
                              inc(a);
  //                            write(input[a]);
                          end
                       else
                          break;
                   End;
               input := input + ' ';
          end;
  End;

  procedure Read_startup_config;

  var
      sc : textfile;
      aline : string;
      loop : integer;

  Begin
       loop := 1;
       assignfile(sc,'startup-config.txt');
       reset(sc);
       readln(sc, aline);
       running_config[1] := 'Current configuration:';
       running_config[2] := '!';
       running_config[3] := code_version;
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
            begin
//              writeln('-------',aline);   readln;
              readln(sc,aline);
              startup_config[loop] := aline;
              running_config[loop+25] := aline;
              inc(loop);
            end;
       running_config[loop+26] := 'ENDofLINES';
       last_line_of_running := loop +25;
       closefile(sc);
  End;

  procedure read_config;

  var
      sc : textfile;
      aline : string;
      loop, loop2 : integer;
      isend : boolean;
      slot : integer;

  begin
       isend := false; loop := 1; slot := 1; port_count := 1;
       assignfile(sc,'modules.txt');
//       fileh := FileOpen('c:\modules.txt',1);
       reset(sc);
       readln(sc, aline);
       if aline = 'Insatalled-modules' then
          begin
              //writeln(aline);
              repeat
                    readln(sc,aline);
                    if aline = 'END' then
                       isend := true
                    else
                      begin
                        modules[loop] := aline;
//                        writeln(modules[loop]); readkey;
                        // setup interface ports
                        if is_word('Management',aline) = false then
                           begin
//                                writeln(aline);
                                if is_word('EMPTY',aline) = true then
                                   inc(slot)
                                else
                                begin
                                 for loop2 := 1 to 24 do
                                    begin
                                          interfaces[port_count].no_config := true;
                                          interfaces[port_count].admin_disable := false;
                                          interfaces[port_count].port_no := shortstring(inttostr(slot) + '/' + inttostr(loop2));
                                          interfaces[port_count].descript := '';
                                          interfaces[port_count].speed := 'auto';
                                          interfaces[port_count].speed_actual := '1Gbit';
                                          interfaces[port_count].root_guard := false;
//                                          writeln(interfaces[port_count].port_no);
                                          inc(port_count);
                                    end;
                                inc(slot);
                                end;
                           end
                        else
                           inc(slot);
                        inc(loop);
                      end;
              until (isend = true);
              dec(port_count);
          end;

       modules[loop] := 'ENDofMODULES';
       readln(sc);
       readln(sc,code_version);
//       writeln(code_version);
       readln(sc);
       readln(sc, aline);
       isend := false;    loop := 1;
       if aline = 'FLASH' then
          begin
              //writeln(aline);
              repeat
                    readln(sc,aline);
                    if aline = 'END' then
                       isend := true
                    else
                      begin
                        flash[loop] := aline;
//                        writeln(aline); readln;
                        inc(loop);
                      end;
              until (isend = true);
          end;
       flash[loop] := 'ENDofFLASH';
       isend := false; loop := 1;
       readln(sc,aline);
       if aline = 'CHASIS' then
          begin
              //writeln(aline);
              repeat
                    readln(sc,aline);
                    if aline = 'END' then
                       isend := true
                    else
                      begin
                        chassis[loop] := aline;
//                        writeln(aline);
                        inc(loop);
                      end;
              until (isend = true);
          end;
       chassis[loop] := 'ENDofLINES';
       isend := false; loop := 1;
       readln(sc,aline);
       if aline = 'SHOWMEMORY' then
          begin
              //writeln(aline);
              repeat
                    readln(sc,aline);
                    if aline = 'END' then
                       isend := true
                    else
                      begin
                        show_memory[loop] := aline;
//                        writeln(aline);
                        inc(loop);
                      end;
              until (isend = true);
          end;
          show_Memory[loop] := 'ENDofMEMORY';
       isend := false; loop := 1;
       readln(sc,aline);
       if aline = 'SHOWARP' then
          begin
              //writeln(aline);
              repeat
                    readln(sc,aline);
                    if aline = 'END' then
                       isend := true
                    else
                      begin
                        show_arp[loop] := aline;
//                        writeln(aline);
                        inc(loop);
                      end;
              until (isend = true);
          end;
          show_arp[loop] := 'ENDofARP';
 //      write('******** ',flash[1]);
       closefile(sc);
  //     readln;

  end;

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

procedure init_enable_menu;

  Begin
    enable_menu[1] := '  alias                     Display configured aliases';
    enable_menu[2] := '  boot                      Boot system from bootp/tftp server/flash image';
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
    enable_menu[14] := '  kill                      Kill active CLI session';
    enable_menu[15] := '  ncopy                     Copy a file';
    enable_menu[16] := '  page-display              Display data one page at a time         --> done';
    enable_menu[17] := '  phy                       PHY related commands';
    enable_menu[18] := '  ping                      Ping IP node                            --> done';
    enable_menu[19] := '  port                      Port security command';
    enable_menu[20] := '  quit                      Exit to User level                      --> done';
    enable_menu[21] := '  reload                    Halt and perform a warm restart';
    enable_menu[22] := '  show                      Display system information              --> done';
    enable_menu[23] := '  skip-page-display         Enable continuous display               --> done';
    enable_menu[24] := '  sntp                      Simple Network Time Protocol commands';
    enable_menu[25] := '  stop-traceroute           Stop TraceRoute operation';
    enable_menu[26] := '  switch-over-active-role   Switch over the active role to standby mgmt blade';
    enable_menu[27] := '  telnet                    Telnet by name or IP address            --> done';
    enable_menu[28] := '  terminal                  display syslog';
    enable_menu[29] := '  trace-l2                  TraceRoute L2';
    enable_menu[30] := '  traceroute                TraceRoute to IP node';
    enable_menu[31] := '  undebug                   Disable debugging functions (see also ''debug'')';
    enable_menu[32] := '  verify                    Verify object contents';
    enable_menu[33] := '  whois                     WHOIS lookup';
    enable_menu[34] := '  write                     Write running configuration to flash or terminal';
    enable_menu[35] := 'ENDofLINES';
  End;

  procedure init_show_menu;

//  var
//   lines : array[1..80] of string;

  begin
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
  end;

  procedure init_config_term_menu;

  begin
    config_term_menu[1] :=   '  aaa                           Define authentication method list';
    config_term_menu[2] :=   '  access-list                   Define Access Control List (ACL)';
    config_term_menu[3] :=   '  aggregated-vlan               Support for larger Ethernet frames up to 1536';
    config_term_menu[4] :=   '                                bytes';
    config_term_menu[5] :=   '  alias                         Configure alias or display configured alias';
    config_term_menu[6] :=   '  all-client                    Restrict all remote management to a host';
    config_term_menu[7] :=   '  arp                           Enter a static IP ARP entry';
    config_term_menu[8] :=   '  banner                        Define a login banner';
    config_term_menu[9] :=   '  batch                         Define a group of commands';
    config_term_menu[10] :=  '  boot                          Set system boot options';
    config_term_menu[11] :=  '  bootp-relay-max-hops          Set maximum allowed hop counts for BOOTP';
    config_term_menu[12] :=  '  buffer-sharing-full           Remove buffer allocation limits per port';
    config_term_menu[13] :=  '  cdp                           Global CDP configuration command';
    config_term_menu[14] :=  '  chassis                       Configure chassis name and polling options';
    config_term_menu[15] :=  '  clear                         Clear table/statistics/keys';
    config_term_menu[16] :=  '  clock                         Set system time and date';
    config_term_menu[17] :=  '  console                       Configure console port';
    config_term_menu[18] :=  '  crypto                        Crypto configuration';
    config_term_menu[19] :=  '  crypto-ssl                    Crypto ssl configuration';
    config_term_menu[20] :=  '  default-vlan-id               Change Id of default VLAN, default is 1';
    config_term_menu[21] :=  '  dot1x-enable                  Enable dot1x system authentication control';
    config_term_menu[22] :=  '  enable                        Password, page-mode and other options';
    config_term_menu[23] :=  '  end                           End Configuration level and go to Privileged';
    config_term_menu[24] :=  '                                level';
    config_term_menu[25] :=  '  errdisable                    Set Error Disable Attributions';
    config_term_menu[26] :=  '  exit                          Exit current level';
    config_term_menu[27] :=  '  extern-config-file            extern configuration file';
    config_term_menu[28] :=  '  fan-speed                     set fan speed';
    config_term_menu[29] :=  '  fan-threshold                 set temperature threshold for fan speed';
    config_term_menu[30] :=  '  fast                          Fast spanning tree options';
    config_term_menu[31] :=  '  fdp                           Global FDP configuration subcommands';
    config_term_menu[32] :=  '  flow-control                  Enable 802.3x flow control on full duplex port';
    config_term_menu[33] :=  '  gig-default                   Set Gig port default options';
    config_term_menu[34] :=  '  hostname                      Rename this switching router       --> done';
    config_term_menu[35] :=  '  interface                     Port commands                      --> done';
    config_term_menu[36] :=  '  ip                            IP settings';
    config_term_menu[37] :=  '  ipv6                          IPv6 settings';
    config_term_menu[38] :=  '  jumbo                         gig port jumbo frame support (10240 bytes)';
    config_term_menu[39] :=  '  legacy-inline-power           set legacy (capacitance-based) PD detection -';
    config_term_menu[40] :=  '                                default';
    config_term_menu[41] :=  '  link-config                   Link Configuration';
    config_term_menu[42] :=  '  link-keepalive                Link Layer Keepalive';
    config_term_menu[43] :=  '  lldp                          Configure Link Layer Discovery Protocol';
    config_term_menu[44] :=  '  lock-address                  Limit number of addresses for a port';
    config_term_menu[45] :=  '  logging                       Event logging settings';
    config_term_menu[46] :=  '  mac                           Set up MAC filtering';
    config_term_menu[47] :=  '  mac-age-time                  Set aging period for all MAC interfaces';
    config_term_menu[48] :=  '  mac-authentication            Configure MAC authentication';
    config_term_menu[49] :=  '  max-acl-log-num               maximum number of ACL log per minute (0 to';
    config_term_menu[50] :=  '                                4096, default 256)';
    config_term_menu[51] :=  '  mirror-port                   Enable a port to act as mirror-port';
    config_term_menu[52] :=  '  module                        Specify module type';
    config_term_menu[53] :=  '  mstp                          Configure MSTP (IEEE 802.1s)';
    config_term_menu[54] :=  '  no                            Undo/disable commands';
    config_term_menu[55] :=  '  optical-monitor               Enable optical monitoring with default';
    config_term_menu[56] :=  '                                alarm/warn interval(3 minutes)';
    config_term_menu[57] :=  '  password-change               Restrict access methods with right to change';
    config_term_menu[58] :=  '                                password';
    config_term_menu[59] :=  '  port                          UDP and Port Security Configuration';
    config_term_menu[60] :=  '  privilege                     Augment default privilege profile';
    config_term_menu[61] :=  '  protected-link-group          Define a Group of ports as Protected Links';
    config_term_menu[62] :=  '  pvlan-preference              Unknown unicast/broadcast traffic handling';
    config_term_menu[63] :=  '  qos                           Quality of service commands';
    config_term_menu[64] :=  '  qos-tos                       IPv4 ToS based QoS settings';
    config_term_menu[65] :=  '  quit                          Exit to User level';
    config_term_menu[66] :=  '  radius-server                 Configure RADIUS server';
    config_term_menu[67] :=  '  rarp                          Enter a static IP RARP entry';
    config_term_menu[68] :=  '  rate-limit-arp                Set limit on received ARP per second';
    config_term_menu[69] :=  '  relative-utilization          Display port utilization relative to selected';
    config_term_menu[70] :=  '                                uplinks';
    config_term_menu[71] :=  '  reserved-vlan-map             Map Reserved vlan Id to some other value not';
    config_term_menu[72] :=  '                                used';
    config_term_menu[73] :=  '  rmon                          Configure RMON settings';
    config_term_menu[74] :=  '  router                        Enable routing protocols           --> done';
    config_term_menu[75] :=  '  scale-timer                   Scale timer by factor for documented features';
    config_term_menu[76] :=  '  service                       Set services such as password encryption';
    config_term_menu[77] :=  '  set-active-mgmt               Configure the active mgmt slot';
    config_term_menu[78] :=  '  set-pwr-fan-speed             Power Fan Speed configuratio';
    config_term_menu[79] :=  '  sflow                         Set sflow params';
    config_term_menu[80] :=  '  show                          Show system information            --> done';
    config_term_menu[81] :=  '  snmp-client                   Restrict SNMP access to a certain IP node';
    config_term_menu[82] :=  '  snmp-server                   Set onboard SNMP server properties';
    config_term_menu[83] :=  '  sntp                          Set SNTP server and poll interval';
    config_term_menu[84] :=  '  spanning-tree                 Set spanning tree parameters';
    config_term_menu[85] :=  '  ssh                           Restrict ssh access by ACL';
    config_term_menu[86] :=  '  stp-group                     Spanning Tree Group settings';
    config_term_menu[87] :=  '  system-max                    Configure system-wide maximum values';
    config_term_menu[88] :=  '  tacacs-server                 Configure TACACS server';
    config_term_menu[89] :=  '  tag-type                      Customize value used to identify 802.1Q Tagged';
    config_term_menu[90] :=  '                                Packets';
    config_term_menu[91] :=  '  telnet                        Set telnet access and timeout';
    config_term_menu[92] :=  '  tftp                          Restrict tftp access';
    config_term_menu[93] :=  '  topology-group                configure topology vlan group for L2 protocols';
    config_term_menu[94] :=  '  traffic-policy                Define Traffic Policy (TP)';
    config_term_menu[95] :=  '  transmit-counter              Define Transmit Queue Counter';
    config_term_menu[96] :=  '  trunk                         Trunk group settings';
    config_term_menu[97] :=  '  unalias                       Remove an alias';
    config_term_menu[98] :=  '  username                      Create or update user account';
    config_term_menu[99] :=  '  vlan                          VLAN settings                      --> done';
    config_term_menu[100] := '  vlan-group                    VLAN group settings';
    config_term_menu[101] := '  web                           Restrict web management access to a certain IP';
    config_term_menu[102] := '                                node';
    config_term_menu[103] := '  web-management                Web management options';
    config_term_menu[104] := '  write                         Write running configuration to flash or terminal';
    config_term_menu[105] := '  <cr>';
    config_term_menu[106] := 'ENDofLINES';
  end;

  procedure init_interface_menu;

  begin
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
  end;

  procedure init_vlan_menu;

  begin
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
  end;

  procedure display_help_match(findword : string);

  var
    loop, len: integer;
    astring : string;

  Begin
       len := Length(findword)-1;
//       writeln('wordlist, ',findword);
       for loop := 1 to 80 do
          begin
            astring := Copy(show_menu[loop], 3, len) + '?';
            if astring = findword then
              writeln(show_menu[loop]);
          end;
  End;

  procedure display_show_arp;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if show_arp[loop] = 'ENDofARP' then
             isend := true
          else
              begin
                  writeln(show_arp[loop]);
                  inc(loop)
              end;
    until isend = true;
//    writeln(chassis[loop]);
  End;

  procedure display_show_boot_pref;

  Begin
    writeln('1 percent busy, from 45 sec ago');
    writeln('Boot system preference(Configured):');
    writeln('        Boot system flash primary');
    writeln('');
    writeln('Boot system preference(Default):');
    writeln('        Boot system flash primary');
    writeln('        Boot system flash secondary');
  End;

  Procedure display_show_clock;

  begin
    writeln(timetostr(time), ' GMT+10 ',datetostr(date));
  end;

  procedure display_show_cpu;

  Begin
    writeln('1 percent busy, from 45 sec ago');
    writeln('1   sec avg:  1 percent busy');
    writeln('5   sec avg:  1 percent busy');
    writeln('60  sec avg:  1 percent busy');
    writeln('300 sec avg:  1 percent busy');
  End;

  procedure display_show_defaults;

  begin
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

  end;

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
  procedure display_show_fdp;

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
        begin
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
               begin
                  lines[index] := '  BPDU guard is Enabled, ROOT protect is ';
               end
            else
               lines[index] := '  BPDU guard is Disabled, ROOT protect is ';
            if interfaces[loop].root_guard = true then
               begin
                  lines[index] := lines[index]+ 'Enabled';
               end
            else
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
               begin
                  lines[index] := '  No port name';
                  inc(index);
               end
            else
               begin
                  lines[index] := '  ' + interfaces[loop].descript;
                  inc(index);
               end;
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
        end;
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
            begin
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
               begin
                  lines[index] := '  BPDU guard is Enabled, ROOT protect is ';
               end
            else
               lines[index] := '  BPDU guard is Disabled, ROOT protect is ';
            if interfaces[loop].root_guard = true then
               begin
                  lines[index] := lines[index]+ 'Enabled';
               end
            else
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
               begin
                  lines[index] := '  No port name';
                  inc(index);
               end
            else
               begin
                  lines[index] := '  ' + interfaces[loop].descript;
                  inc(index);
               end;
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
        end;
      lines[index] := 'ENDofLINES';
      page_display(lines);
  End;
  procedure display_show_int_bri;

  var
    lines : array[1..385] of string;
    loop  : integer;

  Begin
       lines[1] := '';
       lines[2] := 'Port    Link      State  Dupl Speed Trunk Tag Pvid Pri MAC            Name';
       for loop := 1 to port_count do
         begin
             if length(interfaces[loop].port_no) < 4 then
                lines[loop+2] := string(interfaces[loop].port_no) + '     '
             else
               if length(interfaces[loop].port_no) < 5 then
                   lines[loop+2] := string(interfaces[loop].port_no) + '    '
               else
                   lines[loop+2] := string(interfaces[loop].port_no) + '   ';
             if interfaces[loop].admin_disable = true then
                lines[loop+2] := lines[loop+2] + 'Disabled  None   None None  None  No  100  0   0012.f2cf.1200 '
             else
                lines[loop+2] := lines[loop+2] + 'Down      None   None None  None  No  100  0   0012.f2cf.1200 ';
             //  show intrface brieft will only show the first 8 chars
             lines[loop+2] := lines[loop+2] + leftstr(interfaces[loop].descript,8);
         end;
       lines[loop+1] := 'ENDofLINES';
       page_display(lines);
  End;

  procedure display_show_modules;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if modules[loop] = 'ENDofMODULES' then
             isend := true
          else
              begin
                  writeln(modules[loop]);
                  inc(loop)
              end;
    until isend = true;
  End;

  procedure display_show_flash;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if flash[loop] = 'ENDofFLASH' then
             isend := true
          else
              begin
                  writeln(flash[loop]);
                  inc(loop)
              end;
    until isend = true;
  End;

  procedure display_show_memory;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if show_memory[loop] = 'ENDofMEMORY' then
             isend := true
          else
              begin
                  writeln(show_memory[loop]);
                  inc(loop)
              end;
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

  procedure display_running_config;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if running_config[loop] = 'end' then
             isend := true
          else
              begin
                  writeln(running_config[loop]);
                  inc(loop)
              end;
    until isend = true;
    writeln(running_config[loop]);
  End;

  procedure display_stp_protect;

  var
    lines        : array[1..385] of string;
    loop, index  : integer;

  Begin
       index := 1;
       lines[index] := '        Port    BPDU Drop Count';
       inc(index);
       for loop := 1 to port_count do
         begin
             if interfaces[loop].bpdu = true then
              begin
                if length(interfaces[loop].port_no) < 4 then
                      lines[index] := '        ' + string(interfaces[loop].port_no) + '     0'
                else
                     if length(interfaces[loop].port_no) < 5 then
                         lines[index] := '        ' + string(interfaces[loop].port_no) + '    0'
                     else
                         lines[index] := '        ' + string(interfaces[loop].port_no) + '   0';
                inc(index);
              end;
         end;
       lines[index] := 'ENDofLINES';
       page_display(lines);
  End;

  procedure display_startup_config;

  var
    loop : integer;
    isend : boolean;

  Begin
    isend := false; loop := 1;
    repeat
          if startup_config[loop] = 'end' then
             isend := true
          else
              begin
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

  procedure display_show_version;

  Begin
     writeln(code_version);
  End;

  procedure display_show_web;

  Begin
       writeln('No WEB-MANAGEMENT sessions are currently established!');
  End;

  procedure display_show_who;

  begin
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

  procedure display_show;

  var
     strLength, word_count, a : integer;
     word_list : array[1..10] of string;
     show_input : string;

  begin
        a := 1; word_count := 1;
        show_input := input;
        strlength := length(show_input);
        while (show_input[a] <> '') and (a <= strlength)do
          begin
               while (show_input[a] <> ' ') and (a <= strlength)do
                 Begin
                     word_list[word_count] := word_list[word_count] + show_input[a];
                     if show_input[a] <> '' then
                        begin
                            inc(a);
                        end
                     else
                        break;
                 End;
               inc(a);
               inc(word_count);
          end;
        case show_input[1] of
           's' : if (show_input = 'sh') or (show_input = 'sho') or (show_input = 'show') then
                               writeln('Incomplete command.')
                 else
                 if (show_input = 'sh ?') or (show_input = 'sho ?') or (show_input = 'show ?') then
                    page_Display(show_menu)
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_help(word_list[2]) = TRUE) then
                    begin
                      display_help_match(word_list[2]);
                    end
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'arp') = TRUE) then
                    display_show_arp
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'boot-preference') = TRUE) then
                    display_show_boot_pref
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'clock') = TRUE) then
                    display_show_clock
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'chassis') = TRUE) then
                    page_display(chassis)
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'cpu-utilization') = TRUE) then
                    display_show_cpu
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'defaults') = TRUE) then
                    display_show_defaults
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'dot1x') = TRUE) then
                    display_show_dot1x
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'errdisable') = TRUE) and (word_list[3] = '') then
                  Writeln('Incomplete command.')
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'errdisable') = TRUE) and (word_list[3] = '?') then
                    begin
                        Writeln('  recovery   Error disable recovery');
                        Writeln('  summary    Error disable summary')
                    end
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'errdisable') = TRUE) and (is_word(word_list[3],'summary') = TRUE)then
                    writeln
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'errdisable') = TRUE) and (is_word(word_list[3],'recovery') = TRUE)then
                    display_show_errdisabled_recovery
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'fdp') = TRUE) then
                    display_show_fdp
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'flash') = TRUE) then
                    display_show_flash
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'interface') = TRUE) and (is_word(word_list[3],'ethernet') = TRUE)then
                    begin
                        if check_int(shortstring(word_list[4])) = true then
                           display_show_int_eth(shortstring(word_list[4]))
                        else
                          Writeln('port not valid');
                    end
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'interface') = TRUE) and (is_word(word_list[3],'brief') = TRUE)then
                    display_show_int_bri
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'interface') = TRUE) then
                    display_show_int
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'modules') = TRUE) then
                    display_show_modules
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'memory') = TRUE) then
                    display_show_memory
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'port') = TRUE) and (is_word(word_list[3],'security') = TRUE) then
                    display_show_port_security
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'reload') = TRUE) then
                    display_show_reload
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'reserved-vlan-map') = TRUE) then
                    display_show_reserved_vlan
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'running-config') = TRUE) then
                    page_display(running_config)
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'startup-config') = TRUE) then
                    display_startup_config
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'stp-protect') = TRUE) then
                    display_stp_protect
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'telnet') = TRUE) then
                    display_show_telnet
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'version') = TRUE) then
                    display_show_version
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'web-connection') = TRUE) then
                    display_show_web
                 else
                 if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'who') = TRUE) then
                    display_show_who
                 else
                    begin
                      bad_command(show_input);
                     end;
        end;
  end;

  procedure vlan_loop(vlanid :string);

  var
     end_vlan_loop : boolean;

  begin
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
            else
                case input[1] of
                 '?' : page_display(vlan_menu);
                 's' : if (input = 'sh') or (input = 'sho') or (input = 'show') then
                          writeln('Incomplete command.')
                       else
                          begin
                            input := input;
                            display_show;
                          end;
                 'q' : if (input = 'qu') or (input = 'qui') or (input = 'quit')then
                       Begin
                          level := level3;
                          dec(what_level);
                          end_vlan_loop := true;
                       End;
                 'e' : if (input = 'ex') or (input = 'exi') or (input = 'exit')then
                       Begin
                          level := level3;
                          dec(what_level);
                          end_vlan_loop := true;
                       End;
                 else
                       begin
                          bad_command(input);
                       end;
          end;
        until end_vlan_loop = true;
  end; // of vlan_loop

  procedure int_loop(intid : string);

  var
     find_int     : integer;
     end_int_loop : boolean;

  begin
        end_int_loop := false;
        input := input;
        Inc(what_level);
        repeat
          level := level4 + intid + ')#';
          input := #0;
          repeat
            write(hostname, level);
//                input := get_command;
                get_input(input,out_key);
                writeln;
          until input <> '';
          word_list[1] := ''; word_list[2] := ''; word_list[3] := '';
          word_list[4] := ''; word_list[5] := '';
          get_words;
          if (is_help(word_list[1]) = true) and (length(word_list[1]) > 1) then
             Begin
                help_match(word_list[1], interface_menu)
             End
          else
             if out_key = #9 then //tab key
                tab_match(word_list[1],interface_menu)
          else
          case input[1] of
           '?' : page_display(interface_menu);
           'd' : if (is_word(word_list[1],'disable')) = true then
                    begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                interfaces[find_int].admin_disable := true
                    end;
           'i' : if (is_word(word_list[1],'interface') = true) and (is_word(word_list[2],'ethernet') = true) then
                    begin
                         if check_int(shortstring(word_list[3])) = true then
                             intid := word_list[3]
                          else
                             writeln('port not valid');
                    end;
           'p' : if (is_word(word_list[1],'port-name')) = true then
                    begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                interfaces[find_int].descript := word_list[2];
                    end;
           's' : if (input = 'sh') or (input = 'sho') or (input = 'show') then
                               writeln('Incomplete command.')
                 else
                  if (is_word(word_list[1],'stp-bpdu-guard')) = true then
                    begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                interfaces[find_int].bpdu := true;
                    end
                  else
                  if (is_word(word_list[1],'spanning-tree') = true) and (is_word(word_list[2],'root-protect') = true)then
                    begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                interfaces[find_int].root_guard := true;
                    end
                  else
                   if (is_word(word_list[1],'speed-duplex')) = true then
                      begin
                           if (is_word(word_list[2],'10-full')) = true then
                               begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '10-full';
                               end;
                           if (is_word(word_list[2],'10-half')) = true then
                               begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '10-half';
                               end;
                           if (is_word(word_list[2],'100-half')) = true then
                               begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '100-half';
                               end;
                           if (is_word(word_list[2],'100-full')) = true then
                               begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '100-full';
                               end;
                           if (is_word(word_list[2],'1000-full-master')) = true then
                               begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '1000-full-master';
                               end;
                           if (is_word(word_list[2],'1000-full-slave')) = true then
                               begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := '1000-full-slave';
                               end;
                           if (is_word(word_list[2],'auto')) = true then
                               begin
                                  for find_int := 1 to port_count do
                                     if interfaces[find_int].port_no = shortstring(intid) then
                                        interfaces[find_int].speed := 'auto';
                               end;
                      end
                   else
                      begin
                        input := input;
                        display_show;
                      end;
           'n' : if (is_word(word_list[1],'no') = true) and (is_word(word_list[2],'stp-bpdu-guard') = true) then
                    begin
                         for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                interfaces[find_int].bpdu := false;
                    end
                 else
                 if (is_word(word_list[1],'no') = true) and (is_word(word_list[2],'spanning-tree') = true) and (is_word(word_list[3],'root-protect') = true)then
                    begin
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
                  else
                     if (is_word(word_list[1],'enable')) = true then
                        begin
                           for find_int := 1 to port_count do
                             if interfaces[find_int].port_no = shortstring(intid) then
                                interfaces[find_int].admin_disable := false
                        end;
          #0 :;
          else
                    begin
                      bad_command(input);
                    end;
          end;
        until end_int_loop = true;
  end;


  procedure configure_term_loop;

  var
     end_con_term : boolean;

     procedure looking_for_help;

     begin
          if is_help(word_list[1]) = true then
             begin
               writeln('  vlan                          VLAN settings');
               writeln('  vlan-group                    VLAN group settings');
             end
          else
             if is_help(word_list[2]) = true then
                writeln('Unrecognized command')
             else
                if is_help(word_list[3]) = true then
                  Begin
                    if length(word_list[3]) = 1 then
                      begin
                        writeln('  by     VLAN type');
                        writeln('  name   VLAN name');
                        writeln('  <cr>');
                       end
                    else
                      if (word_list[3] = 'b?') or (word_list[3] = 'by?') then
                         writeln('  by     VLAN type')
                      else
                         if (word_list[3] = 'n?') or (word_list[3] = 'na?') or (word_list[3] = 'nam?') or (word_list[3] = 'name?') then
                            writeln('  name   VLAN name');
                  End
                else
                  if (word_list[4]) = '?' then
                     writeln('  ASCII string   VLAN name');
     end; // looking for help

  begin
        end_con_term := false;
        Inc(what_level);
        level := level3;
        repeat
//        input := #0;
        word_list[1] := ''; word_list[2] := ''; word_list[3] := ''; word_list[4] := '';
        repeat
            write(hostname, level);
//            input := get_command;
            get_input(input,out_key);
            writeln;
        until input <> '';
        get_words;
        if (is_help(word_list[1]) = true) and (length(word_list[1]) > 1) then
           Begin
                help_match(word_list[1], config_term_menu)
           End
        else
           if out_key = #9 then //tab key
              tab_match(word_list[1],config_term_menu)
        else
        case input[1] of
           '?' : page_display(config_term_menu);
           'i' : if (is_word(word_list[1],'interface') = TRUE) and (is_word(word_list[2],'ethernet') = TRUE) then
                     begin
                          if check_int(shortstring(word_list[3])) = true then
                             int_loop(word_list[3])
                          else
                             writeln('port not valid');
                     end
                 else
                     writeln('Incomplete command.');
           'h' :  if (is_word(word_list[1],'hostname') = TRUE) then
                     if word_list[2] <> '' then
                        begin
                          hostname := word_list[2];
                          running_config[last_line_of_running-1] := concat('hostname ',word_list[2]);
                          running_config[last_line_of_running] := 'end';
                          inc(last_line_of_running);
                        end
                     else
                        writeln('Incomplete command.');
           'q' : if is_word(word_list[1],'quit') = true then
                     Begin
                        level := level2;
                        dec(what_level);
                        end_con_term := true;
                     End;
           'r' : Begin
                    if (is_word(word_list[1],'router') = true) and (is_word(word_list[2],'?') = true)then
                       begin
                           writeln('  rip    Enable rip');
                           writeln('  vrrp   Enable vrrp');
                       End;
                    if (is_word(word_list[1],'router') = true) and (is_word(word_list[2],'rip') = true) and (is_word(word_list[3],'?') = true) then
                       writeln('rip    Enable rip')
                    else
                    if (is_word(word_list[1],'router') = true) and (is_word(word_list[2],'vrrp') = true) and (is_word(word_list[3],'?') = true) then
                       writeln('vrrp    Enable vrrp')
                    else
                       if (is_word(word_list[1],'router') = true) and (is_word(word_list[2],'rip') = true) and (word_list[3] = '') then
                         begin

                         End
                    else
                       if (is_word(word_list[1],'router') = true) and (is_word(word_list[2],'vrrp') = true) and (word_list[3] = '') then
                         begin

                         End
                    else
                       bad_command(word_list[3]);
                 End;
           's' : if (input = 'sh') or (input = 'sho') or (input = 'show') then
                               writeln('Incomplete command.')
                 else
                     begin
                         input := input;
                         display_show;
                     End;
          'e' : if is_word(word_list[1], 'exit') = true then
                     Begin
                        level := level2;
                        dec(what_level);
                        End_con_term := true;
                     End;
          'v' : if (is_help(input) = TRUE) then
                    begin
                        looking_for_help
                    End
                else
                  if (is_word(word_list[1],'vlan') = TRUE) then
                    if (is_number(word_list[2]) = TRUE) then
                      begin
                        vlans[strtoint(word_list[2])].id := shortstring(word_list[2]);
                        vlans[strtoint(word_list[2])].name := word_list[4];
                        vlan_loop(word_list[2]);
                      End
                    else
                      bad_command(word_list[2]);
          #0 :;
           else
                    begin
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
//            input := get_command;
            get_input(input,out_key);
            writeln;
         until input <> '';
         word_list[1] := ''; word_list[2] := ''; word_list[3] := '';
         word_list[4] := ''; word_list[5] := '';
         get_words;
         if (is_help(word_list[1]) = TRUE) and (length(word_list[1]) > 1) then
                    begin
                      help_match(word_list[1],enable_menu);
                    End
         else
           if out_key = #9 then //tab key
              tab_match(word_list[1],enable_menu)
         else
         case input[1] of
            'a' : ;
            'b' : ;
            'c' : if (is_word(word_list[1],'configure') = true) and (is_word(word_list[2],'terminal') = true)then
                     Configure_term_loop
                  else
                     bad_command(input);
            'd' : if (is_word(word_list[1],'debug') = true) then
                        writeln('*  Debug not implemented in Brocade-Sim');
            'e' : if (is_word(word_list[1],'exit') = true) then
                     Begin
                        level := level1;
                        dec(what_level);
                        End_enabled := true;
                     End;
            'k' : if (is_word(word_list[1],'kill') = true) then
                        writeln('*  Kill not implemented in Brocade-Sim')
                  else
                     if (input = 'kill ?') then
                        begin
                          writeln('  console   Console session');
                          writeln('  ssh       SSH session');
                          writeln('  telnet    Telnet session');
                        End;
            'n' : if (is_word(word_list[1],'ncopy') = true) then
                        writeln('*  ncopy not implemented in Brocade-Sim');
            'p' : if (is_word(word_list[1],'ping') = true) then
                        writeln('*  Ping not implemented in Brocade-Sim')
                        else
                        if (is_word(input,'page-display') = TRUE) then
                            skip_page_display := false;
            'r' : if (input = 're') or (input = 'rel') or (input = 'relo') or (input = 'reloa') or (input = 'reload') then
                     writeln('*  Reload not implemented in Brocade-Sim as yet');
            's' : if (is_word(word_list[1],'skip-page-display') = TRUE) then
                     skip_page_display := true
                  else
                     if (is_word(word_list[1],'show') = TRUE) and (is_word(word_list[2],'?') = TRUE) then
                        page_Display(show_menu)
                     else
                        if (is_word(word_list[1],'show') = true) then
                             display_show;
            't' : if (is_word(word_list[1],'telnet') = TRUE) and (word_list[2] = '') then
                     writeln('Incomplete command.')
                  else
                      if (is_word(word_list[2],'?') = TRUE) then
                         begin
                             writeln('  ASCII string      Host name');
                             writeln('  A.B.C.D           Host IP address');
                             writeln('  X:X::X:X          Host IP6 address');
                         End
                      else
                         writeln('Telnet not implemented in Brocade simulate');
            'u' : if (input = 'un') or (input = 'und') or (input = 'unde') or (input = 'undeb') or (input = 'undebug') then
                        writeln('*  Undebug not implemented in Brocade-Sim');
            'v' : if (input = 've') or (input = 'ver') or (input = 'veri') or (input = 'verif') or (input = 'verify') then
                        writeln('*  verify not implemented in Brocade-Sim');
            'w' : if (input = 'wr') or (input = 'wri') or (input = 'writ') or (input = 'write') then
                    writeln('*  Write not implemented in Brocade-Sim as yet')
                  else
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
//             input := '';
             word_list[1] := ''; word_list[1] := '';
             repeat
                write(hostname, level);
//                input := get_command;
                get_input(input,out_key);
                writeln;
             until input <> '';
             get_words;
             if (is_help(word_list[1]) = TRUE) and (length(word_list[1]) > 1) then
                    begin
                      help_match(word_list[1],top_menu);
                    End
             else
             if out_key = #9 then //tab key
                 tab_match(word_list[1],top_menu)
             else
             case input[1] of
                'e' : if is_word(word_list[1],'enable') = true then
                         Begin
                            level := level2; inc(what_level);
                            Enable_Loop;
                         End
                      else
                         if is_word(word_list[1],'exit')then
                            End_program := true;
                'p' : if is_word(word_list[1],'ping') then
                        writeln('  Ping not implemented in Brocade-Sim');
                's' : if is_word(word_list[1],'stop-traceroute') then
                                  writeln('  There is no Trace Route Operation in progress!')
                      else
                         if (is_word(word_list[1],'show') = true) and (is_word(word_list[2],'?') = true) then
                             page_Display(top_menu)
                         else
                           if (is_word(word_list[1],'show') = true) then
                             display_show;
                't' : if is_word(word_list[1],'traceroute') = true then
                          writeln('  TreaceRoute not implemented in Brocade-Sim');
                '?' : page_Display(top_menu);
                else
                   bad_command(input);
             End;
       until (End_program = True);
  End; // of my_loop

begin
  clrscr;
  try
    // Set gobal var
    skip_page_display := false;
    // init all the menus
    init_top_menu;
    init_show_menu;
    init_config_term_menu;
    init_enable_menu;
    init_interface_menu;
    init_vlan_menu;
    // Display the splash screen
    Splash_screen;
    // read from config ffiles
    Read_config;
    read_startup_config; //read in the default Brocade config
    history_pos := 1; // starting possition for CLI history.
    // main loop
    my_loop;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  End;
End.
