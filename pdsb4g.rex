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
         when pos('"STDOUT":',sal)<>0 then iterate
         when pos('"DSNAME":',sal)<>0 then parse var sal '"DSNAME":' dsname ','
         when pos('"DSORG":',sal)<>0  then parse var sal '"DSORG":' dsorg ','
         when pos('"LRECL":',sal)<>0  then parse var sal '"LRECL":' lrecl ','
         otherwise nop
      end /* select */
      if dsname <> '' & substr(dsorg,3,2) = 'PO' & substr(lrecl,3,2) = '80' then do 
         dsname = lower(dsname)
         i=i+1; dsname.i = changestr('"',dsname,' ')
         dsname.i = strip(dsname.i)
         dsname = ''; dsorg  = ''; lrecl = ''
      end /* if dsname */
   end /* do queued() */
   dsname.0 = i
   call rxqueue "Delete", stem

/* for each PDS                                                      */

   do i = 1 to dsname.0
      folder = translate(dsname.i,'\','.')     
      say 'PDS -----> 'dsname.i
      say 'Folder --> ' folder
      command = "exists = SysIsFileDirectory('"folder"')"
      interpret command
      if exists = 0 then do 
/* New PDS or first time                                             */   
         say 'Folder doesn''t exist'
         'zowe zos-files download am "'||dsname.i||'" --mcr 10'
         say 'Creating 'dsname.i'.json file'
         'zowe zos-files list am "'||dsname.i||'" -a --rfj > 'dsname.i||'.json'
         message = 'first-commit'
         call commit message 
         iterate
      end

/* Update                                                            */

      command = 'zowe zos-files list am "'||dsname.i||'" -a --rfj'  
      stem = rxqueue("Create")
      call rxqueue "Set",stem
      interpret "'"command" | rxqueue' "stem  

      i=0; drop list.; drop table;  member = ''; vers = ''; mod = ''

      do queued()
         pull sal
         select
            when pos('"STDOUT":',sal)<>0 then iterate
            when pos('"MEMBER":',sal)<>0 then parse var sal '"MEMBER": "' member '",'
            when pos('"VERS":',sal)<>0   then parse var sal '"VERS":' vers ','
            when pos('"MOD":',sal)<>0    then parse var sal '"MOD":' mod ','
            otherwise iterate
         end /* select */
         if member <> '' & vers <> '' & mod <> '' then do
            member = strip(member); vers = strip(vers); mod = strip(mod)
            i=i+1; list.i =member
            table.member.new = 'v'||vers ||'m'||mod
            member = ''; vers = ''; mod = ''
         end /* if */
      end /* do queued() */
      call rxqueue "Delete", stem

      input_file  = dsname.i||'.json'
      do while lines(input_file) \= 0
         sal = linein(input_file)
         select
            when pos('"stdout":',sal)<>0 then iterate
            when pos('"member":',sal)<>0 then parse var sal '"member": "' member '",'
            when pos('"vers":',sal)<>0   then parse var sal '"vers":' vers ','
            when pos('"mod":',sal)<>0    then parse var sal '"mod":' mod ','
            otherwise iterate
         end /* select */
         if member <> '' & vers <> '' & mod <> '' then do
            member = strip(member); vers = strip(vers); mod = strip(mod)
            i=i+1; list.i =member
            table.member.old = 'v'||vers ||'m'||mod
            member = ''; vers = ''; mod = ''
         end /* if dsname */
      end /* do queued() */
      call lineout input_file

      list.0 = i
      Call SysStemSort "list."

      do i = 1 to list.0 
         j=i-1
         if list.i = list.j then iterate 
         member = list.i
         select
            when table.member.new = 'TABLE.'||member||'.NEW' then do 
               'del 'folder||'\'||member||'.*'
               message = 'Delete'
               call commit
            end
            when table.member.new <> table.member.old then do 
               'zowe zos-files download ds "'||dsname.i||'('||member||')"'
               message = table.member.new 
               call commit
            end
            otherwise nop
         end
      end

   end /* do i = 1 to dsname.0 */

   if commit = 'Y' then 'git push'

return

commit:
   parse caseless arg message 
   commit = 'Y'
   'git add -A'
   'git commit -a -m "'message'"'
return