/* pdsb4g                                                            */
/* Sync PDS libraries with github repo                               */

do 100
say '['||time()||'] Using rexxfile 'directory()

/* read congig.json file                                             */


call read_config

if pds2git = Y then call pds2git

if git2pds = Y then call git2pds

say '['||time()||'] Using rexxfile 'directory()
end
exit

/* read congig.json file                                             */
read_config:
   say '==================================='
   say ' Reading configuration'
   say '==================================='
   hlq.0 = 0
   input_file  = 'config.json'
   do while lines(input_file) \= 0
      line = caseless linein(input_file)
      valid_record = pos(":",line)
      if valid_record = 0 then iterate
      parse var line '"' head '"' ':' tail ',' 

      if pos('"',tail) = 0 then command = head "='"||tail||"'"
      else command = head "="tail
      
      interpret command 
      if substr(head,1,3) = 'hlq' then hlq.0 = hlq.0 + 1
   end /* do while */
   call lineout input_file
return

/* pds2git - Syncs PDS files with GitHub                             */
pds2git:
   say '==================================='
   say ' Mainframe ---> GitHub'
   say '==================================='
/* retrieve hlq PDS names and load dsname. stem                      */
   if SysFileExists('hlq.json') = 1 then "del hlq.json"
   do i = 1 to hlq.0 
      'zowe zos-files list ds "'hlq.i'" -a --rfj >> hlq.json'   
   end

   drop dsname.; drop folder.; i = 0; dsname = ''; dsorg = ''; sal = ''
   
   input_file  = 'hlq.json'
   do while lines(input_file) \= 0
      sal = linein(input_file)
      select
         when pos('"stdout":',sal)<>0 then iterate
         when pos('"dsname":',sal)<>0 then parse var sal '"dsname":' dsname ','
         when pos('"dsorg":',sal)<>0  then parse var sal '"dsorg":' dsorg ','
         when pos('"lrecl":',sal)<>0  then parse var sal '"lrecl":' lrecl ','
         otherwise nop
      end /* select */
      if dsname <> '' & substr(dsorg,3,2) = 'PO' & substr(lrecl,3,2) = '80' then do 
         dsname = lower(dsname)
         i=i+1; dsname.i = changestr('"',dsname,' ')
         dsname.i = strip(dsname.i)
         dsname = ''; dsorg  = ''; lrecl = ''
      end /* if dsname */
   end /* do queued() */
   call lineout input_file
   dsname.0 = i
   /* dxr*/ do i = 1 to dsname.0
   say dsname.i
   end

/* for each PDS                                                      */

   do i = 1 to dsname.0
      folder.i = translate(dsname.i,'\','.')     
      say dsname.i '--> ' folder.i
      command = "exists = SysIsFileDirectory('"folder.i"')"
      interpret command
      if exists = 0 then do 
/* New PDS or first time                                             */   
         say 'Folder doesn''t exist'

         select 
            when pos('.rex',dsname.i)>0 then ext = '-e rex'
            when pos('.jcl',dsname.i)>0 then ext = '-e jcl'
            otherwise ext = ''
         end

         'zowe zos-files download am "'||dsname.i||'" 'ext' --mcr 10'
         say 'Creating 'dsname.i'.json file'
         'zowe zos-files list am "'||dsname.i||'" -a --rfj > 'dsname.i||'.json'
         message = 'first-commit'
         call commit message 
         "git push"
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
               say 'Deleting 'folder.i||'\'||member 
               'del 'folder.i||'\'||member||'.*'
               message = 'Delete'
               call commit message
            end
            when table.member.new <> table.member.old then do 
               say dsname.i||'('||member||') updated from 'table.member.old ' to 'table.member.new
               select 
                  when pos('.rex',dsname.i)>0 then ext = '-e rex'
                  when pos('.jcl',dsname.i)>0 then ext = '-e jcl'
                  otherwise ext = ''
               end

               'zowe zos-files download ds "'||dsname.i||'('||member||')" 'ext
               message = table.member.new 
               call commit message
            end
            otherwise nop
         end
      end

   end /* do k = 1 to dsname.0 */

   if commit = 'Y' then 'git push'

return

git2pds:
   say '==================================='
   say ' GitHub --> Mainframe'
   say '==================================='

   dir1 = translate(hlq,'\','.')     
   dir1 = translate(dir1,'','*')
   dir1 = translate(dir1,'','%')     
   dir2 = translate(dir1,'/','\')
   dir1 = lower(strip(dir1))
   dir2 = lower(strip(dir2))

   drop dataset.; i=0

   command = 'git pull'
   stem = rxqueue("Create")
   call rxqueue "Set",stem
   interpret "'"command" | rxqueue' "stem  
   do queued()
      filename = '' 
      parse caseless pull sal
      select
         when pos('Already up to date.',sal)<>0 then say 'Up to Date'
         when pos('files changed',sal)<>0 | pos('file changed',sal)<>0 then leave
         when pos(dir1,sal)<>0 | pos(dir2,sal)<>0 then do
            parse var sal filename ' |' . 
            filename = strip(filename)
            len = length(filename)
            dataset_member = substr(filename,1,len-4) 
            dataset_member = translate(dataset_member,'.','/')     
            dataset_member = translate(dataset_member,'.','\')     
            lp = lastpos('.',dataset_member) 
            dataset_member = translate(dataset_member,'(','.',,lp) || ')'
            lp = pos('(',dataset_member)  
            i=i+1; dataset.i = substr(dataset_member,1,lp-1) 
            if SysFileExists(filename) = 0 then Do
               say 'File 'filename 'doesn''t exist'
               'zowe zos-files delete data-set "'||dataset_member||'" -f'
            end
            else do 
               'zowe zos-files upload file-to-data-set "'||filename||'" "'||dataset_member||'"'
            end /* if SysFileExists */   
         end
         otherwise nop
      end
   end /* do queued() */
   
   call rxqueue "Delete", stem
   dataset.0 = i
   do i = 1 to dataset.0
      say dataset.i 
      j = i-1
      if dataset.i = dataset.j then iterate
      'zowe zos-files list am "'||dataset.i||'" -a --rfj > 'dataset.i||'.json'
   end
return

commit:
   parse caseless arg message 
   commit = 'Y'
   'git add -A'
   'git commit -a -m "'message'"'
return