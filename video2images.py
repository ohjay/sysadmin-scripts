#!/usr/bin/env python

import os
import cv2
import numpy as np
from scipy.misc import imresize
from scipy.signal import medfilt

### Parameters (you should edit these)
output_folder = '.'
video_path = 'angrywalk.mp4'
### ----------------------------------

def get_fps(capture):
    if int((cv2.__version__).split('.')[0]) < 3:
        return capture.get(cv2.cv.CV_CAP_PROP_FPS)
    else:
        return capture.get(cv2.CAP_PROP_FPS)

def output_path(basename):
    return os.path.join(output_folder, basename)

def segment(im):
    """(Simple) segmentation mask extraction.
    Subtract the median, then apply a median filter.
    Might do the trick if the background is all one color.
    """
    mask = np.abs(im - np.median(im)).astype(np.bool)
    mask = mask.astype(np.float) * 255.0
    mask = medfilt(mask, kernel_size=5)
    mask = np.all(mask == [255, 255, 255], axis=-1)
    return mask.astype(np.float) * 255.0

# Extract frames from video
capture = cv2.VideoCapture(video_path)

# Determine the frame rate
fps = get_fps(capture)
print('[o] Processing frames from %r FPS video...' % fps)

num_frames = 0
success = True
while success:
    success, frame = capture.read()
    if success:
        # Process frame here
        # e.g. resize, crop, segment, ...
        smask = segment(frame)

        # Write output(s)
        cv2.imwrite(output_path('frame%d.jpg' % num_frames), frame)
        cv2.imwrite(output_path('smask%d.jpg' % num_frames), smask)
        num_frames += 1
print('[+] Processed %r frames from `%s`.' % (num_frames, video_path))
