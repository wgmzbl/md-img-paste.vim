import clipboard
import sys

text = clipboard.paste()
print(sys.argv[1])
if "<svg" in text:
    myFile = open(sys.argv[1], 'w')
    myFile.write(text)
    myFile.close()
    print('done')

