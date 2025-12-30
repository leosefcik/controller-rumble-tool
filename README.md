# controller-rumble-tool
 A Godot app for controlling the rumble motors of a gamepad.
 
 Godot version: 4.5.1
 
## Controller Rumble Tool
 (Gamepad Vibration Massager)

 Credits:
 - Cabin Font - https://github.com/impallari/Cabin
 - Glyphs - https://kenney.nl/assets/input-prompts
 - Icons - https://fonts.google.com/icons
 - Godot 4.5.1, Blender 5.0.1

 GitHub: https://github.com/leosefcik/controller-rumble-tool
 
 Itch.io: https://leosefcik.itch.io/controller-rumble-tool

 Made by leosefcik 2025-2026
 
 https://eggsandchickens.info

 Warning: We are not responsible for any damage that may be caused to you or your controller. Be mindful of excessive vibrations and battery drain.
 
## Export template
 To achieve a smaller export size, I compiled an export template using the following command:
 
 Linux:
 `scons platform=linuxbsd arch=x86_64 production=yes target=template_release debug_symbols=no optimize=size_extra lto=full disable_3d=yes vulkan=no use_volk=no openxr=no disable_navigation_2d=yes disable_navigation_3d=yes disable_xr=yes module_text_server_adv_enabled=no module_text_server_fb_enabled=yes minizip=no`
 
 Windows:
 `scons platform=windows arch=x86_64 production=yes target=template_release debug_symbols=no optimize=size_extra lto=full disable_3d=yes vulkan=no use_volk=no openxr=no disable_navigation_2d=yes disable_navigation_3d=yes disable_xr=yes module_text_server_adv_enabled=no module_text_server_fb_enabled=yes minizip=no`
 
 This brought the binary size (for Linux at least) from 68.2MiB to 26.5MiB! That's fine enough.
 
 Resources used:
 - https://popcar.bearblog.dev/how-to-minify-godots-build-size/
 - https://docs.godotengine.org/en/4.4/contributing/development/compiling/optimizing_for_size.html
