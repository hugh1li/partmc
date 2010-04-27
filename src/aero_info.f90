! Copyright (C) 2009 Nicole Riemer and Matthew West
! Licensed under the GNU General Public License version 2 or (at your
! option) any later version. See the file COPYING for details.

!> \file
!> The pmc_aero_info module.

!> The aero_info_t structure and associated subroutines.
module pmc_aero_info

  use pmc_util
  use pmc_spec_file
  use pmc_mpi
#ifdef PMC_USE_MPI
  use mpi
#endif

  integer, parameter :: AERO_INFO_NONE = 0
  integer, parameter :: AERO_INFO_DILUTION = 1
  integer, parameter :: AERO_INFO_COAG = 2
  integer, parameter :: AERO_INFO_HALVED = 3

  !> Information about added or removed particles describing the
  !> source or sink.
  !!
  !! For each particle that is added or removed from the particle
  !! population the aero_info_t structure gives the ID of the
  !! added/removed particle and the action (dilution, coagulation,
  !! emission, etc) that caused the addition/removal. The action must
  !! be one of the AERO_INFO_* parameters in the pmc_aero_info
  !! module. If the action is AERO_INFO_COAG then the other_id field
  !! will store the ID of the particle that was coagulated with.
  !!
  !! Coagulation always occurs between two particles and the resulting
  !! particle takes the ID of one of the two original particles. In
  !! this case we say that one particle has survived the coagulation
  !! and now has increased mass, while the other particle was
  !! removed. Only the removed particle (the one whose ID was lost)
  !! will be recorded in an aero_info_t structure.
  type aero_info_t
     !> Particle ID number.
     integer :: id
     !> Action on this particle (from AERO_INFO_* parameters).
     integer :: action
     !> Other particle ID for coagulation events, or 0 if not needed.
     integer :: other_id
  end type aero_info_t

contains

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Allocates and initializes.
  subroutine aero_info_allocate(aero_info)

    !> Result.
    type(aero_info_t), intent(inout) :: aero_info

    call aero_info_zero(aero_info)

  end subroutine aero_info_allocate
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Deallocates.
  subroutine aero_info_deallocate(aero_info)

    !> Structure to deallocate.
    type(aero_info_t), intent(inout) :: aero_info

  end subroutine aero_info_deallocate
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Copies aero_info_from to aero_info_to, both
  !> of which must already be allocated.
  subroutine aero_info_copy(aero_info_from, &
       aero_info_to)

    !> Origin structure.
    type(aero_info_t), intent(in) :: aero_info_from
    !> Destination structure.
    type(aero_info_t), intent(inout) :: aero_info_to

    aero_info_to%id = aero_info_from%id
    aero_info_to%action = aero_info_from%action
    aero_info_to%other_id = aero_info_from%other_id

  end subroutine aero_info_copy
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Resets an aero_info to contain zero particles.
  subroutine aero_info_zero(aero_info)

    !> Structure to reset.
    type(aero_info_t), intent(inout) :: aero_info

    aero_info%id = 0
    aero_info%action = AERO_INFO_NONE
    aero_info%other_id = 0

  end subroutine aero_info_zero
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Determines the number of bytes required to pack the given value.
  integer function pmc_mpi_pack_size_aero_info(val)

    !> Value to pack.
    type(aero_info_t), intent(in) :: val

    integer :: total_size

    total_size = 0
    total_size = total_size + pmc_mpi_pack_size_integer(val%id)
    total_size = total_size + pmc_mpi_pack_size_integer(val%action)
    total_size = total_size + pmc_mpi_pack_size_integer(val%other_id)
    pmc_mpi_pack_size_aero_info = total_size

  end function pmc_mpi_pack_size_aero_info

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Packs the given value into the buffer, advancing position.
  subroutine pmc_mpi_pack_aero_info(buffer, position, val)

    !> Memory buffer.
    character, intent(inout) :: buffer(:)
    !> Current buffer position.
    integer, intent(inout) :: position
    !> Value to pack.
    type(aero_info_t), intent(in) :: val

#ifdef PMC_USE_MPI
    integer :: prev_position

    prev_position = position
    call pmc_mpi_pack_integer(buffer, position, val%id)
    call pmc_mpi_pack_integer(buffer, position, val%action)
    call pmc_mpi_pack_integer(buffer, position, val%other_id)
    call assert(842929827, &
         position - prev_position == pmc_mpi_pack_size_apa(val))
#endif

  end subroutine pmc_mpi_pack_aero_info

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Unpacks the given value from the buffer, advancing position.
  subroutine pmc_mpi_unpack_aero_info(buffer, position, val)

    !> Memory buffer.
    character, intent(inout) :: buffer(:)
    !> Current buffer position.
    integer, intent(inout) :: position
    !> Value to pack.
    type(aero_info_t), intent(out) :: val

#ifdef PMC_USE_MPI
    integer :: prev_position

    prev_position = position
    call pmc_mpi_unpack_integer(buffer, position, val%id)
    call pmc_mpi_unpack_integer(buffer, position, val%action)
    call pmc_mpi_unpack_integer(buffer, position, val%other_id)
    call assert(841267392, &
         position - prev_position == pmc_mpi_pack_size_apa(val))
#endif

  end subroutine pmc_mpi_unpack_aero_info

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
end module pmc_aero_info