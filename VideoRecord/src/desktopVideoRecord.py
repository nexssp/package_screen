# Nexss PROGRAMMER 2.0.0 - Python3
# Default template for JSON Data

import tkinter as tk
from moviepy.editor import VideoFileClip
import cv2
import numpy as np
from PIL import ImageGrab
import platform
import json
import sys
# STDIN
NexssStdin = sys.stdin.read()

parsedJson = json.loads(NexssStdin)
# Modify Data
# parsedJson["PythonOutput"] = "Hello from Python! " + \
#     str(platform.python_version())

# parsedJson["test"] = "test"
# Output messages are written through stderr: https://github.com/nexssp/cli/wiki/Nexss-Programmer-Cheat-sheet#messages-and-errors
sys.stderr.write(
    "NEXSS/info: Press q to quit (if full screen recording - move mouse to the total right and q)\n")
    
# Checked on Windows 10
# Press q to quit (if full screen recording - move mouse to the total rightq)
# fourcc = cv2.VideoWriter_fourcc(*'XVID')
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
# fourcc = cv2.VideoWriter_fourcc(*'XVID')

filename = str(parsedJson["start"]) + '_test.avi'
path = parsedJson["cwd"] + '/' + filename
if 'file' in parsedJson:
    filename = parsedJson["file"]

X1 = 0
if 'X1' in parsedJson:
    X1 = parsedJson["X1"]

Y1 = 0
if 'Y1' in parsedJson:
    Y1 = parsedJson["Y1"]

root = tk.Tk()
width = root.winfo_screenwidth()
height = root.winfo_screenheight()

# if there is no params it will make whole screen size.

X2 = width
if 'X2' in parsedJson:
    X2 = parsedJson["X2"]
Y2 = height
if 'Y2' in parsedJson:
    Y2 = parsedJson["Y2"]

# save image sequence
# os.system("ffmpeg -r 1 -i img%01d.png -vcodec mpeg4 -y movie.mp4")

# Video will be not written if the size of grab is different then writer size as below.
vid = cv2.VideoWriter(path, fourcc, 25, (X2 - X1, Y2 - Y1))

moved = False

while(True):
    # bbox specifies specific region (bbox= x,y,width,height)
    img = ImageGrab.grab(bbox=(X1, Y1, X2, Y2))
    img_np = np.array(img)
    # frame = cv2.cvtColor(img_np, cv2.COLOR_BGR2GRAY)

    vid.write(img_np)

    cv2.imshow("test", img_np)
    if(not moved or (cv2.waitKey(25) & 0xFF == ord('w'))):
        cv2.moveWindow("test", X2, Y1)
        moved = True

    if cv2.waitKey(25) & 0xFF == ord('q'):
        vid.release()
        cv2.destroyAllWindows()
        my_clip = VideoFileClip(path)
        parsedJson['fps'] = my_clip.fps
        parsedJson['file'] = filename
        break

NexssStdout = json.JSONEncoder().encode(parsedJson)
# STDOUT
sys.stdout.write(NexssStdout)
