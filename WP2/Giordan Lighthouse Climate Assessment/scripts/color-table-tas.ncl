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

  var = "tas" ;getenv("var")
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

  yrs_splt = str_split(yrs,"-")
  years = ispan(tointeger(yrs_splt(0)),tointeger(yrs_splt(1)),1)
  mons  = (/"01","02","03","04","05","06","07","08","09","10","11","12"/)
  nmons = dimsizes(mons)
  nyrs  = dimsizes(years)
  r_sz = dimsizes(mons)
  c_sz = dimsizes(years)
  vals_flt = new((/r_sz,c_sz/),"float")
  vals_txt = new((/r_sz,c_sz/),"string")

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
  outn = "monthly-mean-col-table-ts_"+var
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

  d1table = new((/nrows-1/),typeof(varf))
  do y=0, nyrs-1
    do m=0, nmons-1
      ym = years(y)+mons(m)
      d1table = where(vdateym.eq.ym,varf,d1table@_FillValue)
      vals_flt(m,y) = avg(d1table) 
      if ( ismissing(vals_flt(m,y)) ) then
        vals_txt(m,y) = "N/A"
      else
        vals_txt(m,y) = sprintf("%3.1f",vals_flt(m,y))
      end if
;     print(years(y)+" "+mons(m)+" "+vals_txt(m,y))
      d1table = d1table@_FillValue
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
  nrow_labels = mons

;
; Define colors to use for the table. Be sure to include white and black for background
; and foreground.
;
  colors = (/"White","Black","white","palegoldenrod","yellow","gold2","goldenrod2","darkorange",\
             "darkorange3","tomato","orangered","orangered3","red3","red3"/)
  bwr_n = (/1, 12, 24, 35, 47, 58, 70, 82, 93, 105, 116, 128/)
  bwr_q = dimsizes(bwr_n)
  colf = "MPL_YlOrRd.rgb"
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
  crange = (/10,12.5,15,17.5,20,22.5,25,27.5,30,32.5,35/)
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
    labels(i-2) = sprintf("%2.0f",rng_end) 
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
  cols_for_txt(:,:) = "black"
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

