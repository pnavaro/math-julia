subroutine sumvec(vec, nlen, update)
    use iso_c_binding
    implicit none

    integer(c_int), intent(in)  :: nlen(1)
    real(c_double), intent(in)  :: vec(nlen(1))
    real(c_double), intent(out) :: update(1)

    update(1) = SUM(vec)

    !print *, "sizeof(vec(1))    = ", sizeof(vec(1))
    !print *, "sizeof(nlen)      = ", sizeof(nlen)
    !print *, "sizeof(update(1)) = ", sizeof(update(1))
    !print *, "sum(vec)          = ", update(1)
end subroutine sumvec
