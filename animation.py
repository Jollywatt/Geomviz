import time
import socket
from math import sin, cos

from client import send_object

def frame(t):
    t *= 2
    r = 0.1*sin(t/2)

    a = (r*cos(3*t), r*sin(3*t), sin(t/2))

    return {
        "Simple Point": [
            (cos(t), sin(t), 0),
            a,
        ],
        "Arrow Vector": [
            a,
            (2*cos(t/3), sin(t/2), cos(t*4/7)),
        ]
    }

def main(fps=10, port=8888):

    t = time.time()

    while True:
        next_frame = t + 1/fps
        send_object(frame(t), show_response=False)
        t = time.time()
        time.sleep(max(0, next_frame - t))

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--fps", default=10, type=int)
    parser.add_argument("--port", default=8888, type=int)
    args = parser.parse_args()

    main(fps=args.fps, port=args.port)