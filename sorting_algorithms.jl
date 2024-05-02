# -*- coding: utf-8 -*-
# ref https://www.clcoding.com/2024/04/sorting-algorithms-using-python.html


# +
function selection_sort(arr)

    n = length(arr)

    for i in 1:n

        min_idx = i

        for j in i+1:n

            if arr[j] < arr[min_idx]

                min_idx = j
            end

        end

        arr[i], arr[min_idx] = arr[min_idx], arr[i]

    end

    return arr

end
# -

# Example usage:

arr = [64, 34, 25, 12, 22, 11, 90]

println("Original array:", arr)

sorted_arr = selection_sort(arr)

println("Sorted array:", sorted_arr)

# +
function quick_sort(arr)

    length(arr) <= 1 && return arr

    pivot = arr[length(arr) ÷ 2]

    left = [x for x in arr if x < pivot]

    middle = [x for x in arr if x == pivot]

    right = [x for x in arr if x > pivot]

    return vcat(quick_sort(left), middle, quick_sort(right))

end
# -

# Example usage:

arr = [64, 34, 25, 12, 22, 11, 90]

println("Original array:", arr)

sorted_arr = quick_sort(arr)

println("Sorted array:", sorted_arr)

# +
function bubble_sort(arr)

    n = length(arr)

    for i in 1:n, j in 1:n-i-1

        if arr[j] > arr[j+1]
            arr[j], arr[j+1] = arr[j+1], arr[j]
        end
        
    end

    return arr

end
# -

# Example usage:

arr = [64, 34, 25, 12, 22, 11, 90]

println("Original array:", arr)

sorted_arr = bubble_sort(arr)

println("Sorted array:", sorted_arr)

# +
function insertion_sort(arr)

    for i in 2:length(arr)

        key = arr[i]

        j = i - 1

        while j >= 1 && key < arr[j]

            arr[j + 1] = arr[j]

            j -= 1
        end

        arr[j + 1] = key

    end

    return arr

end
# -

# Example usage:

arr = [64, 34, 25, 12, 22, 11, 90]

println("Original array:", arr)

sorted_arr = insertion_sort(arr)

println("Sorted array:", sorted_arr)




