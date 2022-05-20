def print_over_colums(array_of_strings, cols=3, width=50):
    """Takes in an array of strings and prints the content over a
     number of colums."""
    ans = ""
    for i, text in enumerate(array_of_strings):
        if i%cols == 0:
            ans += "\n"
        ans += f"| {text.ljust(width)} "
    print(ans)

def uint(a):
    return(a, 0)