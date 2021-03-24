//RODDI01X JOB (C36C2,CHM00,OSN,'VPCHM'),'HERRA.-PROD',
//         MSGLEVEL=(1,1),              CMNEX008
//         MSGCLASS=X
//*------------------------------------------------------
//*------------------------------------------------------
//STEP1  EXEC PGM=IDCAMS
//*
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DEFINE CLUSTER (NAME(RODDI01.KSDS)      -
  INDEXED                                 -
  KEYS(6 1)                               -
  RECSZ(80 80)                            -
  TRACKS(1,1)                             -
  CISZ(4096)                              -
  FREESPACE(3 3) )                        -
  DATA (NAME(RODDI01.KSDS.DATA))          -
  INDEX (NAME(RODDI01.KSDS.INDEX))
/*

