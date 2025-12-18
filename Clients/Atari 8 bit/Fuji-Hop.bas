' Fuji-Rama Title Page
' Written in Atari FastBasic
' @author  Simon Young (with lots of help from Eric Carr and Thomas Cherryhomes)
' @version Deptember 2025
' This is a client for the Fuji-Rama game server

ReleaseMajor=0
ReleaseMinor=1

' FujiNet AppKey settings. These should not be changed
AK_LOBBY_CREATOR_ID = 1     ' FUJINET Lobby
AK_LOBBY_APP_ID  = 1        ' Lobby Enabled Game
AK_LOBBY_KEY_USERNAME = 0   ' Lobby Username key
AK_LOBBY_KEY_SERVER = 4     ' Fuji-Rama Client registered as Lobby appkey 4

' Fuji-Llama client
AK_CREATOR_ID = $B00B       ' Simon Young's creator id
AK_APP_ID = 1               ' Fuji-Llama app id
AK_KEY_SHOWHELP = 0         ' Shown help
AK_KEY_COLORTHEME = 1       ' Color theme

' Silence the loud SIO noise
poke 65,0


DATA NAppKeyBlock()=0,0,0

' Disable BASIC on XL/XE to make more memory available. 
if dpeek(741)-$BC00<0
  ' Disable BASIC
  pause: poke $D301, peek($D301) ! 2: poke $3F8, 1
  ' Set memtop to 48K
  dpoke 741, $BC00
endif

' --------- DIM all the string Arrays -------------------
Dim TableID$(6),TableName$(6),PlayerName$(5),PlayerHand$(5),PlayerValidMoves$(5)

' **************************************************
' ***************** IMPORTANT NOTE *****************

' ** These variables are dimensioned in a specific order to reduce wasted
' space when aligning certain arrays to 4K and 1K boundaries

' Receive buffer
dim responseBuffer(1023) BYTE

' Align screenBuffer at 4096 boundary (and charBuffer at 1024 boundary afterward)
i = (&responseBuffer+1023)/4096*4096 - &responseBuffer + 3071

' If space is available until the next 4096 boundary,
' initialize some player array strings to use this available space
j=0
while i > 768
  TableID$(j)="":TableName$(j)="":PlayerName$(j)=""
  i=i-768
  inc j
wend

' Any remaining space is assigned to a filler array
if i>0 then dim filler(i) BYTE

' The screenbuffer holds the Playfield screen (40*26=1040), followed by an offscreen buffer of the same size.
' It only needs 2080 bytes.
' The charBuffer that is dimensioned immediately following the playfield needs to be 1024 byte aligned.
' This gives us 992 bytes (1024*3-2080) extra space to do something with.
' We use 768 of that to allocate another set of player strings
' 1024*3=3072 bytes, - 768 = 2304 bytes we are allocating below
dim screenBuffer(2303) BYTE

' Allocate 3 more strings, taking up 768 bytes 
TableID$(j)="":TableName$(j)="":PlayerName$(j)=""

' Now charBuffer will be aligned to a 1K boundary
dim charBuffer(1023) BYTE

' *************** END IMPORTANT NOTE ***************
' **************************************************
DIM Screen
' DATA - Character Fonts
' Custom character set for FujiRama - 128 characters, 8 bytes each
' Size: 1024 bytes
data font() byte = 0,0,0,0,0,0,0,0,
data byte = 0,0,64,64,64,64,64,85,
data byte = 0,0,0,0,0,0,0,85,
data byte = 0,0,1,1,1,1,1,85,
data byte = 0,0,64,64,64,64,76,85,
data byte = 0,0,64,64,76,64,76,85,
data byte = 0,0,76,64,76,64,76,85,
data byte = 0,0,0,0,0,0,32,85,
data byte = 0,0,0,0,32,0,32,85,
data byte = 0,0,32,0,32,0,32,85,
data byte = 32,0,32,0,32,0,32,85,
data byte = 0,0,1,1,1,1,33,85,
data byte = 0,0,1,1,33,1,33,85,
data byte = 10,47,191,181,183,183,183,181,
data byte = 128,224,248,120,248,248,248,248,
data byte = 183,183,183,183,183,191,47,10,
data byte = 0,32,136,136,136,136,136,32,
data byte = 0,32,160,32,32,32,32,168,
data byte = 0,32,136,136,8,32,128,168,
data byte = 0,32,136,8,32,8,136,32,
data byte = 0,8,136,136,168,8,8,8,
data byte = 0,168,128,160,8,8,8,160,
data byte = 0,40,128,160,136,136,136,32,
data byte = 0,168,136,8,32,32,32,32,
data byte = 0,32,136,136,32,136,136,32,
data byte = 0,32,136,136,136,40,8,160,
data byte = 0,0,32,32,0,0,32,32,
data byte = 248,248,248,248,248,248,224,128,
data byte = 5,21,26,26,106,106,106,106,
data byte = 85,85,170,170,170,170,170,170,
data byte = 64,80,144,148,164,164,164,164,
data byte = 12,12,12,12,12,12,12,12,
data byte = 0,0,0,0,255,255,0,0,
data byte = 0,32,168,136,136,168,136,136,
data byte = 0,160,136,136,160,136,136,160,
data byte = 0,40,128,128,128,128,128,40,
data byte = 0,160,136,136,136,136,136,160,
data byte = 0,168,136,128,160,128,128,168,
data byte = 0,168,136,128,160,128,128,128,
data byte = 0,40,136,128,152,136,136,40,
data byte = 0,136,136,136,168,136,136,136,
data byte = 0,168,32,32,32,32,32,168,
data byte = 0,40,8,8,8,8,136,32,
data byte = 0,136,136,160,160,136,136,136,
data byte = 0,128,128,128,128,128,128,168,
data byte = 0,136,168,168,136,136,136,136,
data byte = 0,136,136,168,168,168,136,136,
data byte = 0,32,136,136,136,136,136,32,
data byte = 0,160,136,136,136,160,128,128,
data byte = 0,32,136,136,136,136,32,8,
data byte = 0,160,136,136,136,160,136,136,
data byte = 0,40,136,128,32,8,136,160,
data byte = 0,168,32,32,32,32,32,32,
data byte = 0,136,136,136,136,136,136,168,
data byte = 0,136,136,136,136,168,32,32,
data byte = 0,136,136,136,136,168,168,136,
data byte = 0,136,136,32,32,136,136,136,
data byte = 0,136,136,136,168,32,32,32,
data byte = 0,168,8,32,32,128,128,168,
data byte = 106,106,106,106,26,26,21,5,
data byte = 170,170,170,170,170,170,85,85,
data byte = 164,164,164,164,148,144,80,64,
data byte = 106,106,106,106,106,106,106,106,
data byte = 170,170,170,170,170,170,170,170,
data byte = 164,164,164,164,164,164,164,164,
data byte = 165,149,154,154,106,106,106,106,
data byte = 170,254,254,254,190,190,190,190,
data byte = 190,190,190,190,190,255,255,170,
data byte = 255,255,171,171,171,171,171,255,
data byte = 255,234,234,234,234,234,255,255,
data byte = 255,171,171,171,171,171,255,255,
data byte = 171,171,235,235,235,235,235,255,
data byte = 255,171,171,171,171,171,171,171,
data byte = 170,170,255,255,234,234,234,234,
data byte = 170,255,255,235,235,234,234,234,
data byte = 255,235,235,235,235,235,235,255,
data byte = 5,21,26,26,104,99,99,98,
data byte = 85,85,170,170,168,35,35,2,
data byte = 64,80,144,148,164,36,36,36,
data byte = 98,104,98,98,98,98,98,98,
data byte = 170,168,170,238,238,170,186,186,
data byte = 36,164,36,36,36,36,36,36,
data byte = 98,98,104,106,104,104,104,104,
data byte = 254,186,168,18,18,68,100,168,
data byte = 36,36,164,164,164,164,164,164,
data byte = 96,96,97,97,17,19,23,5,
data byte = 100,100,85,17,17,19,87,85,
data byte = 36,36,36,36,20,16,80,64,
data byte = 255,252,240,240,192,192,192,0,
data byte = 255,63,15,15,3,3,3,0,
data byte = 0,192,192,192,240,240,252,255,
data byte = 0,3,3,3,15,15,63,255,
data byte = 10,47,191,181,183,183,183,183,
data byte = 12,12,12,12,252,252,12,12,
data byte = 12,12,12,12,15,15,12,12,
data byte = 0,0,0,0,255,255,12,12,
data byte = 128,224,248,248,120,120,120,120,
data byte = 5,21,31,31,126,126,126,126,
data byte = 85,85,255,239,238,238,238,238,
data byte = 64,80,208,212,244,244,244,244,
data byte = 126,126,126,126,122,122,122,123,
data byte = 238,238,238,238,238,238,238,239,
data byte = 244,244,244,244,180,180,180,180,
data byte = 123,123,127,127,125,125,125,125,
data byte = 239,239,255,255,119,247,247,119,
data byte = 180,180,244,244,244,244,244,244,
data byte = 125,125,125,125,31,31,21,5,
data byte = 247,247,247,245,255,255,85,85,
data byte = 244,244,244,244,212,208,80,64,
data byte = 16,16,16,85,16,16,16,16,
data byte = 16,16,16,85,16,16,16,0,
data byte = 0,0,16,21,16,16,0,0,
data byte = 16,32,168,169,168,168,32,16,
data byte = 16,48,184,236,236,236,184,48,
data byte = 106,106,106,106,255,255,0,0,
data byte = 170,170,170,170,255,255,0,0,
data byte = 0,0,0,0,0,32,32,128,
data byte = 183,183,183,183,181,191,47,10,
data byte = 0,0,0,80,0,0,0,0,
data byte = 0,0,0,0,15,15,12,12,
data byte = 0,0,0,0,252,252,12,12,
data byte = 12,12,12,12,15,15,0,0,
data byte = 12,12,12,12,252,252,0,0,
data byte = 164,164,164,164,255,255,0,0,
data byte = 0,8,8,32,32,32,128,128,
data byte = 0,0,0,0,168,0,0,0,
data byte = 12,12,12,12,255,255,0,0,
data byte = 120,120,120,120,248,248,224,128



' DLI Colors 
data background_color()B.=$0,0,0
data text_color()B.=$0E,$0E,0

' Color Themes: (Background & card border)
' Themes: Green, Blue, Brown, Gray
DATA colorThemeMap()      =  $B4,$88,  $84,$08, $22,$28, $04,$08,' NTSC
DATA                      =  $A4,$78,  $74,$08, $12,$18, $04,$08 ' PAL 
colorTheme=-1

serverEndpoint$=""
query$=""
' Read server endpoint stored from Lobby
@NReadAppKey AK_LOBBY_CREATOR_ID, AK_LOBBY_APP_ID, AK_LOBBY_KEY_SERVER, &serverEndpoint$

' Parse endpoint url into server and query
if serverEndpoint$<>""
  for i=1 to len(serverEndpoint$)
    if serverEndpoint$[i,1]="?"
      query$=serverEndpoint$[i]
      serverEndpoint$=serverEndpoint$[1,i-2]
      exit
    endif
  next
else
  ' Default to known server if not specified by lobby. Override for local testing
  serverEndpoint$="N:https://fujillama.spysoft.nz"
  QUERY$=""$9B 

endif

' Write server endpoint back to app key so when game is relaunched without the lobby it uses the same server
@NWriteAppKey AK_LOBBY_CREATOR_ID, AK_LOBBY_APP_ID, AK_LOBBY_KEY_SERVER, &serverEndpoint$

serverEndpoint$="N:http://192.168.68.200:8080" ' Local server for testing

' Fuji-Net Setup Variblies 
UNIT=1
JSON_MODE=1
URL$=""
JSON$="/tables"
dummy$=""

' Initialize strings and Arrays - this reserves their space in memory so NInput can write to them
Dim TableCurrentPlayers(6),TableMaxPlayers(6),TableStatus(6),PlayerStatus(5),PlayerHandCount(5),PlayerWhiteTokens(5),PlayerBlackTokens(5)
Dim PlayerScore(5),PlayerRoundScore(5),GameStatus(5),xStart(5),yStart(5),CardXSlot(7)
for i=0 to 6
 TableID$(i)=""
 TableName$(i)=""
 TableCurrentPlayers(i)=0
 TableMaxPlayers(i)=0
 TableStatus(i)=0
next i
CardXSlot(1)=8:CardXSlot(2)=12:CardXSlot(3)=16:CardXSlot(4)=20:CardXSlot(5)=24:CardXSlot(6)=28:CardXSlot(7)=32
CardYSlot=20
ok=0
' Player and table selection variables
TableNumber=0
myName$=""
 ' Read player's name from app key
  @NReadAppKey AK_LOBBY_CREATOR_ID, AK_LOBBY_APP_ID, AK_LOBBY_KEY_USERNAME, &myName$
  @ToUpper(&myName$)

if len(myName$)=0 then myName$="LORENZO" ' Default if not loaded from the App key 
if len(myName$)>10 then myName$=myName$[1,10] ' Limit name to 10 characters
for i=1 to len(myName$)
  if myName$[i,1]=" " 
  myName$=myName$[1,i-1]  ' if space in name truncate it
  exit
  endif
next i

' Error variable
_ERR=0    
' Index variable for reading FujiNet JSON data
INDEX=0
' Variables for NInput helper code
__NI_unit=0
__NI_index=0
__NI_bufferEnd=0
__NI_indexStop=0
__NI_resultLen=0

' Setup and Clear all the Game state variables
@ClearState

POKE 731,255 ' Turn off keyclick
TIMER
WaitTime=Time
@InitScreen
@TitleScreen
@MainLoop
@QuitGame

' MY ROUTINES
PROC ClearState
  Drawdeck=0
  DiscardTop=0
  LastMovePlayed$=""
  PreviousLastMovePlayed$=""
  for i=0 to 5
  playerName$(i)=""
  PlayerStatus(i)=0
  PlayerHandCount(i)=0
  PlayerWhiteTokens(i)=0
  PlayerBlackTokens(i)=0
  PlayerScore(i)=0
  PlayerHand$(i)=""
  PlayerValidMoves$(i)=""
  PlayerRoundScore(i)=0
  GameStatus(i)=0
  next i
  move$=""
  PlayerIndex=0
  dealt=0
  leaveTableFlag=0
  countdown =60
  jiffy=0
EndProc

Proc MainLoop
  ' Loop until the player has successfully joined a table
  DO
    Repeat
      if QUERY$[1,1]<>"?"
        @tableSelection
      else 
        ' tablenumber=1 
          for i=1 to len(QUERY$)
            if QUERY$[i,1]="="
            TableID$(TableNumber)=QUERY$[i+1,5]
            endif
          next i
        @JoinTable
      Endif
      @checkErrors
    UNTIL OK=1
    
    REPEAT ' loop until the  game starts
      if Time>500
        @readGameState
        @DrawGameState
        TIMER 
      ENDIF
      @ReadKeyPresses
    UNTIL GameStatus(tablenumber)=3
        @readGameState
        @DrawGameState
    REPEAT ' loop until the round ends
        if playerStatus(PlayerIndex)=1 and Time>1500
            TIMER
            @readGameState
            if LastMovePlayed$<>PreviousLastMovePlayed$ then @DrawGameState
        ENDIF
        if playerStatus(PlayerIndex)<>1
            @readGameState
            if LastMovePlayed$<>PreviousLastMovePlayed$ then @MoveAnimation
            @DrawGameState
        ENDIF
      @ReadKeyPresses
      if playerStatus(PlayerIndex)=1
        jiffy=jiffy+1
        if jiffy=50
          jiffy=0
          countdown=countdown-1
        ENDIF
      @POS 36,17: @PrintVAL CountDown:@Print &" " 
        if countdown<=0 
          move$="F"
          @BadBeep
          @PlayMove
          playerStatus(PlayerIndex)=0
        ENDIF
      ENDIF
      if GameStatus(tablenumber)=4 then @ShowResults
    UNTIL GameStatus(tablenumber)=5
    @ShowGameOver
  LOOP
ENDPROC

PROC MoveAnimation
  dummy$=lastMovePlayed$[1,len(playerName$(playerIndex))]
  if dummy$=playerName$(playerIndex) then exit
  currentplayer=6
  for a=0 to 5
  dummy$=lastMovePlayed$[1,len(playerName$(a))]
    if dummy$=playerName$(a) and dummy$<>""
      currentplayer=a
      Exit
    ENDIF
  next a 
  if currentplayer=6 then exit
  dummy$=lastMovePlayed$[len(playerName$(currentplayer))+2,4]  
  @POS 1,1
  @POS 1,2: @PrintUpper &PlayerName$(currentplayer):@printUpper &" is:"
  if dummy$="drew" 
    @POS 1,3: @PrintUpper &"Drawing"
    inc Drawdeck
    @UpdateScreenBuffer
    @DrawCardFromDeck xStart(currentplayer),yStart(currentplayer),9 
  elif dummy$="play" 
    @POS 1,3: @PrintUpper &"Discarding"
    @PlayCard a
  elif dummy$="fold" 
    @POS 1,3: @PrintUpper &"Folding"
  Endif
EndProc

PROC TitleScreen
  @ClearKeyQueue
  @EnableDoubleBuffer
  @ResetScreen
  X=13
  @POS X,1: @Print &"      m"
  @POS X,2: @Print &"     mpm"
  @POS X,3: @Print &"FUJIopqpvNET"
  @POS X,4: @Print &"     nmpv"
  @POS X,5: @Print &"      nmm"
  @POS X+3,7:@Print &"PRESENTS"
  @POS X+2,8:@Print &"FUJI-LLAMA"
  @POS X-8,10:@Print &"A CARD GAME FOR UP TO 6 PLAYERS"
  @DrawCard 5,13,1
  @DrawCard 9,13,2
  @DrawCard 13,13,3
  @DrawCard 17,13,4
  @DrawCard 21,13,5
  @DrawCard 25,13,6
  @DrawCard 29,13,7
  @DrawCard 33,13,8
  X=(32-len(MyName$))/2
  @POS X,18:@Print &"WELCOME ":@Print &MyName$
  @POS 7,20:@Print &"PRESS ANY KEY TO CONTINUE"
  @POS 36,25:@Print &"V":@PrintVAL ReleaseMajor:@Print &":":@PrintVAL ReleaseMinor
  @POS 5,25:@Print &"H-HELP C-COLOR N-NAME Q-QUIT"
  @DrawBufferEnd
  ' @ShowScreen
  Repeat 
  GET K
  if K=67 then @CycleColorTheme
  if K=78 
    @GoodBeep
    @SetPlayerName
    @TitleScreen
  Elif K=72 
    @GoodBeep
    @DisplayHelpDialog
    @TitleScreen
  Elif K=81 
    @GoodBeep
    @AskSure 2 ' Ask to confirm leaving quiting the program
    @TitleScreen
  ENDIF
  UNTIL K<>0
  @GoodBeep
ENDPROC

PROC TableSelection
  ' This procedure draws the table selection screen and displays the tables available to join
  @ClearState
  @ClearKeyQueue
  @EnableDoubleBuffer
  @ResetScreen
  @DrawTableSelection
  @DrawBufferEnd
  JSON$="/tables"
  @CallFujiNet
  @NInputInit UNIT, &responseBuffer
  INDEX=0
  do
  ' If the first read is empty, we reached the end
  @NInput &dummy$ : if len(dummy$) = 0 then exit
  @NInput &TableID$(INDEX)
  @NInput &dummy$ : @NInput &TableName$(INDEX)
  @NInput &dummy$ : @NInput &dummy$:TableCurrentPlayers(INDEX)=VAL(dummy$)
  @NInput &dummy$ : @NInput &dummy$:TableMaxPlayers(INDEX)=VAL(dummy$)
  @NInput &dummy$ : @NInput &dummy$:TableStatus(INDEX)=VAL(dummy$)
  INC INDEX
  loop 
  @EnableDoubleBuffer 
  @ResetScreen
  @DrawTableSelection
  X=5:Y=7
  for a=0 to 6
  @POS X,Y:@Print &STR$(A+1)
  @Print & ":"
  @PrintUpper & TableName$(a)
  @POS 27,Y
  if TableStatus(a)=0 or TableStatus(a)=2
    @PrintUpper &"OPEN"
  Else
    @PrintUpper &"BUSY"
  ENDIF
  @POS 32,Y:@PrintVal TableCurrentPlayers(a)
  @POS 33,Y:@PrintUpper &"/"
  @POS 34,Y:@PrintVal TableMaxPlayers(a)
  y=y+2
  next a
  @DrawBufferEnd
  @POS 6,22: @Print & "PRESS A TABLE NUMBER TO JOIN"
  @POS 1,25:@Print &"H-HELP C-COLOR N-NAME Q-QUIT R-REFRESH"

  TableNumber=0
  REPEAT
  GET K
  
  if K=67 then @CycleColorTheme
  if K=78 
    @GoodBeep
    @SetPlayerName
    @TableSelection
  Elif K=72 
    @GoodBeep
    @DisplayHelpDialog
    @TableSelection
  Elif K=81 
    @GoodBeep
    @AskSure 2 
    @TableSelection
  Elif K=82
    @GoodBeep
    @TableSelection
  Elif K<49 or K>55
    @BadBeep
  ENDIF
    @GoodBeep
  TableNumber=K-48 ' Convert ASCII to number
  UNTIL TableNumber>0 and TableNumber<8
  DEC TableNumber ' Convert to array index
  @JoinTable
ENDPROC

Proc JoinTable
  JSON$="/join?table="
  JSON$=+TableID$(TableNumber) ' Join the table based on the number selected
  JSON$=+"&player="
  JSON$=+MyName$
  @POS 5,22: @Print &    " CONNECTING TO TABLE          "                  
  @POS 1,25: @Print &    "  PLEASE WAIT THIS MAY TAKE A MOMENT  "
  @CallFujiNet ' Call the FujiNet API to join the table
  @NInputInit UNIT, &responseBuffer ' Initialize reading the api response
  @NInput &dummy$ ' Read the response from the FujiNet API
EndProc

PROC ReadKeyPresses
  K=KEY()
  if K=224 or K=225 or K=229 or K=231 or K=226 or K=228 or K=204 or K=255 or K=197 or k=199
    @CheckVaildMove K
    @ClearKeyQueue
  EliF K=193 AND GameStatus(tablenumber)=2
    @GoodBeep
    @StartGame
    @readGameState
    @ClearKeyQueue
  Elif K=237
    @CycleColorTheme
  Elif K=198
    @GoodBeep
    @DisplayHelpDialog
    @DrawGameState 
  Elif K=213 ' Leave Table confirm
    @GoodBeep
    @AskSure 1 
    @DrawGameState
  Elif K=208 ' Quit Game confrim
    @GoodBeep
    @AskSure 2 
    @DrawGameState
  ENDIF
ENDPROC

PROC CheckVaildMove _move
    KeyPressed=_move
    if KeyPressed=255 then KeyPressed=204
  move$=""
  if playerStatus(PlayerIndex)<>1 then Exit
  if KeyPressed=199 then move$="F"
  if KeyPressed=197
    for a=1 to len(PlayerValidMoves$(PlayerIndex))
      if PlayerValidMoves$(PlayerIndex)[a,1]="D"
       move$="D"
    exit
    endif
    next a
  endif
  DATA Kvalue()=0,224,225,229,231,226,228,204
  For a=1 to 7
    if KeyPressed=Kvalue(a)
      for b=1 to len(PlayerValidMoves$(PlayerIndex))
      Dummy$=PlayerValidMoves$(PlayerIndex)[b,1]
        if Dummy$=STR$(a)
          move$=STR$(a)
        ENDIF
      next b
    ENDIF
  Next a
  if Move$<>"" 
    @GoodBeep           
    @DoMainPlayerAnimation
    @POS 13,24: @Print &"             "
    @PlayMove
    playerStatus(PlayerIndex)=0
  ELSE
    @BadBeep
  ENDIF
ENDPROC

Proc DoMainPlayerAnimation
  if move$="D" then @DrawCardFromDeck xStart(PlayerIndex),yStart(PlayerIndex),8 
  if move$>="1" and move$<="7" then @PlayCardMain val(move$)
EndProc

Proc PlayCardMain _card
  C=_card
  SOUND 0,121,1,8
  mset &screenBuffer+(40*19), 40*6,0 ' Clear area above deck
  if len(PlayerHand$(PlayerIndex))>1 
  ' Remove the played card from the hand
    for a=1 to len(PlayerHand$(PlayerIndex))
      dummy$=PlayerHand$(PlayerIndex)[a,1]
      if dummy$=STR$(C)
        if a=len(PlayerHand$(PlayerIndex)) 
          dummy$=PlayerHand$(PlayerIndex)[1,len(PlayerHand$(PlayerIndex))-1] 
        else
          dummy$=PlayerHand$(PlayerIndex)[1,a-1] 
          value$=PlayerHand$(PlayerIndex)[a+1,len(PlayerHand$(PlayerIndex))] 
          dummy$=+value$
        Endif
        exit
      ENDIF
    NEXT A
    PlayerHand$(PlayerIndex)=dummy$
    @DrawMainPlayerHand playerIndex
  ENDIF
  card=C
  @UpdateScreenBuffer
  endx=20:endy=9
  dx=36:dy=20
  xchange=-1:ychange=-1
 repeat
    @DrawBuffer 
    if dx<>endx then DX=DX+xchange
    if dy<>endy then DY=DY+ychange
    @DrawCard dx,dy,card
  until dx=endx and dy=endy
  @UpdateScreenBuffer
  sound
ENDPROC

PROC ShowResults
  dealt=0
  @EnableDoubleBuffer
  @ResetScreen
  @POS 2,0: @Print &"ROUND OVER - PLAYERS HANDS AND SCORES"
  @POS 0,1: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  @DrawPlayersResults
  @POS 7,25:@Print &"PRESS ANY KEY TO CONTINUE"
  @DrawBufferEnd
  ' @ShowScreen
  GET K
  move$="R"
  @PlayMove
  @POS 2,25:@Print &"PLEASE WAIT FOR NEXT ROUND TO START"
  Repeat
  @readGameState
  UNTIL GameStatus(tablenumber)=3 or GameStatus(tablenumber)=5
  @DrawGameState
ENDPROC

PROC ShowGameOver
  if leaveTableFlag=1 then Exit
  @EnableDoubleBuffer
  @ResetScreen
  @POS 2,0: @Print &"GAME OVER - FINAL SCORES"
  @POS 0,1: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  @DrawFinalResults
  @POS 7,25:@Print &"PRESS ANY KEY TO CONTINUE"
  @DrawBufferEnd
  ' @ShowScreen
  GET K
  move$="G"
  @PlayMove
  @POS 0,25:@Print &"PLEASE WAIT RETURNING TO TABLE SELECTION"
  @readGameState
  @readGameState
ENDPROC

PROC AskSure _type 
  ' Ask the player if they really want to quit or leave
  @ClearKeyQueue
  @EnableDoubleBuffer
  @drawborder 11,9,15,4,128
  x=14:y=9
  INC Y:@PrintAt x,y, &"ARE YOU SURE"
  INC Y
  INC Y:@PrintAt x,y, &"   Y: YES"
  INC Y:@PrintAt x,y, &"   N: NO"
  @DrawBufferEnd
    GET K
    @GoodBeep
    if K=89 ' Y - yes quit
      if _type=1 then @LeaveGame 
      if _type=2 then @QuitGame
    else
      @ClearKeyQueue
      exit
    endif
ENDPROC

PROC SetPlayerName 
  @drawborder 11,9,16,3,128
    @POS 13,10:@Print &"ENTER YOUR NAME"
    cursor = $20
    frame = 0
    @POS 15,12:@Print &MyName$:@PrintByte cursor
    ' Input box to capture player name and show blinking cursor
    ' Ensure at least 1 character name  
    do
      if key()
        get k
        if k=$9B and len(myName$)>0 then exit
        if k>96 then k=k-32
        if k=94 and len(myName$)>0
          myName$=myName$[1,len(myName$)-1]
          @POS 15,12::@Print &myName$:@PrintByte $20:@PrintByte 0
        endif
        if ((k>=65 and k<=90) or (k>=48 and k<58)) and len(myName$)<10
          myName$=+chr$(k)
          @POS 15,12:@Print &MyName$:@PrintByte $20
        endif 
      endif

      pause
      inc frame
      if frame=40
        frame=0
        if cursor = $20
        cursor=$A0
        else
        Cursor = $20
        endif
        @POS 15+len(myName$),12:@PrintByte cursor
      endif
    loop

  ' Name has been captured. Save to app key 
    @NWriteAppKey AK_LOBBY_CREATOR_ID, AK_LOBBY_APP_ID, AK_LOBBY_KEY_USERNAME, &myName$
  
ENDPROC

PROC DisplayHelpDialog 
  @ClearKeyQueue
  @EnableDoubleBuffer
  @DrawBorder 9,5,19,13,0
  X=13:Y=6
  INC Y:@PrintAt x,y, &"Q: QUIT PROGRAM"
  INC Y
  INC Y:@PrintAt x,y, &"H: HOW TO PLAY"
  INC Y
  INC Y:@PrintAt x,y, &"C: TABLE COLOR"
  INC Y
  if GameStatus(tablenumber)<>0
    INC Y:@PrintAt x,y, &"E: LEAVE TABLE"
    INC Y
  EndIF
  if GameStatus(tablenumber)=0
    INC Y:@PrintAt x,y, &"N: CHANGE NAME"
  EndIF
  INC Y
  INC Y:@PrintAt x,y, &"RETURN: RETURN"
  
  @DrawBufferEnd
  Repeat 
    GET K
    if K=67 
    @CycleColorTheme
    K=0
    Elif k=72 ' H - how to play
      @ViewHowToPlay 
    Elif K=78 and GameStatus(tablenumber)=0 ' N - change name
      @SetPlayerName 
      @DisplayHelpDialog 
    Elif K=69 and GameStatus(tablenumber)<>0  ' E - leave table
     @AskSure 1
     @DisplayHelpDialog 
    Elif K=81  ' Q - Quiting program 
      @AskSure 2
      @DisplayHelpDialog 
    Endif


    if k=27 or K=32 or K=155 or STRIG(0) then exit
    @PrintAt 10,24, K
  UNTIL K=155
ENDPROC

PROC ViewHowToPlay
  ' This COULD retrieve from the server. Hard coded for now.
  @EnableDoubleBuffer
  @ResetScreen
  @POS 10,1: @Print &"THE LLAMA COMMANDS YOU:" 
  @DrawCard 1,0,7:@DrawCard 36,0,8
  @POS 4,2: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  y=2               
  inc y:@PrintAt 6,y, &"GET RID OF YOUR POINTS TO WIN"
  inc y:@PrintAt 1,y, &"PLAY ALL YOUR CARDS OR YOU EARN POINTS"
  inc y:@PrintAt 2,y, &"IF YOU CAN NOT PLAY A CARD, YOU WILL"
  inc y:@PrintAt 1,y, &"HAVE TO DECIDE EITHER, DO YOU FOLD, OR"
  inc y:@PrintAt 6,y, &"DRAW A CARD WHICH HOPEFULLY" 
  inc y:@PrintAt 10,y, &"YOU CAN PLAY LATER"
  inc y:
  inc y:@PrintAt 3,y, &"POINTS COME IN THE FORM OF TOKENS"
  inc y:@PrintAt 8,y, &"BLACK ARE 10 POINTS AND"
  inc y:@PrintAt 10,y, &"WHITE ARE 1 POINT"
  inc y:
  inc y:@PrintAt 2,y, &"YOU EARN TOKENS BY HAVING CARDS LEFT"
  inc y:@PrintAt 4,y, &"IN YOUR HAND AT THE END OF A ROUND"
  inc y:@PrintAt 5,y, &"BASED ON THEIR FACE VALUE BUT,"
  inc y:
  inc y:@PrintAt 11,y, &        "CUIDAO, LAS LLAMA"
  inc y:@POS 11,y: @PrintINV&   "@@@@@@@@@@@@@@@@@@@"
  inc y:@PrintAt 3,y, &"FOR THEY WILL GIVE YOU BLACK TOKENS"
  inc y:
  inc y:@PrintAt 4,y, &"IF YOU GET RID OF ALL YOUR CARDS"
  inc y:@PrintAt 9,y, &"YOU CAN RETURN A TOKEN"
  inc y:@PrintAt 7,25, &"PRESS ANY KEY FOR NEXT PAGE"
  @DrawBufferEnd
  ' @ShowScreen
  GET K
  @EnableDoubleBuffer
  @ResetScreen
   @POS 10,1: @Print &"THE LLAMA COMMANDS YOU:" 
  @DrawCard 1,0,8:@DrawCard 36,0,7
  @POS 4,2: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  y=2                ' "12345678911112131415161718192021fffffffa"
  inc y:@PrintAt 5,y, &"YOU START A ROUND WITH 6 CARDS"
  inc y:@PrintAt 4,y, &"THE TOP CARD OF THE DISCARD PILE"
  inc y:@PrintAt 2,y, &"DETERMINES WHICH CARD CAN BE PLAYED"
  inc y
  inc y:@PrintAt 1,y, &"ON YOUR TURN YOU CAN WHEN VAILD:"
  inc y:@PrintAt 1,y, &"PLAY A CARD WITH THE SAME VALUE, OR"
  inc y:@PrintAt 1,y, &"PLAY THE NEXT CARD IN SEQUENCE"
  inc y:@PrintAt 1,y, &"USE KEYS 1-6 MATCHING YOUR CHOICE OF"
  inc y:@PrintAt 1,y, &"CARD OR THE L KEY FOR THE LLAMA CARD"
  inc y:@PrintAt 1,y, &"D KEY TO DRAW A CARD FROM DECK"
  inc y:@PrintAt 1,y, &"F KEY TO FOLD/QUIT THE CURRENT ROUND"
  inc y
  inc y:@PrintAt 1,y, &"THE NEXT CARD IN SEQUENCE AFTER 6 IS"
  inc y:@PrintAt 1,y, &"THE LLAMA AND THEN ITS BACK TO 1"
  INC Y
  inc y:@PrintAt 1,y, &"THE ROUND ENDS WHEN A PLAYER HAS PLAYED"
  inc y:@PrintAt 1,y, &"ALL THEIR CARDS, THE DRAW DECK RUNS OUT"
  inc y:@PrintAt 1,y, &"OR ALL PLAYERS HAVE FOLDED"
  INC Y
  inc y:@PrintAt 1,y, &"THE GAME ENDS WHEN A PLAYER REACHES 40"  
  inc y:@PrintAt 1,y, &"POINTS, THE PLAYER WITH THE LOWEST"  
  inc y:@PrintAt 1,y, &"POINTS WINS" 
  inc y:@PrintAt 7,25, &"PRESS ANY KEY TO RETURN"
  @DrawBufferEnd
  ' @ShowScreen
  GET K
ENDPROC

Proc LeaveGame
 ' do whatever is needed to leave the current game table and return to table selection
 leaveTableFlag=1
 GameStatus(tablenumber)=5
endproc

PROC ReadGameState
 ' Read the game state from the FujiNet API
  ' ? "getting game state from FujiNet"
  JSON$="/state?table="
  JSON$=+TableID$(TableNumber) 
  JSON$=+"&player="
  JSON$=+MyName$
  ' JSON$="/state?table=ai1&player=SIMON"
  @CallFujiNet ' Call the FujiNet API to join the table
  @NInputInit UNIT, &responseBuffer ' Initialize reading the api response
  @NInput &dummy$ ' Read the response from the FujiNet API
  @checkErrors
  PreviousLastMovePlayed$=LastMovePlayed$
  if ok <>1 then Exit 
  @NInput &dummy$
  Drawdeck=VAL(dummy$)
  key$="" : value$=""
  do ' Loop reading key/value pairs until we reach the Start of the Player Array
  ' Get the next line of text from the api response as the key
  @NInput &key$
  ' An empty key means we reached the end of the response
  if len(key$) = 0 then exit
  ' Get the next line of text from the api response as the value
  @NInput &value$
  ' Depending on key, set appropriate variable to the value
  if key$="dp" 
    DiscardTop=VAL(value$)
  elif key$="ts" 
    GameStatus(tablenumber)=VAL(value$)
  elif key$="lmp" 
    LastMovePlayed$=value$
    EXIT
  ENDIF
  loop 
  if LastMovePlayed$=PreviousLastMovePlayed$ and playerStatus(PlayerIndex)=1 then exit
  @NInput &dummy$ ' Read the Start of the Player Array
  INDEX=0
  do ' Loop reading key/value pairs until we reach the Start of the Player Array
  ' Get the next line of text from the api response as the key
  @NInput &key$
  ' An empty key means we reached the end of the response
  if len(key$) = 0 then exit
  ' Get the next line of text from the api response as the value
  @NInput &value$
  ' Depending on key, set appropriate variable to the value
  if key$="n" 
    PlayerName$(INDEX)=value$
    if PlayerName$(INDEX)=MyName$ then PlayerIndex=INDEX ' find the player index for the current player
  elif key$="s" 
    PlayerStatus(INDEX)=VAL(value$)
  elif key$="nc" 
    PlayerHandCount(INDEX)=VAL(value$)
  elif key$="wt" 
    PlayerWhiteTokens(INDEX)=VAL(value$)
  elif key$="bt" 
    PlayerBlackTokens(INDEX)=VAL(value$)
  elif key$="ph" 
    PlayerHand$(INDEX)=value$   
  elif key$="pvm" 
    PlayerValidMoves$(INDEX)=value$
    PlayerScore(INDEX)=(PlayerBlackTokens(INDEX)*10)+PlayerWhiteTokens(INDEX)
    INC INDEX  ' If read last field of a Player Array, increment index and read next player
  ENDIF
  loop 
  if playerStatus(PlayerIndex)=1
    countdown=60
    jiffy=0
  ENDIF
ENDPROC

proc SetPlayerSlots
  data xS()=2,1,1,13,26,26
  data yS()=19,14,8,3,8,14
  xstart(PlayerIndex)=xS(0)
  ystart(PlayerIndex)=yS(0)
  i=1
  for a=0 to 5
    if a<>PlayerIndex
    xStart(a)=xs(i)
    yStart(a)=ys(i)
    inc i
    Endif
  next a
endproc

PROC PlayMove 
  JSON$="/move?table="
  JSON$=+TableID$(TableNumber)
  JSON$=+"&player="
  JSON$=+MyName$
  JSON$=+"&VM=" 
  JSON$=+move$
  @CallFujiNet
ENDPROC

PROC StartGame
  JSON$="/start?table="
  JSON$=+TableID$(TableNumber)
  @CallFujiNet
ENDPROC

Proc DealCards
  data yend()=19,14,8,3,8,14
  data xend0()=9,13,17,21,25,29
  data xend1()=1,3,5,7,9,11
  data xend2()=1,3,5,7,9,11
  data xend3()=14,16,18,20,22,24
  data xend4()=38,36,34,32,30,28
  data xend5()=38,36,34,32,30,28
  for cardnumber=1 to 6
      for player=0 to 5
      if player=0 and playerName$(player)<>"" then @DrawCardFromDeck xend0(cardnumber-1),yend(player),VAL(PlayerHand$(playerindex)[cardnumber,1])
      if player=1 and playerName$(player)<>"" then @DrawCardFromDeck xend1(cardnumber-1),yend(player),9
      if player=2 and playerName$(player)<>"" then @DrawCardFromDeck xend2(cardnumber-1),yend(player),9
      if player=3 and playerName$(player)<>"" then @DrawCardFromDeck xend3(cardnumber-1),yend(player),9
      if player=4 and playerName$(player)<>"" then @DrawCardFromDeck xend4(cardnumber-1),yend(player),9
      if player=5 and playerName$(player)<>"" then @DrawCardFromDeck xend5(cardnumber-1),yend(player),9
    next player
  next cardnumber
  @DrawCardFromDeck 20,9,DiscardTop
  dealt=1
  @SetPlayerSlots
ENDPROC

PROC CheckErrors
  ' Check data returned from FujiNet to see if it was successful or not
  ' and display appropriate message
  ok = 1
  if len(dummy$) > 0 then
  @POS 0,0
  _ERR=VAL(dummy$[5,1])
  if _ERR=1 
    ok = 0
    @PrintUpper &" You need to specify a valid table"
  elif _ERR=2 
    ok = 0
    @PrintUpper &" You need to supply a player name"
    @PrintUpper &" to join a table"
  elif _ERR=3 
    ok = 0
    @PrintUpper &"Sorry: ":@PrintUpper &MyName$:@PrintUpper &" someone is already"
    @PrintUpper &"at table ":@PrintUpper &TableName$(TableNumber):@PrintUpper &"with that name,"
    @PrintUpper &"please try a different"
    @PrintUpper &"table and or name"
  
  elif _ERR=4 
    ok = 0
    @PrintUpper &"Sorry: ":@PrintUpper &MyName$:@PrintUpper &" table ":@PrintUpper &TableName$(TableNumber)
    @PrintUpper &" has a game in progress,"
    @PrintUpper &"please try a different table"
  elif _ERR=5 
    ok = 0
    @PrintUpper &"Sorry: ":@PrintUpper &MyName$:@PrintUpper &" table ":@PrintUpper &TableName$(TableNumber)
    @PrintUpper &" is full, please try a different table"
  elif _ERR=6 
    ok = 0
    @PrintUpper &"Must specify both table and player name"
 elif _ERR=7 
    ok = 0
    @PrintUpper &"Player not found at this table"
  elif _ERR=8 
    ok = 0
    @PrintUpper &"Round is not over yet, no results available"
  elif _ERR=9 
    ok = 0
    @PrintUpper &"No human players at this table"
  else
  ok = 1
  endif
ENDPROC

PROC GoodBeep
  SOUND 0,121,10,8
  pause 4
  SOUND 
ENDPROC

PROC BadBeep
  SOUND 0,255,10,8
  pause 4
  SOUND 
ENDPROC

Proc DrawCardFromDeck _endX _endY _card
  dx=18:dy=10: endX=_endX : endY=_endY : card=_card
  SOUND 0,121,1,8
  dec Drawdeck
  @POS 19,13:@Print &"  "
  @POS 19,13:@PrintVal Drawdeck
  if Drawdeck<=0 then @DrawCard 17,9,0 ' show the draw deck as empty
  @UpdateScreenBuffer
  xchange=-1:ychange=-1
  if endX>dx then xchange=1 
  if endy>dy then ychange=1 
  repeat
    @DrawBuffer 
    if dx<>endx then DX=DX+xchange
    if dy<>endy then DY=DY+ychange
    if card=9 
      @POS dx,dy:@PrintByte 13:@PrintByte 14
      @POS dx,dy+1:@PrintByte 15:@PrintByte 27
      else
      @DrawCard dx,dy,card
    endif
  until dx=endx and dy=endy
  @UpdateScreenBuffer
  sound
ENDPROC

Proc PlayCard _PlayerIndex
  index=_PlayerIndex
  SOUND 0,121,1,8
  endx=20:endy=10
  dx=xStart(index):dy=yStart(index)
  xchange=-1:ychange=-1
  if endX>dx then xchange=1 
  if endy>dy then ychange=1 
  @POS dx,dy:   @Print &"             "
  @POS dx,dy+1: @Print &"             "
  @DrawPlayerHand dx,dy, PlayerHandCount(index), 0
  @UpdateScreenBuffer
  repeat
    @DrawBuffer 
    if dx<>endx then DX=DX+xchange
    if dy<>endy then DY=DY+ychange
    @POS dx,dy:@PrintByte 13:@PrintByte 14
    @POS dx,dy+1:@PrintByte 15:@PrintByte 27
  until dx=endx and dy=endy
  @UpdateScreenBuffer
  sound
ENDPROC

PROC SetCardSlot
@DrawCardFromDeck CardXSlot(card),CardYSlot,card
ENDPROC


' ============================================================================
' Drawing ROUTINES
' ============================================================================
PROC DrawTableSelection
  @POS (34-len(MyName$))/2,1: @Print &"HELLO ":@Print &MyName$
  @POS 10,3: @Print &"WELCOME TO FUJI-LLAMA"  
  @DrawCard 2,3,7:@DrawCard 35,3,8
  @POS 5,4: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  @POS 5,5: @Print &"TABLE NAME":@POS 28,5: @Print &"PLAYERS"
  @POS 5,6: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  for y=7 to 19
  @POS 3,y: @PrintINV &"?":@POS 36,y: @PrintINV &"?"
  next y
  for y=8 to 20 step 2
  @POS 4,y: @Print &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  next y
  @DrawCard 2,20,8:@DrawCard 35,20,7
  @POS 5,21: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
ENDPROC

PROC DrawGameState 
  ' Draw the current game state on the screen
  if GameStatus(tablenumber)=4 or GameStatus(tablenumber)=5 then Exit ' if game over do not redraw screen
  @EnableDoubleBuffer
  @ResetScreen
  @POS 0,5: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  @POS 0,10: @PrintINV &"@@@@@@@@@@@@@@@@"
  @POS 24,10: @PrintINV &"@@@@@@@@@@@@@@@@"
  @POS 0,16: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" 
  @POS 15,5: @PrintByte 223:@POS 23,5: @PrintByte 223 
  for Y=6 to 15  
  @POS 15,Y: @PrintByte 159:@POS 23,Y: @PrintByte 159
  next Y
  @POS 15,10: @PrintByte 221:@POS 23,10: @PrintByte 222  
  @POS 15,16: @PrintByte 254:@POS 23,16: @PrintByte 254                 
  @DrawPlayers
  if LastMovePlayed$="Waiting for players to join"
  @POS 2,3: @Print &"PLEASE WAIT FOR OTHER PLAYERS TO JOIN"
  @POS 3,4: @Print &"OR PRESS S TO START WITH AI PLAYERS" 
  @DrawCard 17,9,8 ' Draw Deck
  
  @DrawBufferEnd
  ' @ShowScreen
  exit
  ENDIF
  if Drawdeck>0 
  @DrawCard 17,9,8 ' Draw Deck
  @POS 19,13: @PrintVal Drawdeck
  else
  @DrawCard 17,9,0 ' Empty Draw Deck
  endif
  if dealt=0 
    DrawDeck=56
    @POS 19,13: @PrintVal Drawdeck
    @DrawBufferEnd
    ' @ShowScreen
    @DealCards
    @EnableDoubleBuffer
  Endif
  @DrawCard 20,9,DiscardTop ' Discard Pile
  '@POS 1,24: @PrintUpper & LastMovePlayed$[1,38]
  @POS 5,25:@Print &"H-HELP C-COLOR E-EXIT Q-QUIT"
  if PlayerStatus(PlayerIndex)=1 
  @POS 13,24: @Print &"YOUR TURN NOW"
  @POS 26,17: @Print &"TIME LEFT:"
  @DrawDrawButton 2,20
  @DrawFoldButton 37,20
  else
  @POS 7,24: @Print &"WAITING FOR OTHERS TO PLAY"
  ENDIF
  @DrawBufferEnd
  ' @ShowScreen
ENDPROC

PROC DrawMainPlayerHand _Index
  DisplayIndex=_Index:YY=19
  if PlayerHandCount(DisplayIndex)<9
    XX=((36-(PlayerHandCount(DisplayIndex)*4))/2)+3
    for a=1 to len(PlayerHand$(DisplayIndex))
      card=VAL(PlayerHand$(DisplayIndex)[a,1])
      if playerStatus(DisplayIndex)=2 then card=9 ' if folded show back of card
      @DrawCard XX,YY,card
      XX=XX+4
    next a
    elif PlayerHandCount(DisplayIndex)<11 ' more than 10 cards so print cards closer together
    XX=((36-(PlayerHandCount(DisplayIndex)*3))/2)+3
    for a=1 to len(PlayerHand$(DisplayIndex))
      card=VAL(PlayerHand$(DisplayIndex)[a,1])
      if playerStatus(DisplayIndex)=2 then card=9 ' if folded show back of card
      @DrawCard XX,YY,card
      XX=XX+3
    next a
  elif PlayerHandCount(DisplayIndex)<16 ' more than 15 cards so print cards closer together
    XX=((36-(PlayerHandCount(DisplayIndex)*2)+1)/2)+2
    for a=1 to len(PlayerHand$(DisplayIndex))
      card=VAL(PlayerHand$(DisplayIndex)[a,1])
      if playerStatus(DisplayIndex)=2 then card=9 ' if folded show back of card
      @DrawCard XX,YY,card
      XX=XX+2
    next a
  else ' more than 15 cards need to double stack cards
   if playerStatus(DisplayIndex)=2
        XX=((36-(PlayerHandCount(DisplayIndex)*2)+1)/2)+2
        for a=1 to len(PlayerHand$(DisplayIndex))-1
          card=9 ' if folded show back of card
          @DrawCard XX,YY,card
          XX=XX+2
        next a
    else
      card1=0:card2=0:card3=0:card4=0:card5=0:card6=0:card7=0
      for a=1 to len(PlayerHand$(DisplayIndex))
        card=VAL(PlayerHand$(DisplayIndex)[a,1])
        if card=1 then inc card1
        if card=2 then inc card2
        if card=3 then inc card3
        if card=4 then inc card4
        if card=5 then inc card5
        if card=6 then inc card6
        if card=7 then inc card7
        @DrawCard CardXSlot(card),CardYSlot,card
      next a
        if card1>1 then @DrawStackedCard 1,card1
        if card2>1 then @DrawStackedCard 2,card2
        if card3>1 then @DrawStackedCard 3,card3
        if card4>1 then @DrawStackedCard 4,card4
        if card5>1 then @DrawStackedCard 5,card5
        if card6>1 then @DrawStackedCard 6,card6
        if card7>1 then @DrawStackedCard 7,card7
    Endif
  Endif

ENDPROC

PROC DrawStackedCard _Card _Count
 @POS CardXSlot(_Card)-1,CardYSlot-1:@PrintByte 28:@PrintByte 29:@PrintByte 30:@printval _Count
 @POS CardXSlot(_Card)-1,CardYSlot:@PrintByte 62:@PrintByte 65
 @POS CardXSlot(_Card)-1,CardYSlot+1:@PrintByte 62
 @POS CardXSlot(_Card)-1,CardYSlot+2:@PrintByte 59
ENDPROC



PROC DrawCard _col _row _card
  XXX=_col:YYY=_row:DrawnCard=_card
  IF DrawnCard=0  ' Blank Card
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 63:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 63:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF DrawnCard=1 ' card 1
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 66:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 67:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
    ElIF DrawnCard=2 ' card 2
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 196:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 197:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF DrawnCard=3 ' card 3
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
   @POS XXX,YYY+1:@PrintByte 62:@PrintByte 68:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 70:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF DrawnCard=4 ' card 4
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 199:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 200:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF DrawnCard=5 ' card 5
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
   @POS XXX,YYY+1:@PrintByte 62:@PrintByte 73:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 70:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF DrawnCard=6 ' card 6
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 202:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 203:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF DrawnCard=7 ' Llama Card
    @POS XXX,YYY:@PrintByte 204:@PrintByte 205:@PrintByte 206
    @POS XXX,YYY+1:@PrintByte 207:@PrintByte 208:@PrintByte 209
    @POS XXX,YYY+2:@PrintByte 210:@PrintByte 211:@PrintByte 212
    @POS XXX,YYY+3:@PrintByte 213:@PrintByte 214:@PrintByte 215
  ElIF DrawnCard=8 ' Back of Card
   @POS XXX,YYY:@PrintByte 97:@PrintByte 98:@PrintByte 99
    @POS XXX,YYY+1:@PrintByte 100:@PrintByte 101:@PrintByte 102
    @POS XXX,YYY+2:@PrintByte 103:@PrintByte 104:@PrintByte 105
    @POS XXX,YYY+3:@PrintByte 106:@PrintByte 107:@PrintByte 108
  ElIF DrawnCard=9 ' back of card when folded 
   @POS XXX,YYY:@PrintByte 225:@PrintByte 226:@PrintByte 227
    @POS XXX,YYY+1:@PrintByte 228:@PrintByte 229:@PrintByte 230
    @POS XXX,YYY+2:@PrintByte 231:@PrintByte 232:@PrintByte 233
    @POS XXX,YYY+3:@PrintByte 234:@PrintByte 235:@PrintByte 236
  endif
ENDPROC

PROC DrawCardLine _col _row _card
  XXX=_col:YYY=_row:card=_card
  IF card=0  
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 63:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 63:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=1 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 66:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 67:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
    ElIF card=2 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 196:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 197:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=3 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
   @POS XXX,YYY+1:@PrintByte 62:@PrintByte 68:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 70:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=4 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 199:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 200:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=5 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
   @POS XXX,YYY+1:@PrintByte 62:@PrintByte 73:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 70:@PrintByte 64
   @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=6 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 202:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 203:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=7 
    @POS XXX,YYY:@PrintByte 204:@PrintByte 205:@PrintByte 206
    @POS XXX,YYY+1:@PrintByte 207:@PrintByte 208:@PrintByte 209
    @POS XXX,YYY+2:@PrintByte 210:@PrintByte 211:@PrintByte 212
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=8 
   @POS XXX,YYY:@PrintByte 97:@PrintByte 98:@PrintByte 99
    @POS XXX,YYY+1:@PrintByte 100:@PrintByte 101:@PrintByte 102
    @POS XXX,YYY+2:@PrintByte 103:@PrintByte 104:@PrintByte 105
   @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  endif
ENDPROC

PROC DrawPlayerScore _col _row _BlackTokens _WhiteTokens
  xx=_col:yy=_row:bt=_BlackTokens:wt=_WhiteTokens
  IF BT=0
  @POS xx,yy:@PrintByte 1:@PrintByte 2:@PrintByte 2:@PrintByte 3
  ELIF BT=1
  @POS xx,yy:@PrintByte 4:@PrintByte 2:@PrintByte 2:@PrintByte 3
  ELIF BT=2   
  @POS xx,yy:@PrintByte 5:@PrintByte 2:@PrintByte 2:@PrintByte 3
  ELIF BT>=3                                               
  @POS xx,yy:@PrintByte 6:@PrintByte 2:@PrintByte 2:@PrintByte 3
  ENDIF
  
  if BT>3 then WT=11 ' max tokens that can be displayed is 39 so if more than 3 black set white to 11 to show max

  IF WT=0
    @POS xx+1,yy:@PrintByte 2:@PrintByte 2:@PrintByte 3
  ELIF WT=1
    @POS xx+1,yy:@PrintByte 2:@PrintByte 2:@PrintByte 11
  ELIF WT=2   
    @POS xx+1,yy:@PrintByte 2:@PrintByte 7:@PrintByte 11
  ELIF WT=3                                               
    @POS xx+1,yy:@PrintByte 7:@PrintByte 7:@PrintByte 11
  ELIF WT=4
    @POS xx+1,yy:@PrintByte 7:@PrintByte 8:@PrintByte 11
  ELIF WT=5   
    @POS xx+1,yy:@PrintByte 8:@PrintByte 8:@PrintByte 11
  ELIF WT=6                                               
    @POS xx+1,yy:@PrintByte 8:@PrintByte 8:@PrintByte 12  
  ELIF WT=7
    @POS xx+1,yy:@PrintByte 9:@PrintByte 8:@PrintByte 12
  ELIF WT=8   
    @POS xx+1,yy:@PrintByte 9:@PrintByte 9:@PrintByte 12
  ELIF WT=9                                               
    @POS xx+1,yy:@PrintByte 9:@PrintByte 10:@PrintByte 12
  ELIF WT>=10                                               
    @POS xx+1,yy:@PrintByte 10:@PrintByte 10:@PrintByte 12
  ENDIF
ENDPROC

PROC DrawDrawButton _col _row 
  XXX=_col:YYY=_row
  @POS XXX,YYY:@PrintByte 220:@PrintByte 224
  @POS XXX,YYY+1:@PrintByte 245:@PrintByte 255
ENDPROC

PROC DrawFoldButton _col _row 
  XXX=_col:YYY=_row
  @POS XXX,YYY:@PrintByte 141:@PrintByte 142
  @POS XXX,YYY+1:@PrintByte 143:@PrintByte 155
ENDPROC

PROC DrawPlayers 
  ' Draw the players around the table
  Xoffset=LEN(PlayerName$(PlayerIndex))
  if Xoffset>12 then Xoffset=12
  X=((36-(Xoffset+6))/2)+2
  Y=17
  @POS X,Y: @PrintUpper &PlayerName$(PlayerIndex)[1,Xoffset]
  @POS X+Xoffset,Y: @Print &":"
  @POS X+Xoffset+1,Y: @PrintVal PlayerStatus(PlayerIndex)
  @DrawPlayerScore X+Xoffset+2,17,PlayerBlackTokens(PlayerIndex),PlayerWhiteTokens(PlayerIndex)
  if PlayerHandCount(playerIndex)>0 and dealt=1 then @DrawMainPlayerHand Playerindex
  DATA XPOS()=1,1,0,25,25
  DATA HPOS()=1,1,13,26,26
  DATA YPOS()=12,6,1,6,12
  slot=0
  For a=0 to 5
      if  a<>PlayerIndex
        if PlayerName$(a)<>""
          Xoffset=len(PlayerName$(a))
          if Xoffset>8 and slot<>2 then Xoffset=8
          if Xoffset>12 and slot=2 then Xoffset=12
          X=(14-(Xoffset+6))/2
          if slot=2 then X=((36-(Xoffset+6))/2)+2
          X=X+XPOS(SLOT)
          @POS X,YPOS(SLOT): @PrintUpper &PlayerName$(a)[1,Xoffset]
          @POS X+Xoffset,YPOS(SLOT): @Print &":"
          @POS X+Xoffset+1,YPOS(SLOT): @PrintVal PlayerStatus(a)
          @DrawPlayerScore X+Xoffset+2,YPOS(SLOT),PlayerBlackTokens(a),PlayerWhiteTokens(a)
          folded=0
          if playerStatus(a)=2 then folded=128
          if dealt=1
            if slot=2 
              @DrawPlayerHand XPOS(SLOT)+((38-(PlayerHandCount(a)+2))/2),YPOS(SLOT)+2,PlayerHandCount(a),folded
              else
              @DrawPlayerHand XPOS(SLOT)+((14-(PlayerHandCount(a)+2))/2),YPOS(SLOT)+2,PlayerHandCount(a),folded
              ENDIF
          endif
          inc SLOT
        Endif
      Endif
  Next a
ENDPROC

PROC DrawPlayerHand _col _row _numCards _folded
  XXX=_col:YYY=_row:folded=_folded:numcards=_numCards
  if numCards=0 then exit
  if numCards>11 then numCards=11
  for i=1 to numCards
  @POS (XXX+i)-1,YYY:@PrintByte 13+folded:@PrintByte 14+folded
  @POS (XXX+i)-1,YYY+1:@PrintByte 15+folded:@PrintByte 27+folded
  next i
ENDPROC

PROC DrawBorder _col _row _sizeX _sizeY _colour
  _X=_col:_Y=_row:Xsize=_sizex:Ysize=_sizey:colour=_colour
  @POS _X,_Y:@PrintByte 119+colour
  For Xstep=_X+1 to _X+Xsize
  @POS Xstep,_Y:@PrintByte 32+colour
  Next Xstep
  @POS Xstep,_Y:@PrintByte 120+colour
  
  For Ystep=_Y+1 to _Y+Ysize
  @POS _X,Ystep:@PrintByte 31+colour
  For Xstep=_X+1 to _X+Xsize
  @POS Xstep,Ystep:@PrintByte 0
  Next Xstep
  @POS Xstep,Ystep:@PrintByte 31+colour
  Next Ystep

  @POS _X,Ystep:@PrintByte 121+colour
  For Xstep=_X+1 to _X+Xsize
  @POS Xstep,Ystep:@PrintByte 32+colour
  Next Xstep
  @POS Xstep,Ystep:@PrintByte 122+colour
ENDPROC

PROC DrawPlayersResults 
  ' Draw the players Results on the screen
  X=1:Y=2
  For aa=0 to 5
    if PlayerName$(aa)<>""
      Xoffset=LEN(PlayerName$(aa))
      if Xoffset>12 then Xoffset=12
      if Xoffset<9 then Xoffset=9
      @POS 0,Y+3: @Print &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      if PlayerStatus(aa)=3 and PlayerHand$(aa)<> ""
        @POS X,Y: @PrintUpper &PlayerName$(aa)[1,Xoffset]: @Print &":"
        @POS X+7,Y+1: @Print &"ROUND WINNER"
        Xoffset=Xoffset+9
      else
        @POS X,Y: @PrintUpper &PlayerName$(aa)[1,Xoffset]:@Print &":"
      Endif
      @DrawResultHands aa,Xoffset+2,Y
      @DrawPlayerScore X+2,Y+1,PlayerBlackTokens(aa),PlayerWhiteTokens(aa)
      @POS X,Y+2: @Print &"SCORE:"
      @POS X+6,Y+2: @PrintVal PlayerScore(aa)
      if PlayerHand$(aa)="" 
        @POS X,Y: @PrintUpper &PlayerName$(aa)[1,Xoffset]: @Print &" HAS NO CARDS LEFT"
        @POS X+7,Y+1: @Print &"WININNG THIS ROUND"
      Endif
      Y=Y+4
    endif
  next aa
ENDPROC

PROC DrawFinalResults 
  ' Draw the players Results on the screen
  X=1:Y=2:loser=0
  For aa=0 to 5
    if PlayerName$(aa)<>""
    if aa=0 
      @POS X,Y: @PrintUpper &PlayerName$(aa)[1,12]:@Print &" IS THE WINNER WITH A SCORE OF ":@PrintVal PlayerScore(aa)
    else
      @POS X,Y: @PrintUpper &PlayerName$(aa)[1,12]:@Print &" SCORE:":@PrintVal PlayerScore(aa)
    endif
      @POS 0,Y+1: @Print &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      Y=Y+2
      loser=aa
    endif
  next aa
  Y=Y-2
  @POS 0,Y+1: @Print &   "                                        "
  @POS X,Y: @PrintUpper &PlayerName$(loser)[1,12]:@Print &" BUSTED ENDING THE GAME"
  @POS X,Y+1:@Print &"WITH A SCORE OF ":@PrintVal PlayerScore(loser)
  @POS X,Y+2:@Print &"SO IS THE LOSER"
  @POS 0,Y+3: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

ENDPROC

PROC DrawResultHands _Index _Xoffset _Yoffset
  DisplayIndex=_Index:XX=_Xoffset:YY=_Yoffset
  for a=1 to len(PlayerHand$(DisplayIndex))
    card=VAL(PlayerHand$(DisplayIndex)[a,1])
    @DrawCardLine XX,YY,card
    XX=XX+3
 next a
ENDPROC

Proc UpdateScreenBuffer
  move &screenBuffer,&screenBuffer+1040, 1040
  @DrawBuffer
ENDPROC

'-------------------------------------------------------------
' PROCEDURES to get Json data and load into the Var Result
'open the API connect and setup for Read JSON file
'Code lifted from the Introduction to Fuji-net for Atari Users
'by Thomas Cherryhomes
'(MASTODON Example)
'--------------------------------------------------------------
PROC CallFujiNet
  dummy$=""
  QUERY$=""$9B
  URL$=serverEndpoint$
  URL$=+JSON$
  URL$=+""$9B
  @openconnection
  @nsetchannelmode 
  @nparsejson
  IF SErr()<>1
  PRINT "Could not parse JSON."
  @nprinterror
  GET K
  ENDIF
  @doJSON
ENDPROC

PROC openconnection ' Open the connection, or throw error and end program
  NOPEN UNIT, 12, 0, URL$
  ' If not successful, then exit.
  IF SERR()<>1  
  PRINT "Could not open connection."
  @nprinterror
  EXIT
  ENDIF
ENDPROC

PROC nsetchannelmode ' Set the channel mode to the JSON_mode
 SIO $71, UNIT, $FC, $00, 0, $1F, 0, 12, JSON_MODE
ENDPROC

PROC nparsejson ' send Parse to the FujiNet, so it parses the JSON value set by the URL$
  SIO $71, UNIT, $50, $00, 0, $1f, 0, 12, 0
ENDPROC

PROC njsonquery ' Query the JSON data that has been parsesed base on the attributes in $query
  SIO $71, UNIT, $51, $80, &query$+1, $1f, 256, 12, 0
ENDPROC

PROC nprinterror ' get the current eror and display on screen 
  NSTATUS UNIT
  PRINT "ERROR- "; PEEK($02ED)
ENDPROC

PROC DoJSON 
  @njsonquery
  NSTATUS UNIT
  IF PEEK($02ED) > 128
  PRINT "Could not fetch query:"
  PRINT QUERY$
  PRINT "ERROR- "; PEEK($02ED)
  EXIT
  ENDIF
ENDPROC

' ============================================================================
' Helper code from  Eric Carr
' (N Helper) Gets the entire response from the specified unit into the provided buffer index for NInput to read from.
' WARNING! No check is made if buffer length is long enough to hold the FujiNet payload.
' ============================================================================

PROC NInputInit __NI_unit __NI_index
  NSTATUS __NI_unit
  __NI_bufferEnd = __NI_index + DPEEK($02EA)
  NGET __NI_unit, __NI_index, __NI_bufferEnd - __NI_index
  NCLOSE __NI_unit ' Close since we are done reading
ENDPROC

' ============================================================================
' (N Helper) Reads a line of text into the specified string - Similar to Atari BASIC: INPUT #N, MyString$
PROC NInput __NI_stringPointer

  ' Start the indexStop at the current index position
  __NI_indexStop = __NI_index
  
  ' Seek the end of this line (or buffer)
  while peek(__NI_indexStop) <> $9B and __NI_indexStop < __NI_bufferEnd
    inc __NI_indexStop
  wend

  ' Calculate the length of this result
  __NI_resultLen = __NI_indexStop - __NI_index
  
  ' Update the length in the output string 
  poke __NI_stringPointer, __NI_resultLen

  ' If we successfully read a value, copy from the buffer to the string that was passed in and increment the index
  if __NI_indexStop < __NI_bufferEnd
    move __NI_index, __NI_stringPointer+1, __NI_resultLen

    ' Move the buffer index for the next input
    __NI_index = __NI_indexStop + 1
  endif
ENDPROC

PROC QuitGame
  ' Enable FujiNet Config to take over D1:
  SIO $70, 1, $D9, $00, 0, $09, 0, 1,0
  ' Reboot via assembly: JMP $E477     
  i=usr(&""$4C$77$E4+1)
ENDPROC

' ============================================================================
' Screen code from  Eric Carr lifted from 5 card stud
' ============================================================================
' Init screen/graphics - leaves screen blank. ShowScreen must be called afer
PROC InitScreen

  ' ============= PLAYER MISSLE GRAPHICS =============

  ' Use player missle graphics as follows:
  ' Player 0 and 3 - Left and Right black bars to cover up the background to render a nice round table
  ' Player 1 - Darken player's secret card
  ' Player 2 - Move selection/active player indicator
  pmgraphics 1

  ' Keeping here in case I need it again - Set player missle priority: Players 0-1, playfield, players 2-3, background
   P.623,2

  ' Hide screen for faster startup
  poke 559,0
    
  ' Clear player data, then set sidebars
  mset pm.0,1024,0
  mset pm.0,255,255
  mset pm.3,255,255

  ' Make the sidebar and selection cursor 4x wide to block as much of the screen as possible, and the secret card 1x wide
  mset 53256,4,3: poke 53257, 0
  
  ' Set side par positions to left and right edge of screen
  PMHPOS 0,16:PMHPOS 3,208
  
  ' ============= COLORS =============

  ' Order: Players 0,1,2,3, Playfield 0,1,2,3, Background
  
  if PEEK(53268)=1 ' Check if we are running PAL on GTIA machines
    ' PAL colors
    move &""$00$0a$fa$00$78$0E$00$24$00+1, 704, 9
    move_color = $EE
  else
    ' NTSC colors
    move &""$00$0a$fa$00$88$0E$00$34$00+1, 704, 9
    move_color = $FE
  endif

  text_color(2) = move_color

  @CycleColorTheme  

  ' ============= PLAYFIELD =============
  @DisableDoubleBuffer
  
  ' Copy the custom character set data to the location
  move &font,&charBuffer,8*128

  ' Tell Atari to use the new location
  P.756,&charBuffer/256

  ' Custom Display List to give us 2 more rows (40x26) with DLI for coloring
  DL$ = ""$20$F0$44$00$00$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$84$84$20$04$41$00$00
  
  ' Copy the display list from the string to memory.
  displayList = &DL$+1
  dpoke displayList+len(DL$)-2,displayList

  ' Tell the display list the new location of the screen buffer
  dpoke displayList+3,&screenBuffer

  ' Use DLI to change the text/background colors of the bottom status rows
  DLISET dli_colors = background_color INTO $D01A, text_color INTO $D017
  DLI dli_colors

  ' Enable the new Display list
  dpoke 560, displayList

  ' Reset the screen
  @ResetScreen

  ' Disable accidental break key press
  poke 16,64:poke 53774,64

  @ShowScreen

ENDPROC

PROC CycleColorTheme
  ' First time called? Load from app key
  if colorTheme = -1
    colorTheme = 0
    temp$=""
    @NReadAppKey AK_CREATOR_ID, AK_APP_ID, AK_KEY_COLORTHEME, &temp$
    if len(temp$)=1 then colorTheme = val(temp$)
  else
    ' Otheriwse, just cycle theme
    sound 0, 220,10,5
    pause 4
    sound 0, 200,10,5
    
    colorTheme = (colorTheme + 1) mod 4 
  endif

  ' Set new theme colors (NTSC/PAL + theme index)
  i = (PEEK(53268)=1)*2*4 + 2*colorTheme
  h=colorThemeMap(i)
  j=colorThemeMap(i+1)

  pause 2
  background_color(0)= colorThemeMap(i)
  background_color(1)= colorThemeMap(i)
  POKE 708, colorThemeMap(i+1)

  ' Store in app key to recall on next program start
  @NWriteAppKey AK_CREATOR_ID, AK_APP_ID, AK_KEY_COLORTHEME, &STR$(colorTheme)
  sound
  @ClearKeyQueue
ENDPROC

' Call to show the screen, or occasionally to stop Atari attract/screensaver color mode from occuring
PROC ShowScreen
  poke 77,0:pause:poke 559,46+16
ENDPROC

' Call to clear the screen and and draw the four corners
PROC ResetScreen
  mset screen,40*26,0
  
  ' Draw the four black corners of the screen
  poke screen, 88:poke screen+39,89
  poke screen+40*24, 90:poke screen+40*25-1,91
ENDPROC

PROC DrawBuffer
  pause
  move &screenBuffer+1040,&screenBuffer, 1040
ENDPROC

Proc DrawBufferEnd
  @DrawBuffer
  @DisableDoubleBuffer
endproc

PROC EnableDoubleBuffer
  screen = &screenBuffer + 1040
ENDPROC

PROC DisableDoubleBuffer
  screen = &screenbuffer
ENDPROC

PROC ClearStatusBar
  PMHPOS 2,0
  mset &screenBuffer+1040+40*25, 40,0
  mset &screenBuffer+40*25, 40,0
ENDPROC

PROC ClearKeyQueue
  ' Clear out any queued key presses
  while key() : get k:wend
  K=0
ENDPROC

' ============================================================================
' (Utility Functions) Convert string to upper case, replace character in string
PROC ToUpper text
  for __i=text+1 to text + peek(text)
    if peek(__i) >$60 and peek(__i)<$7B then poke __i, peek(__i)-32
  next
ENDPROC

' ============================================================================
' Print #6 Replacement (From Eric Carr)
' Since there is a custom screen location for 26 rows, print #6 will not work out of the box, 
' I use POKE routines to PRINT. These were written over time as needed, so not as organized or optimized as they could be.
' I wrote these before switching to a double buffered approach. A speed/size optimization could be done
' revert to PRINT #6, but would still need some trickery for the last 2 rows. 

PROC PrintUpper text
  temp$=$(text)
  @ToUpper &temp$
  @Print &temp$
ENDPROC

PROC PrintAt _col _row text
  @Pos _col, _row
  @Print text
ENDPROC

PROC POS _col _row
  __loc = screen + 40*_row +_col
ENDPROC

' Inverse is the analog to COLOR(128)
PROC PrintInv text
  __print_inverse=128
  @Print text
  __print_inverse=0
ENDPROC

' Reverse prints right aligned, starting at the current location
PROC PrintReverse
  __print_reverse = 1
ENDPROC

PROC PrintVal text
  @Print &str$(text)
ENDPROC

' Prints text, followed by space up the specified character length.
' Useful for printing "100" in one moment, then "1  " next, without building the string manually
PROC PrintValSpace text __len
  @PrintSpace &str$(text), __len
ENDPROC

' Prints space for the rest of this line - used for bottom status bar
PROC PrintSpaceRest
  __charsLeft = 40 - (__loc-screen-40*_row)
  if  __charsLeft>0 then mset __loc, __charsLeft, 0
ENDPROC

PROC PrintSpace text __len
  if __print_reverse 
    temp$=""
    while peek(text)+len(temp$)<__len: temp$ =+" ": wend
    temp$ =+ $(text)    
  else 
    temp$ = $(text)
    while len(temp$)<__len: temp$ =+" ": wend
  endif

  @print &temp$
ENDPROC

' ============================================================================
' Core Printing routine. Converts from ATASCII to INTERNAL, handling inverted, alphanumeric and a few other supported characters
PROC Print text
  if __print_reverse then __loc = __loc - peek(text)+1
  ' Go through each character and convert from ATASCII to INTERNAL, then poke to memory to draw it
  FOR __i=text+1 to text+peek(text)
    _code = peek(__i)
    
    if _code<32
      _code= _code + 64
    elif _code< 95
      _code= _code - 32
      if _code = 12 : _code=116 ' Handle comma
      elif _code = 13 : _code=125  ' Handle hyphen
      elif _code = 14 : _code=115  ' Handle period
      elif _code = 15 : _code=124  ' Handle /
      endif
    elif _code<128
    elif _code<160
      _code= _code + 64
    elif _code<223
      _code= _code - 32
    endif

    poke __loc,_code+__print_inverse
    inc __loc
  next

  ' Reset print reverse
  __print_reverse = 0
  
ENDPROC

' Print a byte directly (INTERNAL, not ATASCII)
PROC PrintByte _byte
  poke __loc,_byte
  inc __loc
ENDPROC

' ============================================================================

' ============================================================================
' (N AppKey Helpers from Eric Carr) Call NRead/WriteAppKey to read or write app key

PROC __NOpenAppKey __N_creator __N_app __N_key __N_mode
  dpoke &NAppKeyBlock, __N_creator
  poke &NAppKeyBlock + 2, __N_app
  poke &NAppKeyBlock + 3, __N_key
  poke &NAppKeyBlock + 4, __N_mode
  SIO $70, 1, $DC, $80, &NAppKeyBlock, $09, 6, 0,0
ENDPROC

PROC NWriteAppKey __N_creator __N_app __N_key __N_string
  @__NOpenAppKey __N_creator, __N_app, __N_key, 1
  SIO $70, 1, $DE, $80, __N_string+1, $09, 64, peek(__N_string), 0
ENDPROC

PROC NReadAppKey __N_creator __N_app __N_key __N_string
  @__NOpenAppKey __N_creator, __N_app, __N_key, 0
  SIO $70, 1, $DD, $40, __N_string, $01, 66,0, 0
  MOVE __N_string+2, __N_string+1,64
  ' /\ MOVE - The first two bytes are the LO/HI length of the result. Since only the
  ' first byte is meaningful (length<=64), and since FastBasic string
  ' length is one byte, we just shift the entire string left 1 byte to
  ' overwrite the unused HI byte and instantly make it a string!
ENDPROC


