#!/bin/bash

# Counter variables
profile_counter=1
gemini_counter=1
webp_counter=1
video_counter=1

# Function to pad numbers with zeros
pad_number() {
    printf "%03d" $1
}

# Move and rename files
for file in *; do
    # Skip the script itself and tmp directory
    if [[ "$file" == "rename.sh" ]] || [[ "$file" == "tmp" ]]; then
        continue
    fi

    # Get file extension in lowercase
    ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    # Determine new name based on file type and content
    if [[ "$file" == *"webp"* ]]; then
        new_name="aygp_webp_$(pad_number $webp_counter).$ext"
        ((webp_counter++))
    elif [[ "$file" == *"Gemini"* ]]; then
        new_name="aygp_gemini_$(pad_number $gemini_counter).$ext"
        ((gemini_counter++))
    elif [[ "$file" == *".mp4" ]]; then
        new_name="aygp_video_$(pad_number $video_counter).$ext"
        ((video_counter++))
    else
        new_name="aygp_profile_$(pad_number $profile_counter).$ext"
        ((profile_counter++))
    fi

    # Move file to tmp directory with new name
    mv "$file" "tmp/$new_name"
done

# Move files back from tmp
mv tmp/* .
rmdir tmp
