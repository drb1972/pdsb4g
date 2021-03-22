/* pdsb4g                                                            */
/* Sync PDS libraries with github repo                               */

say '['||time()||'] Using rexxfile 'directory()

/* read congig.json file                                             */
call read_config

if pds2git = Y then call pds2git




say '['||time()||'] Using rexxfile 'directory()

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
      say dsname.i '--> ' folder
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

      j=0; drop list.; drop table.;  member = ''; vers = ''; mod = ''

/* Load old member version                                           */

      say 'Loading previous member versions'
      input_file  = dsname.i||'.json'
      do while lines(input_file) \= 0
         sal = linein(input_file)
         select
            when pos('"stdout":',sal)<>0 then iterate
            when pos('"member":',sal)<>0 then parse var sal '"member": "' member '",'
            when pos('"vers":',sal)<>0   then parse var sal '"vers":' vers ','
            when pos('"mod":',sal)<>0    then parse var sal '"mod":' mod ','
            otherwise nop
         end /* select */
         if member <> '' & vers <> '' & mod <> '' then do
            member = strip(member); vers = strip(vers); mod = strip(mod)
            j=j+1; list.j =member
            table.member.old = 'v'||vers ||'m'||mod
            member = ''; vers = ''; mod = ''
         end /* if dsname */
      end /* do queued() */
      call lineout input_file

/* Load current member version                                       */
      say 'Loading current member versions'
      'zowe zos-files list am "'||dsname.i||'" -a --rfj > 'dsname.i||'.json'
      message = 'members-changed' 
      call commit message
      input_file  = dsname.i||'.json'
      do while lines(input_file) \= 0
         sal = linein(input_file)
         select
            when pos('"stdout":',sal)<>0 then iterate
            when pos('"member":',sal)<>0 then parse var sal '"member": "' member '",'
            when pos('"vers":',sal)<>0   then parse var sal '"vers":' vers ','
            when pos('"mod":',sal)<>0    then parse var sal '"mod":' mod ','
            otherwise nop
         end /* select */
         if member <> '' & vers <> '' & mod <> '' then do
            member = strip(member); vers = strip(vers); mod = strip(mod)
            j=j+1; list.j =member
            table.member.new = 'v'||vers ||'m'||mod
            member = ''; vers = ''; mod = ''
         end /* if dsname */
      end /* do queued() */
      call lineout input_file

      list.0 = j

      -- /* dxr */ do j = 1 to list.0
      --             member = list.j
      --             say '---> member 'member 'table.member.new 'table.member.new 'table.member.old 'table.member.old
      --          end


/* sort stem buble method */
      Do k = list.0 To 1 By -1 Until flip_flop = 1
         flip_flop = 1
         Do j = 2 To k
            m = j - 1
            If list.m > list.j Then Do
               xchg   = list.m
               list.m = list.j
               list.j = xchg
               flip_flop = 0
            End /* If stem.m */
         End /* Do j = 2 */
      End /* Do i = stem.0 */


      do k = 1 to list.0 
         j=k-1
         if list.k = list.j then iterate 
         member = list.k
         select
            when table.member.new = 'TABLE.'||member||'.NEW' then do 
               say 'Deleting 'folder||'\'||member 
               'del 'folder||'\'||member||'.*'
               message = 'Delete'
               call commit message
            end
            when table.member.new <> table.member.old then do 
               say dsname.i||'('||member||') updated from 'table.member.old ' to 'table.member.new
               'zowe zos-files download ds "'||dsname.i||'('||member||')"'
               message = table.member.new 
               call commit message
            end
            otherwise nop
         end
      end

   end /* do k = 1 to dsname.0 */

   if commit = 'Y' then 'git push'

return

commit:
   parse caseless arg message 
   commit = 'Y'
   'git add -A'
   'git commit -a -m "'message'"'
return