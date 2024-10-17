;----------------------------------------------------------------------
; Procedure to attach a horizontal labelbar to the bottom of plot.
;----------------------------------------------------------------------
load "trimPNG.ncl"
load "add_labelbar.ncl"

;----------------------------------------------------------------------
; Main code
;----------------------------------------------------------------------
begin

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

  outn = "monthly-mean-col-table-ts_"+var
  ;; set-up to recognise and account for climate and extreme indices
  cindex = False
  vex = ""
  if ( var.eq."windyd" ) then
    cindex = True
    vex = var
    var = "windspeed"
    exnam = "Windy Days" ; days with mean wind speed above 10.8 m/s
    exunt = "days"
  end if
  if ( var.eq."summerd" ) then
    cindex = True
    vex = var
    var = "tas"
    exnam = "Summer Days" ; days when TX (daily maximum temperature) > 25°C
    exunt = "days"
  end if
  if ( var.eq."tropicn" ) then
    cindex = True
    vex = var
    var = "tas"
    exnam = "Tropical Nights" ; days when TN (daily minimum temperature) > 20 °C
    exunt = "days"
  end if

  yrs_splt = str_split(yrs,"-")
  years = ispan(tointeger(yrs_splt(0)),tointeger(yrs_splt(1)),1)
  mons  = (/"01","02","03","04","05","06","07","08","09","10","11","12"/)
  mnams = (/"J","F","M","A","M","J","J","A","S","O","N","D"/)
  nmons = dimsizes(mons)
  nyrs  = dimsizes(years)
  r_sz = dimsizes(mons)
  c_sz = dimsizes(years)
  vals_flt = new((/r_sz,c_sz/),"float")
  vals_txt = new((/r_sz,c_sz/),"string")
  vals_col = vals_txt
  vals_col(:,:) = "black"
  misscol = "red"

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
 
  frm  = "png"
  imgres = 1400
  frm@wkWidth = imgres
  frm@wkHeight = imgres
; outn = "monthly-mean-col-table-ts_"+var
  img  = odir+outn
  wks  = gsn_open_wks(frm,img)

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

  vdateym = new((/nrows-1/),typeof(vdate))
  do n=0 , nrows-2
    vdates = str_split(vdate(n),"/")
    vdateym(n) = vdates(2)+vdates(1)
  end do

  ndays = (nrows-1)/24
  ddtable = new((/ndays/),typeof(varf))
  ddate = new((/ndays/),typeof(vdate))
  ddateym = new((/ndays/),typeof(vdate))
  vard  = new((/ndays/),typeof(varf))
  if ( cindex.eq.True ) then
    n=0
    if ( vex.eq."windyd" ) then
      do d=0 , ndays-1
        ddate(d) = vdate(n)
        vard(d)  = avg(varf(n:n+23))
        n = n+24
      end do
      vard = where(vard.ge.10.8,1.,0.)  ; find windy days and set them to 1
    end if
    if ( vex.eq."summerd" ) then
      do d=0 , ndays-1
        ddate(d) = vdate(n)
        vard(d)  = max(varf(n:n+23))
        n = n+24
      end do
      vard = where(vard.gt.25.,1.,0.) ; find summer days and set them to 1
    end if
    if ( vex.eq."tropicn" ) then
      do d=0 , ndays-1
        ddate(d) = vdate(n)
        vard(d)  = min(varf(n:n+23))
        n = n+24
      end do
      vard = where(vard.gt.20.,1.,0.)  ; find tropic nights and set them to 1
    end if

    ddatex = new((/ndays,3/),typeof(vdate))
    ddatez = new((/ndays/),typeof(vdate))
    ddatey = new((/ndays/),typeof(vdate))
    do d=0 , ndays-1
      ddates = str_split(ddate(d),"/")
      ddatex(d,:) = ddates(:)
      ddateym(d) = ddatex(d,2)+ddatex(d,1)
      ddatey(d) = ddatex(d,2)
    end do
    ddateyi = tointeger(ddatey)
  end if

  d1table = new((/nrows-1/),typeof(varf))
  do y=0, nyrs-1
    do m=0, nmons-1
      ym = years(y)+mons(m)
      if ( cindex.eq.False ) then
        d1table = where(vdateym.eq.ym,varf,d1table@_FillValue)
        vals_flt(m,y) = avg(d1table)
        dtable = d1table
        d1table = d1table@_FillValue
        lpdateym = vdateym
        ndateym = nrows-1
      else
        ddtable = where(ddateym.eq.ym,vard,ddtable@_FillValue)
        vals_flt(m,y) = sum(ddtable)
        dtable = ddtable
        ddtable = ddtable@_FillValue
        lpdateym = ddateym
        ndateym = ndays
      end if
      if ( ismissing(vals_flt(m,y)) ) then
        vals_txt(m,y) = "N/A"
        vals_col(m,y) = misscol
      else
        if ( cindex.eq.False ) then
          vals_txt(m,y) = sprintf("%3.1f",vals_flt(m,y))
        else
          vals_txt(m,y) = sprintf("%3.0f",vals_flt(m,y))
        end if
        tot = 0.
        do n=0 , ndateym-1
          lpdate = lpdateym(n)
          if ( lpdate.eq.ym ) then
            tot = tot + 1
          end if
        end do
        percv = tofloat(num(.not.ismissing(dtable)))*100./tot
        if ( percv.lt.40. ) then
          vals_col(m,y) = misscol
        end if
      end if
;     print(years(y)+" "+mons(m)+" "+vals_txt(m,y))
      delete(dtable)
      delete(lpdateym)
      delete(ndateym)
    end do
  end do
  delete(y)

  ncr = dimsizes(vals_flt)
  ; Count rows and columns of actual data.
  ncols = dimsizes(years) ; ncr(1)
  nrows = dimsizes(mons)  ; ncr(0)

  col_width  = 1./ncols 
  row_width  = 1./nrows
  col_width2 = col_width/2.
  row_width2 = row_width/2.

  ncol_labels = tostring(years)
  nrow_labels = mnams

;
; Define colors to use for the table. Be sure to include white and black for background
; and foreground.
;
  colors = (/"White","Black","white","palegoldenrod","yellow","gold2","goldenrod2","darkorange",\
             "darkorange3","tomato","orangered","orangered3","red3","red3"/)
  bwr_n = (/1, 12, 24, 35, 47, 58, 70, 82, 93, 105, 116, 128/)
  bwr_q = dimsizes(bwr_n)
  if ( cindex.eq.False ) then
    if ( var.eq."rhus" ) then
      colf = "MPL_cool.rgb"
    else
      colf = "MPL_YlOrRd.rgb"
    end if 
  else
    if ( vex.eq."windyd" ) then
      colf = "MPL_cool.rgb"
    else
      colf = "MPL_YlOrRd.rgb"
    end if
  end if
  do c=0 , bwr_q-1
    bwr_i = bwr_n(c)
    ac := asciiread(colf, (/bwr_i+3-1/), "string")
    ac := ac(bwr_i+2-1)
    nc := str_split(ac, " ")
;   rd := stringtofloat(nc(0))/255
;   gn := stringtofloat(nc(1))/255
;   bl := stringtofloat(nc(2))/255
;   rd := decimalPlaces(rd,2,True)
;   gn := decimalPlaces(gn,2,True)
;   bl := decimalPlaces(bl,2,True)
    rd := decimalPlaces(stringtofloat(nc(0)),2,True)
    gn := decimalPlaces(stringtofloat(nc(1)),2,True)
    bl := decimalPlaces(stringtofloat(nc(2)),2,True)
    colors(c+2) = "(/"+rd+", "+gn+", "+bl+"/)"
  end do
; print(colors)

  col_sz = dimsizes(colors)
  if ( cindex.eq.False ) then
    if ( var.eq."rhus" ) then
      crange = (/44.,48,52,56,62,66,70,74,78,82,86/)
    else
      crange = (/10,12.5,15,17.5,20,22.5,25,27.5,30,32.5,35/)
    end if
  else
    crange = (/4.,8,10,12,14,16,18,20,22,24,26/)
  end if
  labels = new(dimsizes(colors)-1,"string")    ; for labelbar

; Assign a color to a particular range of data.
  cols_for_vals = new(ncr,"string")
  cols_for_txt = new(ncr,"string")
  do i=2,col_sz-1
    if ( i.eq.2 ) then
      rng_beg = -100.
      rng_end = crange(i-2)
    end if
    if ( i.gt.2 .and. i.lt.(col_sz-1) ) then
      rng_beg = crange(i-3)
      rng_end = crange(i-2)
    end if
    if ( i.eq.(col_sz-1) ) then
      rng_beg = crange(i-3)
      rng_end = 100.
    end if

    cols_for_vals = where(rng_beg.le.vals_flt .and. vals_flt.lt.rng_end,\
                          colors(i),cols_for_vals)
    ;print(i+": "+rng_beg+" "+rng_end+": "+colors(i))
;---Create formatted labels for the labelbar
    if ( cindex.eq.False ) then
      labels(i-2) = sprintf("%2.0f",rng_end) 
    else
      labels(i-2) = sprintf("%2.0i",rng_end)
    end if
                  ;sprintf("%3.1f", rng_beg) + " - " + \
                  ;sprintf("%3.1f",rng_end)
  end do

; cols_for_txt = where(cols_for_vals.eq."Navy" .or. \
;                     cols_for_vals.eq."MediumBlue" .or. \
;                     cols_for_vals.eq."blue4".or. \
;                     cols_for_vals.eq."blue3" .or. \
;                     cols_for_vals.eq."blue1" .or. \
;                     cols_for_vals.eq."Brown" .or. \
;                     cols_for_vals.eq."saddlebrown", "white","black")
  cols_for_txt(:,:) = vals_col ;"black"
  cols_for_vals = where(ismissing(cols_for_vals),"grey",cols_for_vals)
  cols_for_txt = where(ismissing(cols_for_txt),"white",cols_for_txt) 

; Start the graphics.
  gsn_define_colormap(wks,colors) 

; Create a blank plot so we can get some tickmarks.
;
; Do the blank plot before the table, so we can maximize
; the blank plot. Later we'll make sure the table goes
; in the same location as the blank plot.
;
  resb                         = True
  resb@gsnDraw                 = False
  resb@gsnFrame                = False

  resb@vpYF                    = 0.90
  resb@vpXF                    = 0.10
  resb@vpHeightF               = 0.40
  resb@vpWidthF                = 0.90 

; Explicitly label X axis. The blank plot goes from 0 to 1, by default.
  resb@tmXBMode                = "Explicit"
  resb@tmXBValues              = fspan(col_width2,1.-col_width2,ncols)
  resb@tmXBLabels              = ncol_labels
  resb@tmXBLabelFontHeightF    = 0.008            ; Make font a little smaller

; Explicitly label Y axis.
  resb@tmYLMode                = "Explicit"
  resb@tmYLValues              = fspan(row_width2,1.-row_width2,nrows)
;
; The Y labels need to be reversed, because the label in the first
; row in the ASCII file is associated with the top of the plot.
;
  resb@tmYLLabels              = nrow_labels(::-1)
  resb@tmYLLabelFontHeightF    = 0.008            ; Make font a little smaller

; Rotate the X axis labels 90 degrees.
;  resb@tmXBLabelAngleF         = 90.
;  resb@tmXBLabelJust           = "CenterRight"
  resb@tiXAxisString     = "years"
  resb@tiYAxisString     = "months"
  resb@tiXAxisFontHeightF = 0.010
  resb@tiYAxisFontHeightF = 0.010

; Turn off right and top tickmarks
  resb@tmYROn                  = False
  resb@tmXTOn                  = False

  blank = gsn_csm_blank_plot(wks,resb)
  add_labelbar(wks,blank,colors(2:),labels)   ; Attach labelbar

;
; Get position and size of the blank plot so we can
; be sure to draw the table in same location.
;
  getvalues blank
    "vpXF"      : vpx
    "vpYF"      : vpy
    "vpWidthF"  : vpw
    "vpHeightF" : vph
  end getvalues

; Start and end coordinates for table.
  x = (/vpx,vpx+vpw/)
  y = (/vpy-vph,vpy/)

; Set up resources for table
  rest               = True
  rest@gsLineColor   = -1               ; No border lines
  rest@gsLineThicknessF = 0.001
  rest@gsFillColor   = cols_for_vals     ; Each cell of table
  rest@txFontColor   = cols_for_txt
  rest@txFontHeightF = 0.008             ; Size of centered text

  gsn_table(wks,ncr,x,y,vals_txt,rest)    ; Draw table

; res_text                   = True              ; text mods desired
; res_text@txFontHeightF   = 0.008
; res_text@txJust            = "CenterLeft"      ; text justification
; dum = gsn_add_text(wks,blank,"%",1.00,0.0,res_text)  ; add text

  draw(blank)
  
; Advance the frame.
  frame(wks)

  print("saved")
  trimPNG(img+"."+frm)

end

