/* rexx                                                               */
say 'goodbye'
say 'hello'

/* Obtencion de listado de elementos en Baseline                      */
address ispexec
Do forever
   'addpop column(16) row(6)'
   'display panel(CHMBP0)'
   if rc > 4 then do
      'rempop'
   return
   end
   'rempop'
   leave
end
address TSO
"newstack"
user = userid()
fjob = '//'||user||Y
fjob = strip(fjob||" JOB (C36C2,CHM00,OSN,'CHM'), ")
queue fjob
queue "//         'HERR.-PROD',MSGCLASS=X,CLASS=P,"
queue "//         MSGLEVEL=(1,1),NOTIFY=&SYSUID"
queue "//*---------------------------------------"
queue "//BASELIS  EXEC PGM=IKJEFT01,"
queue "//         PARM='%CHMBR00 "CAM"'"
queue "//SYSEXEC  DD DISP=SHR,DSN=CHM.PROD.INICIAL"
queue "//SYSTSPRT DD  SYSOUT=*"
queue "//SYSTSIN  DD DUMMY"
queue "//SYSIN    DD DISP=(NEW,DELETE,DELETE),DSN=&&BASELIS,"
queue "//         RECFM=FBA,LRECL=133,BLKSIZE=0,"
queue "//         SPACE=(CYL,(2,2),RLSE),UNIT=SYSDA"
queue "$$"
call outtrap "line.", "*"
"submit * end($$)"
return