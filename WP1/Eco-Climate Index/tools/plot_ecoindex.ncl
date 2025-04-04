;***********************************************************
; pdf_1.ncl
;
; Concepts illustrated:
;   - Generating univariate probability distributions
;   - Generating PDFs of each sample distribution
;   - Paneling two plots horizontally on a page
;***********************************************************
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"   
load "tools/trimPNG.ncl"

begin

  hdir = getenv("hdir") ;"/home/netapp-clima-scratch/jciarlo/paleosim"
  dtyp = getenv("dtyp") ;"CPMs"
  dnam = getenv("dnam") ;"ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0_CP"
  onam = getenv("onam") ;"iNaturalist"
  nboot = getenv("nboot") ;8
  spc   = getenv("spc")   ;"polyommatus-celina"
  yrs   = getenv("yrs")   ;"1995-1999"
  tdim  = getenv("tdim")  ;"1d"

  dp = getenv("dp")
  drawPoints = False
  if ( dp.eq."true" ) then
    drawPoints = True 
  end if
  drawSummary = False
  if ( dp.eq."summary" ) then
    drawSummary = True
  end if

  if ( dtyp .eq. "CPMs" ) then
    dnam_splt = str_split(dnam,"_")
    glob = dnam_splt(0)
    if ( glob.eq."ECMWF-ERA5" ) then
      gmod = "ERA5"
    end if
    regi = dnam_splt(2)
    if ( regi.eq."ICTP-RegCM5-0" ) then
      rmod = "RegCM5"
    end if
    dshort = gmod+"-"+rmod
  end if
  if ( dtyp .eq. "OBS" ) then
    dshort = dnam
    if ( dnam.eq."EOBS-010-c25e" ) then
      dshort = "EOBS"
    end if
  end if

  spc_splt = str_split(spc,"-")
  spc_t = str_capital(spc_splt(0))+" "+spc_splt(1)
 
  ddir = hdir+"/data/"+dtyp+"/"+dnam+"/index/"+onam+"/boot_"+nboot+"/ndis/"
  dfil = ddir+"EcoIndex_"+dnam+"_"+onam+"_"+spc+"_"+yrs+".nc" 

  idir = hdir+"/images/"
  if ( drawPoints.eq.True ) then
    outim = idir+"EcoIndex_"+dnam+"_"+onam+"_"+spc+"_"+yrs+"_points"
  else
    if ( drawSummary.eq.True ) then
      outim = idir+"EcoIndex_"+dnam+"_"+onam+"_"+spc+"_"+yrs+"_summary"
    else
      outim = idir+"EcoIndex_"+dnam+"_"+onam+"_"+spc+"_"+yrs
    end if
  end if
  formo = "png"
  wks  = gsn_open_wks (formo,outim)             ; send graphics to PNG file

  f = addfile(dfil, "r")
  ei = f->comp(0,:,:)

  if ( drawPoints.eq.True .or. drawSummary.eq.True ) then
    ;;; extract station data for plotting
    ldir = hdir+"/data/"+dtyp+"/"+dnam+"/index/"+onam+"/"
    lfil = ldir+spc+"_"+onam+"_"+dnam+".log"

    ;; extract data from log file
    nrows = numAsciiRow(lfil)
    lines := asciiread(lfil,(/nrows/),"string")
    heads := lines(0)
    lines := lines(1:nrows-1)

    hchar := stringtochar(heads)
    fdel = " "
    ilon = new((/nrows/),"string")
    ilat = new((/nrows/),"string")
    do l=0 , nrows-2
      lsplt = str_split(lines(l),fdel)
      ilon(l) = lsplt(2)
      ilat(l) = lsplt(1)
    end do
    ilon := stringtofloat(ilon)
    ilat := stringtofloat(ilat)

    ;;; checking EI values at observation locations
    eldir = hdir+"/data/"+dtyp+"/"+dnam+"/index/"+onam+"/boot_"+nboot+"/ndis/latlon/"
    elfil = eldir+"EcoIndex_"+dnam+"_"+onam+"_"+spc+"_"+yrs+".log"
    nlrows = numAsciiRow(elfil)
    elines := asciiread(elfil,(/nlrows/),"string")
    evals := elines(1:nlrows-1)
    eavg = avg(stringtofloat(evals))
    estd = stddev(stringtofloat(evals))

    if ( drawSummary ) then
      nvals = dimsizes(lines)
      th1 = 0.1
      th2 = 0.5
      cl = 0
      cm = 0
      do l=0 , nvals-1 
        thisval = evals(l)
        if ( thisval.ge.th1 ) then
          cl = cl + 1
        end if
        if ( thisval.ge.th2 ) then
          cm = cm + 1 
        end if
      end do

      pcl = cl*100./nvals
      pcm = cm*100./nvals
    end if
  end if

  if ( tdim.eq."2d" ) then
    xlat = f->lat
    xlon = f->lon
;   rpol = f->rotated_latitude_longitude
;   plat = rpol@grid_north_pole_latitude
;   plon = rpol@grid_north_pole_longitude
    ei@lat2d = xlat
    ei@lon2d = xlon
    dims = dimsizes(xlat)
    nlat = dims(0)
    nlon = dims(1)
  end if
  if ( tdim.eq."1d" ) then
    xlat = f->latitude
    xlon = f->longitude
    nlat = dimsizes(xlat)
    nlon = dimsizes(xlon)
  end if

 ;***********************
 ; plot
 ;***********************

  res  = True
  if ( drawPoints.eq.True ) then
    res@gsnDraw             = False
    res@gsnFrame            = False            
  else
    res@gsnDraw             = True              ; don't draw yet
    res@gsnFrame            = True              ; don't advance frame yet
  end if

  res@mpLimitMode       = "Corners"            ; choose range of map
  res@tfDoNDCOverlay         = True      ; do not transform
  if ( tdim.eq."2d" ) then
    res@tfDoNDCOverlay        = False      ; do not transform
   ;res@mpProjection        = "CylindricalEquidistant"
      dllon = 0
      dllat = 0
      drlon = 0
      drlat = 0
      res@mpLeftCornerLatF  = xlat(0,0) + dllat
      res@mpLeftCornerLonF  = xlon(0,0) + dllon
      res@mpRightCornerLatF = xlat(nlat-1,nlon-1) + drlat
      res@mpRightCornerLonF = xlon(nlat-1,nlon-1) + drlon
      res@mpCenterLonF = xlon(nlat/2,nlon/2) 
      res@mpCenterLatF = xlat(nlat/2,nlon/2)
;     if (prj .eq. "LAMCON") then
;       trlats = f@standard_parallel
;       res@mpProjection        = "LambertConformal"
;       res@mpLambertParallel1F = trlats(0)
;       res@mpLambertParallel2F = trlats(1)
;       res@mpLambertMeridianF  = clon
;     end if
;     if (prj .eq. "NORMER") then
;       res@mpProjection        = "Mercator"
;     end if
;     if (prj .eq. "ROTMER") then
;       clat = ff@latitude_of_projection_origin
;       res@mpProjection        = "Mercator"
;       res@mpCenterLonF = clon
;       res@mpCenterLatF = clat
;     end if
  end if
  if ( tdim.eq."1d" ) then
    res@mpLeftCornerLatF  = min(xlat)
    res@mpLeftCornerLonF  = min(xlon)
    res@mpRightCornerLatF = max(xlat)
    res@mpRightCornerLonF = max(xlon)
  end if

  ; usually, when data is placed onto a map, it is TRANSFORMED to the specified
  ; projection. Since this model is already on a native lambert conformal grid,
  ; we want to turn OFF the tranformation.

  res@cnFillOn               = True      ; color plot desired
  res@cnFillMode             = "RasterFill"
  res@cnLinesOn              = False       ; no contour lines
  res@mpFillOn               = False

  res@mpGeophysicalLineColor = "black"     ; color of continental outlines
  res@mpPerimOn              = True      ; draw box around map
  res@mpGridLineDashPattern  = 5         ; lat/lon lines as dashed

; res@gsnAddCyclic           = False     ; regional data don't add
; res@pmTickMarkDisplayMode  = "Always"  ;
  res@mpGridAndLimbOn        = False               ; turn on grid lines
  res@lbLabelBarOn           = True 
  res@lbOrientation          =   "vertical"
 ;res@lbLabelFontHeightF   = 0.02
  res@lbTitleFontHeightF   = 0.018                ; make title smaller
  res@lbTitleString    = "EI (#)"
 ;res@lbTitlePosition      = "Top"
  res@tmYROn = False            ; Turn off right tickmarks.
  res@tmXTOn = False            ; Turn off top tickmarks.
  res@tmYLOn = False
  res@tmXBOn = False
  res@gsnLeftString          = "" 
  if ( drawPoints.eq.True ) then
    res@gsnRightString         = "~F33~m="+eavg+"~C~~F33~s="+estd
  else
    if ( drawSummary.eq.True ) then
      prcl = decimalPlaces(pcl,1,True)
      prcm = decimalPlaces(pcm,1,True)
      res@gsnRightString         = "%>0.1="+prcl+"~C~%>0.5="+prcm
    else
      res@gsnRightString         = ""
    end if
  end if
; res@gsnLeftStringFontHeightF  = 0.01
  res@gsnRightStringFontHeightF = 0.01
  if ( drawSummary.eq.True ) then
    res@gsnCenterString        = spc_t
  else
    res@tiMainOn = True
    res@tiMainString = spc_t
    res@gsnCenterString        = dshort+" ("+yrs+")"  
  end if
  res@mpDataBaseVersion    = "HighRes"

  res@cnLevelSelectionMode   = "ExplicitLevels"
; res@cnConstFLabelFormat    = "0f1"
  res@cnLevels = (/.1,.2,.3,.4,.5,.6,.7,.8,.9,1/) 
  cmap = read_colormap_file("WhiteBlueGreenYellowRed")
; cmap = cmap(::-1,:) ; reverse the color map
  res@cnFillPalette = cmap

  if ( drawPoints.eq.False ) then
    plot = gsn_csm_contour_map(wks,ei,res)
  end if

;********************************
; plot original data
;********************************
  if ( drawPoints.eq.True ) then 
    polyres                   = True
    polyres@gsMarkerIndex     = 16          ; polymarker style
    polyres@gsMarkerSizeF     = 3.          ; polymarker size

    plot   = gsn_csm_contour_map_ce(wks,ei,res)
    dumP   = gsn_add_polymarker(wks,plot,ilon(:),ilat(:),polyres)
    draw(plot)
    frame(wks)
  end if

;*****************************************************
; save output image
;******************************************************
 
   trimPNG(outim+"."+formo)

end
