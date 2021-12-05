import clipboard
from collections.abc import Iterable
text = clipboard.paste()
if isinstance(text,Iterable):
    print('start')
    if "<svg" in text:
        print('done')


bbc

bbc

