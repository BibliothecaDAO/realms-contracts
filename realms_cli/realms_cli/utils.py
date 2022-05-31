from typing import List

def print_over_colums(array_of_strings, cols=2, width=40):
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

def parse_multi_input(cli_input) -> List:
    """Parse input and check for multiple args
    
    1-4   -> [1,2,3,4]
    1,2,5 -> [1,2,5]
    1     -> [1]

    Returns
        List of args
    """
    if "-" in cli_input:
        low, high = cli_input.split("-")
        return list(range(int(low), int(high)+1))
    if "," in cli_input:
        words = cli_input.split(",")
        return words
    return [cli_input]
