-- swayimg: colors and font matching Sway, Waybar, fuzzel, mako and kitty
-- (Catppuccin Mocha with the purple accent #be8cff).
-- Colors are 0xAARRGGBB. Only the look is changed, key bindings stay default.
-- Reference: /usr/share/doc/swayimg/CONFIG.md

-- Text overlay (file name, size, scale, EXIF): same font as the rest
swayimg.text.font = "JetBrainsMono Nerd Font"
swayimg.text.size = 18
swayimg.text.color = 0xfff0d7ff
swayimg.text.background = 0xcc0f0b14   -- dark box behind the text, readable on bright images
swayimg.text.shadow = 0x00000000       -- flat look, no shadow

-- Viewer: dark background, muted chessboard behind transparent images
swayimg.viewer.set_window_background(0xff0f0b14)
swayimg.viewer.set_image_chessboard(16, 0xff22192e, 0xff332645)
swayimg.viewer.mark_color = 0xffbe8cff

-- Slideshow: same as the viewer
swayimg.slideshow.set_window_background(0xff0f0b14)
swayimg.slideshow.set_image_chessboard(16, 0xff22192e, 0xff332645)
swayimg.slideshow.mark_color = 0xffbe8cff

-- Gallery: purple frame around the selected thumbnail, like the focused window in Sway
swayimg.gallery.window_color = 0xff0f0b14
swayimg.gallery.unselected_color = 0xff0b080f
swayimg.gallery.selected_color = 0xff22192e
swayimg.gallery.border_color = 0xffbe8cff
swayimg.gallery.border_size = 3
swayimg.gallery.mark_color = 0xffbe8cff
