$PROBLEM  PHENOBARB SIMPLE MODEL
$INPUT  ID TIME AMT WGT APGR DV
$DATA  pheno5.dta IGNORE=@ IGNORE=(ID.EQ.3)
$SUBROUTINE  ADVAN1 TRANS2
$PK
      TVCL=THETA(1)
      TVV=THETA(2)
      CL=TVCL*EXP(ETA(1))
      V=TVV*EXP(ETA(2))
      S1=V
$ERROR
      W=F
      Y=F+W*EPS(1)
      IPRED=F         ;  individual-specific prediction
      IRES=DV-IPRED   ;  individual-specific residual
      IWRES=IRES/W    ;  individual-specific weighted residual

$THETA  (0,0.0105)    ; CL 
$THETA  (0,1.0500)    ; V
$OMEGA            .4  ; IVCL
                  .25 ; IVV
$SIGMA            .04                         

$ESTIMATION  MAXEVALS=9999 SIGDIGITS=4 POSTHOC
