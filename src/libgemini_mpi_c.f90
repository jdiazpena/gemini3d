!> This module contains C/CXX wrappers for functions in libgemini_mpi.  These routines match those in libgemini_mpi.f90 and are
!!   principally meant to convert the C pointers to various data objects into fortran pointers (including in the case of the
!!   grid a class pointer (pointer to polymorphic object).  Other polymorhpic objects (neutraldata, etc.) are kept in a static
!!   derived type (intvars::gemini_work) and don't need to be passes as class pointers.
module gemini3d_mpi_C

use, intrinsic :: iso_c_binding, only : c_f_pointer, C_PTR, C_INT, wp => C_DOUBLE

use phys_consts, only : lsp
use meshobj, only: curvmesh
use config, only: gemini_cfg
use io, only: output_plasma,output_aur,find_milestone,input_plasma,create_outdir
use potential_comm, only: get_BGEfields,velocities
use grid, only: lx1,lx2,lx3
use grid_mpi, only: grid_drift, read_grid
use collisions, only: conductivities
use potentialBCs_mumps, only: init_Efieldinput
use potential_comm,only : pot2perpfield, electrodynamics
use neutral_perturbations, only: init_neutralperturb,neutral_denstemp_update,neutral_wind_update,neutral_perturb
use temporal, only : dt_comm
use sanity_check, only : check_finite_pertub, check_finite_output
use advec_mpi, only: set_global_boundaries_allspec, halo_interface_vels_allspec
use multifluid_mpi, only: halo_allparams
use sources_mpi, only: RK2_prep_mpi_allspec
use ionization_mpi, only: get_gavg_Tinf
use neutral_perturbations, only: clear_dneu

use gemini3d, only: fluidvar_pointers,fluidauxvar_pointers, electrovar_pointers, gemini_work
use gemini3d_mpi, only: outdir_fullgridvaralloc, get_initial_state, check_fileoutput, check_dryrun, &
 BGfield_Lagrangian, get_initial_drifts, init_procgrid, init_Efieldinput_in, pot2perpfield_in, &
 init_neutralperturb_in, dt_select, neutral_atmos_wind_update, neutral_perturb_in, &
 electrodynamics_in, check_finite_output_in, halo_interface_vels_allspec_in, set_global_boundaries_allspec_in, &
 halo_allparams_in, RK2_prep_mpi_allspec_in, get_gavg_Tinf_in, clear_dneu_in
use gemini3d_C, only : set_gridpointer_dyntype

implicit none (type, external)

contains

!> create output directory and allocate full grid potential storage
subroutine outdir_fullgridvaralloc_C(cfgC,intvarsC,lx1,lx2all,lx3all) bind(C)
  type(C_PTR), intent(in) :: cfgC
  type(C_PTR), intent(inout) :: intvarsC
  integer(C_INT), intent(in) :: lx1,lx2all,lx3all

  type(gemini_cfg), pointer :: cfg
  type(gemini_work), pointer :: intvars

  call c_f_pointer(cfgC, cfg)
  call c_f_pointer(intvarsC,intvars)

  call outdir_fullgridvaralloc(cfg, intvars, lx1, lx2all, lx3all)
end subroutine outdir_fullgridvaralloc_C

!! TODO: allocatable X, how to handle?
! subroutine read_grid_in_C(cfgC, xtype, xC) bind(C)
!   type(C_PTR), intent(in) :: cfgC
!   integer(C_INT), intent(in) :: xtype
!   type(C_PTR), intent(inout) :: xC

!   type(gemini_cfg), pointer :: cfg
!   class(curvmesh), pointer :: x

!   call c_f_pointer(cfgC, cfg)
!   x=>set_gridpointer_dyntype(xtype, xC)

!   call read_grid(cfg%indatsize,cfg%indatgrid,cfg%flagperiodic, x)
!   !! read in a previously generated grid from filenames listed in input file
! end subroutine read_grid_in_C

subroutine get_initial_state_C(cfgC,fluidvarsC,electrovarsC,intvarsC,xtype, xC,UTsec,ymd,tdur) bind(C)
  type(C_PTR), intent(inout) :: cfgC
  type(c_ptr), intent(inout) :: fluidvarsC, electrovarsC
  type(C_PTR), intent(inout) :: intvarsC
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(inout) :: xC
  real(wp), intent(inout) :: UTsec
  integer(C_INT), dimension(3), intent(inout) :: ymd
  real(wp), intent(inout) :: tdur

  type(gemini_cfg), pointer :: cfg
  real(wp), dimension(:,:,:,:), pointer :: fluidvars, electrovars
  type(gemini_work), pointer :: intvars
  class(curvmesh), pointer :: x

  call c_f_pointer(cfgC, cfg)
  call c_f_pointer(intvarsC,intvars)
  x=>set_gridpointer_dyntype(xtype, xC)

  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])
  call c_f_pointer(electrovarsC,electrovars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])

  call get_initial_state(cfg, fluidvars,electrovars,intvars, x, UTsec, ymd, tdur)
end subroutine get_initial_state_C

subroutine check_fileoutput_C(cfgC,fluidvarsC,electrovarsC,intvarsC,t,tout,tglowout,tmilestone,flagoutput,ymd,UTsec) bind(C)
  type(C_PTR), intent(in) :: cfgC
  type(c_ptr), intent(inout) :: fluidvarsC, electrovarsC
  type(C_PTR), intent(inout) :: intvarsC
  real(wp), intent(in) :: t
  real(wp), intent(inout) :: tout,tglowout,tmilestone
  integer(C_INT), intent(inout) :: flagoutput
  integer(C_INT), dimension(3), intent(in) :: ymd
  real(wp), intent(in) :: UTsec

  type(gemini_cfg), pointer :: cfg
  real(wp), dimension(:,:,:,:), pointer :: fluidvars, electrovars
  type(gemini_work), pointer :: intvars

  call c_f_pointer(cfgC, cfg)
  call c_f_pointer(intvarsC,intvars)

  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])
  call c_f_pointer(electrovarsC,electrovars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])

  call check_fileoutput(cfg, fluidvars, electrovars, intvars, t, tout,tglowout,tmilestone,flagoutput,ymd,UTsec)
end subroutine check_fileoutput_C

subroutine check_dryrun_C(cfgC) bind(C)
  type(C_PTR), intent(in) :: cfgC

  type(gemini_cfg), pointer :: cfg

  call c_f_pointer(cfgC, cfg)

  call check_dryrun(cfg)
end subroutine check_dryrun_C

subroutine BGfield_Lagrangian_C(cfgC, xtype,xC, electrovarsC,intvarsC,v2grid,v3grid) bind(C)
  type(C_PTR), intent(in) :: cfgC
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  type(c_ptr), intent(inout) :: electrovarsC
  type(C_PTR), intent(inout) :: intvarsC
  real(wp), intent(inout) :: v2grid,v3grid

  type(gemini_cfg), pointer :: cfg
  class(curvmesh), pointer :: x
  real(wp), dimension(:,:,:,:), pointer :: electrovars
  type(gemini_work), pointer :: intvars

  call c_f_pointer(cfgC, cfg)
  x=>set_gridpointer_dyntype(xtype, xC)
  call c_f_pointer(intvarsC,intvars)

  call c_f_pointer(electrovarsC,electrovars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])

  call BGfield_Lagrangian(cfg, x, electrovars, intvars, v2grid, v3grid)
end subroutine BGfield_Lagrangian_C

subroutine get_initial_drifts_C(cfgC, xtype,xC, fluidvarsC,fluidauxvarsC,electrovarsC,intvarsC) bind(C)
  type(C_PTR), intent(in) :: cfgC
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  type(C_PTR), intent(inout) :: fluidvarsC
  type(C_PTR), intent(in) :: fluidauxvarsC, electrovarsC
  type(C_PTR), intent(inout) :: intvarsC

  type(gemini_cfg), pointer :: cfg
  class(curvmesh), pointer :: x
  real(wp), dimension(:,:,:,:), pointer :: fluidvars, fluidauxvars, electrovars
  type(gemini_work), pointer :: intvars

  call c_f_pointer(cfgC, cfg)
  x=>set_gridpointer_dyntype(xtype, xC)
  call c_f_pointer(intvarsC,intvars)

  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])
  call c_f_pointer(fluidauxvarsC,fluidauxvars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])
  call c_f_pointer(electrovarsC,electrovars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])

  call get_initial_drifts(cfg, x, fluidvars, fluidauxvars, electrovars, intvars)
end subroutine get_initial_drifts_C

subroutine init_procgrid_C(lx2all,lx3all,lid2in,lid3in) bind(C)
  integer(C_INT), intent(in) :: lx2all,lx3all,lid2in,lid3in

  call init_procgrid(lx2all,lx3all,lid2in,lid3in)
end subroutine init_procgrid_C

subroutine init_Efieldinput_in_C(cfgC, xtype,xC, dt,t, intvarsC,ymd,UTsec) bind(C)
  type(C_PTR), intent(in) :: cfgC
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  real(wp), intent(in) :: dt,t
  type(C_PTR), intent(inout) :: intvarsC
  integer(C_INT), dimension(3), intent(in) :: ymd
  real(wp), intent(in) :: UTsec

  type(gemini_cfg), pointer :: cfg
  class(curvmesh), pointer :: x
  type(gemini_work), pointer :: intvars

  call c_f_pointer(cfgC, cfg)
  x=>set_gridpointer_dyntype(xtype, xC)
  call c_f_pointer(intvarsC,intvars)

  call init_Efieldinput_in(cfg, x, dt, t, intvars, ymd, UTsec)

end subroutine init_Efieldinput_in_C

subroutine pot2perpfield_in_C(xtype,xC, electrovarsC) bind(C)
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  type(C_PTR), intent(inout) :: electrovarsC

  class(curvmesh), pointer :: x
  real(wp), dimension(:,:,:,:), pointer :: electrovars

  x=>set_gridpointer_dyntype(xtype, xC)
  call c_f_pointer(electrovarsC,electrovars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])

  call pot2perpfield_in(x,electrovars)
end subroutine pot2perpfield_in_C

subroutine init_neutralperturb_in_C(dt, cfgC, xtype,xC, intvarsC, ymd,UTsec) bind(C)
  real(wp), intent(in) :: dt
  type(C_PTR), intent(in) :: cfgC
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  type(C_PTR), intent(inout) :: intvarsC
  integer(C_INT), dimension(3), intent(in) :: ymd
  real(wp), intent(in) :: UTsec

  type(gemini_cfg), pointer :: cfg
  class(curvmesh), pointer :: x
  type(gemini_work), pointer :: intvars

  call c_f_pointer(cfgC, cfg)
  x=>set_gridpointer_dyntype(xtype, xC)
  call c_f_pointer(intvarsC,intvars)

  call init_neutralperturb_in(dt, cfg, x, intvars, ymd, UTsec)
end subroutine init_neutralperturb_in_C

subroutine dt_select_C(cfgC, xtype,xC, fluidvarsC,fluidauxvarsC, it,t,tout,tglowout,dt) bind(C)
  type(C_PTR), intent(in) :: cfgC
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  type(C_PTR), intent(in) :: fluidvarsC, fluidauxvarsC
  integer(C_INT), intent(in) :: it
  real(wp), intent(in) :: t,tout,tglowout
  real(wp), intent(inout) :: dt

  type(gemini_cfg), pointer :: cfg
  class(curvmesh), pointer :: x
  real(wp), dimension(:,:,:,:), pointer :: fluidvars, fluidauxvars

  call c_f_pointer(cfgC, cfg)
  x=>set_gridpointer_dyntype(xtype, xC)

  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])
  call c_f_pointer(fluidauxvarsC,fluidauxvars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])

  call dt_select(cfg, x, fluidvars, fluidauxvars, it, t, tout, tglowout, dt)
end subroutine dt_select_C

subroutine neutral_atmos_wind_update_C(intvarsC,v2grid,v3grid) bind(C)
  type(C_PTR), intent(inout) :: intvarsC
  real(wp), intent(in) :: v2grid,v3grid

  type(gemini_work), pointer :: intvars

  call c_f_pointer(intvarsC,intvars)
  call neutral_atmos_wind_update(intvars, v2grid, v3grid)
end subroutine neutral_atmos_wind_update_C

subroutine neutral_perturb_in_C(cfgC, intvarsC, xtype,xC, dt,t,ymd,UTsec,v2grid,v3grid) bind(C)
  type(C_PTR), intent(in) :: cfgC
  type(C_PTR), intent(inout) :: intvarsC
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  real(wp), intent(in) :: dt,t
  integer(C_INT), dimension(3), intent(in) :: ymd
  real(wp), intent(in) :: UTsec
  real(wp), intent(in) :: v2grid,v3grid

  type(gemini_cfg), pointer :: cfg
  type(gemini_work), pointer :: intvars
  class(curvmesh), pointer :: x

  call c_f_pointer(cfgC, cfg)
  call c_f_pointer(intvarsC,intvars)
  x=>set_gridpointer_dyntype(xtype, xC)

  call neutral_perturb_in(cfg, intvars, x, dt, t, ymd, UTsec, v2grid, v3grid)

end subroutine neutral_perturb_in_C

subroutine electrodynamics_in_C(cfgC, fluidvarsC,fluidauxvarsC,electrovarsC, intvarsC, xtype,xC, it,t,dt,ymd,UTsec) bind(C)
  type(C_PTR), intent(in) :: cfgC
  type(C_PTR), intent(inout) :: fluidvarsC
  type(C_PTR), intent(in) :: fluidauxvarsC, electrovarsC

  type(C_PTR), intent(inout) :: intvarsC
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC

  integer(C_INT), intent(in) :: it
  real(wp), intent(in) :: t,dt
  integer(C_INT), dimension(3), intent(in) :: ymd
  real(wp), intent(in) :: UTsec

  type(gemini_cfg), pointer :: cfg
  real(wp), dimension(:,:,:,:), pointer :: fluidvars, fluidauxvars, electrovars
  type(gemini_work), pointer :: intvars
  class(curvmesh), pointer :: x

  call c_f_pointer(cfgC, cfg)
  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])
  call c_f_pointer(fluidauxvarsC,fluidauxvars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])
  call c_f_pointer(electrovarsC,electrovars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])
  call c_f_pointer(intvarsC,intvars)
  x=>set_gridpointer_dyntype(xtype, xC)

  call electrodynamics_in(cfg, fluidvars, fluidauxvars, electrovars, intvars, x, it, t, dt, ymd, UTsec)
end subroutine electrodynamics_in_C

subroutine check_finite_output_in_C(cfgC, fluidvarsC, electrovarsC, t) bind(C)
  type(C_PTR), intent(in) :: cfgC
  type(C_PTR), intent(in) :: fluidvarsC, electrovarsC
  real(wp), intent(in) :: t

  type(gemini_cfg), pointer :: cfg
  real(wp), dimension(:,:,:,:), pointer :: fluidvars, electrovars

  call c_f_pointer(cfgC, cfg)
  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])
  call c_f_pointer(electrovarsC,electrovars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])

  call check_finite_output_in(cfg, fluidvars, electrovars, t)
end subroutine check_finite_output_in_C

subroutine halo_interface_vels_allspec_in_C(xtype,xC, fluidvarsC, lsp) bind(C)
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  type(C_PTR), intent(inout) :: fluidvarsC
  integer(C_INT), intent(in) :: lsp

  class(curvmesh), pointer :: x
  real(wp), dimension(:,:,:,:), pointer :: fluidvars

  x=>set_gridpointer_dyntype(xtype, xC)
  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])

  call halo_interface_vels_allspec_in(x, fluidvars, lsp)
end subroutine halo_interface_vels_allspec_in_C

subroutine set_global_boundaries_allspec_in_C(xtype,xC, fluidvarsC,fluidauxvarsC, intvarsC, lsp) bind(C)
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  type(C_PTR), intent(inout) :: fluidvarsC, fluidauxvarsC
  type(C_PTR), intent(inout) :: intvarsC
  integer, intent(in) :: lsp

  class(curvmesh), pointer :: x
  real(wp), dimension(:,:,:,:), pointer :: fluidvars, fluidauxvars
  type(gemini_work), pointer :: intvars

  x=>set_gridpointer_dyntype(xtype, xC)
  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])
  call c_f_pointer(fluidauxvarsC,fluidauxvars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])
  call c_f_pointer(intvarsC,intvars)

  call set_global_boundaries_allspec_in(x, fluidvars, fluidauxvars, intvars, lsp)
end subroutine set_global_boundaries_allspec_in_C

subroutine halo_allparams_in_C(xtype,xC, fluidvarsC,fluidauxvarsC) bind(C)
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  type(C_PTR), intent(inout) :: fluidvarsC, fluidauxvarsC

  class(curvmesh), pointer :: x
  real(wp), dimension(:,:,:,:), pointer :: fluidvars, fluidauxvars

  x=>set_gridpointer_dyntype(xtype, xC)
  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])
  call c_f_pointer(fluidauxvarsC,fluidauxvars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])

  call halo_allparams_in(x, fluidvars, fluidauxvars)
end subroutine halo_allparams_in_C

subroutine RK2_prep_mpi_allspec_in_C(xtype,xC, fluidvarsC) bind(C)
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(in) :: xC
  type(C_PTR), intent(inout) :: fluidvarsC

  class(curvmesh), pointer :: x
  real(wp), dimension(:,:,:,:), pointer :: fluidvars

    x=>set_gridpointer_dyntype(xtype, xC)
  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])

  call RK2_prep_mpi_allspec_in(x, fluidvars)
end subroutine RK2_prep_mpi_allspec_in_C

subroutine get_gavg_Tinf_in_C(intvarsC, gavg,Tninf) bind(C)
  type(C_PTR), intent(in) :: intvarsC
  real(wp), intent(inout) :: gavg,Tninf

  type(gemini_work), pointer :: intvars

  call c_f_pointer(intvarsC,intvars)
  call get_gavg_Tinf_in(intvars, gavg,Tninf)
end subroutine get_gavg_Tinf_in_C

subroutine clear_dneu_in_C(intvarsC) bind(C)
  type(C_PTR), intent(inout) :: intvarsC

  type(gemini_work), pointer :: intvars

  call c_f_pointer(intvarsC,intvars)
  call clear_dneu_in(intvars)
end subroutine clear_dneu_in_C


end module gemini3d_mpi_C