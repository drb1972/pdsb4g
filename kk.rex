/* rexx */

drop memberlist.

command = 'zowe zos-files list am "roddi01.git.rexx" -a --rfj'  /* dxr */
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

input_file  = 'roddi01.git.rexx.json'  /* dxr */
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

do i = 1 to list.0 /* dxr borrar */
   j=i-1
   if list.i = list.j then iterate 
   member = list.i
   select
      when table.member.new = 'TABLE.'||member||'.NEW' then do 
         say member 'Hay que borrarlo del dir con mensaje deleted y commitpush'
      end
      when table.member.new <> table.member.old then do 
         say member 'es nuevo, hay que bajarlo'
      end
      otherwise nop
   end
end


exit