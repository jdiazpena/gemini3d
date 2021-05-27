submodule (io:plasma_input) plasma_input_hdf5

use timeutils, only : date_filename
use h5fortran, only: hdf5_file

implicit none (type, external)

contains

module procedure input_root_currents_hdf5
!! READS, AS INPUT, A FILE GENERATED BY THE GEMINI.F90 PROGRAM

character(:), allocatable :: filenamefull
real(wp), dimension(:,:,:), allocatable :: J1all,J2all,J3all
real(wp), dimension(:,:,:), allocatable :: tmpswap

type(hdf5_file) :: hf

!>  CHECK TO MAKE SURE WE ACTUALLY HAVE THE DATA WE NEED TO DO THE MAG COMPUTATIONS.
if (flagoutput==3) error stop 'Need current densities in the output to compute magnetic fields'


!> FORM THE INPUT FILE NAME
filenamefull = date_filename(outdir,ymd,UTsec) // '.h5'
print *, 'Input file name for current densities:  ', filenamefull

call hf%initialize(filenamefull, status='old', action='r')

!> LOAD THE DATA
!> PERMUTE THE ARRAYS IF NECESSARY
allocate(J1all(lx1,lx2all,lx3all),J2all(lx1,lx2all,lx3all),J3all(lx1,lx2all,lx3all))
if (flagswap==1) then
  allocate(tmpswap(lx1,lx3all,lx2all))
  call hf%read('/J1all', tmpswap)
  J1all = reshape(tmpswap,[lx1,lx2all,lx3all],order=[1,3,2])
  call hf%read('/J2all', tmpswap)
  J2all = reshape(tmpswap,[lx1,lx2all,lx3all],order=[1,3,2])
  call hf%read('/J3all', tmpswap)
  J3all = reshape(tmpswap,[lx1,lx2all,lx3all],order=[1,3,2])
  deallocate(tmpswap)
else
  !! no need to permute dimensions for 3D simulations
  call hf%read('/J1all', J1all)
  call hf%read('/J2all', J2all)
  call hf%read('/J3all', J3all)
end if
print *, 'Min/max current data:  ',minval(J1all),maxval(J1all),minval(J2all),maxval(J2all),minval(J3all),maxval(J3all)

call hf%finalize()

!> DISTRIBUTE DATA TO WORKERS AND TAKE A PIECE FOR ROOT
call bcast_send(J1all,tag%J1,J1)
call bcast_send(J2all,tag%J2,J2)
call bcast_send(J3all,tag%J3,J3)

end procedure input_root_currents_hdf5


module procedure input_root_mpi_hdf5

!! READ INPUT FROM FILE AND DISTRIBUTE TO WORKERS.
!! STATE VARS ARE EXPECTED INCLUDE GHOST CELLS.  NOTE ALSO
!! THAT RECORD-BASED INPUT IS USED SO NO FILES > 2GB DUE
!! TO GFORTRAN BUG WHICH DISALLOWS 8 BYTE INTEGER RECORD
!! LENGTHS.

type(hdf5_file) :: hf

integer :: lx1,lx2,lx3,lx2all,lx3all,isp
integer :: ix1

real(wp), dimension(-1:size(x1,1)-2,-1:size(x2all,1)-2,-1:size(x3all,1)-2,1:lsp) :: nsall, vs1all, Tsall
integer :: lx1in,lx2in,lx3in,u, utrace
real(wp) :: tin
real(wp), dimension(3) :: ymdtmp
real(wp) :: tstart,tfin
real(wp), dimension(:,:), allocatable :: Phislab
real(wp), allocatable :: tmp(:,:,:,:), tmpPhi(:), tmpPhi2(:,:)

!> so that random values (including NaN) don't show up in Ghost cells
nsall = 0
ns = 0
vs1all= 0
vs1 = 0
Tsall = 0
Ts = 0

!> SYSTEM SIZES
lx1=size(ns,1)-4
lx2=size(ns,2)-4
lx3=size(ns,3)-4
lx2all=size(x2all)-4
lx3all=size(x3all)-4


allocate(Phislab(1:lx2all,1:lx3all))  !space to store EFL potential


!> READ IN FROM FILE, AS OF CURVILINEAR BRANCH THIS IS NOW THE ONLY INPUT OPTION
call get_simsize3(indatsize, lx1in, lx2in, lx3in)
print '(2A,3I6)', indatsize,' input dimensions:',lx1in,lx2in,lx3in
print '(A,3I6)', 'Target (output) grid structure dimensions:',lx1,lx2all,lx3all

if (flagswap==1) then
  print *, '2D simulation: **SWAP** x2/x3 dims and **PERMUTE** input arrays'
  lx3in=lx2in
  lx2in=1
end if

if (.not. (lx1==lx1in .and. lx2all==lx2in .and. lx3all==lx3in)) then
  error stop 'The input data must be the same size as the grid which you are running the simulation on' // &
       '- use a script to interpolate up/down to the simulation grid'
end if

call hf%initialize(indatfile, status='old', action='r')

if (flagswap==1) then
  allocate(tmp(lx1,lx3all,lx2all,lsp))

  call hf%read('/nsall', tmp)
  nsall(1:lx1,1:lx2all,1:lx3all,1:lsp) = reshape(tmp,[lx1,lx2all,lx3all,lsp],order=[1,3,2,4])
  call hf%read('/vs1all', tmp)
  vs1all(1:lx1,1:lx2all,1:lx3all,1:lsp) = reshape(tmp,[lx1,lx2all,lx3all,lsp],order=[1,3,2,4])
  call hf%read('/Tsall', tmp)
  Tsall(1:lx1,1:lx2all,1:lx3all,1:lsp) = reshape(tmp,[lx1,lx2all,lx3all,lsp],order=[1,3,2,4])
  !! permute the dimensions so that 2D runs are parallelized
  if (hf%exist('/Phiall')) then
    if (hf%ndims('/Phiall') == 1) then
      print *, size(Phislab)
      allocate(tmpPhi(lx3all))
      call hf%read('/Phiall',tmpPhi)
      if (size(Phislab, 1) /= 1) then
        write(stderr,*) 'Phislab shape',shape(Phislab)
        error stop 'Phislab x2 /= 1'
      endif
      Phislab(1, :) = tmpPhi
    else
      print *,size(Phislab)
      allocate(tmpPhi2(lx3all, lx2all))
      call hf%read('/Phiall',tmpPhi2)
      Phislab = reshape(tmpPhi2,[lx2all,lx3all], order=[2,1])
    endif
  else
    Phislab = 0
  end if

  deallocate(tmp)
else
  call hf%read('/nsall', nsall(1:lx1,1:lx2all,1:lx3all,1:lsp))
  call hf%read('/vs1all', vs1all(1:lx1,1:lx2all,1:lx3all,1:lsp))
  call hf%read('/Tsall', Tsall(1:lx1,1:lx2all,1:lx3all,1:lsp))
  if (hf%exist('/Phiall')) then
    if (hf%ndims('/Phiall') == 1) then
      if (lx2all==1) then
        allocate(tmpPhi(lx3all))
      else
        allocate(tmpPhi(lx2all))
      end if
      call hf%read('/Phiall', tmpPhi)
      ! FIXME: MH please delete if you are okay with this
      !if (size(Phislab, 1) /= 1) then
      !  write(stderr,*) 'Phislab shape',shape(Phislab)
      !  error stop 'Phislab x2 /= 1'
      !endif
      if (lx2all==1) then
        Phislab(1,:) = tmpPhi
      else
        Phislab(:,1)=tmpPhi
      end if
    else
      call hf%read('/Phiall', Phislab)
    endif
  else
    Phislab = 0
  end if
end if

call hf%finalize()

!> Apply EFL approx to compute full grid potential
do ix1=1,lx1
  Phiall(ix1,1:lx2all,1:lx3all)=Phislab(1:lx2all,1:lx3all)
end do

!> ROOT BROADCASTS IC DATA TO WORKERS
call cpu_time(tstart)
call bcast_send(nsall,tag%ns,ns)
call bcast_send(vs1all,tag%vs1,vs1)
call bcast_send(Tsall,tag%Ts,Ts)
call bcast_send(Phiall,tag%Phi,Phi)
call cpu_time(tfin)
print '(A,ES12.3,A)', 'Sent ICs to workers in', tfin-tstart, ' seconds.'

deallocate(Phislab)

end procedure input_root_mpi_hdf5

end submodule plasma_input_hdf5
