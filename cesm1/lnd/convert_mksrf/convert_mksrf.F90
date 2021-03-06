program convert_mksrf
  implicit none
  include 'netcdf.inc'

!-----------------------------------------------------------------
! 
! TO COMPILE: gmake EXENAME=convert_glacier
! TO RUN    : ./convert_glacier 
! make surface type netcdf file
! use peltier 1x1 data for glacier information
! use 21k data
!-----------------------------------------------------------------

  integer, parameter :: r8 = selected_real_kind(12)

! File specific settings

  integer, parameter :: nlon = 720  !input grid : longitude points
  integer, parameter :: nlat = 360  !input grid : latitude  points
  integer, parameter :: nlonw = 360  !input grid : longitude points
  integer, parameter :: nlatw = 180  !input grid : latitude  points
  integer, parameter :: numpft = 16       !number of plant types

  real(r8) :: lon(nlon)                   !longitude dimension array (1d)
  real(r8) :: lat(nlat)                   !latitude dimension array (1d) 
  real(r8) :: longxy(nlon,nlat)           !longitude dimension array (2d)        
  real(r8) :: latixy(nlon,nlat)           !longitude dimension array (2d)
  real(r8) :: lonw(nlonw)                   !longitude dimension array (1d)
  real(r8) :: latw(nlatw)                   !latitude dimension array (1d)
  real(r8) :: longxyw(nlonw,nlatw)           !longitude dimension array (2d)
  real(r8) :: latixyw(nlonw,nlatw)           !longitude dimension array (2d)
  real(r8) :: edge(4)                     !N,E,S,W edges of grid
  real(r8) :: edgew(4)                    !N,E,S,W edges of grid
  real(r8) :: dx,dy                       !grid increments
  real(r8) :: dxw,dyw                     !grid increments
  real(r8) :: delta		          ! tolerance
 
  real(r8) :: ice(nlon,nlat)		  !Icemask (after lat flip)
  real(r8) :: top(nlon,nlat)		  !Topo ( " ") 
  real(r8) :: Icemask(nlon,nlat)	  !input ice
  real(r8) :: Topo(nlon,nlat)		  !input top (use for landmask) 
  real(r8) :: lmask(nlon,nlat)	          !input landmask
! nanr 10oct10
  real(r8) :: plmask(nlon,nlat)	          !pft input landmask
  real(r8) :: pct_glacier(nlon,nlat)      !pct glacier
  real(r8) :: pct_pft(nlon,nlat,0:numpft) !percent pft
  real(r8) :: landmask(nlon,nlat)         !land mask
! nanr 10oct10
  real(r8) :: plandmask(nlon,nlat)         !land mask
! nanr 10octo10
!  real(r8) :: landmaskw(nlonw,nlatw)      !land mask
  real(r8) :: lgmlandmask(nlon,nlat)      !lgmland mask
  real(r8) :: pct_lake(nlon,nlat)       !pct lake
  real(r8) :: pct_wetland(nlon,nlat)    !pct wetland
!  nanr 30sep10
!  real(r8) :: pct_lake(nlonw,nlatw)       !pct lake
!  real(r8) :: pct_wetland(nlonw,nlatw)    !pct wetland
!  end nanr


  integer :: dimlon_id                    !netCDF dimension id
  integer :: dimlat_id                    !netCDF dimension id
  integer :: dimpft_id                    !netCDF dimension id

  integer :: lon_id                       !1d longitude array id
  integer :: lat_id                       !1d latitude array id
  integer :: longxy_id                    !2d longitude array id
  integer :: latixy_id                    !2d latitude array id
  integer :: edgen_id                     !northern edge of grid (edge(1)) id
  integer :: edgee_id                     !eastern  edge of grid (edge(2)) id
  integer :: edges_id                     !southern edge of grid (edge(3)) id
  integer :: edgew_id                     !western  edge of grid (edge(4)) id
  integer :: pct_glacier_id               !pct_glacier id
  integer :: pct_pft_id                   !pct_pft id
  integer :: landmask_id                  !landmask id
! nanr 8oct10
  integer :: plandmask_id                  !pft landmask id
  integer :: lgmlandmask_id               !lgmlandmask id
  integer :: pct_lake_id                  !pct_lake id
  integer :: pct_wetland_id               !pct_lake id


  integer :: i,j                          !indicis
  integer :: ndatai =  1                  !input unit
  integer :: ndatat  = 2                  !input unit
  integer :: ncid                         !netCDF file id
  integer :: ncid2                        !netCDF file id 2
  integer :: ncid_pelt                    !netCDF file id
  integer htopo_p1_id                     ! input topo file vars
  integer ice_p1_id                       ! input topo file vars
  integer ret     		          ! return id
  integer :: dim1_id(1)                   !netCDF dimension id for 1-d variables
  integer :: dim2_id(2)                   !netCDF dimension id for 2-d variables
  integer :: dim3_id(3)                   !netCDF dimension id for 3-d variables
  integer :: status                       !status
  integer :: jcount                       !integer counter
  integer :: icount                       !integer counter


  character(len=256) :: filei, fileig, fileil, fileip !input filenames
  character(len=256) :: fileog, fileol, fileop !output filenames
  character(len=256) :: name,unit            !netCDF attributes

!-----------------------------------------------------------------
  filei  = '/myTopoPath/topo-ice.0.5degree.myrun.nc'
  fileig = '/inputdata/lnd/clm2/rawdata/mksrf_glacier.060929.nc'
  fileip = '/inputdata/lnd/clm2/rawdata/pftlandusedyn.0.5x0.5.simyr1850-2005.c090630/mksrf_landuse_rc1850_c090630.nc'
  fileil = '/inputdata/lnd/clm2/rawdata/mksrf_lanwat.050425.nc'
  fileog = 'mksrf_glacier_lgm21ka.example.nc'
  fileop = 'mksrf_pft_lgm21ka.example.nc'
  fileol = 'mksrf_lanwat_lgm21ka.example.nc'
! -----------------------------------------------------------------

  ret = nf_open (filei, nf_nowrite, ncid_pelt)
  if (ret == nf_noerr) then

! get id and var for topo 
    call wrap_inq_varid (ncid_pelt, 'TOP', htopo_p1_id   )
    call wrap_get_var8 (ncid_pelt, htopo_p1_id, Topo)

! get id and var for ice (0-100)
    call wrap_inq_varid (ncid_pelt, 'ICE', ice_p1_id   )
    call wrap_get_var8 (ncid_pelt, ice_p1_id, Icemask)

! get id and var for landmask (0-100)
    call wrap_inq_varid (ncid_pelt, 'LANDMASK', landmask_id   )
    call wrap_get_var8 (ncid_pelt, landmask_id, lmask)

  else
    write(6,*)'cannot open peltier file1 successfully'
    call endrun 
  endif
  ret = nf_close (ncid_pelt)

  ret = nf_open (fileig, nf_nowrite, ncid)
  if (ret == nf_noerr) then

! get id and var for glacier (0-100)
    call wrap_inq_varid (ncid, 'PCT_GLACIER', pct_glacier_id   )
    call wrap_get_var8 (ncid, pct_glacier_id, pct_glacier)

  else
    write(6,*)'cannot open glacier file successfully'
    call endrun 
  endif
  ret = nf_close (ncid)

  ret = nf_open (fileip, nf_nowrite, ncid)
  if (ret == nf_noerr) then

! get id and var for landmask
! nanr:  reading pd landmask from 8oct10
    call wrap_inq_varid (ncid, 'LANDMASK', plandmask_id   )
    call wrap_get_var8 (ncid, plandmask_id, plandmask)

! get id and var for pft
    call wrap_inq_varid (ncid, 'PCT_PFT', pct_pft_id   )
    call wrap_get_var8 (ncid, pct_pft_id, pct_pft)

  else
    write(6,*)'cannot open pft file successfully'
    call endrun 
  endif
  ret = nf_close (ncid)

  ret = nf_open (fileil, nf_nowrite, ncid)
  if (ret == nf_noerr) then

! get id and var for lanwat
    call wrap_inq_varid (ncid, 'PCT_LAKE', pct_lake_id   )
    call wrap_get_var8 (ncid, pct_lake_id, pct_lake)

! get id and var for lanwat
    call wrap_inq_varid (ncid, 'PCT_WETLAND', pct_wetland_id   )
    call wrap_get_var8 (ncid, pct_wetland_id, pct_wetland)

  else
    write(6,*)'cannot open lanwat file successfully'
    call endrun
  endif
  ret = nf_close (ncid)


! flip longitudes to go from -180 to 180
! plandmask is already from -180 to 180
  do j = 1,nlat
!  jcount = 1
   do i = 1,nlon/2
   ice(i,j) = Icemask(i+nlon/2,j)
   top(i,j) = Topo(i+nlon/2,j)
   landmask(i,j) = lmask(i+nlon/2,j)

   ice(i+nlon/2,j) = Icemask(i,j)
   top(i+nlon/2,j) = Topo(i,j)

   landmask(i+nlon/2,j) = lmask(i,j)
!   jcount = jcount+1
   enddo
  enddo 
  print *,'Peltier data put in south to north format'
  print *,maxval(pct_glacier)

 
! Define North, East, South, West edges of grid

  edge(1) =   90.
  edge(2) =  180.
  edge(3) =  -90.
  edge(4) =   -180.

! Make latitudes and longitudes at center of grid cell

  dx = (edge(2)-edge(4)) / nlon
  dy = (edge(1)-edge(3)) / nlat

  do j = 1, nlat
     do i = 1, nlon
        latixy(i,j) = (edge(3)+dy/2.) + (j-1)*dy
        longxy(i,j) = (edge(4)+dx/2.) + (i-1)*dx
       end do
  end do

  lat(:) = latixy(1,:)
  lon(:) = longxy(:,1)

! Define North, East, South, West edges of grid

! nanr 30sep10 05deg landwat grid
!  edgew(1) =   90.
!  edgew(2) =  360.
!  edgew(3) =  -90.
!  edgew(4) =    0.

! Make latitudes and longitudes at center of grid cell

!  dxw = (edgew(2)-edgew(4)) / nlonw
!  dyw = (edgew(1)-edgew(3)) / nlatw

!  do j = 1, nlatw
!     do i = 1, nlonw
!        latixyw(i,j) = (edgew(3)+dyw/2.) + (j-1)*dyw
!        longxyw(i,j) = (edgew(4)+dxw/2.) + (i-1)*dxw
!       end do
!  end do
!
!  latw(:) = latixyw(1,:)
!  lonw(:) = longxyw(:,1)
! end nanr

! ---------- create pct_glacier, where ice, set to 100% ------
! ---------- create landmask

  do j = 1,nlat
   do i = 1,nlon
    if (ice(i,j)==100) then
    		pct_glacier(i,j) = 100._r8
    		pct_pft(i,j,0) = 100._r8
    		pct_pft(i,j,1) = 0._r8
    		pct_pft(i,j,2) = 0._r8
    		pct_pft(i,j,3) = 0._r8
    		pct_pft(i,j,4) = 0._r8
    		pct_pft(i,j,5) = 0._r8
    		pct_pft(i,j,6) = 0._r8
    		pct_pft(i,j,7) = 0._r8
    		pct_pft(i,j,8) = 0._r8
    		pct_pft(i,j,9) = 0._r8
    		pct_pft(i,j,10) = 0._r8
    		pct_pft(i,j,11) = 0._r8
    		pct_pft(i,j,12) = 0._r8
    		pct_pft(i,j,13) = 0._r8
    		pct_pft(i,j,14) = 0._r8
    		pct_pft(i,j,15) = 0._r8
    		pct_pft(i,j,16) = 0._r8
! nanr 30sep10 - 0.5deg lanwat
    		pct_lake(i,j)    =  0._r8
    		pct_wetland(i,j) =  0._r8
   end if
   ! error checking
   if (pct_glacier(i,j) == 100._r8 .and. pct_wetland(i,j) > 0._r8) then
    	print *,' i,j,latixy,lonxy   = ',i,j,latixy(i,j),longxy(i,j)
    	print *,' ice,pctgla,pctpft0 = ',ice(i,j),pct_glacier(i,j),pct_pft(i,j,0)
    	print *,' pctlk/wetland      = ', pct_lake(i,j), pct_wetland(i,j)
    	print *,' ---------------------------------------'
    end if
    if (pct_glacier(i,j) == 100._r8 .and. pct_lake(i,j) > 0._r8) then
    	print *,' i,j,latixy,lonxy   = ',i,j,latixy(i,j),longxy(i,j)
    	print *,' ice,pctgla,pctpft0 = ',ice(i,j),pct_glacier(i,j),pct_pft(i,j,0)
    	print *,' pctlk/wetland      = ', pct_lake(i,j), pct_wetland(i,j)
    	print *,' ---------------------------------------'
    end if

! nanr 10/8/10 - padding the pfts to 100.
! nanr 11/02/10 - padding the pfts to 100.
! set all new cells to bareground (pft1 == 100)
! set all new cells to something else (pft13 == 100)
     if(landmask(i,j) == 1 .and. plandmask(i,j) == 0) then

     		pct_pft(i,j,0) = 0._r8
     		pct_pft(i,j,1) = 0._r8
     		pct_pft(i,j,2) = 0._r8
     		pct_pft(i,j,3) = 0._r8
     		pct_pft(i,j,4) = 0._r8
     		pct_pft(i,j,5) = 0._r8
     		pct_pft(i,j,6) = 0._r8
     		pct_pft(i,j,7) = 0._r8
     		pct_pft(i,j,8) = 0._r8
     		pct_pft(i,j,9) = 0._r8
     		pct_pft(i,j,10) = 0._r8
     		pct_pft(i,j,11) = 0._r8
     		pct_pft(i,j,12) = 0._r8
     		pct_pft(i,j,13) = 100._r8
     		pct_pft(i,j,14) = 0._r8
     		pct_pft(i,j,15) = 0._r8
     		pct_pft(i,j,16) = 0._r8
     end if
   enddo
  enddo
  print *,maxval(pct_glacier)
  print *,'pct_pft data created '

! nanr 30sep10 - commented out b/c using 05deg lanwat mask
! jcount=0
! do j = 1,nlat,2
!  do j = 1,nlat,2
!   icount=0
!    jcount=jcount+1
!   do i = 1,nlon,2
!    icount=icount+1
!    if(Icemask(i,j)==1) pct_lake(icount,jcount) = 0._r8
!    if(Icemask(i,j)==1) pct_wetland(icount,jcount) = 0._r8
!    if(Topo(i,j)>=0) landmaskw(icount,jcount) =  1._r8
!   enddo
!  enddo
! end nanr
  print *,'landmask data created '
! nanr 30sep10  print *,'landmaskw data created '




! -------------------------------------------------------------

! -----------------------------------------------------------------
! create netcdf file 1
! -----------------------------------------------------------------

  print *,'Writing netcdf file...'

  call wrap_create (fileog, nf_clobber, ncid)
  call wrap_put_att_text (ncid, nf_global, 'data_type', 'pct_glacier_data')

! Define dimensions

  call wrap_def_dim (ncid, 'lon' , nlon, dimlon_id)
  call wrap_def_dim (ncid, 'lat' , nlat, dimlat_id)

! Define grid variables

  name = 'lon'
  unit = 'degrees east'
  dim1_id(1) = dimlon_id
  call wrap_def_var (ncid,'LON', nf_float, 1, dim1_id, lon_id)
  call wrap_put_att_text (ncid, lon_id, 'long_name', name)
  call wrap_put_att_text (ncid, lon_id, 'units'    , unit)

  name = 'lat'
  unit = 'degrees north'
  dim1_id(1) = dimlat_id
  call wrap_def_var (ncid,'LAT', nf_float, 1, dim1_id, lat_id)
  call wrap_put_att_text (ncid, lat_id, 'long_name', name)
  call wrap_put_att_text (ncid, lat_id, 'units'    , unit)

  name = 'longitude-2d'
  unit = 'degrees east'
  dim2_id(1) = dimlon_id
  dim2_id(2) = dimlat_id
  call wrap_def_var (ncid, 'LONGXY', nf_float, 2, dim2_id, longxy_id)
  call wrap_put_att_text (ncid, longxy_id, 'long_name', name)
  call wrap_put_att_text (ncid, longxy_id, 'units'    , unit)

  name = 'latitude-2d'
  unit = 'degrees north'
  dim2_id(1) = dimlon_id
  dim2_id(2) = dimlat_id
  call wrap_def_var (ncid, 'LATIXY', nf_float, 2, dim2_id, latixy_id)
  call wrap_put_att_text (ncid, latixy_id, 'long_name', name)
  call wrap_put_att_text (ncid, latixy_id, 'units'    , unit)

  name = 'northern edge of surface grid'
  unit = 'degrees north'
  call wrap_def_var (ncid, 'EDGEN', nf_float, 0, 0, edgen_id)
  call wrap_put_att_text (ncid, edgen_id, 'long_name', name)
  call wrap_put_att_text (ncid, edgen_id, 'units'    , unit)

  name = 'eastern edge of surface grid'
  unit = 'degrees east'
  call wrap_def_var (ncid, 'EDGEE', nf_float, 0, 0, edgee_id)
  call wrap_put_att_text (ncid, edgee_id, 'long_name', name)
  call wrap_put_att_text (ncid, edgee_id, 'units'    , unit)

  name = 'southern edge of surface grid'
  unit = 'degrees north'
  call wrap_def_var (ncid, 'EDGES', nf_float, 0, 0, edges_id)
  call wrap_put_att_text (ncid, edges_id, 'long_name', name)
  call wrap_put_att_text (ncid, edges_id, 'units'    , unit)

  name = 'western edge of surface grid'
  unit = 'degrees east'
  call wrap_def_var (ncid, 'EDGEW', nf_float, 0, 0, edgew_id)
  call wrap_put_att_text (ncid, edgew_id, 'long_name', name)
  call wrap_put_att_text (ncid, edgew_id, 'units'    , unit)

! Define input file specific variables

  name = 'percent glacier'
  unit = 'unitless'
  dim2_id(1) = lon_id
  dim2_id(2) = lat_id
  call wrap_def_var (ncid ,'PCT_GLACIER' ,nf_float, 2, dim2_id, pct_glacier_id)
  call wrap_put_att_text (ncid, pct_glacier_id, 'long_name', name)
  call wrap_put_att_text (ncid, pct_glacier_id, 'units'    , unit)

  name = 'land mask'
  unit = 'unitless'
  ! call wrap_def_var (ncid ,'LANDMASK' ,nf_float, 2, dim2_id, lgmlandmask_id)
  ! call wrap_put_att_text (ncid, lgmlandmask_id, 'long_name', name)
  ! call wrap_put_att_text (ncid, lgmlandmask_id, 'units'    , unit)
  call wrap_def_var (ncid ,'LANDMASK' ,nf_float, 2, dim2_id, landmask_id)
  call wrap_put_att_text (ncid, landmask_id, 'long_name', name)
  call wrap_put_att_text (ncid, landmask_id, 'units'    , unit)

! End of definition

  status = nf_enddef(ncid)

! Create output file

  call wrap_put_var_realx (ncid, lon_id        , lon)
  call wrap_put_var_realx (ncid, lat_id        , lat)
  call wrap_put_var_realx (ncid, longxy_id     , longxy)
  call wrap_put_var_realx (ncid, latixy_id     , latixy)
  call wrap_put_var_realx (ncid, edgen_id      , edge(1))
  call wrap_put_var_realx (ncid, edgee_id      , edge(2))
  call wrap_put_var_realx (ncid, edges_id      , edge(3))
  call wrap_put_var_realx (ncid, edgew_id      , edge(4))
  call wrap_put_var_realx (ncid, pct_glacier_id, pct_glacier)
  call wrap_put_var_realx (ncid, landmask_id   , landmask)
  ! call wrap_put_var_realx (ncid, lgmlandmask_id   , lgmlandmask)

  call wrap_close(ncid)

! -----------------------------------------------------------------
! create netcdf file 2 pft
! -----------------------------------------------------------------

  print *,'Writing pft netcdf file...'

  call wrap_create (fileop, nf_clobber, ncid2)
  call wrap_put_att_text (ncid2, nf_global, 'data_type', 'pct_pft_data')

! Define dimensions

  call wrap_def_dim (ncid2, 'lon' , nlon, dimlon_id)
  call wrap_def_dim (ncid2, 'lat' , nlat, dimlat_id)
  call wrap_def_dim (ncid2, 'pft' , numpft+1, dimpft_id)

! Define grid variables

  name = 'lon'
  unit = 'degrees east'
  dim1_id(1) = dimlon_id
  call wrap_def_var (ncid2,'LON', nf_float, 1, dim1_id, lon_id)
  call wrap_put_att_text (ncid2, lon_id, 'long_name', name)
  call wrap_put_att_text (ncid2, lon_id, 'units'    , unit)

  name = 'lat'
  unit = 'degrees north'
  dim1_id(1) = dimlat_id
  call wrap_def_var (ncid2,'LAT', nf_float, 1, dim1_id, lat_id)
  call wrap_put_att_text (ncid2, lat_id, 'long_name', name)
  call wrap_put_att_text (ncid2, lat_id, 'units'    , unit)

  name = 'longitude-2d'
  unit = 'degrees east'
  dim2_id(1) = dimlon_id
  dim2_id(2) = dimlat_id
  call wrap_def_var (ncid2, 'LONGXY', nf_float, 2, dim2_id, longxy_id)
  call wrap_put_att_text (ncid2, longxy_id, 'long_name', name)
  call wrap_put_att_text (ncid2, longxy_id, 'units'    , unit)

  name = 'latitude-2d'
  unit = 'degrees north'
  dim2_id(1) = dimlon_id
  dim2_id(2) = dimlat_id
  call wrap_def_var (ncid2, 'LATIXY', nf_float, 2, dim2_id, latixy_id)
  call wrap_put_att_text (ncid2, latixy_id, 'long_name', name)
  call wrap_put_att_text (ncid2, latixy_id, 'units'    , unit)

  name = 'northern edge of surface grid'
  unit = 'degrees north'
  call wrap_def_var (ncid2, 'EDGEN', nf_float, 0, 0, edgen_id)
  call wrap_put_att_text (ncid2, edgen_id, 'long_name', name)
  call wrap_put_att_text (ncid2, edgen_id, 'units'    , unit)

  name = 'eastern edge of surface grid'
  unit = 'degrees east'
  call wrap_def_var (ncid2, 'EDGEE', nf_float, 0, 0, edgee_id)
  call wrap_put_att_text (ncid2, edgee_id, 'long_name', name)
  call wrap_put_att_text (ncid2, edgee_id, 'units'    , unit)

  name = 'southern edge of surface grid'
  unit = 'degrees north'
  call wrap_def_var (ncid2, 'EDGES', nf_float, 0, 0, edges_id)
  call wrap_put_att_text (ncid2, edges_id, 'long_name', name)
  call wrap_put_att_text (ncid2, edges_id, 'units'    , unit)

  name = 'western edge of surface grid'
  unit = 'degrees east'
  call wrap_def_var (ncid2, 'EDGEW', nf_float, 0, 0, edgew_id)
  call wrap_put_att_text (ncid2, edgew_id, 'long_name', name)
  call wrap_put_att_text (ncid2, edgew_id, 'units'    , unit)

! Define input file specific variables

  name = 'percent pft'
  unit = 'unitless'
  dim3_id(1) = lon_id
  dim3_id(2) = lat_id
  dim3_id(3) = dimpft_id
  call wrap_def_var (ncid2,'PCT_PFT' ,nf_float, 3, dim3_id, pct_pft_id)
  call wrap_put_att_text (ncid2, pct_pft_id, 'long_name', name)
  call wrap_put_att_text (ncid2, pct_pft_id, 'units'    , unit)

  name = 'land mask'
  unit = 'unitless'
  call wrap_def_var (ncid2 ,'LANDMASK' ,nf_float, 2, dim2_id, landmask_id)
  call wrap_put_att_text (ncid2, landmask_id, 'long_name', name)
  call wrap_put_att_text (ncid2, landmask_id, 'units'    , unit)

! End of definition

  status = nf_enddef(ncid2)

! Create output file

  call wrap_put_var_realx (ncid2, lon_id        , lon)
  call wrap_put_var_realx (ncid2, lat_id        , lat)
  call wrap_put_var_realx (ncid2, longxy_id     , longxy)
  call wrap_put_var_realx (ncid2, latixy_id     , latixy)
  call wrap_put_var_realx (ncid2, edgen_id      , edge(1))
  call wrap_put_var_realx (ncid2, edgee_id      , edge(2))
  call wrap_put_var_realx (ncid2, edges_id      , edge(3))
  call wrap_put_var_realx (ncid2, edgew_id      , edge(4))
  call wrap_put_var_realx (ncid2, pct_pft_id    , pct_pft)
  call wrap_put_var_realx (ncid2, landmask_id   , landmask)

  call wrap_close(ncid2)



  print *,'Writing lanwat file...'

  call wrap_create (fileol, nf_clobber, ncid)
  call wrap_put_att_text (ncid, nf_global, 'data_type', 'lanwat_data')

! Define dimensions

! nanr 30sep10 - 05 deg grid
!  call wrap_def_dim (ncid, 'lon' , nlonw, dimlon_id)
!  call wrap_def_dim (ncid, 'lat' , nlatw, dimlat_id)
! end nanr

  call wrap_def_dim (ncid, 'lon' , nlon, dimlon_id)
  call wrap_def_dim (ncid, 'lat' , nlat, dimlat_id)

! Define grid variables

  name = 'lon'
  unit = 'degrees east'
  dim1_id(1) = dimlon_id
  call wrap_def_var (ncid,'LON', nf_float, 1, dim1_id, lon_id)
  call wrap_put_att_text (ncid, lon_id, 'long_name', name)
  call wrap_put_att_text (ncid, lon_id, 'units'    , unit)

  name = 'lat'
  unit = 'degrees north'
  dim1_id(1) = dimlat_id
  call wrap_def_var (ncid,'LAT', nf_float, 1, dim1_id, lat_id)
  call wrap_put_att_text (ncid, lat_id, 'long_name', name)
  call wrap_put_att_text (ncid, lat_id, 'units'    , unit)

  name = 'longitude-2d'
  unit = 'degrees east'
  dim2_id(1) = dimlon_id
  dim2_id(2) = dimlat_id
  call wrap_def_var (ncid, 'LONGXY', nf_float, 2, dim2_id, longxy_id)
  call wrap_put_att_text (ncid, longxy_id, 'long_name', name)
  call wrap_put_att_text (ncid, longxy_id, 'units'    , unit)

  name = 'latitude-2d'
  unit = 'degrees north'
  dim2_id(1) = dimlon_id
  dim2_id(2) = dimlat_id
  call wrap_def_var (ncid, 'LATIXY', nf_float, 2, dim2_id, latixy_id)
  call wrap_put_att_text (ncid, latixy_id, 'long_name', name)
  call wrap_put_att_text (ncid, latixy_id, 'units'    , unit)

  name = 'northern edge of surface grid'
  unit = 'degrees north'
  call wrap_def_var (ncid, 'EDGEN', nf_float, 0, 0, edgen_id)
  call wrap_put_att_text (ncid, edgen_id, 'long_name', name)
  call wrap_put_att_text (ncid, edgen_id, 'units'    , unit)

  name = 'eastern edge of surface grid'
  unit = 'degrees east'
  call wrap_def_var (ncid, 'EDGEE', nf_float, 0, 0, edgee_id)
  call wrap_put_att_text (ncid, edgee_id, 'long_name', name)
  call wrap_put_att_text (ncid, edgee_id, 'units'    , unit)

  name = 'southern edge of surface grid'
  unit = 'degrees north'
  call wrap_def_var (ncid, 'EDGES', nf_float, 0, 0, edges_id)
  call wrap_put_att_text (ncid, edges_id, 'long_name', name)
  call wrap_put_att_text (ncid, edges_id, 'units'    , unit)

  name = 'western edge of surface grid'
  unit = 'degrees east'
  call wrap_def_var (ncid, 'EDGEW', nf_float, 0, 0, edgew_id)
  call wrap_put_att_text (ncid, edgew_id, 'long_name', name)
  call wrap_put_att_text (ncid, edgew_id, 'units'    , unit)

! Define input file specific variables

  name = 'percent lake'
  unit = 'unitless'
  dim2_id(1) = lon_id
  dim2_id(2) = lat_id
  call wrap_def_var (ncid ,'PCT_LAKE' ,nf_float, 2, dim2_id, pct_lake_id)
  call wrap_put_att_text (ncid, pct_lake_id, 'long_name', name)
  call wrap_put_att_text (ncid, pct_lake_id, 'units'    , unit)

  name = 'percent wetland'
  unit = 'unitless'
  dim2_id(1) = lon_id
  dim2_id(2) = lat_id
  call wrap_def_var (ncid ,'PCT_WETLAND' ,nf_float, 2, dim2_id, pct_wetland_id)
  call wrap_put_att_text (ncid, pct_wetland_id, 'long_name', name)
  call wrap_put_att_text (ncid, pct_wetland_id, 'units'    , unit)

  name = 'land mask'
  unit = 'unitless'
  call wrap_def_var (ncid ,'LANDMASK' ,nf_float, 2, dim2_id, landmask_id)
  call wrap_put_att_text (ncid, landmask_id, 'long_name', name)
  call wrap_put_att_text (ncid, landmask_id, 'units'    , unit)

! End of definition

  status = nf_enddef(ncid)

! Create output file

  call wrap_put_var_realx (ncid, lon_id        , lon)
  call wrap_put_var_realx (ncid, lat_id        , lat)
  call wrap_put_var_realx (ncid, longxy_id     , longxy)
  call wrap_put_var_realx (ncid, latixy_id     , latixy)
  call wrap_put_var_realx (ncid, edgen_id      , edge(1))
  call wrap_put_var_realx (ncid, edgee_id      , edge(2))
  call wrap_put_var_realx (ncid, edges_id      , edge(3))
  call wrap_put_var_realx (ncid, edgew_id      , edge(4))
  call wrap_put_var_realx (ncid, pct_lake_id, pct_lake)
  call wrap_put_var_realx (ncid, pct_wetland_id, pct_wetland)
  call wrap_put_var_realx (ncid, landmask_id   , landmask)
! nanr 30sep10 - moving to 05 deg grid
!  call wrap_put_var_realx (ncid, lon_id        , lonw)
!  call wrap_put_var_realx (ncid, lat_id        , latw)
!  call wrap_put_var_realx (ncid, longxy_id     , longxyw)
!  call wrap_put_var_realx (ncid, latixy_id     , latixyw)
!  call wrap_put_var_realx (ncid, edgen_id      , edgew(1))
!  call wrap_put_var_realx (ncid, edgee_id      , edgew(2))
!  call wrap_put_var_realx (ncid, edges_id      , edgew(3))
!  call wrap_put_var_realx (ncid, edgew_id      , edgew(4))
!  call wrap_put_var_realx (ncid, pct_lake_id, pct_lake)
!  call wrap_put_var_realx (ncid, pct_wetland_id, pct_wetland)
!  call wrap_put_var_realx (ncid, landmask_id   , landmaskw)
! end nanr


  call wrap_close(ncid)


end program convert_mksrf


!===============================================================================

subroutine wrap_create (path, cmode, ncid)
  implicit none
  include 'netcdf.inc'
  integer, parameter :: r8 = selected_real_kind(12)
  character(len=*) path
  integer cmode, ncid, ret
  ret = nf_create (path, cmode, ncid)
  if (ret.ne.NF_NOERR) call handle_error (ret)
end subroutine wrap_create

!===============================================================================

subroutine wrap_def_dim (nfid, dimname, len, dimid)
  implicit none
  include 'netcdf.inc'
  integer, parameter :: r8 = selected_real_kind(12)
  integer :: nfid, len, dimid
  character(len=*) :: dimname
  integer ret
  ret = nf_def_dim (nfid, dimname, len, dimid)
  if (ret.ne.NF_NOERR) call handle_error (ret)
end subroutine wrap_def_dim

!===============================================================================

subroutine wrap_def_var (nfid, name, xtype, nvdims, vdims, varid)
  implicit none
  include 'netcdf.inc'
  integer, parameter :: r8 = selected_real_kind(12)
  integer :: nfid, xtype, nvdims, varid
  integer :: vdims(nvdims)
  character(len=*) :: name
  integer ret
  ret = nf_def_var (nfid, name, xtype, nvdims, vdims, varid)
  if (ret.ne.NF_NOERR) call handle_error (ret)
end subroutine wrap_def_var

!===============================================================================

subroutine wrap_put_att_text (nfid, varid, attname, atttext)
  implicit none
  include 'netcdf.inc'
  integer, parameter :: r8 = selected_real_kind(12)
  integer :: nfid, varid
  character(len=*) :: attname, atttext
  integer :: ret, siz
  siz = len_trim(atttext)
  ret = nf_put_att_text (nfid, varid, attname, siz, atttext)
  if (ret.ne.NF_NOERR) call handle_error (ret)
end subroutine wrap_put_att_text

!===============================================================================

subroutine wrap_put_var_realx (nfid, varid, arr)
  implicit none
  include 'netcdf.inc'
  integer, parameter :: r8 = selected_real_kind(12)
  integer :: nfid, varid
  real(r8) :: arr(*)
  integer :: ret
#ifdef CRAY
  ret = nf_put_var_real (nfid, varid, arr)
#else
  ret = nf_put_var_double (nfid, varid, arr)
#endif
  if (ret.ne.NF_NOERR) call handle_error (ret)
end subroutine wrap_put_var_realx

!===============================================================================

subroutine wrap_put_var_int (nfid, varid, arr)
  implicit none
  include 'netcdf.inc'
  integer, parameter :: r8 = selected_real_kind(12)
  integer :: nfid, varid
  integer :: arr(*)
  integer :: ret
  ret = nf_put_var_int (nfid, varid, arr)
  if (ret.ne.NF_NOERR) call handle_error (ret)
end subroutine wrap_put_var_int
  
!===============================================================================

subroutine wrap_close (ncid)
  implicit none
  include 'netcdf.inc'
  integer, parameter :: r8 = selected_real_kind(12)
  integer :: ncid
  integer :: ret
  ret = nf_close (ncid)
  if (ret.ne.NF_NOERR) then
     write(6,*)'WRAP_CLOSE: nf_close failed for id ',ncid
     call handle_error (ret)
  end if
end subroutine wrap_close

!===============================================================================

subroutine handle_error(ret)
  implicit none
  include 'netcdf.inc'
  integer :: ret
  if (ret .ne. nf_noerr) then
     write(6,*) 'NCDERR: ERROR: ',nf_strerror(ret)
     call abort
  endif
end subroutine handle_error

!===============================================================================


subroutine wrap_inq_varid (nfid, varname, varid)
  implicit none
  include 'netcdf.inc'

  integer nfid, varid
  character*(*) varname

  integer ret

  ret = nf_inq_varid (nfid, varname, varid)
  if (ret.ne.NF_NOERR) call handle_error (ret)
end subroutine wrap_inq_varid
!==========================================

subroutine endrun
  implicit none
  include 'netcdf.inc'

  call abort
  stop 999
end subroutine endrun

!===============================================

subroutine wrap_get_var8 (nfid, varid, arr)
  implicit none
  include 'netcdf.inc'

  integer nfid, varid
  real*8 arr(*)

  integer ret

  ret = nf_get_var_double (nfid, varid, arr)
  if (ret.ne.NF_NOERR) call handle_error (ret)
end subroutine wrap_get_var8

!================================
