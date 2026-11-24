#!/usr/bin/env python3
"""The keys in niri's config, for the manual: JSON [{section, rows: [{label, keys: [[key, ...], ...]}]}].

Read from the files niri reads, so the manual can't fall behind them. Sections are the files'
"// --- Name ---" comments. Media keys are left out; pairs (left/right) and 1-9 become one row.
"""
import json
import os
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from kdl import nodes, tokens

NIRI = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'niri'
# The shell's defaults first: a personal bind for the same keys replaces them
FILES = [(NIRI / 'shell/config.kdl', 'Launcher and lock'), (NIRI / 'cfg/keybinds.kdl', 'Other')]

SECTION = re.compile(r'^[ \t]*//[ \t]*[─-]{2,}[ \t]*(.+?)[ \t]*[─-]{2,}[ \t]*$', re.M)
KEYS = {'mod': 'spr', 'super': 'spr', 'ctrl': 'ctrl', 'control': 'ctrl', 'shift': 'shift', 'alt': 'alt',
        'left': '←', 'right': '→', 'up': '↑', 'down': '↓', 'return': 'enter', 'escape': 'esc', 'delete': 'del',
        'minus': '−', 'equal': '=', 'plus': '+', 'comma': ',', 'period': '.', 'slash': '/', 'space': 'space',
        'wheelscrollup': 'scroll', 'wheelscrolldown': 'scroll', 'wheelscrollleft': 'tilt', 'wheelscrollright': 'tilt'}
OPPOSITES = [('left', 'right'), ('up', 'down'), ('first', 'last')]
# Keys of a folded pair -> what the keycap says
PAIRS = {('left', 'right'): '← →', ('up', 'down'): '↑ ↓', ('home', 'end'): 'home / end',
         ('wheelscrollup', 'wheelscrolldown'): 'scroll', ('wheelscrollleft', 'wheelscrollright'): 'tilt'}
# Where the action's own name reads badly; {d} is "up / down" or "left / right"
LABELS = {
    'focus-window-or-workspace-{d}': 'Focus window or workspace {d}',
    'move-window-{d}-or-to-workspace-{d}': 'Move window {d}, then to the next workspace',
    'move-column-to-{d}': 'Move column to {d}',
    'expand-column-to-available-width': 'Fill the free width',
    'toggle-column-tabbed-display': 'Tabs for this column',
    'toggle-window-floating': 'Float window',
    'fullscreen-window': 'Fullscreen',
    'toggle-keyboard-shortcuts-inhibit': 'Take the keys back from a fullscreen app',
    'power-off-monitors': 'Turn the screens off',
    'toggle-overview': 'Overview',
    'show-hotkey-overlay': "niri's own key list",
    'quit': 'Log out',
}


def unquote(token):
    return json.loads(token) if token.startswith('"') else token


def binds(path, fallback):
    """(section, combo, action, args, title) for every bind in one file."""
    text = path.read_text()
    ts = tokens(text)
    sections = [(m.start(), m.group(1)) for m in SECTION.finditer(text)]
    for first, _, opening, closing in nodes(ts):
        if ts[first][0] != 'binds' or opening is None: continue
        for start, _, inner, end in nodes(ts, opening + 1, closing):
            if inner is None: continue
            title = next((unquote(ts[i + 1][0]) for i in range(start, inner)
                          if ts[i][0] == 'hotkey-overlay-title='), None)
            action = [ts[i][0] for i in range(inner + 1, end) if ts[i][0] not in (';', '\n')]
            if not action: continue
            section = next((name for at, name in reversed(sections) if at < ts[start][1]), fallback)
            yield section, ts[start][0], action[0], [unquote(a) for a in action[1:]], title


def combo(keys):
    """"Mod+CTRL+Left" -> (('ctrl', 'mod'), 'left'); the last part is the key."""
    *mods, key = keys.lower().split('+')
    return tuple(sorted({'super': 'mod', 'control': 'ctrl'}.get(m, m) for m in mods)), key


def caps(mods, key):
    order = ['mod', 'ctrl', 'alt', 'shift']
    return [KEYS.get(m, m) for m in sorted(mods, key=lambda m: order.index(m) if m in order else 9)] + [KEYS.get(key, key)]


def label(action, args, words=None):
    text = LABELS.get(action)
    if text is None:
        text = action.replace('-', ' ')
        if args: text += ' ' + ' '.join(str(a) for a in args)
        text = text[0].upper() + text[1:]
    return text.replace('{d}', words or '')


def pair(one, two):
    """The label of two binds that differ only by direction, or None."""
    if one['mods'] != two['mods'] or one['args'] != two['args'] or one['title'] or two['title']: return None
    for a, b in OPPOSITES:
        for x, y in ((a, b), (b, a)):
            mark = lambda name, word: re.sub(rf'\b{word}\b', '{d}', name)
            if x in one['action'].split('-') and mark(one['action'], x) == mark(two['action'], y):
                words, name = f'{x} / {y}', mark(one['action'], x)
                # Direction in the label's order, keycap in the key's own
                return LABELS.get(name) and label(name, [], words) or label(name.replace('{d}', words), one['args'])
    return None


def main():
    found = {}  # combo -> bind, in file order; a later file replaces the earlier bind in place
    for path, fallback in FILES:
        if not path.exists(): continue
        for section, keys, action, args, title in binds(path, fallback):
            mods, key = combo(keys)
            if key.startswith('xf86'): continue
            found[mods, key] = {'section': section, 'mods': mods, 'key': key, 'action': action, 'args': args, 'title': title}

    sections, pending = {}, list(found.values())
    while pending:
        bind = pending.pop(0)
        rows = sections.setdefault(bind['section'], [])
        same = [b for b in pending if b['section'] == bind['section']]
        # 1-9
        digits = [b for b in same if bind['key'].isdigit() and b['key'].isdigit()
                  and b['mods'] == bind['mods'] and b['action'] == bind['action']]
        if digits:
            pending = [b for b in pending if b not in digits]
            rows.append({'label': label(bind['action'], []), 'keys': [caps(bind['mods'], f"{bind['key']}–{digits[-1]['key']}")]})
            continue
        # Left and right, up and down, ...
        for other in same:
            names = next((n for n in PAIRS if {bind['key'], other['key']} == set(n)), None)
            text = names and pair(bind, other)
            if text:
                pending.remove(other)
                rows.append({'label': text, 'keys': [caps(bind['mods'], PAIRS[names])]})
                break
        else:
            # The same action on other keys
            alike = [b for b in same if (b['action'], b['args']) == (bind['action'], bind['args'])]
            pending = [b for b in pending if b not in alike]
            rows.append({'label': bind['title'] or label(bind['action'], bind['args']),
                         'keys': [caps(b['mods'], b['key']) for b in [bind, *alike]]})
    print(json.dumps([{'section': s, 'rows': r} for s, r in sections.items()], ensure_ascii=False))


if __name__ == '__main__':
    main()
