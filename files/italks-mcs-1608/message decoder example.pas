
type TGenSensMsg = packed record
       MsgID      :byte;       // Message Identification Value = 0x01
       Status     :byte;       // Content Depends on Message ID ==for future use
       BaromBar   :word;       // Air Pressure in mBar
       Temp       :int16;      // in 0,01 degC
       Humidity   :byte;       // Relative Humidity in %
       LevelX     :int8;       // Inverse Sinus of Spirit Level in Deg X-Direction -128 = -90 Degr .. +127 = +90 Degr
       LevelY     :int8;       // Inverse Sinus of Spirit Level in Deg Y-Direction -128 = -90 Degr .. +127 = +90 Degr
       LevelZ     :int8;       // Inverse Sinus of Spirit Level in Deg Z-Direction -128 = -90 Degr .. +127 = +90 Degr
       VibAmp     :byte;       // Amplitude of Vibration Detected == Future
       VibFreq    :byte;       // Approx. Frequency of Vibration Detected in Hz = Future
     end;

type TTrackMsg = packed record //
       MsgID      :byte;       // Message Identification Value = 0x01
       Bits       :byte;       // bit0= Start Message
                               // bit1= Object Moving
                               // bit2= Object Stopped
                               // bit3= Vibration Detected
       Temp       :int16;      // Temperature in 0,1 degC
       GPSFixAge  :byte;       // bit 0..7 = Age of last GPS Fix in Minutes,
       SatCnt_HiLL:byte;       // bit 0..4 = SatInFix, 		bit5 Latitude 25 bit 6,7 = Longitude 25,26
       Lat        :T3Byte;     // bit 0..23 = latitude  bit 0..23
       Lon        :T3Byte;     // bit 0..23 = longitude bit 0..23
     end;

type TAliveMsg = packed record //
       MsgID         :byte;    // Message Identification Value = 0x01
       Battery       :byte;    //
       Profile       :byte;    //
       CmdAck        :byte;    //
       GPSFixAge     :byte;    // bit 0..7 = Age of last GPS Fix in Minutes,
       SatCnt_HiLL   :byte;    // bit 0..4 = SatInFix, 		bit5 Latitude 25 bit 6,7 = Longitude 25,26
       Lat           :T3Byte;  // bit 0..23 = latitude  bit 0..23
       Lon           :T3Byte;  // bit 0..23 = longitude bit 0..23
     end;


function revendian32(w:int32):int32;
begin
  result := ((w shl 24)and $FF000000) or
            ((w shl  8)and $00FF0000) or
            ((w shr  8)and $0000FF00) or
            ((w shr 24)and $000000FF);
end;


function MsgIDToStr(MsgID:integer):string;
begin
  case MsgID of
    MsgIDAlive:    result:='Alive';
    MsgIDTracking: result:='Tracking';
    MsgIDGenSens:  result:='GenSens';
    MsgIDRotSens:  result:='RotSens';
    MsgIDAlarm:    result:='Alarm';
    MsgIDReboot:   result:='Reboot';
    else           result:='Unknown';
  end;
end;


procedure DecodeMsgIDGenSens(Data:TBytes);
var R:TGenSensMsg;
begin
  move(Data[0],R,sizeof(R));
  writeln('MsgID='    + MsgIDToStr(r.MsgID));
  writeln('Status='   + IntToStr(r.Status));
  writeln('BaroPres=' + format('%7.2f',[(100000+revendian16(R.BaromBar))/100]));
  writeln('Temp='     + format('%4.2f',[revendian16(r.Temp)/100]));
  writeln('Humidity=' + IntToStr(r.Humidity));
  writeln('LevelX='   + IntToStr(r.LevelX));
  writeln('LevelY='   + IntToStr(r.LevelY));
  writeln('LevelZ='   + IntToStr(r.LevelZ));
  writeln('VibAmp='   + IntToStr(r.VibAmp));
  writeln('VibFreq='  + IntToStr(r.VibFreq));
end;


procedure DecodeMsgIDTracking(Data:TBytes);
var R:TTrackMsg; FixAge:integer; lat,lon:int32;
begin
  move(Data[0],R,sizeof(R));
  writeln('MsgID='+MsgIDToStr(r.MsgID));
  writeln('Start='   +booltostr(r.Bits and $01>0,'1','0'));
  writeln('Moving='  +booltostr(r.Bits and $02>0,'1','0'));
  writeln('Stopped=' +booltostr(r.Bits and $04>0,'1','0'));
  writeln('VibrDet=' +booltostr(r.Bits and $08>0,'1','0'));
  writeln('Temp='+format('%4.2f',[revendian16(r.Temp)/100]));
  if r.GPSFixAge<60   then FixAge:=r.GPSFixAge              else
  if r.GPSFixAge<120  then FixAge:=60+(r.GPSFixAge-60)*5    else
  if r.GPSFixAge<255  then FixAge:=360+(r.GPSFixAge-120)*30 else FixAge:=0;
  if r.GPSFixAge<255  then
    writeln('FixAge='+timetostrx(-FixAge/minperday))
  else
    writeln('Fixage=""');
  writeln('SatInFix='+IntToStr(r.SatCnt_HiLL and $1F));
  Lat := (r.Lat[0] shl 16) or (r.Lat[1] shl 8) or (r.Lat[2]);
  Lon := (r.Lon[0] shl 16) or (r.Lon[1] shl 8) or (r.Lon[2]);
  if r.SatCnt_HiLL and $20>0 then lat:=lat or $FF000000;
  if r.SatCnt_HiLL and $40>0 then lon:=lon or $01000000;
  if r.SatCnt_HiLL and $80>0 then lon:=lon or $FE000000;
  writeln('Lat='+format('%7.5f',[Lat/100000]));
  writeln('Lon='+format('%7.5f',[Lon/100000]));
end;


procedure DecodeMsgIDAlive(Data:TBytes);
var R:TAliveMsg; FixAge:integer; lat,lon:int32;
begin
  move(Data[0],R,sizeof(R));
  writeln('MsgID='+MsgIDToStr(r.MsgID));
  writeln('Format='   +inttostr(r.MessageFormat));
  writeln('Profile='  +inttostr(r.Profile));
  writeln('CmdAck='  +inttostr(r.CmdAck));
  if r.GPSFixAge<60   then FixAge:=r.GPSFixAge              else
  if r.GPSFixAge<120  then FixAge:=60+(r.GPSFixAge-60)*5    else
  if r.GPSFixAge<255  then FixAge:=360+(r.GPSFixAge-120)*30 else FixAge:=0;
  if r.GPSFixAge<255  then writeln('FixAge='+timetostrx(-FixAge/minperday))
                      else writeln('Fixage=""');
  writeln('SatInFix='+IntToStr(r.SatCnt_HiLL and $1F));
  Lat := (r.Lat[0] shl 16) or (r.Lat[1] shl 8) or (r.Lat[2]);
  Lon := (r.Lon[0] shl 16) or (r.Lon[1] shl 8) or (r.Lon[2]);
  if r.SatCnt_HiLL and $20>0 then lat:=lat or $FF000000;
  if r.SatCnt_HiLL and $40>0 then lon:=lon or $01000000;
  if r.SatCnt_HiLL and $80>0 then lon:=lon or $FE000000;
  writeln('Lat='+format('%7.5f',[Lat/100000]));
  writeln('Lon='+format('%7.5f',[Lon/100000]));
  writeln('Battery='  +format('%3.0f%%',[r.Battery*100/256]));
end;


procedure DecodePL(Data:TBytes);
begin
  case data[0] of
    MsgIDAlive    : DecodeMsgIDAlive(Data);
    MsgIDTracking : DecodeMsgIDTracking(Data);
    MsgIDGenSens  : DecodeMsgIDGenSens(Data);
    else raise exception.Create('Invalid message ID');
  end;
end;


