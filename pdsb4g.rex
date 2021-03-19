/* pdsb4g                                                            */
/* Sync PDS libraries with github repo                               */

/* read congig.json file                                             */
call read_config

if pds2git = Y then call pds2git






exit

/* read congig.json file                                             */
read_config:
   input_file  = 'config.json'
   do while lines(input_file) \= 0
      line = caseless linein(input_file)
      valid_record = pos(":",line)
      if valid_record = 0 then iterate
      parse var line '"' head '"' ':' tail ',' 

      if pos('"',tail) = 0 then command = head "='"||tail||"'"
      else command = head "="tail
      
      interpret command 
   end /* do while */
   call lineout input_file
return

/* pds2git - Syncs PDS files with GitHub                             */
pds2git:

/* retrieve hlq PDS names and load dsname. stem                      */
   command = 'zowe zos-files list ds "'hlq'" -a --rfj'   
   stem = rxqueue("Create")
   call rxqueue "Set",stem
   interpret "'"command" | rxqueue' "stem  

   drop dsname.; i = 0; dsname = ''; dsorg = ''; sal = ''
   
   do queued()
      pull sal
      select
         when pos("STDOUT",sal)<>0 then iterate
         when pos("DSNAME",sal)<>0 then parse var sal '"DSNAME":' dsname ','
         when pos("DSORG",sal)<>0  then parse var sal '"DSORG":' dsorg ','
         when pos("LRECL",sal)<>0  then parse var sal '"LRECL":' lrecl ','
         otherwise nop
      end /* select */
      if dsname <> '' & substr(dsorg,3,2) = 'PO' & substr(lrecl,3,2) = '80' then do 
         dsname = lower(dsname)
         i=i+1; dsname.i = changestr('"',dsname,' ')
         dsname.i = strip(dsname.i)
         dsname = ''; dsorg  = ''
      end /* if dsname */
   end /* do queued() */
   dsname.0 = i
   call rxqueue "Delete", stem

/* for each PDS                                                      */

   do i = 1 to dsname.0
      folder = translate(dsname.i,'\','.')     
      command = "exists = SysIsFileDirectory('"folder"')"
      interpret command
      if exists = 0 then do 
/* New PDS or first time                                             */
         'zowe zos-files download am "'||dsname.i||'" --mcr 10'
         'zowe zos-files list am "'||dsname.i||'" -a --rfj > 'dsname.i||'.json'
      end

/* Update                                                            */


   end /* do i = 1 to dsname.0 */



return