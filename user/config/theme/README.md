# Theme Manager

## Sets
- `$HOME/.profile` contains ABYSS\_THEME
- swww background 
- niri borders
- eww colors
- foot colors
- GTK mouse
- GTK light/dark theme
- GTK icon set

## Usage
- [ ] `./theme-manager.sh
    - [ ] Sets `swww img $HOME/.config/theme/$ABYSS\_THEME/wallpaper.\*`
    - [ ] Niri uses already $ABYSS\_THEME to load correct colors
    - [ ] eww uses already $ABYSS\_THEME to load correct colors
    - [ ] foot uses already $ABYSS\_THEME to load correct colors
    - [ ] export GTK3_CONFIG, GTK_THEME, GTK_ICONS to the proper path

Should:
- [ ] Start with niri
- [ ] Initialize swww-daemon and eww-daemon
- [ ] Load $THEME background
- [ ] Allow `./theme/manager.sh new-theme` to change theme
    - [ ] Update swww img to corresponding theme
    - [ ] Update c
