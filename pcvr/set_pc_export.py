"""Prepare the non-VR Windows export without tying the check to a version number."""
from pathlib import Path
import re

config = Path(__file__).with_name("project.godot")
text = config.read_text(encoding="utf-8")
pattern = r'config/name="[^"]+ VR V[0-9]+"'
assert len(re.findall(pattern, text)) == 1, "Expected one '<titre> VR V<n>' project name"
assert text.count("openxr/enabled=true") == 1, "Expected one enabled OpenXR setting"
text = re.sub(pattern, lambda m: m.group(0).replace(" VR V", " PC V"), text, count=1)
text = text.replace("openxr/enabled=true", "openxr/enabled=false", 1)
config.write_text(text, encoding="utf-8")
print("PC CLASSIQUE : OpenXR desactive dans le projet Godot")
