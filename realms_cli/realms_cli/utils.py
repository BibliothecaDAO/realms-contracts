def print_over_colums(array_of_strings, cols=3, width=30):
    ans = ""
    for i, s in enumerate(array_of_strings):
        factor = i%cols
        if factor == 0:
            ans += "\n"
        ans += f"| {s.ljust(width)} "
    print(ans)
