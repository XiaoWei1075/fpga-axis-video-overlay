#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import os
import glob

def load_raw_frame(filepath):
    """Load a single 256x256x3 RGB frame from .raw file."""
    try:
        data = np.fromfile(filepath, dtype=np.uint8)
        if len(data) < 256 * 256 * 3:
            padded = np.zeros(256 * 256 * 3, dtype=np.uint8)
            padded[:len(data)] = data
            data = padded
        else:
            data = data[:256*256*3]
        return data.reshape((256, 256, 3))
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return np.zeros((256, 256, 3), dtype=np.uint8)

def main():
    outdata_dir = "/home/xiaowei/Vivado_Projects/image_filter/OutData"
    
    # Find all .raw files and sort by frame number
    raw_files = sorted(glob.glob(os.path.join(outdata_dir, "*.raw")))
    if not raw_files:
        print(f"No .raw files found in {outdata_dir}")
        return
    
    # Load all frames
    frames = [load_raw_frame(f) for f in raw_files]
    
    # Create figure and axis
    fig, ax = plt.subplots(figsize=(8, 8))
    im = ax.imshow(frames[0])
    
    frame_index = [0]  # Use list to allow modification in nested function
    
    def update(frame):
        """Update function for animation."""
        frame_index[0] = frame
        im.set_array(frames[frame])
        return [im]
    
    # Create animation: 10 fps = 100ms per frame
    anim = animation.FuncAnimation(
        fig, update,
        frames=len(frames),
        interval=100,  # 100ms per frame -> 10 fps
        blit=True,
        repeat=True
    )
    
    plt.show()

if __name__ == "__main__":
    main()
