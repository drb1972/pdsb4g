/* rexx */

len = length(dataset)
dataset = substr(dataset,1,len-4) 
dataset = translate(dataset,'.','/')     
dataset = translate(dataset,'.','\')     
lp = lastpos('.',dataset) 
dataset = translate(dataset,'(','.',,lp) || ')'     
