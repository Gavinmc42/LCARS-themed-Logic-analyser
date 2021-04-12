program lcars;

{$mode objfpc}{$H+}

{ VideoCore IV example - LCARS Demo                                           }

uses
  RaspberryPi, {Include RaspberryPi to make sure all standard functions are included}
  GlobalConst,
  GlobalTypes,
  BCM2835,
  Platform,
  Threads,
  Console,
  Devices,
  math,
  SysUtils,
  GPIO,
  //FileSystem,
  //FATFS,       {Include the FAT file system driver}
  //MMC,         {Include the MMC/SD core to access our SD card}
  //Time,
  GraphicsConsole,
  Services,
  Framebuffer,
  Classes,
  //uScreenshot,
  //FPimage,
  //fpreadbmp,
  //fpwritepng,
  //Zipper,
  //RGraphics,
  OpenVG,       {Include the OpenVG unit so we can use the various types and structures}
  VGShapes2,     {Include the VGShapes unit to give us access to all the functions}
  VC4;          {Include the VC4 unit to enable access to the GPU}

var
 gpiodata:LongWord;

 GHandle:TWindowHandle;

 Width:Integer;  {A few variables used by our shapes example}
 Height:Integer;

 Gwidth:Word;
 Gheight:Word;
 
 Top:VGfloat;
 Grid:VGfloat;
 ShapeX:VGfloat;
 ShapeY:VGfloat;
 ShapeW:VGfloat;
 ShapeH:VGfloat;
 Dotsize:VGfloat;
 Spacing:VGfloat;
 
 CX:VGfloat;
 CY:VGfloat;
 
 EX:VGfloat;
 EY:VGfloat;
 
 PolyX:array[0..4] of VGfloat;
 PolyY:array[0..4] of VGfloat;
 
 Fontsize:Integer;
 
 STcolor0:TVGShapesColor;
 STcolor1:TVGShapesColor;
 STcolor2:TVGShapesColor;
 STcolor3:TVGShapesColor;
 STcolor4:TVGShapesColor;
 STcolor5:TVGShapesColor;
 STcolor6:TVGShapesColor;
 STcolor7:TVGShapesColor;
 STcolor8:TVGShapesColor;

 Hour,Min,Sec,HSec : word;


 //s: string;

 //Filename0:String;
 //Filename1:String;
 //Filename2:String;
 //FileStream:TFileStream;
 //StringList:TStringList;

 //image: TFPCustomImage;
 //reader: TFPCustomImageReader;
 //writer: TFPCustomImageWriter;

 //image2: TFPCustomImage;
 //reader2: TFPCustomImageReader;
 //writer2: TFPCustomImageWriter;

 //DestFilename:String;
 //DestFilename2:String;

 //ImageNo:Integer;
 //Device:TDiskDevice;
 //Volume:TDiskVolume;
 //Drive:TDiskDrive;


procedure Button(X,Y,W,H:Integer;const Color:TVGShapesColor);
begin
   {Button}
   VGShapesSetFill(Color);
   VGShapesRect(Grid * X,Height - Grid * Y,Grid * W,Grid * H);

end;


procedure RButton(X,Y,W,H:Integer;const Color:TVGShapesColor);
begin
 {Rounded Button}
 VGShapesSetFill(Color);
 VGShapesRoundrect(Grid * X,Height - Grid * Y,Grid * W,Grid * H,Grid * H,Grid * H);

end;

procedure LRButton(X,Y,W,H:Integer;const Color:TVGShapesColor);
begin
 {Left Rounded Button}
 VGShapesSetFill(Color);
 VGShapesRect(Grid * (X + H/2),Height - Grid * Y,Grid * (W - H/2) ,Grid * H);
 VGShapesRoundrect(Grid * X,Height - Grid * Y,Grid * H ,Grid * H,Grid * H,Grid * H);


end;

procedure RRButton(X,Y,W,H:Integer;const Color:TVGShapesColor);
begin
 {Right Rounded Button}
 VGShapesSetFill(Color);
 VGShapesRect(Grid * X,Height - Grid * Y,Grid * (W - H /2  ),Grid * H);
 VGShapesRoundrect(Grid * (X + W - H),Height - Grid * Y, Grid * H,Grid * H,Grid * H,Grid * H);

end;

procedure LDElbow(X,Y,W,H,EW,EH:Integer;const Color:TVGShapesColor);
begin
 {Left Down Elbow}
 VGShapesSetFill(Color);

 VGShapesRect(Grid * (X + EW/2) ,Height - Grid * Y,Grid * W,Grid * H);
 VGShapesArc(Grid * (X + EW/2),Height - Grid * (Y + EW/2 - H), Grid * EW, Grid * EW,90, 90);

 VGShapesRect(Grid * (X + EW/2 - 1),Height - Grid * (Y + EW/2 - H), Grid * EW,Grid * EH);

 VGShapesSetFill(STcolor0);
 VGShapesRoundrect(Grid * (X + EW),Height - Grid * (Y + EH + H),Grid * EW,Grid * (H + EH), Grid * 2 * H,Grid * 2 *H);

end;

procedure RUElbow(X,Y,W,H:Integer;const Color:TVGShapesColor);
begin
 {Right UP Elbow}
 VGShapesSetFill(Color);
 VGShapesRect(Grid * X,Height - Grid * Y,Grid * (W - H /2  ),Grid * H);
 VGShapesRoundrect(Grid * (X + W - H),Height - Grid * Y, Grid * H,Grid * H,Grid * H,Grid * H);

end;

procedure LUElbow(X,Y,W,H,EW,EH:Integer;const Color:TVGShapesColor);
begin
 {Left UP Elbow}
 VGShapesSetFill(Color);

 VGShapesRect(Grid * (X + EW/2) ,Height - Grid * (Y + EH),Grid * W,Grid * H);
 VGShapesArc(Grid * (X + EW/2),Height - Grid * (Y ), Grid * EW, Grid * EW,180, 90);

 VGShapesRect(Grid * (X + EW/2 - 1),Height - Grid * (Y + EW/2), Grid * EW,Grid * EH);

 VGShapesSetFill(STcolor0);
 VGShapesRoundrect(Grid * (X + EW),Height - Grid * (Y + EH - H),Grid * EW,Grid * EH, Grid * 2 * H,Grid * 2 *H);

end;

procedure RDElbow(X,Y,W,H:Integer;const Color:TVGShapesColor);
begin
 {Right Down Elbow}
 VGShapesSetFill(Color);
 VGShapesRect(Grid * X,Height - Grid * Y,Grid * (W - H /2  ),Grid * H);
 VGShapesRoundrect(Grid * (X + W - H),Height - Grid * Y, Grid * H,Grid * H,Grid * H,Grid * H);

end;



begin
  //Enable Console Autocreate
 ConsoleFramebufferDeviceAdd(FramebufferDeviceGetDefault);

 GHandle:=GraphicsWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_FULL);

 //while not DirectoryExists('C:\') do
 // begin
   {Sleep for a second}
 //  Sleep(1000);
//end;

 {Initialize OpenVG and the VGShapes unit}
 VGShapesInit(Width,Height);

 {Convert the RGB color to use for our shapes into a TVGShapesColor record}
 VGShapesRGB(255,153,0,STcolor1);
 VGShapesRGB(204,153,204,STcolor2);
 VGShapesRGB(153,153,204,STcolor3);
 VGShapesRGB(204,102,102,STcolor4);
 VGShapesRGB(255,204,153,STcolor5);
 VGShapesRGB(153,153,255,STcolor6);
 VGShapesRGB(255,153,102,STcolor7);
 VGShapesRGB(204,102,153,STcolor8);
 VGShapesRGB(0,0,0,STcolor0);

  {Calculate some default values based on the size of the screen, remember that
  OpenVG coordinates put 0,0 at the bottom left NOT the top left like most other
  things}
 Grid:=Width * 0.005;
 Top:=Height * 0.93;


 ShapeX:=Grid * 2;
 ShapeY:=Grid * 6;
 ShapeW:=Grid * 10;
 ShapeH:=Grid * 3;

 Fontsize:=Trunc(Height * 0.033);

 {Start a picture the full width and height of the screen}
 VGShapesStart(Width,Height);
 {Make the background black}
 VGShapesBackground(0,0,0);

 VGShapesWindowClear();


 Button(2,16,20,11,STcolor5);

 Button(2,28,20,11,STcolor5);



 LUElbow(2,29,46,3,20,10, STcolor2);

 Button(59,39,80,3,STcolor6);
 Button(140,39,58,3,STcolor5);

 LDElbow(2,43,186,3,20,10, STcolor1);

 Button(2,62,20,11,STcolor8);

 Button(2,74,20,11,STcolor6);

 Button(2,86,20,11,STcolor3);

 Button(2,98,20,11,STcolor2);

 Button(2,110,20,11,STcolor7);

 Button(2,122,20,11,STcolor3);

 Button(2,134,20,11,STcolor2);

 Button(2,146,20,11,STcolor7);

 { Controls }
 RButton(30,35,25,6,STcolor6);


 //RRButton(2,69,10,5,STcolor6);

 //LRButton(2,75,5,5,STcolor7);

 //RRButton(2,82,5,5,STcolor8);

 //VGShapesArc(500,300,550,350,90, 90);



  {Draw the title of our demo towards the right hand edge}
 VGShapesSetFill(STcolor1);
 VGShapesTextEnd(120 * Grid,Height - 49 * Grid,'BINARY STATUS ANALYSER',VGShapesSansTypeface,Fontsize );

 VGShapesSetFill(STcolor0);

 VGShapesTextEnd(20 * Grid, Height - 14 * Grid,'I2C0',VGShapesSansTypeface,Fontsize div 2);
 VGShapesTextEnd(20 * Grid, Height - 26 * Grid,'I2C1',VGShapesSansTypeface,Fontsize div 2);
 VGShapesTextEnd(20 * Grid, Height - 60 * Grid,'GPIO4',VGShapesSansTypeface,Fontsize div 2);
 VGShapesTextEnd(20 * Grid, Height - 72 * Grid,'GPIO5',VGShapesSansTypeface,Fontsize div 2);
 VGShapesTextEnd(20 * Grid, Height - 84 * Grid,'GPIO6',VGShapesSansTypeface,Fontsize div 2);
 VGShapesTextEnd(20 * Grid, Height - 96 * Grid,'GPIO7',VGShapesSansTypeface,Fontsize div 2);
 VGShapesTextEnd(20 * Grid, Height - 108 * Grid,'GPIO8',VGShapesSansTypeface,Fontsize div 2);
 VGShapesTextEnd(20 * Grid, Height - 120 * Grid,'GPIO9',VGShapesSansTypeface,Fontsize div 2);
 VGShapesTextEnd(20 * Grid, Height - 132 * Grid,'GPIO10',VGShapesSansTypeface,Fontsize div 2);
 VGShapesTextEnd(20 * Grid, Height - 144 * Grid,'GPIO11',VGShapesSansTypeface,Fontsize div 2);



 {Quadratic bezier}
 //VGShapesSetFill(STcolor2);
 //VGShapesQbezier(300,300,400,400,500,400);

 {Cubic bezier}

 //VGShapesCbezier(50,300,50,350,50,350, 70, 350);

 GPIOFunctionSelect(GPIO_PIN_14,GPIO_FUNCTION_IN);

 {End our picture and render it to the screen}
 VGShapesEnd;


  //Filename1 := 'C:\screenshot1.bmp';
  //VGShapesSaveEnd(Filename1);

       //ConsoleWindowWriteLn(WindowHandle, 'Start time '  +  IntToStr(GetTickCount64)) ;
       //Gwidth:=GraphicsWindowGetMaxX(GHandle);
       //GHeight:=GraphicsWindowGetMaxY(GHandle);
       //try
       //   begin
       //        SaveScreen(Filename1,0 , 0, Gwidth, GHeight , 16);
       //   end;
       //except
        //  on E: Exception do
       //    begin
           //ConsoleWindowWriteLn(WindowHandle, 'Error ' + E.Message);
        //   end;
      // end;

 {Sleep for 10 seconds}
 Sleep(100000);
 
 {Clear our screen, cleanup OpenVG and deinitialize VGShapes}
 VGShapesFinish;
 
 {VGShapes calls BCMHostInit during initialization, we should also call BCMHostDeinit to cleanup}
 BCMHostDeinit;
 

 {Halt the main thread here}
 ThreadHalt(0);
end.

