#!/usr/bin/env bash
# App list for the "app" module in config.toml: one line per desktop entry,
# "<desktop id><TAB><Nerd Font icon>  <Name>", sorted by name.
# The icon is picked from the app's id/icon/name, else from its categories.
# User entries come first, so they override system ones with the same id.

dirs=(
    "$HOME/.local/share/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
    /var/lib/flatpak/exports/share/applications
    /usr/local/share/applications
    /usr/share/applications
)

files=()
for d in "${dirs[@]}"; do
    for f in "$d"/*.desktop; do [[ -f $f ]] && files+=("$f"); done
done
((${#files[@]})) || exit 0

# %c with a number prints that Unicode character (needs a UTF-8 locale)
LC_ALL=C.UTF-8 gawk '
function glyph(key, cat) {
    # Specific apps (id, icon or name)
    if (key ~ /firefox|librewolf/)                 return 0xF0239  # md-firefox
    if (key ~ /brave|chrom/)                       return 0xF059F  # md-web
    if (key ~ /nvim|neovim|vim/)                   return 0x0E6AE  # custom-neovim
    if (key ~ /vscodium|vscode/)                   return 0xF0A1E  # md-microsoft_visual_studio_code
    if (key ~ /spotify/)                           return 0xF04C7  # md-spotify
    if (key ~ /vesktop|discord/)                   return 0xF066F  # md-discord
    if (key ~ /chatterino|twitch/)                 return 0xF0543  # md-twitch
    if (key ~ /thunderbird/)                       return 0xF01EE  # md-email
    if (key ~ /mullvad/)                           return 0xF099D  # md-shield_lock
    if (key ~ /claude/)                            return 0xF06A9  # md-robot
    if (key ~ /localsend/)                         return 0xF0497  # md-share_variant
    if (key ~ /obsidian/)                          return 0xF039E  # md-note_text
    if (key ~ /gimp/)                              return 0xF11E3  # md-image_edit
    if (key ~ /writer/)                            return 0xF0219  # md-file_document
    if (key ~ /calc/)                              return 0xF0C7E  # md-file_table
    if (key ~ /impress/)                           return 0xF0428  # md-presentation
    if (key ~ /libreoffice-base/)                  return 0xF01BC  # md-database
    if (key ~ /libreoffice-math/)                  return 0xF00EC  # md-calculator
    if (key ~ /libreoffice-draw|fontforge/)        return 0xF0001  # md-vector_square
    if (key ~ /font/)                              return 0xF06D6  # md-format_font
    if (key ~ /wallpaper|blackhole/)               return 0xF0E09  # md-wallpaper
    if (key ~ /network|nm-connection/)             return 0xF05A9  # md-wifi
    if (key ~ /cmake/)                             return 0xF1323  # md-hammer_wrench
    # Categories
    if (cat ~ /;TerminalEmulator;/)                return 0xF018D  # md-console
    if (cat ~ /;FileManager;/)                     return 0xF024B  # md-folder
    if (cat ~ /;WebBrowser;/)                      return 0xF059F  # md-web
    if (cat ~ /;Email;/)                           return 0xF01EE  # md-email
    if (cat ~ /;InstantMessaging;|;Chat;/)         return 0xF0361  # md-message
    if (cat ~ /;Security;/ || key ~ /bitwarden|keepass/) return 0xF0306  # md-key
    if (cat ~ /;Monitor;/)                         return 0xF0A07  # md-monitor_dashboard
    if (cat ~ /;Printing;/)                        return 0xF042A  # md-printer
    if (cat ~ /;Mixer;/ || key ~ /pwgraph/)        return 0xF057E  # md-volume_high
    if (cat ~ /;Music;/)                           return 0xF075A  # md-music
    if (cat ~ /;Video;|;Player;/)                  return 0xF040C  # md-play_circle
    if (cat ~ /;AudioVideo;|;Audio;/)              return 0xF0FCE  # md-movie_open
    if (cat ~ /;Graphics;/)                        return 0xF02E9  # md-image
    if (cat ~ /;Office;/)                          return 0xF0219  # md-file_document
    if (cat ~ /;Game;/)                            return 0xF0297  # md-gamepad_variant
    if (cat ~ /;Maps;/)                            return 0xF034D  # md-map
    if (cat ~ /;IDE;|;Development;/)               return 0xF0169  # md-code_braces
    if (cat ~ /;Settings;/)                        return 0xF0493  # md-cog
    return 0xF08C6                                                 # md-application
}
BEGINFILE {
    id = FILENAME; sub(/.*\//, "", id); sub(/\.desktop$/, "", id)
    main = 0; name = icon = cat = ""; hidden = 0
}
/^\[/ { main = ($0 == "[Desktop Entry]"); next }
main && /^Name=/       && name == "" { name = substr($0, 6) }
main && /^Icon=/                     { icon = substr($0, 6) }
main && /^Categories=/               { cat = ";" substr($0, 12) }
main && /^(NoDisplay|Hidden)=true/   { hidden = 1 }
ENDFILE {
    # Name first only for sorting, cut off again below
    if (!seen[id]++ && !hidden && name != "")
        printf "%s\t%s\t\033[38;2;190;140;255m%c\033[0m  %s\n", name, id, glyph(tolower(id " " icon " " name), cat), name
}
' "${files[@]}" | sort -f | cut -f2-
