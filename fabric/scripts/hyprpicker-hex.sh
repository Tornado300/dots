#!/bin/bash


# Convert RGB to HSV and Hex
rgb_convert() {
    local R=$1
    local G=$2
    local B=$3

    # Input validation
    for val in $R $G $B; do
        if [[ $val -lt 0 || $val -gt 255 ]]; then
            echo "Error: RGB values must be between 0-255"
            exit 1
        fi
    done

    # RGB to Hex conversion
    hex=$(printf "#%02x%02x%02x" "$R" "$G" "$B")
 
    # RGB to HSV conversion
    r=$(echo "scale=4; $R/255" | bc)
    g=$(echo "scale=4; $G/255" | bc)
    b=$(echo "scale=4; $B/255" | bc)

    # notify-send "" "$(echo "scale=4; v=$r; if ($g > v) v=$g; if ($b > v) v=$b; v" | bc | xargs printf '%.4f' | tr "," ".")"

    max=$(echo "scale=4; v=$r; if ($g > v) v=$g; if ($b > v) v=$b; v" | bc | xargs printf "%.4f" | tr "," ".")
    min=$(echo "scale=4; v=$r; if ($g < v) v=$g; if ($b < v) v=$b; v" | bc | xargs printf "%.4f" | tr "," ".")
    delta=$(echo "$max - $min" | bc)
    # notify-send "" "$max - $min = $delta"

    # Value calculation
    v=$max

    # Saturation calculation
    if (( $(echo "$max == 0" | bc) )); then
        s=0
	# notify-send "" "00000!!!!!"
    else
        s=$(echo "scale=4; $delta / $max" | bc)
	notify-send "" "$s"
    fi

    # Hue calculation
    if (( $(echo "$delta == 0" | bc) )); then
        h=0
    else
	# notify-send "" "$r $g $b $delta"
        case $max in
            $r) h=$(echo "scale=4; 60 * (($g - $b)/$delta)" | bc);;
            $g) h=$(echo "scale=4; 60 * (2 + ($b - $r)/$delta)" | bc);;
            $b) h=$(echo "scale=4; 60 * (4 + ($r - $g)/$delta)" | bc);;
        esac
	# notify-send "" "$(echo "scale=4; 60 * (($g - $b)/$delta)" | bc)"
	# notify-send "" "$(echo "scale=4; 60 * (2 + ($b - $r)/$delta)" | bc)"
	# notify-send "" "$(echo "scale=4; 60 * (4 + ($r - $g)/$delta)" | bc)"
	notify-send "" "$h"
    	if (( $(echo "$h == 0" | bc) )); then
            h=$(echo "$h + 360" | bc)
        fi
    fi
    # notify-send "" "$h $s $v"
    # Format HSV output
    hsv=$(printf "%.1f,%.2f,%.2f" "$h" "$s" "$v" | tr "," ".")
    # notify-send "" "$hsv"
    # Display results
    echo "Hex: $hex"
    echo "HSV: $hsv"
}

# Execute hyprpicker and save the output to a variable
hyprpicker -a -n -f rgb && sleep 0.1

# Create a temporal 64x64 PNG file with the color in /tmp using convert
magick -size 64x64 xc:"rgb($(wl-paste))" /tmp/color.png

old_IFS="${IFS-}"
IFS=' ' read -r R G B <<< $(wl-paste)
IFS="$old_IFS"


result=$(rgb_convert "$R" "$G" "$B")
hex=$(echo "$result" | grep -oP '#\K[0-9a-fA-F]{6}')
hsv_values=$(echo "$result" | grep -oE '[0-9]{1,3},')
h=$(echo "$hsv_values" | awk 'NR==1' | tr -d '°' | tr ',' '.')
s=$(echo "$hsv_values" | awk 'NR==2' | tr ',' '.')
v=$(echo "$hsv_values" | awk 'NR==3' | tr ',' '.')
notify-send "$result" "$hsv_values"

hex=$(grep '^Hex' <<< "$results" | cut -d' ' -f2)
H=$(grep '^Hsv' <<< "$results" | cut -d' ' -f2)
S=$(grep '^Hsv' <<< "$results" | cut -d' ' -f3)
V=$(grep '^Hsv' <<< "$results" | cut -d' ' -f4)

rgb="$R,$G,$B"
hsv="$H,$S,$V"
# notify-send "HEX color picked" "$(wl-paste)" -i /tmp/color.png -a "Hyprpicker"


 # notify-send "HEX:        RGB:             HSV:" "#$hex   $rgb    $hsv" -i /tmp/color.png -a "Hyprpicker"


# Remove the temporal file
rm /tmp/color.png

# Exit
exit 0
