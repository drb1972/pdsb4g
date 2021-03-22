/* rexx */

filename =  'roddi01/git/rexx/rexx04.txt'

if SysFileExists(filename) = 0 then Do
   say 'File 'filename 'doesn''t exist'     
end
exit