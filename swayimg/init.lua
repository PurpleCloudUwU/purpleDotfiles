-- swayimg: colors and font matching Sway, Waybar, fuzzel, mako and kitty
-- (Catppuccin Mocha with the purple accent #b794f6).
-- Colors are 0xAARRGGBB. Only the look is changed, key bindings stay default.
-- Reference: /usr/share/doc/swayimg/CONFIG.md

-- Text overlay (file name, size, scale, EXIF): same font as the rest
swayimg.text.font = "JetBrainsMono Nerd Font"
swayimg.text.size = 18
swayimg.text.color = 0xffcdd6f4
swayimg.text.background = 0xcc1e1e2e   -- dark box behind the text, readable on bright images
swayimg.text.shadow = 0x00000000       -- flat look, no shadow

-- Viewer: dark background, muted chessboard behind transparent images
swayimg.viewer.set_window_background(0xff1e1e2e)
swayimg.viewer.set_image_chessboard(16, 0xff313244, 0xff45475a)
swayimg.viewer.mark_color = 0xffb794f6

-- Slideshow: same as the viewer
swayimg.slideshow.set_window_background(0xff1e1e2e)
swayimg.slideshow.set_image_chessboard(16, 0xff313244, 0xff45475a)
swayimg.slideshow.mark_color = 0xffb794f6

-- Gallery: purple frame around the selected thumbnail, like the focused window in Sway
swayimg.gallery.window_color = 0xff1e1e2e
swayimg.gallery.unselected_color = 0xff181825
swayimg.gallery.selected_color = 0xff313244
swayimg.gallery.border_color = 0xffb794f6
swayimg.gallery.border_size = 3
swayimg.gallery.mark_color = 0xffb794f6
