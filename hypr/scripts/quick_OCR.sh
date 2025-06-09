#!/usr/bin/env python3
import subprocess
import tempfile
import easyocr

def group_lines(result, y_threshold=10):
    # Sort boxes by top y coordinate
    result.sort(key=lambda r: r[0][0][1])  # top-left y of the box
    lines = []
    current_line = []
    last_y = None

    for bbox, text, _ in result:
        y = bbox[0][1]
        if last_y is None or abs(y - last_y) < y_threshold:
            current_line.append((bbox[0][0], text))  # left x, text
        else:
            # Sort current line by x, then append
            current_line.sort()
            lines.append(" ".join(t for _, t in current_line))
            current_line = [(bbox[0][0], text)]
        last_y = y

    # Final line
    if current_line:
        current_line.sort()
        lines.append(" ".join(t for _, t in current_line))

    return lines

# Take screenshot
with tempfile.NamedTemporaryFile(suffix=".png") as tmp:
    region = subprocess.check_output(["slurp"]).decode().strip()
    subprocess.run(["grim", "-g", region, tmp.name])

    # Run OCR
    reader = easyocr.Reader(['en'], gpu=False)
    raw_result = reader.readtext(tmp.name)

    # Group text into lines
    lines = group_lines(raw_result)

    # Join lines and copy to clipboard
    text = "\n".join(lines)
    subprocess.run(["wl-copy"], input=text.encode("utf-8"))

