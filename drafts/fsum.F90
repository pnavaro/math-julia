function f_sum(n, x) result(s) bind(C, name="f_sum")
    use, intrinsic :: iso_c_binding, only: c_int, c_double
    implicit none
    integer(c_int) :: n
    real(c_double) :: x(n)    
    real(c_double) :: s
    integer    :: i

    s = 0.0
    do i = 1, n
      s = s + x(i)
    end do

end function f_sum
