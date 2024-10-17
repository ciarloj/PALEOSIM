load "trimPNG.ncl"

begin
;*************************
; read in data
;*************************

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; change inputs manually ;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  var = getenv("var")
  frq = "hr"
  yrs = "1997-2022"

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;; end of inputs ;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  vars  = (/"date","time","winddir","windspeed","rhus","tas","dtas","ps"/)
  vlabs = (/"Date","Time [GMT]","WD [o]","WS [m/s]","RH [%]","AT [oC]","DT [oC]","AP [hPa]"/)
  vnams = (/"Date","Time","Wind Direction","Wind Speed","Relative Humidity","Air Temperature","Dew Point Temperature","Air Pressure"/) 
  units = (/"#","#","~F34~0~F~","m s~S~-1~N~","%","~F34~0~F~C","~F34~0~F~C","hPa"/)
  nvars = dimsizes(vars)

  decades = False
  if ( var.eq."tas" ) then
    decades = True
  end if

  ;; identify correct column for var
  do v=0, nvars-1
    vv = vars(v)
    if ( vv.eq.var ) then
      cn = v
      break
    end if
  end do

  ddir = "../"
  odir = ddir+"images/"
  system("mkdir -p "+odir)

  outn = "annual-cycle_"+var
  wks = gsn_open_wks("png",odir+outn)

  ;; extract data from file
  dfil = ddir+"Giordan_data_hr.csv"
  fdel = ","

  nrows = numAsciiRow(dfil)
  lines := asciiread(dfil,(/nrows/),"string")
  heads := lines(0)
  titles = str_split(heads,fdel)
  ncols  = dimsizes(titles)

  ;; confirm correct column
  vlab = vlabs(cn)
  dlab = titles(cn)
  if ( vlab.ne.dlab ) then
    print("ERROR. Labels don't match!")
    print("  expecting = "+vlab)
    print("  getting   = "+dlab)
    exit
  end if

  ;; sort data
  lines := lines(1:nrows-1)
  table  = new((/nrows-1,ncols/),"string")
  do l=0 , nrows-2
    lsplt = str_split(lines(l),fdel)
    table(l,:) = lsplt(:)
    delete(lsplt)
  end do
  table = where(table.eq."N/A",table@_FillValue,table)

  ;; get variable data
  unit = units(cn)
  vnam = vnams(cn)
  varf = stringtofloat(table(:,cn))
  vdate = table(:,0)

  d1table = new((/nrows-1/),typeof(varf))
  avcycle = new((/366/),typeof(varf))
  stcycle = avcycle
  sbcycle = avcycle
  mxcycle = avcycle
  mncycle = avcycle
  av2000s = avcycle
  av2010s = avcycle
  dmcycle = new((/366/),typeof(vdate))
  fullCYC = new((/6,366/),typeof(varf))

  vdatex = new((/nrows-1,3/),typeof(vdate))
  vdatez = new((/nrows-1/),typeof(vdate))
  vdatey = new((/nrows-1/),typeof(vdate))
  do n=0 , nrows-2
    vdates = str_split(vdate(n),"/")
    vdatex(n,:) = vdates(:)
    vdatez(n) = vdatex(n,0)+"/"+vdatex(n,1)
    vdatey(n) = vdatex(n,2)
  end do
  vdateyi = tointeger(vdatey)

  mons = (/"01","02","03","04","05","06","07","08","09","10","11","12"/)
  mxdy = (/ 31 , 29 , 31 , 30 , 31 , 30 , 31 , 31 , 30 , 31 , 30 , 31 /) 
  n = 0 
  do m=0 , 11
    mn = mons(m)
    md = mxdy(m)
    do d=0 , md-1
      dmcycle(n) = sprinti("%0.2i", (d+1))+"/"+mn
      n = n+1
    end do
  end do

  if ( var.eq."rsds" ) then
    varf = where(varf.eq.0.,varf@_FillValue,varf)
  end if

  do n=0 , 365
    dm = dmcycle(n)
    d1table = where(vdatez.eq.dm,varf,d1table@_FillValue)
    avcycle(n) = avg(d1table)
    stcycle(n) = avcycle(n)+stddev(d1table)
    sbcycle(n) = avcycle(n)-stddev(d1table)
    mxcycle(n) = max(d1table)
    mncycle(n) = min(d1table)
    if ( decades.eq.True ) then
      d1table1 = where(vdateyi.lt.2010,d1table,d1table@_FillValue)
      d1table2 = where(vdateyi.ge.2010,d1table,d1table@_FillValue)
      av2000s(n) = avg(d1table1)
      av2010s(n) = avg(d1table2)
    end if
    d1table = d1table@_FillValue
  end do
  racycle = runave(avcycle,30,-1)
  
  fullCYC(0,:) = avcycle(:)
; fullCYC(1,:) = racycle(:)
  fullCYC(2,:) = mxcycle(:)
  fullCYC(3,:) = mncycle(:)

  if ( decades.eq.True ) then
    fullCYC(4,:) = av2000s(:)
    fullCYC(5,:) = av2010s(:)
  end if

  vmin = floor(min(mncycle))
  vmax = ceil(max(mxcycle))
 
; ;;; find top 3 years and bottom 3 years
; vdatey(:) = vdatex(:,2)
; yrs2 = str_split(yrs,"-")
; y1 = tointeger(yrs2(0))
; y2 = tointeger(yrs2(1))
; ny = y2-y1+1
;
; yearstat = new((/2,ny/),typeof(varf))
; do y=0 , ny-1
;   yr = tostring(y1+y)
;   d1table = where(vdatey.eq.yr,varf,d1table@_FillValue)
;   yearstat(0,y) = tofloat(yr)
;   nvalid = num(.not.ismissing(d1table))
;   if ( nvalid.ge.7884 ) then 
;     yearstat(1,y) = avg(d1table)  ;; only consider years with more than 90% of timesteps
;   end if
;   delete(nvalid)
;   d1table = d1table@_FillValue
; end do
;
; ;; identify bottom 3 years 
; yearindx = dim_pqsort(yearstat,1) 
; yearsort = yearstat
; do y=0 , ny-1
;   ii = yearindx(1,y)
;   yearsort(0,y) = yearstat(0,ii)
;   yearsort(1,y) = yearstat(1,ii)
; end do
; print("Bottom 3 years:")
; print(yearsort(0,0)+" = "+yearsort(1,0))
; print(yearsort(0,1)+" = "+yearsort(1,1))
; print(yearsort(0,2)+" = "+yearsort(1,2))
;
; ;; for top3 - reset missing to -9999 and sort again with -1
;
; do n=0 , 365
;   dmy = dmcycle(n)+"/"+yearsort(0,0)
;   d1table = where(vdate.eq.dmy,varf,d1table@_FillValue)
;   fullCYC(4,n) = avg(d1table)
;   d1table = d1table@_FillValue
; end do
 
  ;***********************
  ; plot
  ;***********************

  res            = True               ; plot mods desired
  res@gsnDraw    = False              ; don't draw yet
  res@gsnFrame   = False              ; don't advance frame yet

  res@tmYROn     = False              ; Turn off right tickmarks.
  res@tmXTOn     = False              ; Turn off top tickmarks.

  res@trYMinF = vmin
  res@trYMaxF = vmax
  res@trXMinF = 1
  res@trXMaxF = 366

  bins  = ispan(1,366,1)
; xx = (/31,60,91,121,152,182,213,244,274,305,335,366/)  ; end day of mon
  xx = (/16,45,76,106,137,167,198,229,259,290,320,351/)  ; mid day of mon
; mlab = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
  mlab = (/"J","F","M","A","M","J","J","A","S","O","N","D"/)
  res@tmXBMode = "Explicit"           ;-- use explicit x-axis bottom values
  res@tmXBValues = xx                 ;-- x-axis bottom values
  res@tmXBMinorValues = bins(::5)-1  ;-- minor tick marks
  res@tmXBLabels = mlab               ;-- x-axis bottom labels

  res@xyMarkLineMode    = "Lines"
  res@xyMarkers         = (/16,16,16,16,16,16/)
  res@xyLineThicknessF  = (/3,3,3,3,3,3/)     ; Thicken the lines
  res@xyDashPatterns    = (/0,0,2,2,6,6/)
  res@xyLineColors      = (/"blue","red","black","black","springgreen3","tan2"/)

; res@gsnCenterStringFontHeightF    = 0.02
; res@gsnCenterString               = fnam+" "+vnam ;+" ("+yrs+")"

  res@tiYAxisString        = vnam+" ("+unit+")"
  res@tiXAxisString        = "months"
  res@tiYAxisFontHeightF   = 0.020
  res@tiXAxisFontHeightF   = 0.020

  plot = gsn_csm_xy(wks,bins,fullCYC,res)

  ;; prepare shaded area

  yp = new((/2*366/),typeof(varf))
  xp = new((/2*366/),typeof(bins))

  do k=0, 366-1
    yp(k)          = stcycle(k)
    xp(k)          = bins(k)
    xp(2*366-1-k)  = bins(k)
    yp(2*366-1-k)  = sbcycle(k)
  end do

  gsres                   = True                        ; poly res
  gsres@tfPolyDrawOrder   = "Predraw"                   ; draw this first
  gsres@gsFillColor       = "SlateBlue"                 ; color chosen
  gsres@gsFillOpacityF    = 0.5
  dummy = gsn_add_polygon (wks,plot,xp,yp,gsres)

  ;************************************************
  ; Set resources for customizing a simple legend
  ;************************************************
  if ( decades.eq.True ) then 
    genres                         = True
    genres@XPosPercent             = 3                       ; move to the right

    genres@ItemSpacePercent        = 3
    textres                        = True
    textres@lgLabelFontHeights     = 0.013
    textres@lgPerimOn              = False                   ; no perimeter
    textres@lgItemCount            = 2                       ; how many
    lineres                        = True
    lineres@LineLengthPercent      = 6                       ; expressed as %, 0->100, length of line
    lineres@lgLineLabelFontHeights = 0.013                   ; font height
    textres@lgLabels               = (/"1999-2009","2010-2022"/)
    lineres@lgLineThicknesses      = (/3,3/)             ; line thickness
    lineres@lgDashIndexes          = (/6,6/)              ; line patterns
    lineres@lgLineColors           = (/"springgreen3","tan2"/)

    dum = simple_legend(wks, plot, genres, lineres, textres)
  end if


  draw(plot)                                            ; draw
  frame(wks)                                            ; advance frame

  trimPNG(odir+outn+".png")


end
