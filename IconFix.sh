echo "Cleaning up apps..."
wget -q -O ~/.local/share/icons/steam_fix.svg https://upload.wikimedia.org/wikipedia/commons/8/83/Steam_icon_logo.svg
# List of apps we want to hide
find /usr/share/applications -name "*steam*.desktop" | while read -r file; do
    fileName=$(basename "$file")
    fileNewHome="$HOME/.local/share/applications/$fileName"

    cp "$file" "$fileNewHome"

    sed -i "s|^Icon=.*|Icon=$HOME/.local/share/icons/steam_fix.svg|" "$fileNewHome"
    sed -i "s|^Name=.*|Name=Steam|" "$fileNewHome"

    touch "$fileNewHome"
done

find /usr/share/applications \( -name "xterm.desktop" -o -name "uxterm.desktop" \) | while read -r file; do
    fileName=$(basename "$file")
    fileNewHome="$HOME/.local/share/applications/$fileName"
    cp "$file" "$fileNewHome"

    sed -i '/^NoDisplay=/d' "$fileNewHome"
    echo "NoDisplay=true" >> "$fileNewHome"

    touch "$fileNewHome"
done
