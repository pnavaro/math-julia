# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.4'
#       jupytext_version: 1.2.2
#   kernelspec:
#     display_name: Julia 1.0.0
#     language: julia
#     name: julia-1.0
# ---

# # Loops
#
# Topics:
# 1. `while` loops
# 2. `for` loops
# <br>
#
# ## while loops
#
# The syntax for a `while` is
#
# ```julia
# while *condition*
#     *loop body*
# end
# ```
#
# For example, we could use `while` to count or to iterate over an array.

n = 0
while n < 10
    n += 1
    println(n)
end
n

# +
myfriends = ["Ted", "Robyn", "Barney", "Lily", "Marshall"]

i = 1
while i <= length(myfriends)
    friend = myfriends[i]
    println("Hi $friend, it's great to see you!")
    i += 1
end
# -

# ## for loops
#
# The syntax for a `for` loop is
#
# ```julia
# for *var* in *loop iterable*
#     *loop body*
# end
# ```
#
# We could use a for loop to generate the same results as either of the examples above:

for n in 1:10
    println(n)
end

# +
myfriends = ["Ted", "Robyn", "Barney", "Lily", "Marshall"]

for friend in myfriends
    println("Hi $friend, it's great to see you!")
end
# -

# Now let's use `for` loops to create some addition tables, where the value of every entry is the sum of its row and column indices. <br>
#
# First, we initialize an array with zeros.

m, n = 5, 5
A = fill(0, (m, n))

for i in 1:m
    for j in 1:n
        A[i, j] = i + j
    end
end
A

# Here's some syntactic sugar for the same nested `for` loop

B = fill(0, (m, n))

for i in 1:m, j in 1:n
    B[i, j] = i + j
end
B

# The more "Julia" way to create this addition table would have been with an *array comprehension*.

C = [i + j for i in 1:m, j in 1:n]

# ### Exercises
#
# #### 4.1 
# Loop over integers between 1 and 100 and print their squares.



# #### 4.2 
# Add to the code above a bit to create a dictionary, `squares` that holds integers and their squares as key, value pairs such that
#
# ```julia
# squares[10] == 100
# ```



# + {"deletable": false, "editable": false, "hide_input": true, "nbgrader": {"checksum": "3e96c8051261bb7e0da6df69d54fbe89", "grade": true, "grade_id": "cell-54834a2e4e122b70", "locked": true, "points": 1, "schema_version": 1, "solution": false}}
@assert squares[10] == 100
@assert squares[11] == 121
# -

# #### 4.3 
# Use an array comprehension to create an an array `squares_arr` that stores the squares for all integers between 1 and 100.



# + {"deletable": false, "editable": false, "hide_input": true, "nbgrader": {"checksum": "f0331aaa26a8ec9bc2e637073115083c", "grade": true, "grade_id": "cell-17d4631c51b8b4f7", "locked": true, "points": 1, "schema_version": 1, "solution": false}}
@assert length(squares_arr) == 100
@assert sum(squares_arr) == 338350
# -

# Please click on `Validate` on the top, once you are done with the exercises.
