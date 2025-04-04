begin

  ;; input parameters
  flog = getenv("flog")
  spc  = getenv("spc")
  obs  = getenv("obs")
  nam  = getenv("nam")
  nboot = stringtointeger(getenv("nboot"))  ; bootstrap replications
  idir = getenv("idir")
  bdir = getenv("bdir")
; hbase = getenv("hbase")

  print("## Bootstrapping by "+nboot+" for "+spc+" ##")

  ;; prepare output
  outf = bdir+"/"+flog

  ;; extract data from log file
  inpf = idir+"/"+flog
  print("## extracting from file: "+inpf+" ##")
  nrows = numAsciiRow(inpf)
  lines := asciiread(inpf,(/nrows/),"string")
  heads_t := lines(0)
  lines := lines(1:nrows-1)

  heads := str_split(heads_t," ")
  ncols = dimsizes(heads)

  print("-- changing strings to data matrix")
  valo = new((/ncols,nrows-1/),"double")
  do r=0 , nrows-2
    lsplt := todouble(str_split(lines(r)," "))
    valo(:,r) = lsplt(:)
  end do

  nval = nboot*(nrows-1)
  valb = new((/ncols,nval/),typeof(valo))
  stat = new((/ncols,2/),typeof(valb))

  print("## checking basic statistics")
  ;; check basic statitics for data cleaning
  stato = new((/ncols,5/),typeof(valb))
  do c=3 , ncols -1
    valx := valo(c,:)
    minx := min(valx)
    maxx := max(valx)
    avgx := avg(valx)
    medx := dim_median(valx)
    stdx := stddev(valx)
    stato(c,0) = minx
    stato(c,1) = maxx
    stato(c,2) = avgx
    stato(c,3) = medx
    stato(c,4) = stdx
    print(heads(c)+" min="+minx+" max="+maxx+" avg="+avgx+" median="+medx+" st.dev="+stdx)
  end do

  print("... saving original statistics ...")
  txtx = new((/6/),"string")
  txtx(0) = heads_t
  txtx(1) = "MN lat lon"
  txtx(2) = "MX lat lon"
  txtx(3) = "AV lat lon"
  txtx(4) = "MD lat lon"
  txtx(5) = "SD lat lon"
  do c=3 , ncols-1
    txtx(1) = txtx(1)+" "+stato(c,0)
    txtx(2) = txtx(2)+" "+stato(c,1)
    txtx(3) = txtx(3)+" "+stato(c,2)
    txtx(4) = txtx(4)+" "+stato(c,3)
    txtx(5) = txtx(5)+" "+stato(c,4)
  end do
  csvnm = str_split(flog,".")
  csvnm := csvnm(0)
  statof = idir+"/"+csvnm+"_stats.csv"
  write_table(statof,"w",[/txtx/],"%s")

  ;***************************************************************
  ; https://www.ncl.ucar.edu/Document/Functions/Contributed/generate_sample_indices.shtml
  ;***************************************************************
  NN    = nrows-1                       ; number of samples in dataset

  vBoot = new((/NN*nboot/),typeof(valb))
  iw = generate_sample_indices( NN, 1 )  ; with replacement
  do c=3 , ncols -1
    vals := valo(c,:)

    ;; bootstrapping
    do n=0 , nboot-1
      nA = 0+(n*NN)
      nB = (NN-1)+(n*NN)
      iwvals = vals(iw)
      vBoot(nA:nB) = iwvals(:)
    end do
    valb(c,:) = vBoot(:)
  end do

  ; prepare valb to save to csv - space delimited
  print("... saving bootstrap ...")
  txtb = new((/nval+1/),"string")
  txtb(0) = heads_t
  do n=0 , nval-1
    ;print("preparing csv "+(n+1)+"/"+nval)
    txtl = (n+1)+""
    do c=1 , ncols-1 
      txtl = txtl+" "+valb(c,n)
    end do
    txtb(n+1) = txtl
  end do

  bootd = idir+"/boot_"+nboot 
  bootf = bootd+"/"+csvnm+".csv"
  write_table(bootf,"w",[/txtb/],"%s")

; ; standardize indices based on W_i = ( X_i - X^bar ) / sigma
; print("... standardizing bootstrap ...")

; if ( hbase.eq."href" ) then
;   ; use historical avg and stddev from historical data for standardization
;   hflog = getenv("hflog")
;   ;; extract data from log file
;   nrowsh = numAsciiRow(hflog)
;   linesh := asciiread(scrf,(/nrowsh/),"string")
;   avgslh := linesh(1)
;   stdslh := linesh(2)
; end if

; valw = valb
  do c=3 , ncols -1
    vals := valb(c,:)
;   if ( hbase.eq."href" ) then
;     avgs := stringtofloat(avgslh(c))
;     stds := stringtofloat(stdslh(c))
;   else
      avgs := avg(vals)
      stds := stddev(vals)  
;   end if 
   ;do n=0 , nval-1
   ; ;if ( stds.eq.0 .and. avgs.eq.0 ) then
   ; ;  valw(c,n) = vals(n)
   ; ;else 
   ;    valw(c,n) = (vals(n) - avgs )/ stds
   ; ;end if
   ;end do
    stat(c,0) = avgs
    stat(c,1) = stds
  end do

; standd = bootd+"/standard"
; system("mkdir -p "+standd)
; if ( hbase.ne."href" ) then
    print("... saving bootstrapped statistics ...")
    txtc = new((/3/),typeof(txtb))
    txtc(0) = heads_t
    txtc(1) = "A lat lon"
    txtc(2) = "SD lat lon"
    do c=3 , ncols-1
      txtc(1) = txtc(1)+" "+stat(c,0)
      txtc(2) = txtc(2)+" "+stat(c,1)
    end do
    statsf = bootd+"/"+csvnm+"_stats.csv"
    write_table(statsf,"w",[/txtc/],"%s")
; end if

; txts = txtb
; do n=0 , nval-1
;   ;print("preparing csv "+(n+1)+"/"+nval)
;   txtl = (n+1)+""
;   do c=1 , ncols-1
;     txtl = txtl+" "+valw(c,n)
;   end do
;   txts(n+1) = txtl
; end do
; standf = standd+"/"+csvnm+".csv"
; write_table(standf,"w",[/txts/],"%s")

end
