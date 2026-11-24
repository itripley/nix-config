# Each kitty tab has its own background. kitty has one per window, so this changes the window's
# image when the active tab changes (watcher), and for the Alt keys in backgrounds.conf (kitten).
# New tabs take the first image no tab has: backgrounds.py shuffles the list, and kitty loads
# it in order, so this loads one image at a time.
import random

from kittens.tui.handler import result_handler
from kitty.fast_data_types import get_options
from kitty.utils import log_error


def count():
    return len(get_options().background_image or ())


def used(boss, but=None):
    return [t.bg_index for t in boss.all_tabs if t is not but and hasattr(t, "bg_index")]


def seen(boss, index=-1):  # how many images from the start of this list have been shown
    images = get_options().background_image
    last, n = getattr(boss, "bg_seen", (None, 0))
    boss.bg_seen = images, max(n if last == images else 0, index + 1)
    return boss.bg_seen[1]


def show(boss, tm):
    tab = tm.active_tab
    n = count()
    if tab is None or not n:
        return
    if not hasattr(tab, "bg_index"):
        taken = used(boss)
        tab.bg_index = min(range(n), key=taken.count)
        tab.bg_off = False
    seen(boss, tab.bg_index % n)
    want = -1 if tab.bg_off else tab.bg_index % n
    if getattr(tm, "bg_shown", 0) != want:  # a new window shows image 0
        boss.set_background_image(None, (tm.os_window_id,), False, None, global_index=want)
        tm.bg_shown = want


def on_tab_bar_dirty(boss, window, data):  # also called when the active tab changes
    try:
        show(boss, data["tab_manager"])
    except Exception as e:  # kitty doesn't catch it here
        log_error(f"tab_backgrounds.py: {e!r}")


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    tm = boss.active_tab_manager
    tab = tm.active_tab if tm else None
    n = count()
    if tab is None or not n:
        return
    show(boss, tm)  # gives the tab an image if it has none yet
    if args[1] == "off":
        tab.bg_off = True
    else:
        if args[1] == "random":
            taken = used(boss)
            others = [i for i in range(n) if i != tab.bg_index % n]
            free = [i for i in others if i not in taken]
            # One not seen yet, else any that no other tab has
            tab.bg_index = seen(boss) if seen(boss) < n else random.choice(free or others or [0])
        else:
            tab.bg_index = (tab.bg_index + int(args[1])) % n
        tab.bg_off = False
    show(boss, tm)
