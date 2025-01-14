#include <define.h>

MODULE MOD_SnowFraction

!-----------------------------------------------------------------------
   USE MOD_Precision
   IMPLICIT NONE
   SAVE

! PUBLIC MEMBER FUNCTIONS:
   PUBLIC :: snowfraction
#ifdef LULC_IGBP_PFT
   PUBLIC :: snowfraction_pftwrap
#endif
#ifdef LULC_IGBP_PC
   PUBLIC :: snowfraction_pcwrap
#endif


!-----------------------------------------------------------------------

   CONTAINS

!-----------------------------------------------------------------------


   subroutine snowfraction (lai,sai,z0m,zlnd,scv,snowdp,wt,sigf,fsno)

!=======================================================================
!
! !DESCRIPTION:
! Provide snow cover fraction
!
! Original author : Yongjiu Dai, /09/1999/, /04/2014/
!
! REVISIONS:
! Hua Yuan, 10/2019: removed sigf to be compatible with PFT classification
!=======================================================================

   use MOD_Precision
   implicit none

! dummy arguments
   real(r8), INTENT(in) :: scv    ! snow water equivalent [mm or kg/m3]
   real(r8), INTENT(in) :: snowdp ! snow depth [m]
   real(r8), INTENT(in) :: z0m    ! aerodynamic roughness length [m]
   real(r8), INTENT(in) :: zlnd   ! aerodynamic roughness length over soil surface [m]
   real(r8), INTENT(in) :: lai    ! leaf area index [-]
   real(r8), INTENT(in) :: sai    ! stem area index [-]

   real(r8), INTENT(out) :: wt    ! fraction of vegetation covered with snow [-]
   real(r8), INTENT(out) :: sigf  ! fraction of veg cover, excluding snow-covered veg [-]
   real(r8), INTENT(out) :: fsno  ! fraction of soil covered by snow [-]

   real(r8) :: fmelt              ! dimensionless metling factor
   real(r8), parameter :: m = 1.0 ! the value of m used in CLM4.5 is 1.0.
                                  ! while the value of m given by Niu et al (2007) is 1.6
                                  ! while Niu (2012) suggested 3.0
!-----------------------------------------------------------------------
   if(lai+sai > 1e-6) then
      ! Fraction of vegetation buried (covered) by snow
      wt = 0.1*snowdp/z0m
      wt = wt/(1.+wt)

      ! Fraction of vegetation cover free of snow
      sigf = 1. - wt
   else
      wt = 0.
      sigf = 0.
   endif

! 10/16/2019, yuan:
   !if(sigf < 0.001) sigf = 0.
   !if(sigf > 0.999) sigf = 1.

! Fraction of soil covered by snow
   fsno = 0.0
   if(snowdp > 0.) then
      fmelt = (scv/snowdp/100.) ** m
      fsno  = tanh(snowdp/(2.5 * zlnd * fmelt))
   end if

   end subroutine snowfraction

#ifdef LULC_IGBP_PFT
   subroutine snowfraction_pftwrap (ipatch,zlnd,scv,snowdp,wt,sigf,fsno)

!=======================================================================
!
! !DESCRIPTION:
! A wrap SUBROUTINE to calculate snow cover fraction for PFT run
!
! REVISIONS:
! Hua Yuan, 10/2019: initial code adapted from snowfraction() by Yongjiu Dai
!
! Hua Yuan, 10/2019: removed sigf_p to be compatible with PFT classification
!=======================================================================

   use MOD_Precision
   USE MOD_LandPFT
   USE MOD_Vars_PFTimeInvariants
   USE MOD_Vars_PFTimeVariables
   implicit none

! dummy arguments
   INTEGER,  INTENT(in) :: ipatch ! patch index

   real(r8), INTENT(in) :: zlnd   ! aerodynamic roughness length over soil surface [m]
   real(r8), INTENT(in) :: scv    ! snow water equivalent [mm or kg/m3]
   real(r8), INTENT(in) :: snowdp ! snow depth [m]

   real(r8), INTENT(out) :: wt    ! fraction of vegetation covered with snow [-]
   real(r8), INTENT(out) :: sigf  ! fraction of veg cover, excluding snow-covered veg [-]
   real(r8), INTENT(out) :: fsno  ! fraction of soil covered by snow [-]

   real(r8) :: fmelt              ! dimensionless metling factor
   real(r8), parameter :: m = 1.0 ! the value of m used in CLM4.5 is 1.0.
                                  ! while the value of m given by Niu et al (2007) is 1.6
                                  ! while Niu (2012) suggested 3.0
!-----------------------------------------------------------------------

   ! local variables
   INTEGER i, p, ps, pe
   REAL(r8) wt_tmp

   wt_tmp = 0.
   ps = patch_pft_s(ipatch)
   pe = patch_pft_e(ipatch)

   DO i = ps, pe
      p = pftclass(i)

      if(tlai_p(i)+tsai_p(i) > 1.e-6) then
         ! Fraction of vegetation buried (covered) by snow
         wt = 0.1*snowdp/z0m_p(i)
         wt = wt/(1.+wt)

         ! Fraction of vegetation cover free of snow
         sigf_p(i) = 1. - wt
      else
         wt = 0.
         sigf_p(i) = 0.
      endif

      !if(sigf_p(i) < 0.001) sigf_p(i) = 0.
      !if(sigf_p(i) > 0.999) sigf_p(i) = 1.

      wt_tmp = wt_tmp + wt*pftfrac(i)
   ENDDO

   wt   = wt_tmp
   sigf = sum(sigf_p(ps:pe) * pftfrac(ps:pe))

   ! Fraction of soil covered by snow
   fsno = 0.0
   if(snowdp > 0.) then
      fmelt = (scv/snowdp/100.) ** m
      fsno  = tanh(snowdp/(2.5 * zlnd * fmelt))
   end if

   end subroutine snowfraction_pftwrap
#endif

#ifdef LULC_IGBP_PC
   subroutine snowfraction_pcwrap (ipatch,zlnd,scv,snowdp,wt,sigf,fsno)

!=======================================================================
!
! !DESCRIPTION:
! A wrap SUBROUTINE to calculate snow cover fraction for PC run
!
! REVISIONS:
! Hua Yuan, 10/2019: initial code adapted from snowfraction() by Yongjiu Dai
!
! Hua Yuan, 10/2019: removed sigf_c to be compatible with PFT classification
!=======================================================================

   use MOD_Precision
   USE MOD_LandPC
   USE MOD_Vars_PCTimeInvariants
   USE MOD_Vars_PCTimeVariables
   implicit none

! dummy arguments
   INTEGER,  INTENT(in) :: ipatch ! patch index

   real(r8), INTENT(in) :: scv    ! snow water equivalent [mm or kg/m3]
   real(r8), INTENT(in) :: snowdp ! snow depth [m]
   real(r8), INTENT(in) :: zlnd   ! aerodynamic roughness length over soil surface [m]

   real(r8), INTENT(out) :: wt    ! fraction of vegetation covered with snow [-]
   real(r8), INTENT(out) :: sigf  ! fraction of veg cover, excluding snow-covered veg [-]
   real(r8), INTENT(out) :: fsno  ! fraction of soil covered by snow [-]

   real(r8) :: fmelt              ! dimensionless metling factor
   real(r8), parameter :: m = 1.0 ! the value of m used in CLM4.5 is 1.0.
                                  ! while the value of m given by Niu et al (2007) is 1.6
                                  ! while Niu (2012) suggested 3.0
!-----------------------------------------------------------------------
   ! local variables
   INTEGER p, pc
   REAL(r8) wt_tmp

   wt_tmp = 0.
   pc = patch2pc(ipatch)

   DO p = 0, N_PFT-1
      if(tlai_c(p,pc)+tsai_c(p,pc) > 1.e-6) then
         ! Fraction of vegetation buried (covered) by snow
         wt = 0.1*snowdp/z0m_c(p,pc)
         wt = wt/(1.+wt)

         ! Fraction of vegetation cover free of snow
         sigf_c(p,pc) = 1. - wt
      else
         wt = 0.
         sigf_c(p,pc) = 0.
      endif

      !if(sigf_c(p,pc) < 0.001) sigf_c(p,pc) = 0.
      !if(sigf_c(p,pc) > 0.999) sigf_c(p,pc) = 1.

      wt_tmp = wt_tmp + wt*pcfrac(p,pc)
   ENDDO

   wt   = wt_tmp
   sigf = sum(sigf_c(:,pc) * pcfrac(:,pc))

! Fraction of soil covered by snow
   fsno = 0.0
   if(snowdp > 0.) then
      fmelt = (scv/snowdp/100.) ** m
      fsno  = tanh(snowdp/(2.5 * zlnd * fmelt))
   end if

   end subroutine snowfraction_pcwrap
#endif

END MODULE MOD_SnowFraction
