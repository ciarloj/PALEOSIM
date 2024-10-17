load "trimPNG.ncl"

begin
;*************************
; read in data
;*************************

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; change inputs manually ;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  var = getenv("var")
  frq = getenv("frq")
  yrs = "1997-2022*"

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;; end of inputs ;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  vars  = (/"date","time","winddir","windspeed","rhus","tas","dtas","ps"/)
  vlabs = (/"Date","Time [GMT]","WD [o]","WS [m/s]","RH [%]","AT [oC]","DT [oC]","AP [hPa]"/)
  vnams = (/"Date","Time","Wind Direction","Wind Speed","Relative Humidity","Air Temperature","Dew Point Temperature","Air Pressure"/)
  units = (/"#","#","~F34~0~F~","m s~S~-1~N~","%","~F34~0~F~C","~F34~0~F~C","hPa"/)
  nvars = dimsizes(vars)

  if ( frq.eq."hr" ) then
    fnam = "Hourly"
  end if
  if ( frq.eq."daymean" ) then
    fnam = "Daily Mean"
  end if
  if ( frq .eq."daymax" ) then
    fnam = "Daily Maximum"
  end if
  if ( frq .eq."daymin" ) then
    fnam = "Daily Minimum"
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

  outn = "pdf_"+frq+"_"+var
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

  if ( var.eq."rsds" ) then
    varf = where(varf.eq.0.,varf@_FillValue,varf)
  end if

  binsz = 0.1
  if ( var.eq."ps" ) then
    binsz = 1.
  end if
  if ( frq.ne."hr" ) then
;   vdate = table(:,0)
;   vtime = table(:,1) 
    ndays = (nrows-1)/24
    dtable = new((/ndays/),typeof(varf))
    oneday = new((/24/),typeof(varf))
    l=0
    do d=0 , ndays-1
      do h=0 , 23
        oneday(h) = varf(l) 
        if ( h.eq.23 ) then
          if ( frq.eq."daymean" ) then
            dtable(d) = avg(oneday)
          end if
          if ( frq.eq."daymax" ) then
            dtable(d) = max(oneday)
          end if
          if ( frq.eq."daymin" ) then
            dtable(d) = min(oneday)
          end if
          oneday(:) = oneday@_FillValue
        end if
        l = l+1
      end do 
    end do
    varf := dtable
    binsz = 0.5
    if ( var.eq."rhum" .or. var.eq."winddir" .or. var.eq."ps" ) then
      binsz = 1.
    end if
    if ( var.eq."rsds" ) then
      binsz = 5.
    end if
  end if

  vmin = floor(min(varf))
  vmax = ceil(max(varf))
  opt = True
  opt@bin_min = vmin
  opt@bin_max = vmax
  
; if ( binsz.eq.1 ) then
;   nbin = toint(vmax-vmin+1)    ;; for binsize of 1 m/s OR 1 degC OR 1 mm/day etc
; end if
; if ( binsz.eq.0.1 ) then
;   nbin = toint(vmax-vmin+1)*10 
; end if
  nbin = toint((vmax-vmin+1)/binsz)
  bins = fspan(vmin,vmax,nbin)

  vpdf = pdfx(varf,nbin,opt)
  
  ;***********************
  ; plot
  ;***********************

  res            = True               ; plot mods desired
; res@gsnDraw    = False              ; don't draw yet
; res@gsnFrame   = False              ; don't advance frame yet

  res@tmYROn     = False              ; Turn off right tickmarks.
  res@tmXTOn     = False              ; Turn off top tickmarks.

  res@trYMinF = 0.
  res@trYMaxF = ceil(max(vpdf)*10.)/10.
  if ( var.eq."winddir" ) then
    res@trYMaxF = ceil(max(vpdf)*100.)/100.
    res@trXMaxF = 360.
  end if

  res@xyMarkLineMode    = "Markers"
  res@xyMarkers         = (/16/)
  res@xyMarkerColors    = (/"blue"/)
  res@xyMarkerSizeF     = 0.0050

; res@gsnCenterStringFontHeightF    = 0.02
; res@gsnCenterString               = fnam+" "+vnam ;+" ("+yrs+")"

  res@tiXAxisString        = vnam+" ("+unit+")"
  res@tiYAxisString        = "Probability (%)"
  res@tiYAxisFontHeightF   = 0.020
  res@tiXAxisFontHeightF   = 0.020

  plot = gsn_csm_xy(wks,bins,vpdf,res)

  trimPNG(odir+outn+".png")


end
