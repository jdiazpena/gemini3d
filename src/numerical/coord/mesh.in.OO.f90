module meshobj

!> This is a base type for defining most general characteristics of a curvlinear mesh; extension define specific coordinate systems.
!    However, the idea here is to insulate the numerical parts of the program from that so that they can deal exclusively with the
!    generic metric factors, etc.

use, intrinsic:: iso_fortran_env, only: wp=>real64
implicit none (type, external)
public

!> curvmesh is an overarching dervied type containing functionality and data that is not specific to individual coordinate systems
!   (which are extended types).  Note that all arrays are pointers because they need to be targets and allocatable AND the fortran
!   standard does not support have allocatable, target attributed inside a derived type.  Because of this is it not straightforward
!   to check the allocation status of these arrays (i.e. fortran also does not allow one to check the allocation status of a pointer).  
!   Thus the quantities which are not, for sure, allocated need to have an allocation status variable so we can check...  Because
!   the pointers are always allocated in groups we do not need separate status vars for each array thankfully...
type :: curvmesh
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Generic properties !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
  logical :: xi_alloc_status=.false.    ! pointers are allocated in groups, statuses stored here
  logical :: dxi_alloc_status=.false. 
  logical :: difflen_alloc_status=.false.

  !> SIZE INFORMATION.  Specified and set by base class methods
  integer :: lx1,lx2,lx3,lx2all,lx3all
  !! for program units that may not be able to access module globals
  
  !!> CURVILINEAR VARIABLES AND DIFFS.  (private)
  real(wp), dimension(:), pointer :: x1     ! provided in input file
  real(wp), dimension(:), pointer :: x1i    ! recomputed by base class once x1 set
  real(wp), dimension(:), pointer :: dx1        ! recomputed by base class from x1
  !! because sub arrays need to be assigned to aliases in calculus module program units
  real(wp), dimension(:), pointer :: dx1i   ! recomputed by base class from interface locations (themselves recomputed)
  
  real(wp), dimension(:), pointer :: x2
  real(wp), dimension(:), pointer :: x2i
  real(wp), dimension(:), pointer :: dx2        ! this (and similar dx arrays) are pointers because they become associated with other pointers (meaning they have to either have the "target" keyword or themselves be pointers).  These should also be contiguous but I believe that is guaranteed as long as they are assigned through allocate statements (see fortran standard)
  real(wp), dimension(:), pointer :: dx2i
  
  real(wp), dimension(:), pointer :: x3
  real(wp), dimension(:), pointer :: x3i
  real(wp), dimension(:), pointer :: dx3
  real(wp), dimension(:), pointer :: dx3i
  
  real(wp), dimension(:), pointer :: x2all
  real(wp), dimension(:), pointer  :: x2iall
  real(wp), dimension(:), pointer :: dx2all
  real(wp), dimension(:), pointer  :: dx2iall
  
  real(wp), dimension(:), pointer :: x3all
  real(wp), dimension(:), pointer  :: x3iall
  real(wp), dimension(:), pointer :: dx3all
  real(wp), dimension(:), pointer  :: dx3iall
  
  !> DIFFERENTIAL LENGTH ELEMENTS NEEDED TO COMPUTE COURANT NUMBERS.  Compute by a method in generic class
  real(wp), dimension(:,:,:), pointer :: dl1i,dl2i,dl3i
  
  !> A FLAG FOR INDICATING WHETHER OR NOT PERIODIC.  set by input files
  logical :: flagper
  
  !> flag for indicated type of grid (0 - closed dipole; 1 - open dipole inverted; 2 - non-inverted).  Computed by method in generic
  !class
  integer :: gridflag
 
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Coordinate system specific properties !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
  !> METRIC FACTORS.  These are pointers to be assigned/allocated/filled by subclass for specific coordinate system
  logical :: coord_alloc_status=.false.    ! single status variable for all coord-specific arrays

  real(wp), dimension(:,:,:), pointer :: h1,h2,h3     ! need to be computed by subclass for specific coordinate system
  !! these are the cell-centered metric coefficients
  real(wp), dimension(:,:,:), pointer :: h1x1i,h2x1i,h3x1i
  !! metric factors at x1 cell interfaces; dimension 1 has size lx1+1
  real(wp), dimension(:,:,:), pointer :: h1x2i,h2x2i,h3x2i
  !! metric factors at x2 interfaces; dim. 2 has lx2+1
  real(wp), dimension(:,:,:), pointer :: h1x3i,h2x3i,h3x3i
  !! metric factors at x3 interfaces; dim. 3 has lx3+1
  
  !ROOT ONLY FULL GRID METRIC FACTORS (WORKERS WILL NOT ALLOCATE).  Again these must have subclass methods to provide allocation and filling
  real(wp), dimension(:,:,:), pointer :: h1all,h2all,h3all
  real(wp), dimension(:,:,:), pointer :: h1x1iall,h2x1iall,h3x1iall
  !! dimension 1 has size lx1+1
  real(wp), dimension(:,:,:), pointer :: h1x2iall,h2x2iall,h3x2iall
  !! dim. 2 has lx2all+1
  real(wp), dimension(:,:,:), pointer :: h1x3iall,h2x3iall,h3x3iall
  !! dim. 3 has lx3all+1
  
  !> Problem-depedent geometric terms that can be precomputed, e.g. for advection and elliptic equations
  
  !> UNIT VECTORS - Pointers.  Subclass methods must allocate and assign values to these.  
  real(wp), dimension(:,:,:,:), pointer :: e1,e2,e3
  !! unit vectors in curvilinear space (cartesian components)
  real(wp), dimension(:,:,:,:), pointer :: er,etheta,ephi
  !! spherical unit vectors (cartesian components)
  
  !> GEOMAGNETIC GRID DATA
  real(wp), dimension(:,:,:), pointer :: r,theta,phi
  !! may be used in the interpolation of neutral perturbations
  
  !> FULL-GRID GEOMAGNETIC INFORMATION - USED BY ROOT IN INTERPOLATING ELECTRIC FIELD FILE INPUT.  Pointers.  Subclass methods for each
  !coordinate system must allocate and compute these. 
  real(wp), dimension(:,:,:), pointer :: rall,thetaall,phiall
  
  !> GEOGRAPHIC DATA; pointers
  real(wp), dimension(:,:,:), pointer :: glat,glon,alt
  
  !> MAGNETIC FIELD - THIS IS  PART OF THE GRID SINCE THE COORDINATE SYSTEM USED IS BASED ON THE MAGNETIC FIELD.  Pointers
  real(wp), dimension(:,:,:), pointer :: Bmag
  real(wp), dimension(:,:), pointer :: I

  !> Gravitational field
  real(wp), dimension(:,:,:), pointer :: g1,g2,g3
  
  !> NEED FOR EIA CALCULATIONS.  Pointers
  real(wp), dimension(:,:,:), pointer :: altall,glonall
  real(wp), dimension(:,:,:), pointer :: Bmagall
  
  !> DEFINE POINTS TO EXCLUDE FROM NUMERICAL SOLVES?. Pointers
  real(wp), dimension(:,:,:), pointer :: nullpts
  !! this could be a logical but I'm going to treat it as real*8
  integer :: lnull
  !! length of null point index array
  integer, dimension(:,:), pointer :: inull

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Methods !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
  contains
    procedure :: set_coords
    procedure :: calc_coord_diffs
    procedure :: calc_difflengths
    !procedure :: refine
    procedure :: init_storage
    final :: destructor
end type curvmesh

contains
  !> assign coordinates to internal variables given some set of input arrays.
  !   Assume that the data passed in include ghost cells
  subroutine set_coords(self,x1,x2,x3,x2all,x3all)
    class(curvmesh) :: self
    real(wp), dimension(:), intent(in) :: x1,x2,x3
    real(wp), dimension(:), intent(in) :: x2all,x3all
    integer :: lx1,lx2,lx3,lx2all,lx3all

    lx1=size(x1,1)-4
    lx2=size(x2,1)-4
    lx3=size(x3,1)-4
    lx2all=size(x2all,1)-4
    lx3all=size(x3all,1)-4
    self%lx1=lx1; self%lx2=lx2; self%lx3=lx3
    self%lx2all=lx2all; self%lx3all=lx3all

    allocate(self%x1(-1:lx1+2),self%x2(-1:lx2+2),self%x3(-1:lx3+2))
    self%x1=x1; self%x2=x2; self%x3=x3
    allocate(self%x2all(-1:lx2all+2),self%x3all(-1:lx3all+2))
    self%x2all=x2all; self%x3all=x3all

    self%xi_alloc_status=.true.
  end subroutine set_coords

  !> compute diffs from given grid spacing
  subroutine calc_coord_diffs(self)
    class(curvmesh) :: self
    integer :: lx1,lx2,lx3

    if (.not. self%xi_alloc_status) error stop ' attempting to compute diffs without coordinates!'

    lx1=self%lx1; lx2=self%lx2; lx3=self%lx3    ! limits indexing verboseness, which drives me crazy

    allocate(self%dx1(0:lx1+2), self%x1i(1:lx1+1), self%dx1i(1:lx1))    
    self%dx1 = self%x1(0:lx1+2)-self%x1(-1:lx1+1)       !! computing these avoids extra message passing (could be done for other coordinates
    self%x1i(1:lx1+1) = 0.5_wp*(self%x1(0:lx1)+self%x1(1:lx1+1))
    self%dx1i=self%x1i(2:lx1+1)-self%x1i(1:lx1)

    allocate(self%dx2(0:lx2+2), self%x2i(1:lx2+1), self%dx2i(1:lx2))    
    self%dx2 = self%x2(0:lx2+2)-self%x2(-1:lx2+1)       !! computing these avoids extra message passing (could be done for other coordinates
    self%x2i(1:lx2+1) = 0.5_wp*(self%x2(0:lx2)+self%x2(1:lx2+1))
    self%dx2i=self%x2i(2:lx2+1)-self%x2i(1:lx2)

    allocate(self%dx3(0:lx3+2), self%x3i(1:lx3+1), self%dx3i(1:lx3))
    self%dx3 = self%x3(0:lx3+2)-self%x3(-1:lx3+1)
    self%x3i(1:lx3+1)=0.5_wp*(self%x3(0:lx3)+self%x3(1:lx3+1))
    self%dx3i=self%x3i(2:lx3+1)-self%x3i(1:lx3)

    self%dxi_alloc_status=.true.
  end subroutine calc_coord_diffs

  !> calculate differential lengths (units of m), needed for CFL calculations
  subroutine calc_difflengths(self)
    class(curvmesh) :: self
    real(wp), dimension(:,:,:), allocatable :: tmpdx
    integer :: lx1,lx2,lx3

    if (.not. self%dxi_alloc_status .or. .not. self%coord_alloc_status) then
      error stop ' attempting to compute differential lengths without interface diffs or metric factors!'
    end if

    lx1=self%lx1; lx2=self%lx2; lx3=self%lx3

    allocate(tmpdx(1:lx1,1:lx2,1:lx3))
    allocate(self%dl1i(1:lx1,1:lx2,1:lx3),self%dl2i(1:lx1,1:lx2,1:lx3),self%dl3i(1:lx1,1:lx2,1:lx3))
    tmpdx=spread(spread(self%dx1i,2,lx2),3,lx3)
    self%dl1i=tmpdx*self%h1(1:lx1,1:lx2,1:lx3)
    tmpdx=spread(spread(self%dx2i,1,lx1),3,lx3)
    self%dl2i=tmpdx*self%h2(1:lx1,1:lx2,1:lx3)
    tmpdx=spread(spread(self%dx3i,1,lx1),2,lx2)
    self%dl3i=tmpdx*self%h3(1:lx1,1:lx2,1:lx3)
    deallocate(tmpdx)

    self%difflen_alloc_status=.true.
  end subroutine calc_difflengths

  !> allocate space for metric factors
  subroutine init_storage(self)
    class(curvmesh) :: self
    integer :: lx1,lx2,lx3

    lx1=self%lx1; lx2=self%lx2; lx3=self%lx3

    if (.not. self%coord_alloc_status ) then     ! use this as a proxy for if any other coordinate-specific arrays exist
      allocate(self%h1(1:lx1,1:lx2,1:lx3),self%h2(1:lx1,1:lx2,1:lx3),self%h3(1:lx1,1:lx2,1:lx3))
      ! fixme: interface metric factors
      allocate(self%h1x1i(1:lx1+1,1:lx2,1:lx3),self%h2x1i(1:lx1+1,1:lx2,1:lx3),self%h3x1i(1:lx1+1,1:lx2,1:lx3))
      allocate(self%h1x2i(1:lx1,1:lx2+1,1:lx3),self%h2x2i(1:lx1,1:lx2+1,1:lx3),self%h3x2i(1:lx1,1:lx2+1,1:lx3))
      allocate(self%er(1:lx1,1:lx2,1:lx3,3),self%etheta(1:lx1,1:lx2,1:lx3,3),self%ephi(1:lx1,1:lx2,1:lx3,3))
      allocate(self%e1(1:lx1,1:lx2,1:lx3,3),self%e2(1:lx1,1:lx2,1:lx3,3),self%e3(1:lx1,1:lx2,1:lx3,3))
      allocate(self%Bmag(1:lx1,1:lx2,1:lx3),self%I(1:lx2,1:lx3))
      allocate(self%g1(1:lx1,1:lx2,1:lx3),self%g2(1:lx1,1:lx2,1:lx3),self%g3(1:lx1,1:lx2,1:lx3))
      allocate(self%r(1:lx1,1:lx2,1:lx3),self%theta(1:lx1,1:lx2,1:lx3),self%phi(1:lx1,1:lx2,1:lx3))

      ! fixme:  there are a number of full-grid arrays that are coordinate specific to be allocated here...
      self%coord_alloc_status=.true.
    else
      error stop ' attempting to allocated space for coordinate-specific arrays when they already exist!'
    end if
  end subroutine init_storage

  !> allocate space for root-only grid quantities
  subroutine init_storage_root(self)
    class(curvmesh) :: self

    !fixme:  allocate root storage here; maybe check myid==0???

  end subroutine init_storage_root

  !> type destructor; written generally, viz. as if it is possible some grid pieces are allocated an others are not
  subroutine destructor(self)
    type(curvmesh) :: self

    ! deallocation statements here; always check allocated first...
    if (self%xi_alloc_status) deallocate(self%x1,self%x2,self%x3,self%x2all,self%x3all)    ! these are from set_coords
    if (self%dxi_alloc_status) then                                  ! from calc_coord_diffs
      deallocate(self%dx1,self%x1i,self%dx1i)
      deallocate(self%dx2,self%x2i,self%dx2i)
      deallocate(self%dx3,self%x3i,self%dx3i)
    end if
    if (self%difflen_alloc_status) deallocate(self%dl1i,self%dl2i,self%dl3i)    ! from calc_difflengths

    ! coordinate-specific arrays set by type extensions
    if (self%coord_alloc_status) then
      deallocate(self%h1,self%h2,self%h3,self%er,self%etheta,self%ephi,self%e1,self%e2,self%e3)
      deallocate(self%g1,self%g2,self%g3)
    end if

    ! let the user know that the destructor indeed ran
    print*, '  curvmesh destructor completed successefully'
  end subroutine destructor

end module meshobj