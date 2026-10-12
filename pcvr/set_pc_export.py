"""CI only: prepares a normal PC build that does not start OpenXR/Vulkan.

Run after producing the VR executable. The checkout's local config is the
VR baseline; GitHub Actions gets a disposable copy and changes it in-place.
"""
from pathlib import Path

config = Path(__file__).with_name("project.godot")
text = config.read_text(encoding="utf-8")
from_name = 'config/name="Ile Manga VR V5"'
from_xr = 'openxr/enabled=true'
assert text.count(from_name) == 1, "VR project name missing or ambiguous"
assert text.count(from_xr) == 1, "OpenXR setting missing or ambiguous"
text = text.replace(from_name, 'config/name="Ile Manga PC V5"')
text = text.replace(from_xr, 'openxr/enabled=false')
config.write_text(text, encoding="utf-8")
print("PC CLASSIQUE : OpenXR desactive dans l'export Windows PC")
