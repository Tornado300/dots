import re
import subprocess


def qalculate(query):
    # math_symbols = set("+-*/=^%()[]{}<>|&!~0123456789")
    # math_functions = [
        # "sqrt", "sin", "cos", "tan", "log", "exp", "pow", "abs", "asin", "acos", "atan", "sinh", "cosh", "tanh"
    # ]
    # symbol_count = sum(1 for z in query if z in math_symbols)
    # function_count = 0
    # for func in math_functions:
        # function_count += len(re.findall(r'\b' + func + r'\s*\(', query))
    # function_count = sum(len(func) for func in math_functions if func in query)
    # score = symbol_count + function_count
    score = 0
    # qalc = subprocess.run(["qalc", query], text=True, capture_output=True)
    # if "error:" in qalc.stdout:
        # qalc.stdout = "ERROR!"
    qalc = 00000
    # command = f"wl-copy $(qalc -t {query.replace("*", r"\*")})"
    command = None
    return {"entry": {"name":qalc.stdout, "command":command}, "weight": (score / len(query)) * 100 + 40}
