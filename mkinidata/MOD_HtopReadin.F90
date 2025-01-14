#include <define.h>

MODULE MOD_HtopReadin

!-----------------------------------------------------------------------
   USE MOD_Precision
   IMPLICIT NONE
   SAVE

! PUBLIC MEMBER FUNCTIONS:
   PUBLIC :: HTOP_readin


!-----------------------------------------------------------------------

   CONTAINS

!-----------------------------------------------------------------------


   SUBROUTINE HTOP_readin (dir_landdata, lc_year)

! ===========================================================
! Read in the canopy tree top height
! ===========================================================

         USE MOD_Precision
         USE MOD_SPMD_Task
         USE MOD_Vars_Global
         USE MOD_Const_LC
         USE MOD_Const_PFT
         USE MOD_Vars_TimeInvariants
         USE MOD_LandPatch
#ifdef LULC_IGBP_PFT
         USE MOD_LandPFT
         USE MOD_Vars_PFTimeInvariants
         USE MOD_Vars_PFTimeVariables
#endif
#ifdef LULC_IGBP_PC
         USE MOD_LandPC
         USE MOD_Vars_PCTimeInvariants
         USE MOD_Vars_PCTimeVariables
#endif
         USE MOD_NetCDFVector
#ifdef SinglePoint
         USE MOD_SingleSrfdata
#endif

         IMPLICIT NONE

         INTEGER, intent(in) :: lc_year    ! which year of land cover data used
         character(LEN=256), INTENT(in) :: dir_landdata

         ! Local Variables
         character(LEN=256) :: c
         character(LEN=256) :: landdir, lndname, cyear
         integer :: i,j,t,p,ps,pe,m,n,npatch

         REAL(r8), allocatable :: htoplc  (:)
         REAL(r8), allocatable :: htoppft (:)

         write(cyear,'(i4.4)') lc_year
         landdir = trim(dir_landdata) // '/htop/' // trim(cyear)


#ifdef LULC_USGS

         IF (p_is_worker) THEN
            do npatch = 1, numpatch
               m = patchclass(npatch)

               htop(npatch) = htop0(m)
               hbot(npatch) = hbot0(m)

            end do
         ENDIF

#endif

#ifdef LULC_IGBP
#ifdef SinglePoint
         allocate (htoplc (numpatch))
         htoplc(:) = SITE_htop
#else
         lndname = trim(landdir)//'/htop_patches.nc'
         CALL ncio_read_vector (lndname, 'htop_patches', landpatch, htoplc)
#endif

         IF (p_is_worker) THEN
            do npatch = 1, numpatch
               m = patchclass(npatch)

               htop(npatch) = htop0(m)
               hbot(npatch) = hbot0(m)

               ! trees or woody savannas
               IF ( m<6 .or. m==8) THEN
                  ! 01/06/2020, yuan: adjust htop reading
                  IF (htoplc(npatch) > 2.) THEN
                     htop(npatch) = htoplc(npatch)
                     hbot(npatch) = htoplc(npatch)*hbot0(m)/htop0(m)
                     hbot(npatch) = max(1., hbot(npatch))
                     !htop(npatch) = max(htop(npatch), hbot0(m)*1.2)
                  ENDIF
               ENDIF

            end do
         ENDIF

         IF (allocated(htoplc))   deallocate ( htoplc )
#endif


#ifdef LULC_IGBP_PFT
#ifdef SinglePoint
         allocate(htoppft(numpft))
         htoppft = pack(SITE_htop_pfts, SITE_pctpfts > 0.)
#else
         lndname = trim(landdir)//'/htop_pfts.nc'
         CALL ncio_read_vector (lndname, 'htop_pfts', landpft,   htoppft)
#endif

         IF (p_is_worker) THEN
            do npatch = 1, numpatch
               t = patchtype(npatch)
               m = patchclass(npatch)

               IF (t == 0) THEN
                  ps = patch_pft_s(npatch)
                  pe = patch_pft_e(npatch)

                  DO p = ps, pe
                     n = pftclass(p)

                     htop_p(p) = htop0_p(n)
                     hbot_p(p) = hbot0_p(n)

                     ! for trees
                     ! 01/06/2020, yuan: adjust htop reading
                     IF ( n>0 .and. n<9 .and. htoppft(p)>2.) THEN
                        htop_p(p) = htoppft(p)
                        hbot_p(p) = htoppft(p)*hbot0_p(n)/htop0_p(n)
                        hbot_p(p) = max(1., hbot_p(p))
                     ENDIF
                  ENDDO

                  htop(npatch) = sum(htop_p(ps:pe)*pftfrac(ps:pe))
                  hbot(npatch) = sum(hbot_p(ps:pe)*pftfrac(ps:pe))

               ELSE
                  htop(npatch) = htop0(m)
                  hbot(npatch) = hbot0(m)
               ENDIF

            ENDDO
         ENDIF

         IF (allocated(htoppft)) deallocate(htoppft)
#endif

#ifdef LULC_IGBP_PC
#ifdef SinglePoint
         allocate(htoplc(1))
         htoplc(:) = sum(SITE_htop_pfts * SITE_pctpfts)
#else
         lndname = trim(landdir)//'/htop_patches.nc'
         CALL ncio_read_vector (lndname, 'htop_patches', landpatch, htoplc )
#endif

         IF (p_is_worker) THEN
            do npatch = 1, numpatch
               t = patchtype(npatch)
               m = patchclass(npatch)
               IF (t == 0) THEN
                  p = patch2pc(npatch)
                  htop_c(:,p) = htop0_p(:)
                  hbot_c(:,p) = hbot0_p(:)

                  DO n = 1, N_PFT-1
                     ! 01/06/2020, yuan: adjust htop reading
                     IF (n < 9 .and. htoplc(npatch)>2.) THEN
                        htop_c(n,p) = htoplc(npatch)
                     ENDIF
                  ENDDO
                  htop(npatch) = sum(htop_c(:,p)*pcfrac(:,p))
                  hbot(npatch) = sum(hbot_c(:,p)*pcfrac(:,p))
               ELSE
                  htop(npatch) = htop0(m)
                  hbot(npatch) = hbot0(m)
               ENDIF
            end do
         ENDIF

         IF (allocated(htoplc)) deallocate(htoplc)
#endif

   END SUBROUTINE HTOP_readin

END MODULE MOD_HtopReadin
