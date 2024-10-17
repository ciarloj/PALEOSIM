load "trimPNG.ncl"

begin
;*************************
; read in data
;*************************

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; change inputs manually ;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  var = "tas" ;getenv("var")
  frq = "hr"  ;getenv("frq")
  fcs = "2seasC"
  yrs = "1997-2022"

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

  outn = "pdf-"+fcs+"_"+frq+"_"+var
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
  
  vdatex = new((/nrows-1,3/),typeof(vdate))
  vdatem = new((/nrows-1/),typeof(vdate))
  vdatey = new((/nrows-1/),typeof(vdate))
  do n=0 , nrows-2
    vdates = str_split(vdate(n),"/")
    vdatex(n,:) = vdates(:)
    vdatem(n) = vdatex(n,1)
    vdatey(n) = vdatex(n,2)
  end do
  vdateyi = tointeger(vdatey)

  if ( fcs.eq."decs" ) then
    varf1 = where(vdateyi.lt.2010,varf,varf@_FillValue)
    varf2 = where(vdateyi.ge.2010,varf,varf@_FillValue)
  end if
  if ( fcs.eq."4seas" ) then
    varfdjf = where(vdatem.eq."12".or.vdatem.eq."01".or.vdatem.eq."02",varf,varf@_FillValue)
    varfmam = where(vdatem.eq."03".or.vdatem.eq."04".or.vdatem.eq."05",varf,varf@_FillValue)
    varfjja = where(vdatem.eq."06".or.vdatem.eq."07".or.vdatem.eq."08",varf,varf@_FillValue)
    varfson = where(vdatem.eq."09".or.vdatem.eq."10".or.vdatem.eq."11",varf,varf@_FillValue)
  end if
  if ( fcs.eq."2seas" ) then
    varfwet = where(vdatem.eq."11".or.vdatem.eq."12".or.vdatem.eq."01".or.vdatem.eq."02".or.vdatem.eq."03".or.vdatem.eq."04",varf,varf@_FillValue)
    varfhot = where(vdatem.eq."05".or.vdatem.eq."06".or.vdatem.eq."07".or.vdatem.eq."08".or.vdatem.eq."09".or.vdatem.eq."10",varf,varf@_FillValue)
  end if
  if ( fcs.eq."2seasB" ) then
    varfwet = where(vdatem.eq."05".or.vdatem.eq."12".or.vdatem.eq."01".or.vdatem.eq."02".or.vdatem.eq."03".or.vdatem.eq."04",varf,varf@_FillValue)
    varfhot = where(vdatem.eq."11".or.vdatem.eq."06".or.vdatem.eq."07".or.vdatem.eq."08".or.vdatem.eq."09".or.vdatem.eq."10",varf,varf@_FillValue)
  end if
  if ( fcs.eq."2seasC" ) then
    varfwet = where(vdatem.eq."11".or.vdatem.eq."12".or.vdatem.eq."01".or.vdatem.eq."02".or.vdatem.eq."09".or.vdatem.eq."10",varf,varf@_FillValue)
    varfhot = where(vdatem.eq."05".or.vdatem.eq."06".or.vdatem.eq."07".or.vdatem.eq."08".or.vdatem.eq."03".or.vdatem.eq."04",varf,varf@_FillValue)
  end if

  binsz = 0.1

  vmin = floor(min(varf))
  vmax = ceil(max(varf))
  opt = True
  opt@bin_min = vmin
  opt@bin_max = vmax
  
  nbin = toint((vmax-vmin+1)/binsz)
  bins = fspan(vmin,vmax,nbin)

  if ( fcs.eq."decs" ) then
    vpdf = new((/2,nbin/),"double")
    vpdf1 = pdfx(varf1,nbin,opt)
    vpdf2 = pdfx(varf2,nbin,opt)
    vpdf(0,:) = vpdf1(:)
    vpdf(1,:) = vpdf2(:)
  else if ( fcs.eq."4seas" ) then
    vpdf = new((/4,nbin/),"double")
    vpdfdjf = pdfx(varfdjf,nbin,opt)
    vpdfmam = pdfx(varfmam,nbin,opt)
    vpdfjja = pdfx(varfjja,nbin,opt)
    vpdfson = pdfx(varfson,nbin,opt)
    vpdf(0,:) = vpdfdjf(:)
    vpdf(1,:) = vpdfmam(:)
    vpdf(2,:) = vpdfjja(:)
    vpdf(3,:) = vpdfson(:)
  else if ( fcs.eq."2seas".or.fcs.eq."2seasB".or.fcs.eq."2seasC" ) then
    vpdf = new((/2,nbin/),"double")
    vpdfwet = pdfx(varfwet,nbin,opt)
    vpdfhot = pdfx(varfhot,nbin,opt)
    vpdf(0,:) = vpdfwet(:)
    vpdf(1,:) = vpdfhot(:)
  else
    vpdf = pdfx(varf,nbin,opt)
  end if  
  end if
  end if

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

  res@xyMarkLineMode    = "Markers"
  res@xyMarkers         = (/16/)
  res@xyMarkerColors    = (/"blue"/)
  res@xyMarkerSizeF     = 0.0050

  res@tiXAxisString        = vnam+" ("+unit+")"
  res@tiYAxisString        = "Probability (%)"
  res@tiYAxisFontHeightF   = 0.020
  res@tiXAxisFontHeightF   = 0.020

  res@pmLegendDisplayMode    = "Always"            ; turn on legend
  res@pmLegendSide           = "Top"               ; Change location of
  res@pmLegendParallelPosF   = .90                 ; move units right
  res@pmLegendOrthogonalPosF = -0.12               ; move units down

  res@pmLegendWidthF         = 0.08                ; Change width and
  res@pmLegendHeightF        = 0.06                ; height of legend.
  res@lgLabelFontHeightF     = .01                 ; change font height
  if ( fcs.eq."decs" ) then
    res@xyMarkers       := (/16,16/)
    res@xyMarkerColors  := (/"blue","red"/)
    res@xyExplicitLegendLabels = (/"1999-2009","2010-2022"/)         ; explicit labels
  end if
  if ( fcs.eq."4seas" ) then
    res@xyMarkers       := (/16,16,16,16/)
    res@xyMarkerColors  := (/"blue","green","red","brown"/)
    res@xyExplicitLegendLabels = (/"DJF","MAM","JJA","SON"/)         ; explicit labels
  end if
  if ( fcs.eq."2seas" ) then
    res@xyMarkers       := (/16,16/)
    res@xyMarkerColors  := (/"blue","red"/)
    res@xyExplicitLegendLabels = (/"NDJFMA","MJJASO"/)         ; explicit labels
  end if
  if ( fcs.eq."2seasB" ) then
    res@xyMarkers       := (/16,16/)
    res@xyMarkerColors  := (/"blue","red"/)
    res@xyExplicitLegendLabels = (/"DJFMAM","JJASON"/)         ; explicit labels
  end if
  if ( fcs.eq."2seasC" ) then
    res@xyMarkers       := (/16,16/)
    res@xyMarkerColors  := (/"blue","red"/)
    res@xyExplicitLegendLabels = (/"SONDJF","MAMJJA"/)         ; explicit labels
  end if

  plot = gsn_csm_xy(wks,bins,vpdf,res)

  trimPNG(odir+outn+".png")


end
