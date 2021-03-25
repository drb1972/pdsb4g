/* rexx */

call read_config
if SysIsFileDirectory('C:\Temp') = 0 then "md C:\Temp"

"cd C:\Temp"

parse var ghrepo . '//' . '/' . '/' folder_name '.git'

if SysIsFileDirectory(folder_name) = 0 then do
   "rmdir /S /Q "folder_name
   "git clone "ghrepo
   "cd "folder_name
   "copy "currdir||"\pdsb4g.rex"
   "copy "currdir||"\config.json"
   "echo pdsb4g.rex >> .gitignore"
   "echo *.json >> .gitignore"
   "echo *.txt >> .gitignore"
   "echo *.md >> .gitignore"
end
"rexx pdsb4g.rex"
exit

/* read congig.json file                                             */
read_config:
   say '==================================='
   say ' Reading configuration'
   say '==================================='
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
   
   "dir > currdir.txt"
   input_file  = 'currdir.txt'
   do while lines(input_file) \= 0
      line = caseless linein(input_file)
      if pos('Directory of',line)<>0 then do     
         parse var line ' Directory of ' currdir
         leave 
      end 
   end /* do while */
   call lineout input_file
return
