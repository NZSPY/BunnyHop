
' Some code snippets from Eric Carr
' This is not a workign application, just a collection of code that can be used to read JSON from FujiNET
' many thnaks to Eric for the help :-)

' ------------------------------------------------------------------------------------
' NInputInit - Gets the entire response from FujiNet into specified array
' NInput - Call repeatedly to read the next key or value into a string. Similar to Atari BASIC: INPUT #UNIT, MyString$
' ------------------------------------------------------------------------------------
' You can use it like this:

' Receive buffer
dim responseBuffer(1023) BYTE


... call fujinet


' Initialize reading the api response
@NInputInit UNIT, &responseBuffer

' Initialize strings - this reserves their space in memory so NInput can write to them
key$="" : value$=""
INDEX=0

do
  ' Get the next line of text from the api response as the key
  @NInput &key$
  
  ' An empty key means we reached the end of the response
  if len(key$) = 0 then exit

  ' Get the next line of text from the api response as the value
  @NInput &value$

  ' Depending on key, set appropriate variable to the value
  if key$="t" then tableID$(INDEX)=value$
  if key$="n" then tableName$(INDEX)=value$
  if key$="p" then tablePlayerName$(INDEX)=value$
  if key$="m" then TableMaxPlayers$(INDEX)=value$

  ' If read last field of a table, increment index
  if key$="m" then INC INDEX
loop 

' ------------------------------------------------------------------------------------

' Or if you know the exact number of fields (like list of tables), 
' you can read directly into table values and ignore checking the key


' Receive buffer
dim responseBuffer(1023) BYTE

' Initialize strings - this reserves their space in memory so NInput can write to them
dummy$=""
for i=0 to 6
 TableID$(i)=""
 TableName$(i)=""
 TableCurrentPlayers$(i)=""
 TableMaxPlayers$(i)=""
next i


... call fujinet


' Initialize reading the api response
 @NInputInit UNIT, &responseBuffer

INDEX=0
do
  ' If the first read is empty, we reached the end
  @NInput &dummy$ : if len(dummy$) = 0 then exit
  @NInput &TableID$(INDEX)

  @NInput &dummy$ : @NInput &TableName$(INDEX)
  @NInput &dummy$ : @NInput &TableCurrentPlayers$(INDEX)
  @NInput &dummy$ : @NInput &TableMaxPlayers$(INDEX)

  INC INDEX
loop 


' ============================================================================
' (N Helper) Gets the entire response from the specified unit into the provided buffer index for NInput to read from.
' WARNING! No check is made if buffer length is long enough to hold the FujiNet payload.
PROC NInputInit __NI_unit __NI_index
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