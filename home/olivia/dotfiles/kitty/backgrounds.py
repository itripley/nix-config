# kitty's background images: WezTerm's (dotfiles/wezterm/backdrops), in random order. kitty sorts
# them by name and starts with the first, so this makes numbered links, one folder per
# process and reload.
# A normal image hides background_opacity, so these are see-through copies (ImageMagick, cached).
import os
import random
import shutil
import subprocess
from pathlib import Path

STRENGTH = 4  # how strong the images are, in % (WezTerm dims them by 0.96)

SUFFIXES = (".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tif", ".tiff")
images = [
    f
    for f in (Path(__file__).resolve().parent.parent / "wezterm/backdrops").iterdir()
    if f.suffix.lower() in SUFFIXES
]
cache = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "kitty-backgrounds"
magick = shutil.which("magick")


def see_through(f):
    out = cache / f"{f.stem}-{int(f.stat().st_mtime)}-{STRENGTH}.png"
    if not out.exists() and magick:
        cache.mkdir(parents=True, exist_ok=True)
        tmp = out.with_suffix(f".{os.getpid()}.tmp")
        # fmt: off
        done = subprocess.run([
            magick, f"{f}[0]", "-auto-orient", "-resize", "2560x2560>", "-alpha", "set",
            "-channel", "A", "-evaluate", "set", f"{STRENGTH}%", "+channel",
            "-define", "png:compression-level=1", f"PNG32:{tmp}",
        ], capture_output=True)
        # fmt: on
        if done.returncode == 0:
            tmp.rename(out)
        else:
            tmp.unlink(missing_ok=True)
    return out if out.exists() else None


links = [c for c in map(see_through, images) if c]
if not links:  # no ImageMagick and nothing cached: plain images, dimmed by kitty, no blur
    links = images
    print(f"background_tint {1 - STRENGTH / 100}")
if links and os.environ.get("XDG_RUNTIME_DIR"):
    base = Path(os.environ["XDG_RUNTIME_DIR"]) / "kitty-backgrounds"
    base.mkdir(mode=0o700, exist_ok=True)
    previous = set()
    for old in base.iterdir():  # this process's last list, and closed processes
        pid = old.name.partition("-")[0]
        if not Path("/proc", pid).exists() or pid == str(os.getpid()):
            if pid == str(os.getpid()):
                previous |= {f.resolve() for f in old.glob("000.*")}
            shutil.rmtree(old, ignore_errors=True)
    # A new name each time, so a reload never reuses images kitty already loaded
    here = base / f"{os.getpid()}-{random.randrange(10**9)}"
    here.mkdir()
    random.shuffle(links)
    links.sort(key=lambda f: f.resolve() in previous)  # not the same one first again
    for i, f in enumerate(links):
        (here / f"{i:03}{f.suffix}").symlink_to(f)
    print(f"background_image {here}/*")
