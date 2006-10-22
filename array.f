C     Utility functions for handling V array of particle volumes.
C
C     There are two different representations of particle size
C     distributions used throughout this code: a sectional
C     representation and an explicit particle representation.
C
C     The sectional representation stores the number and mass of
C     particles in bins, which are logarithmicly spaced. The bins are
C     described by the bin_v(n_bin) and bin_r(n_bin) arrays, which store the
C     volume and radius of the centerpoint of each bin. The variable
C     dlnr ... FIXME

      module mod_array
      contains

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine compute_volumes(n_bin, n_spec, vol_frac,
     *     MM, i_start, i_end, 
     *     n_ini, bin_v, dlnr, V, M)

      use mod_bin

      integer n_bin        ! INPUT: number of bins
      integer n_spec       ! INPUT: number of species
      real*8 vol_frac(n_spec) ! INPUT: composition of particles
      integer MM           ! INPUT: physical size of V
      integer i_start      ! INPUT:
      integer i_end        ! INPUT:
      integer n_ini(n_bin) ! INPUT: initial number distribution
      real*8 bin_v(n_bin)  ! INPUT: volume of particles in bins (m^3)
      real*8 dlnr          ! INPUT: scale factor
      real*8 V(MM,n_spec)  ! OUTPUT: particle volumes  (m^3)
      integer M            ! OUTPUT: logical dimension of V

      real*8 pi
      parameter (pi = 3.14159265358979323846d0)

      real*8 total_vol_frac, v_low, v_high, pv
      integer k, i, sum_e, sum_a, delta_n, i_spec

      sum_e = i_start - 1

      total_vol_frac = 0.d0
      do i=1,n_spec
         total_vol_frac = total_vol_frac + vol_frac(i)
      enddo

      do k = 1,n_bin
         delta_n = n_ini(k)
         sum_a = sum_e + 1
         sum_e = sum_e + delta_n
         call bin_edge(n_bin, bin_v, k, v_low)
         call bin_edge(n_bin, bin_v, k + 1, v_high)
         do i = sum_a,sum_e
            pv = dble(i - sum_a + 1) / dble(sum_e - sum_a + 2)
     &           * (v_high - v_low) + v_low
            do i_spec = 1,n_spec
               V(i,i_spec) = vol_frac(i_spec)/total_vol_frac * pv
            enddo
         enddo
      enddo

      M = sum_e - i_start + 1

      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
 
      subroutine zero_v(MM,n_spec,V)

      integer MM      ! INPUT: 
      integer n_spec  ! INPUT: number of species
      integer i,j
      real*8 V(MM,n_spec)


      do i=1,MM
         do j=1,n_spec
            V(i,j) = 0.d0
         enddo
      enddo

      return
      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine find_rand_pair(M, s1, s2)
      
      integer M       ! INPUT: number of particles
      integer s1, s2  ! OUTPUT: s1 and s2 are not equal, random
                      !         particles with (1 <= s1,s2 <= M)

      ! FIXME: rand() only returns a REAL*4, so we might not be able to
      ! generate all integers between 1 and M if M is too big.
 100  s1 = int(rand() * float(M)) + 1
      if ((s1 .lt. 1) .or. (s1 .gt. M)) goto 100
 101  s2 = int(rand() * float(M)) + 1
      if ((s2 .lt. 1) .or. (s2 .gt. M)) goto 101
      if (s1 .eq. s2) goto 101

      return
      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
     
      subroutine find_rand_pair_acc_rej(MM, M, V, max_k, kernel,
     &     s1, s2)
      
      integer MM      ! INPUT: physical dimension of V
      integer M       ! INPUT: logical dimension of V
      real*8 V(MM)    ! INPUT: array of particle volumes   (m^3)
      real*8 max_k    ! INPUT: maximum value of the kernel (m^3 s^(-1))
C      external kernel ! INPUT: kernel function
      integer s1, s2  ! OUTPUT: s1 and s2 are not equal, random
                      !         particles with V(s1/s2) != 0
      interface
         subroutine kernel(v1, v2, k)
         real*8, intent(in) :: v1
         real*8, intent(in) :: v2
         real*8, intent(out) :: k
         end subroutine
      end interface

      real*8 k, p

 200  continue
      call find_rand_pair(M, s1, s2) ! test particles s1, s2
      call kernel(V(s1), V(s2), k)
      p = k / max_k     ! collision probability   
      if (dble(rand()) .gt. p ) goto 200

      return
      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine coagulate(MM, M, V, V_comp,n_spec,
     &        n_bin, bin_v, bin_r, bin_g, bin_gs, bin_n, dlnr,
     &        s1, s2, bin_change)

      use mod_bin

      integer MM           ! INPUT: physical dimension of V
      integer M            ! INPUT/OUTPUT: logical dimension of V
      integer n_spec       ! INPUT: number of species 
      real*8 V(MM,n_spec)  ! INPUT/OUTPUT: particle volumes  (m^3)
      real*8 V_comp        ! INPUT: computational volume   (m^3)

      integer n_bin        ! INPUT: number of bins
      real*8 bin_v(n_bin)  ! INPUT: volume of particles in bins (m^3)
      real*8 bin_r(n_bin)  ! INPUT: radius of particles in bins (m)
      real*8 bin_g(n_bin)  ! INPUT/OUTPUT: total mass in bins 
      real*8 bin_gs(n_bin,n_spec)  ! INPUT/OUTPUT: species mass in bins
      integer bin_n(n_bin) ! INPUT/OUTPUT: number in bins
      real*8 dlnr          ! INPUT: bin scale factor

      integer s1           ! INPUT: first particle to coagulate
      integer s2           ! INPUT: second particle to coagulate
      logical bin_change   ! OUTPUT: whether an empty bin filled,
                           !         or a filled bin became empty

      integer k1, k2, kn, i, j
      real*8  pv1, pv2

      bin_change = .false.

      call particle_vol(MM,n_spec,V,s1,pv1)
      call particle_vol(MM,n_spec,V,s2,pv2)

      ! remove s1 and s2 from bins
      call particle_in_bin(pv1, n_bin, bin_v, k1)
      call particle_in_bin(pv2, n_bin, bin_v, k2)
      bin_n(k1) = bin_n(k1) - 1
      bin_n(k2) = bin_n(k2) - 1
      bin_g(k1) = bin_g(k1) - pv1
      bin_g(k2) = bin_g(k2) - pv2
      do j=1,n_spec
         if((bin_gs(k1,j)-V(s1,j)) .lt.0.d0) 
     &        write(6,*)'help gs ',k1,j, bin_gs(k1,j),V(s1,j),
     &        bin_gs(k1,j)-V(s1,j)
         if((bin_gs(k2,j)-V(s2,j)) .lt.0.d0) 
     &        write(6,*)'help gs ',k2,j, bin_gs(k2,j),V(s2,j),
     &        bin_gs(k2,j)-V(s2,j)
         bin_gs(k1,j) = bin_gs(k1,j) - V(s1,j)
         bin_gs(k2,j) = bin_gs(k2,j) - V(s2,j)
      enddo

      if ((bin_n(k1) .lt. 0) .or. (bin_n(k2) .lt. 0)) then
         write(*,*)'ERROR: invalid bin_n'
         call exit(2)
      endif

      ! add particle 2 onto particle 1
      do i=1,n_spec
         V(s1,i) = V(s1,i) + V(s2,i)
         if (V(s1,i) .lt. 0.d0) then
            write(6,*)'help! ',s1,i,V(s1,i)
         endif
      enddo

      ! shift the last particle into empty slot
      do i=1,n_spec
         V(s2,i) = V(M,i)
      enddo
      M = M - 1    ! shorten array

      ! add new particle to bins
      call particle_vol(MM,n_spec,V,s1,pv1)
      call particle_in_bin(pv1, n_bin, bin_v, kn)
      bin_n(kn) = bin_n(kn) + 1
      bin_g(kn) = bin_g(kn) + pv1
      do j=1,n_spec
         bin_gs(kn,j) = bin_gs(kn,j) + V(s1,j)
      enddo

      if ((bin_n(k1) .eq. 0) .or. (bin_n(k2) .eq. 0))
     &     bin_change = .true.
      if ((bin_n(kn) .eq. 1) .and. (kn .ne. k1) .and. (kn .ne. k2))
     &     bin_change = .true.
      return
      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
     
      subroutine maybe_coag_pair(MM, M, V, V_comp, n_spec,
     &           n_bin, bin_v, bin_r, bin_g, bin_gs, bin_n, dlnr,
     &           del_t, n_samp, kernel, did_coag, bin_change)

      integer MM           ! INPUT: physical dimension of V
      integer M            ! INPUT/OUTPUT: logical dimension of V
      integer n_spec       ! INPUT: number of species
      real*8 V(MM,n_spec)  ! INPUT/OUTPUT: particle volumes
      real*8 V_comp        ! INPUT: computational volume

      integer n_bin        ! INPUT: number of bins
      real*8 bin_v(n_bin)  ! INPUT: volume of particles in bins
      real*8 bin_r(n_bin)  ! INPUT: radius of particles in bins
      real*8 bin_g(n_bin)  ! INPUT/OUTPUT: total mass in bins
      real*8 bin_gs(n_bin,n_spec) ! INPUT/OUTPUT: species mass in bins
      integer bin_n(n_bin) ! INPUT/OUTPUT: number in bins
      real*8 dlnr          ! INPUT: bin scale factor
      
      real*8 del_t         ! INPUT: timestep
      integer n_samp       ! INPUT: number of samples per timestep
C      external kernel      ! INPUT: kernel function
      logical did_coag     ! OUTPUT: whether a coagulation occured
      logical bin_change   ! OUTPUT: whether bin structure changed

      interface
         subroutine kernel(v1, v2, k)
         real*8, intent(in) :: v1
         real*8, intent(in) :: v2
         real*8, intent(out) :: k
         end subroutine
      end interface

      integer s1, s2
      real*8 p, k
      real*8 pv1, pv2

      call find_rand_pair(M, s1, s2) ! test particles s1, s2
      call particle_vol(MM,n_spec,V,s1,pv1)
      call particle_vol(MM,n_spec,V,s2,pv2)
      call kernel(pv1, pv2, k)
      p = k * 1d0/V_comp * del_t * 
     &            (dble(M)*(dble(M)-1d0)/2d0) / dble(n_samp)
      bin_change = .false.
      if (dble(rand()) .lt. p) then
         call coagulate(MM, M, V, V_comp, n_spec,
     &        n_bin, bin_v, bin_r, bin_g, bin_gs, bin_n, dlnr,
     &        s1, s2, bin_change)
         did_coag = .true.
      else
         did_coag = .false.
      endif

      return
      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine double(MM, M, V, V_comp, n_spec,
     &     n_bin, bin_v, bin_r, bin_g, bin_gs, bin_n, dlnr)

      integer MM           ! INPUT: physical dimension of V
      integer M            ! INPUT/OUTPUT: logical dimension of V
      integer n_spec       ! INPUT: number of species
      real*8 V(MM,n_spec)  ! INPUT/OUTPUT: particle volumes
      real*8 V_comp        ! INPUT/OUTPUT: computational volume

      integer n_bin        ! INPUT: number of bins
      real*8 bin_v(n_bin)  ! INPUT: volume of particles in bins
      real*8 bin_r(n_bin)  ! INPUT: radius of particles in bins
      real*8 bin_g(n_bin)  ! INPUT/OUTPUT: mass in bins
      real*8 bin_gs(n_bin,n_spec) ! INPUT/OUTPUT: species mass in bins
      integer bin_n(n_bin) ! INPUT/OUTPUT: number in bins
      real*8 dlnr          ! INPUT: bin scale factor

      integer i,j

      ! only double if we have enough space to do so
      if (M .gt. MM / 2) then
         write(*,*)'ERROR: double without enough space'
         call exit(2)
      endif
      
      ! double V and associated structures
      do i = 1,M
         do j=1,n_spec
            V(i + M,j) = V(i,j)
         enddo
      enddo
      M = 2 * M
      V_comp = 2d0 * V_comp
      
      ! double bin structures
      do i = 1,n_bin
         bin_g(i) = bin_g(i) * 2d0
         bin_n(i) = bin_n(i) * 2
         do j=1,n_spec
            bin_gs(i,j) = bin_gs(i,j) * 2d0
         enddo
      enddo

      return
      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine est_k_max(n_bin, bin_v, bin_n, kernel, k_max)
      
      integer n_bin         ! INPUT: number of bins
      real*8 bin_v(n_bin)   ! INPUT: volume of particles in bins (m^3)
      integer bin_n(n_bin)  ! INPUT: number in each bin
C      external kernel       ! INPUT: kernel function
      real*8 k_max          ! OUTPUT: maximum kernel value

      interface
         subroutine kernel(v1, v2, k)
         real*8, intent(in) :: v1
         real*8, intent(in) :: v2
         real*8, intent(out) :: k
         end subroutine
      end interface

      real*8 k
      integer i, j
      logical use_bin(n_bin)

      ! use_bin starts as non-empty bins
      do i = 1,n_bin
         use_bin(i) = (bin_n(i) .gt. 0)
      enddo

      ! add all bins downstream of non-empty bins
      do i = 2,n_bin
         if (use_bin(i)) use_bin(i-1) = .true.
      enddo

      ! add all bins upstream of non-empty bins
      do i = (n_bin-1),1,-1
         if (use_bin(i)) use_bin(i+1) = .true.
      enddo
      
      k_max = 0d0
      do i = 1,n_bin
         if (use_bin(i)) then
            do j = 1,i
               if (use_bin(j)) then
                  call kernel(bin_v(i), bin_v(j), k)
                  if (k .gt. k_max) then
                     k_max = k
                  endif
               endif
            enddo
         endif
      enddo

      return
      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine est_k_avg(n_bin, bin_v, bin_n, kernel, k_avg)
      
      integer n_bin         ! INPUT: number of bins
      real*8 bin_v(n_bin)   ! INPUT: volume of particles in bins (m^3)
      integer bin_n(n_bin)  ! INPUT: number in each bin
C      external kernel       ! INPUT: kernel function
      real*8 k_avg          ! OUTPUT: average kernel value

      interface
         subroutine kernel(v1, v2, k)
         real*8, intent(in) :: v1
         real*8, intent(in) :: v2
         real*8, intent(out) :: k
         end subroutine
      end interface

      real*8 k
      integer i, j, div
      
      k_avg = 0d0
      div = 0
      do i = 1,n_bin
         if (bin_n(i) .gt. 0) then
            do j = 1,n_bin
               if (bin_n(j) .gt. 0) then
                  call kernel(bin_v(i), bin_v(j), k)
                  k_avg = k_avg + k *  dble(bin_n(i)) * dble(bin_n(j))
                  div = div + bin_n(i) * bin_n(j)
               endif
            enddo
         endif
      enddo

      k_avg = k_avg / dble(div)

      return
      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine moments(MM, M, V, V_comp, n_spec,
     &     n_bin, bin_v, bin_r, bin_g, bin_gs, bin_n, dlnr)

      use mod_bin

      integer MM           ! INPUT: physical dimension of V
      integer M            ! INPUT: logical dimension of V
      integer n_spec       ! INPUT: number of species
      real*8 V(MM,n_spec)  ! INPUT: particle volumes (m^3)
      real*8 V_comp        ! INPUT: computational volume (m^3)

      integer n_bin        ! INPUT: number of bins
      real*8 bin_v(n_bin)  ! INPUT: volume of particles in bins (m^3)
      real*8 bin_r(n_bin)  ! INPUT: radius of particles in bins (m)
      real*8 bin_g(n_bin)  ! OUTPUT: total mass in bins    (????)
      real*8 bin_gs(n_bin,n_spec) !OUTPUT: species mass in bins
      integer bin_n(n_bin) ! OUTPUT: number in bins  
      real*8 dlnr          ! INPUT: bin scale factor
      
      integer i, k, j
      real*8 pv

      do k = 1,n_bin
         bin_g(k) = 0d0
         bin_n(k) = 0
         do j=1,n_spec
            bin_gs(k,j) = 0d0
         enddo
      enddo
      do i = 1,M
         call particle_vol(MM,n_spec,V,i,pv)
         call particle_in_bin(pv, n_bin, bin_v, k)
         bin_g(k) = bin_g(k) + pv
         bin_n(k) = bin_n(k) + 1
         do j=1,n_spec
            bin_gs(k,j) = bin_gs(k,j) + V(i,j)
         enddo
      enddo

      end subroutine
      
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine check_event(time, timestep, interval, last_time,
     &     do_event)

      ! Computes whether an event is scheduled to take place. The events
      ! should occur ideally at times 0, interval, 2*interval, etc. The
      ! events are guaranteed to occur at least interval * (1 -
      ! tolerance) apart, and if at least interval time has passed then
      ! the next call is guaranteed to do the event. Otherwise the
      ! timestep is used to guess whether to do the event.

      real*8 time       ! INPUT: current time
      real*8 timestep   ! INPUT: an estimate of the time to the next call
      real*8 interval   ! INPUT: how often the event should be done
      real*8 last_time  ! INPUT/OUTPUT: when the event was last done
      logical do_event  ! OUTPUT: whether the event should be done

      real*8, parameter :: tolerance = 1d-6 ! fuzz for event occurance

      real*8 closest_interval_time

      ! if we are at time 0 then do the event unconditionally
      if (time .eq. 0d0) then
         do_event = .true.
      else
         ! if we are too close to the last time then don't do it
         if ((time - last_time) .lt. interval * (1d0 - tolerance)) then
            do_event = .false.
         else
            ! if it's been too long since the last time then do it
            if ((time - last_time) .ge. interval) then
               do_event = .true.
            else
               ! gray area -- if we are closer than we will be next
               ! time then do it
               closest_interval_time = anint(time / interval) * interval
               if (abs(time - closest_interval_time)
     &              .lt. abs(time + timestep - closest_interval_time))
     &              then
                  do_event = .true.
               else
                  do_event = .false.
               endif
            endif
         endif
      endif

      if (do_event) then
         last_time = time
      endif

      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine particle_vol(MM,n_spec,V,i,pv)

      integer MM           ! INPUT: physical dimension of V
      integer n_spec       ! INPUT: number of species
      real*8 V(MM,n_spec)  ! INPUT: particle volumes (m^3)
      integer i            ! INPUT: particle index
      real*8 pv            ! OUPUT: total volume of particle

!     FIXME: fix callers to just call particle_vol_base directly
      call particle_vol_base(n_spec, V(i,:), pv)

      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine particle_vol_base(n_spec, V, pv)

      integer, intent(in) :: n_spec ! number of species
      real*8, intent(in) :: V(n_spec)  ! particle volumes (m^3)
      real*8, intent(out) :: pv ! total volume of particle

      integer i

      pv = 0d0
      do i = 1,n_spec
         pv = pv + V(i)
      enddo

      end subroutine

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      end module
