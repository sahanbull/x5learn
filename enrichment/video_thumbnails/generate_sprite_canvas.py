from PIL import Image
import os, math


def main(args):
    max_frames_row = 10.0
    frames = []

    material_id = os.path.basename(os.path.normpath(args["folder_path"]))

    file_ids = [int(i.replace("thumb_", "").replace(".jpg", ""))
                for i in os.listdir(args["folder_path"])
                if i.startswith("thumb_")]

    file_ids.sort()
    files = ["thumb_{}.jpg".format(i) for i in file_ids]

    for current_file in files:
        try:
            with Image.open(os.path.join(args["folder_path"], current_file)) as im:
                frames.append(im.getdata())
        except:
            print(current_file + " is not a valid image")

    tile_width = frames[0].size[0]
    tile_height = frames[0].size[1]

    if len(frames) > max_frames_row:
        spritesheet_width = tile_width * max_frames_row
        required_rows = math.ceil(len(frames) / max_frames_row)
        spritesheet_height = tile_height * required_rows
    else:
        spritesheet_width = tile_width * len(frames)
        spritesheet_height = tile_height

    spritesheet = Image.new("RGB", (int(spritesheet_width), int(spritesheet_height)))

    for current_frame in frames:
        top = tile_height * math.floor((frames.index(current_frame)) / max_frames_row)
        left = tile_width * (frames.index(current_frame) % max_frames_row)
        bottom = top + tile_height
        right = left + tile_width

        box = (left, top, right, bottom)
        box = [int(i) for i in box]
        cut_frame = current_frame.crop((0, 0, tile_width, tile_height))

        spritesheet.paste(cut_frame, box)

    spritesheet.save(os.path.join(args["folder_path"], "sprite_sheet_{}.jpg".format(material_id)))


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='generates the sprite sheet')
    parser.add_argument('--folder-path', required=True, type=str, help='path to folder')

    args = vars(parser.parse_args())
    main(args)
