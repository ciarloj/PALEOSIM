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
  yrs = "1997-2022*"

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;; end of inputs ;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  vars  = (/"date","time","winddir","windspeed","rhus","tas","dtas","ps"/)
  vlabs = (/"Date","Time [GMT]","WD [o]","WS [m/s]","RH [%]","AT [oC]","DT [oC]","AP [hPa]"/)
  vnams = (/"Date","Time","Wind Direction","Wind Speed","Relative Humidity","Air Temperature","Dew Point Temperature","Air Pressure"/)
  units = (/"#","#","~F34~0~F~","m s~S~-1~N~","%","~F34~0~F~C","~F34~0~F~C","hPa"/)
  nvars = dimsizes(vars)

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

  outn = "diurnal-cycle_"+var
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
  vtime = table(:,1)

  d1table = new((/nrows-1/),typeof(varf))
  avcycle = new((/24/),typeof(varf))
  stcycle = avcycle
  sbcycle = avcycle
  mxcycle = avcycle
  mncycle = avcycle
; dmcycle = new((/24/),typeof(vdate))
  fullCYC = new((/6,24/),typeof(varf))

  vtimeh = new((/nrows-1/),typeof(vdate))
  do n=0 , nrows-2
    vtimes := str_split(vtime(n),":")
    vtimeh(n) = vtimes(0)
  end do

  hrs = (/"00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"/) 

  if ( var.eq."rsds" ) then
    varf = where(varf.eq.0.,varf@_FillValue,varf)
  end if

  do h=0 , 23
    hr = hrs(h)
    d1table = where(vtimeh.eq.hr,varf,d1table@_FillValue)
    avcycle(h) = avg(d1table)
    stcycle(h) = avcycle(h)+stddev(d1table)
    sbcycle(h) = avcycle(h)-stddev(d1table)
    mxcycle(h) = max(d1table)
    mncycle(h) = min(d1table)
    d1table = d1table@_FillValue
  end do
; racycle = runave(avcycle,30,-1)
  
  fullCYC(0,:) = avcycle(:)
; fullCYC(1,:) = racycle(:)
  fullCYC(2,:) = mxcycle(:)
  fullCYC(3,:) = mncycle(:)

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
  res@trXMaxF = 24

  bins  = ispan(1,24,1)
  hlabs = (/"00","02","04","06","08","10","12","14","16","18","20","22"/)
  xx = ispan(1,23,2)  ; mid day of mon
  res@tmXBMode = "Explicit"           ;-- use explicit x-axis bottom values
  res@tmXBValues = xx                 ;-- x-axis bottom values
  res@tmXBMinorValues = bins(::2)-1   ;-- minor tick marks
  res@tmXBLabels = hlabs              ;-- x-axis bottom labels

  res@xyMarkLineMode    = "Lines"
  res@xyMarkers         = (/16,16,16,16,16/)
  res@xyLineThicknessF  = (/3,3,3,3,1/)     ; Thicken the lines
  res@xyDashPatterns    = (/0,0,2,2,1/)
  res@xyLineColors      = (/"blue","red","black","black","green"/)

; res@gsnCenterStringFontHeightF    = 0.02
; res@gsnCenterString               = fnam+" "+vnam ;+" ("+yrs+")"

  res@tiYAxisString        = vnam+" ("+unit+")"
  res@tiXAxisString        = "hours"
  res@tiYAxisFontHeightF   = 0.020
  res@tiXAxisFontHeightF   = 0.020

  plot = gsn_csm_xy(wks,bins,fullCYC,res)

  ;; prepare shaded area

  yp = new((/2*24/),typeof(varf))
  xp = new((/2*24/),typeof(bins))

  do k=0, 24-1
    yp(k)          = stcycle(k)
    xp(k)          = bins(k)
    xp(2*24-1-k)  = bins(k)
    yp(2*24-1-k)  = sbcycle(k)
  end do

  gsres                   = True                        ; poly res
  gsres@tfPolyDrawOrder   = "Predraw"                   ; draw this first
  gsres@gsFillColor       = "SlateBlue"                 ; color chosen
  gsres@gsFillOpacityF    = 0.5
  dummy = gsn_add_polygon (wks,plot,xp,yp,gsres)

; ;************************************************
; ; Set resources for customizing a simple legend
; ;************************************************
; genres                         = True
; genres@XPosPercent             = 75                      ; move to the right
;
; genres@ItemSpacePercent        = 3
; textres                        = True
; textres@lgLabelFontHeights     = 0.013
; textres@lgPerimOn              = False                   ; no perimeter
; textres@lgItemCount            = 2                       ; how many
; lineres                        = True
; lineres@LineLengthPercent      = 6                       ; expressed as %, 0->100, length of line
; lineres@lgLineLabelFontHeights = 0.013                   ; font height
; textres@lgLabels               = (/"Mean","2xSt.Dev.","Min./Max."/)
; lineres@lgLineThicknesses      = (/3,12,3/)             ; line thickness
; lineres@lgDashIndexes          = (/0,0,2/)              ; line patterns
; lineres@lgLineColors           = (/"blue","SlateBlue","black"/)
;
; dum = simple_legend(wks, plot, genres, lineres, textres)

  draw(plot)                                            ; draw
  frame(wks)                                            ; advance frame

  trimPNG(odir+outn+".png")


end
