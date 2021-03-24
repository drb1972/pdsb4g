/* rexx                                                               */
/* Busqueda de conflictos - Elementos duplicados - Tipo JCL           */
/*====================================================================*/
dsname    = 'TMPPR.CHM.AUDIT.JCLS'
/*====================================================================*/
upper cam
call init
/* cambio 02 */
/*
apl.1 = SPT
apl.0 = 1
*/

say 'test'

call aplicaciones_CHM /* Carga todos lod CAM de tres letras */

do apl = 1 to apl.0
   cam = apl.apl
   z = value(cam,'NO')
   say 'Tratando 'cam
   call trata_JCLS
   miembro = cam
   if value(cam) = 'SI' then do
      do g = 1 to cam.cam.0
         queue cam.cam.g
      end
   call crea_miembro
   drop cam.cam. /* Libera memoria */
   end
end /* do */
"delstack"
call salir



/*== Se obtiene lista de JCLS ========================================*/
Trata_JCLS:
/*-- Obtengo los tipos de JCL del CAM --------------------------------*/
cam4= cam||'T'
src = ''
call Libtypes
if src > 00 then do
   cam4 = cam||'Z'
   call Libtypes
end
if src > 00 then do
   say 'No existe Libtype JCLs para' cam
   return
end
c_tjcl = 0
drop tipojcl.
do i = 1 to sal.0
   parse var sal.i . '<libType>'v_tipojcl'</libType>' .
   if substr(v_tipojcl,1,1) = 'J' then do
      c_tjcl  = c_tjcl + 1
      tipojcl.c_tjcl = strip(v_tipojcl)
  /*  tipojcl = strip(v_tipojcl) */
   end /* if */
end /* do */
tipojcl.0 = c_tjcl

do i = 1 to tipojcl.0
   say '==>' tipojcl.i
end

drop jcls.
say 'Obteniendo miembros de Baseline - Tipo: JC@'
call obtener_miembros /* Obtengo lista de miembros */
cont = 0
do i = 1 to sal.0
   v1 = ''
   parse var sal.i . '<component>'v1'</' .
   if v1  = '' then do
      cont = cont +1
      jcls.cont = v1
   end /* if */
end /* do i */
jcls.0 = cont

/*== Si no hay =======================================================*/

if jcls.0 = 0 then do
   say 'No hay JCLs' cam
   return
end
/* En este stem escribo el texto */
drop cam.cam.
x = 0

/*== Proceso JCLs ====================================================*/

do i = 1 to jcls.0
   say 'JCL ==> 'left(jcls.i,8)

   do h = 1 to tipojcl.0
      tipojcl = tipojcl.h
      correcto = 'KO'
      call JCL_baseline
      src_bas8 = 'N'
      do j = 1 to sal_base.0
         parse var sal_base.j . '<componentType>' v_type '</' .
         parse var sal_base.j . '<statusReturnCode>' v_src_bas '</' .
         if v_src_bas = '08' then do
            src_bas8 = 'Y'
         end
         if v_type  = '' then do
            type = v_type
            z = value(jcls.i,type)
            correcto = 'OK'
            src_bas8 = 'N'
            leave
         end
         if jcls.i = value(jcls.i) then do /* Salida rc=08 */
            z = value(jcls.i,'')
         end
      end /* do j */
      if correcto = 'OK' then leave
   end /* tipojcl */

   call JCL_historico
   call limpia
   do j = 1 to sal.0
      parse var sal.j . '<componentType>'    v_type    '</' .
      if v_type  = '' then type = v_type
      parse var sal.j . '<package>'          v_pack    '</' .
      if v_pack  = '' then pack = v_pack
      parse var sal.j . '<checkedOutStatus>' v_ckout   '</' .
      if v_ckout = '' then ckout= v_ckout
      parse var sal.j . '<backedOutStatus>'  v_bkout   '</' .
      if v_bkout = '' then bkout= v_bkout
      parse var sal.j . '<promotedStatus>'   v_prom    '</' .
      if v_prom  = '' then prom = v_prom
      parse var sal.j . '<demotedStatus>'    v_demo    '</' .
      if v_demo  = '' then demo = v_demo
      parse var sal.j . '<deletedStatus>'    v_dele    '</' .
      if v_dele  = '' then dele = v_dele
      parse var sal.j . '<baselinedStatus>'  v_base    '</' .
      if v_base  = '' then base = v_base
      parse var sal.j . '<processingType>'   v_proc    '</' .
      if v_proc  = '' then process = v_proc
      if pos('</result>',sal.j) > 0 then result = 'OK'

   /* if type  = '' & pack  = '' & ckout  = '' & bkout  = '' & ,
         prom  = '' & demo  = '' & base   = '' & dele   = '' & , */
      if result = 'OK' then do
         /* drb
         say 'JCL   'left(jcls.i,8) value(jcls.i)
         say 'type  'type
         say 'ckout 'ckout
         say 'bkout 'bkout
         say 'prom  'prom
         say 'demo  'demo
         say 'base  'base
         say 'dele  'dele
         say 'procs 'process
         'eject'
            drb */
         if dele = 'Y' then do
            call limpia
            iterate
         end /* if dele */
      /* if process = 'S' then do  /* Scratch */
            call limpia
            iterate
         end /* if = S  */ */
         if process = 'R' then do  /* Rename  */
            call limpia
            iterate
         end /* if = R  */
      /* Si quiero solo un tipo, no duplicados  */
         if pos(type,value(jcls.i)) > 0 then do
      /* Si quiero todos los paquetes y tipos   */
      /* if type = value(jcls.i) then do */
            call limpia
            iterate
         end
         else do
      /* Si quiero solo un tipo, no duplicados  */
            zz = value(jcls.i)||type
            z  = value(jcls.i,zz)
      /* .......hasta aqui ...................  */
            if value(cam) = 'NO' then do
               z = value(cam,'SI')
               x=x+1 ; cam.cam.x= copies('-',72)
               x=x+1 ; cam.cam.x= cam
               x=x+1 ; cam.cam.x= copies('-',72)
            end
            if jclant  = jcls.i then do
               x=x+1 ; cam.cam.x= ''
               x=x+1 ; cam.cam.x= jcls.i
               x=x+1 ; cam.cam.x= copies('-',72)
               x=x+1 ; cam.cam.x= 'Baseline ' substr(value(jcls.i),1,3)
            end /* if jclant */
         end /* else */
         select
            when prom = 'Y' then do
               x=x+1;cam.cam.x= 'Promote  ' type 'En paquete 'pack
            end
            when ckout= 'Y' then do
               x=x+1;cam.cam.x= 'CheckOut ' type 'En paquete 'pack
            end
            when bkout= 'Y' then do
               x=x+1;cam.cam.x= 'BackOut  ' type 'En paquete 'pack
            end
            when demo = 'Y' then do
               x=x+1;cam.cam.x= 'Demoted  ' type 'En paquete 'pack
            end
/*          when dele = 'Y' then do
               x=x+1;cam.cam.x= 'Deleted  ' type 'En paquete 'pack
            end */
            when base = 'Y' & src_bas8 = 'Y' then do
               x=x+1;cam.cam.x= 'Error    ' type 'Tipo no definido'
            end
            when base = 'Y' & src_bas8 = 'N' then do
               x=x+1;cam.cam.x= 'Baselined' type 'En paquete 'pack
            end
            when process = 'S' then do  /* Scratch */
               x=x+1;cam.cam.x= 'Scratched' type 'En paquete 'pack
         end /* if = S  */
            otherwise do
      /* @@@@  say jcls.i 'No cumple reglas (Delete Scratch)' */
               x=x+1;cam.cam.x= 'Baselined' type 'En paquete 'pack
            end /* otherwise */
         end /* select */
         jclant = jcls.i
         call limpia
      end /* if result */
   end /* do j */
end /* do  i */
cam.cam.0 = x
return

/*--------------------------------------------------------------------*/
obtener_miembros:
   mvslib = 'CHMPR.PROD.BASE.'||cam||'.JCL'
   drop sal. ; k = 0
   k = k + 1 ; sal.k ='<?xml version="1.0"?>'
   k = k + 1 ; sal.k ='<service name="DSS">'
   k = k + 1 ; sal.k =' <scope name="SERVICE">'
   k = k + 1 ; sal.k ='  <message name="LIST">'
   k = k + 1 ; sal.k ='   <header>'
   k = k + 1 ; sal.k ='    <subsys>P</subsys>'
   k = k + 1 ; sal.k ='    <product>CMN</product>'
   k = k + 1 ; sal.k ='   </header>'
   k = k + 1 ; sal.k ='  <request>'
   k = k + 1 ; sal.k ='    <mvsLib>'||mvslib||'</mvsLib>'
   k = k + 1 ; sal.k ='    <component>*</component>'
   k = k + 1 ; sal.k ='    <listComponentOnly>Y</listComponentOnly>'
   k = k + 1 ; sal.k ='    <returnHashToken>N</returnHashToken>'
   k = k + 1 ; sal.k ='   </request>'
   k = k + 1 ; sal.k ='  </message>'
   k = k + 1 ; sal.k =' </scope>'
   k = k + 1 ; sal.k ='</service>'
   sal.0 = k

   "execio "sal.0" diskw xmlin(finis stem sal."
   "call '"comcload"(serxmlbc)' "
   retorno = rc
   "execio * diskr xmlout(finis stem sal."
   /* drb
   do kk = 1 to sal.0
      say sal.kk
   end */
   /*
   call check_retorno
   if xmlrc = 00 then say 'DSS SERVICE LIST ok para' mvslib
   */
return

/*--------------------------------------------------------------------*/
JCL_Baseline:
   drop sal. ; k = 0
   k = k + 1 ; sal.k ='<?xml version="1.0"?>                       '
   k = k + 1 ; sal.k ='<service name="CMPONENT">                   '
   k = k + 1 ; sal.k =' <scope name="HISTORY">                     '
   k = k + 1 ; sal.k ='  <message name="LISTBASE">                 '
   k = k + 1 ; sal.k ='   <header>                                 '
   k = k + 1 ; sal.k ='    <subsys>P</subsys>                      '
   k = k + 1 ; sal.k ='    <product>CMN</product>                  '
   k = k + 1 ; sal.k ='   </header>                                '
   k = k + 1 ; sal.k ='  <request>                                 '
   k = k + 1 ; sal.k ='    <component>'||jcls.i||'</component>  '
   k = k + 1 ; sal.k ='    <componentType>'||tipojcl||'</componentType>'
   k = k + 1 ; sal.k ='    <applName>'||cam||'T</applName>    '
   k = k + 1 ; sal.k ='   </request>                               '
   k = k + 1 ; sal.k ='  </message>                                '
   k = k + 1 ; sal.k =' </scope>                                   '
   k = k + 1 ; sal.k ='</service>                                  '
   sal.0 = k

   "execio "sal.0" diskw xmlin(finis stem sal."
   "call '"comcload"(serxmlbc)' "
   retorno = rc
   /* drb
   do jjj = 1 to sal.0
      say sal.jjj
   end
      drb */
   "execio * diskr xmlout(finis stem sal_base."
   /* drb
   do jjj = 1 to sal.0
      say sal.jjj
   end
      drb */
   /*
   call check_retorno
   if xmlrc = 00 then say 'CMP SERVICE HIST ok para' jcls.i
   */
return

/*--------------------------------------------------------------------*/
JCL_historico:
   drop sal. ; k = 0
   k = k + 1 ; sal.k ='<?xml version="1.0"?>                    '
   k = k + 1 ; sal.k ='<service name="CMPONENT">                '
   k = k + 1 ; sal.k =' <scope name="HISTORY">                  '
   k = k + 1 ; sal.k ='  <message name="LIST">                  '
   k = k + 1 ; sal.k ='   <header>                              '
   k = k + 1 ; sal.k ='    <subsys>P</subsys>                   '
   k = k + 1 ; sal.k ='    <product>CMN</product>               '
   k = k + 1 ; sal.k ='   </header>                             '
   k = k + 1 ; sal.k ='  <request>                              '
   k = k + 1 ; sal.k ='    <component>'||jcls.i||'</component>  '
   k = k + 1 ; sal.k ='    <componentType>J*</componentType>    '
/* k = k + 1 ; sal.k ='    <checkedOutStatus>Y</checkedOutStatus>'
   k = k + 1 ; sal.k ='    <deletedStatus>N</deletedStatus>  '
   k = k + 1 ; sal.k ='    <promotedStatus>Y</promotedStatus> '
   k = k + 1 ; sal.k ='    <demotedStatus>Y</demotedStatus>  '
   k = k + 1 ; sal.k ='    <baselinedStatus>Y</baselinedStatus>  '
   k = k + 1 ; sal.k ='    <delArchStatus>Y</delArchStatus>     '  */
   k = k + 1 ; sal.k ='   </request>                            '
   k = k + 1 ; sal.k ='  </message>                             '
   k = k + 1 ; sal.k =' </scope>                                '
   k = k + 1 ; sal.k ='</service>                               '
   sal.0 = k

   "execio "sal.0" diskw xmlin(finis stem sal."
   "call '"comcload"(serxmlbc)' "
   retorno = rc
   "execio * diskr xmlout(finis stem sal."
  /*  drb
   do fff = 1 to sal.0
      say sal.fff
   end
   */
/* call check_retorno
   if xmlrc = 00 then say 'CMP SERVICE HIST ok para' jcls.i
   */
return

/*- Obtiene cams dados de alta en CHM - Cam de tres letras -----------*/
aplicaciones_CHM:
   k = 0 ; drop sal.
   k=k+1;sal.k= '<?xml version="1.0"?>'
   k=k+1;sal.k= '<service name="PARMS">'
   k=k+1;sal.k= '<scope name="APL">'
   k=k+1;sal.k= '<message name="LIST">'
   k=k+1;sal.k= '<header>'
   k=k+1;sal.k= '<subsys>P</subsys>'
   k=k+1;sal.k= '<product>CMN</product>'
   k=k+1;sal.k= '</header>'
   k=k+1;sal.k= '<request>'
   k=k+1;sal.k= '<applName></applName>'
   k=k+1;sal.k= '</request>'
   k=k+1;sal.k= '</message>'
   k=k+1;sal.k= '</scope>'
   k=k+1;sal.k= '</service>'
   sal.0 = k

   "execio "sal.0" diskw xmlin(finis stem sal."
   drop sal.
   "call '"comcload"(serxmlbc)' "
   retorno = rc
   "execio * diskr xmlout(finis stem sal."
   if retorno > 0 then do
      say '<?xml version="1.0"?>'
      do i = 1 to sal.0
         say '<'sal.i'>'
      end
      say '</xml>'
      call salir
   end
/*- Se extraen los registros con el nombre de las aplicaciones       -*/
   drop apl.
   ix1 = 0
   do i = 1 to sal.0
      parse var sal.i . '<applName>' vapl '</' .
      if vapl ='' then do
         if substr(vapl,1,3) = substr(apl.ix1,1,3) then iterate
         ix1=ix1+1; apl.ix1= substr(vapl,1,3)
      end
   end
   apl.0 = ix1

return
/*--------------------------------------------------------------------*/
/*- Obtiene LibTypes -------------------------------------------------*/
Libtypes:
   k = 0 ; drop sal.
   k=k+1;sal.k= '<?xml version="1.0"?>      '
   k=k+1;sal.k= '<service name="LIBTYPE">   '
   k=k+1;sal.k= ' <scope name="APL">        '
   k=k+1;sal.k= '  <message name="LIST">    '
   k=k+1;sal.k= '   <header>                '
   k=k+1;sal.k= '    <subsys>P</subsys>     '
   k=k+1;sal.k= '    <product>CMN</product> '
   k=k+1;sal.k= '   </header>               '
   k=k+1;sal.k= '  <request>                '
   k=k+1;sal.k= '    <applName>'cam4'</applName>'
   k=k+1;sal.k= '   </request>              '
   k=k+1;sal.k= '  </message>               '
   k=k+1;sal.k= ' </scope>                  '
   k=k+1;sal.k= '</service>                 '
   sal.0 = k

   "execio "sal.0" diskw xmlin(finis stem sal."
   drop sal.
   "call '"comcload"(serxmlbc)' "
   retorno = rc
   "execio * diskr xmlout(finis stem sal."
/* if retorno > 0 then do
      say '<?xml version="1.0"?>'
      do i = 1 to sal.0
         say '<'sal.i'>'
      end
      say '</xml>'
      call salir
   end  */
/*- Se extraen los registros con el nombre de las aplicaciones       -*/
   do i = 1 to sal.0
      parse var sal.i . '<statusReturnCode>'v_src'</statusReturnCode>' .
      if v_src  = '' then do
         src = v_src
      end
   end
return

/*--------------------------------------------------------------------*/
Init:
   drop todo.
   /* Alloc de librermas de salida */
   x=outtrap('novale',0)
   "delete '"dsname"'"
   "alloc fi(fdatos) lrecl(80) blksize(0) recfm(f b) dsorg(po) ",
   "cylinders space(5,15) unit(sysda) new reu dsntype(library) ",
   "da('"dsname"')"
   "FREE FI(FDATOS)"
   x=outtrap('off')

   /* Alloc de librermas de CHM */
   comcload = 'CHM.PROD.COMC.LOAD'

   tcpiport = 'CHM.PADM.TCPIPORT'
   "alloc da('"tcpiport"') fi(SERQPARM) shr reu"
   "alloc fi(xmlin)  lrecl(255) blksize(0) recfm(v b) ",
         "cylinders space(5,8) unit(sysda) new reu"
   "alloc fi(xmlout)  lrecl(5000) blksize(0) recfm(v b) ",
         "cylinders space(5,8) unit(sysda) new reu"
return


/*------- Limpia -----------------------------------------------------*/
Limpia:
   Type    = ''
   Pack    = ''
   CKout   = ''
   BKout   = ''
   Prom    = ''
   Demo    = ''
   Base    = ''
   Dele    = ''
   Process = ''
   Result  = ''
return

/*------- Crea_miembro -----------------------------------------------*/
crea_miembro:
   "alloc fi(datos) da('"dsname"("miembro")') shr"
   "execio "queued()" diskw datos(finis"
   "free fi(datos)"
return

/*------- Salir ------------------------------------------------------*/
salir:
   "FREE FI(SERQPARM xmlin xmlout)"
   exit
return

/*------- Error en la llamada XML ------------------------------------*/
check_retorno:
   "execio * diskr xmlout(finis stem error."
    do n = 1 to error.0
       parse var error.n . 'ReturnCode>'var'</' .
       if var <> '' then xmlrc = var
       parse var error.n . 'ReasonCode>'var'</' .
       if var <> '' then xmlrs = var
       parse var error.n . 'statusMessage>'var'</' .
       if var <> '' then xmlmsg = var
    end
    if retorno > 0 then do
       say 'retorno:'retorno' en 'service scope message
       say 'msg:'xmlmsg
       say 'rc :'xmlrc
       say 'rs :'xmlrs
/*     call salir  */
    end
return
