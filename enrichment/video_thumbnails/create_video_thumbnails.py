import os
import subprocess

from converter import Converter


def main(args):
    NUM_THUMBS = args["num_thumbs"]
    FFMPEG_PATH = "ffmpeg"

    record = args["url_id"].split(",")

    if record == []:
        exit(0)

    url, material_id = record[0].strip(), record[1].strip()

    c = Converter()

    info = c.probe(url)
    duration = info.format.duration  # duration in seconds

    thumbnail_duration = round(duration / NUM_THUMBS, 1)

    # generate folder
    dir_name = os.path.join(args["output_dir"], str(material_id))
    print(dir_name)

    if not os.path.exists(dir_name):  # if no dir, make one
        os.mkdir(dir_name)

    # generate each frame
    for frame_id in range(NUM_THUMBS):
        pic_name = os.path.join(dir_name, "thumb_{}.jpg".format(frame_id))

        if os.path.exists(pic_name):  # if thumbnail exists: move on
            print("{} exists !! moving on...".format(pic_name))
            continue

        time_point = min((frame_id + 1) * thumbnail_duration, duration)

        cmd = [FFMPEG_PATH, '-y', '-loglevel', 'warning', '-i', url, '-s', '332x175', '-ss', str(time_point),
               '-frames:v', '1',
               pic_name]

        subprocess.call(cmd)
        print("{} thumbnail created".format(pic_name))


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Proceess text to extract the most important bits')
    parser.add_argument('--url-id', required=True, type=str, help='url, material_id seperated by a comma')
    parser.add_argument('--output-dir', required=True, type=str, help='column name of the field with text')
    parser.add_argument('--num-thumbs', default=100, type=int, help='number of thumbnails')

    args = vars(parser.parse_args())
    main(args)
