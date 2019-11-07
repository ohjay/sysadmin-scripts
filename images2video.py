#!/usr/bin/env python

import os
import imageio
import argparse
import cv2
import numpy as np
from scipy.misc import imresize

def write_video(images_dir, out_path, fps, out_width, out_height):
    fourcc = cv2.VideoWriter_fourcc('m', 'p', '4', 'v')
    out = cv2.VideoWriter()
    size = (out_width, out_height)
    success = out.open(out_path, fourcc, fps, size, True)
    if not success:
        print('[-] Failed to open the video writer.')
        return
    
    for i, frame_name in enumerate(sorted(os.listdir(images_dir))):
        if i % 10 == 0:
            print('[o] Writing frame %d.' % i)
        frame_path = os.path.join(images_dir, frame_name)
        frame = imageio.imread(frame_path)
        frame = frame[:, :, ::-1]  # RGB -> BGR
        if frame.dtype in (np.float, np.float64):
            frame = (np.clip(frame, 0, 1) * 255).astype(np.uint8)
        out.write(frame)
    out.release()
    print('[+] Finished writing video to %s.' % out_path)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('images_dir', type=str, help='directory containing images to write')
    parser.add_argument('--out_path', '-o', type=str, default='out.mov')
    parser.add_argument('--fps', type=int, default=30)
    parser.add_argument('--out_width', type=int, default=400)
    parser.add_argument('--out_height', type=int, default=400)
    args = parser.parse_args()
    write_video(args.images_dir, args.out_path, args.fps, args.out_width, args.out_height)
