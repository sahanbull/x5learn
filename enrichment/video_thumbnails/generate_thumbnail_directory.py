import os
import shutil

# patterns
SPRITE_PATTERN = "sprite_"
SPRITE_OUTPUT = "sprite_sheets"

THUMB_PATTERN = "thumb_0"
THUMB_OUTPUT = "thumbnails"


def main(args):
    is_thumbnails = args["is_thumbnails"]
    if is_thumbnails:
        pattern = THUMB_PATTERN
        out_dir = THUMB_OUTPUT
    else:
        pattern = SPRITE_PATTERN
        out_dir = SPRITE_OUTPUT

    image_files = set()
    for root, dirs, files in os.walk(args["folder_path"], topdown=False):
        for file in files:
            if pattern in file and file.endswith(".jpg"):
                image_files.add(os.path.join(root, file))

    # create output directory
    output_dir = os.path.join(args["folder_path"], out_dir)
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
        print("Directory ", output_dir, " Created ")
    else:
        print("Directory ", output_dir, " already exists")

    # write them to sprite sheet folder
    for image_filename in image_files:
        if is_thumbnails:
            material_id = os.path.basename(os.path.dirname(image_filename))
            name = "tn_{}_332x175.jpg".format(int(material_id))
        else:
            name = os.path.basename(os.path.normpath(image_filename))
        # copy to output folder
        shutil.copy(image_filename, os.path.join(output_dir, name))


if __name__ == '__main__':
    """This script can be used both to create a sprite sheet directory or a thumbnail directory"""
    import argparse

    parser = argparse.ArgumentParser(description='generates the sprite sheet')
    parser.add_argument('--folder-path', required=True, type=str, help='path to folder')
    parser.add_argument('--is-thumbnails', action='store_true')

    args = vars(parser.parse_args())
    main(args)
