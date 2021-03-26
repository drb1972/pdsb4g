# pdsb4g
PDS Bridge for GIT

1.- Install ooRexx
2.- Create an empty GitHub repo
3.- Edit config.json
   3.1.- Set the HLQs in the format:
         "hlq.1"   : "RODDI01.GIT*",
         "hlq.2"   : "SYS1.PARMLI*",
         ...
         numbers must be in sequential order
   3.2.- set your GitHub repo name in "ghrepo"  :
   3.3.- To have bidirectional synch leave pds2git and git2pds values set to Y
4.- Run st.rex 

The first time the service is executed takes a while until synchronizes PDSs with GitHub. Following times is very fast by updating any change. 

