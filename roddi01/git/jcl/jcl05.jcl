//StepName EXEC PGM=IDCAMS
//SYSPRINT DD   SYSOUT=SYSOUT
//SYSIN    DD   *
    DEFINE CLUSTER -
       (NAME (Name) -
       STORAGECLASS (StorageClass) -
       MANAGEMENTCLASS (ManagementClass) -
       DATACLASS (DataClass))
/*