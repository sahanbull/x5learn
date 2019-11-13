import os
import shutil


def main(args):
    # get all sprite images
    SPRITE_PATTERN = "sprite_"

    sprite_files = set()
    for root, dirs, files in os.walk(args["folder_path"], topdown=False):
        for file in files:
            if SPRITE_PATTERN in file and file.endswith(".jpg"):
                sprite_files.add(os.path.join(root, file))

    # create output directory
    output_dir = os.path.join(args["folder_path"], "sprite_sheets")
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
        print("Directory ", output_dir, " Created ")
    else:
        print("Directory ", output_dir, " already exists")

    # write them to sprite sheet folder
    for sprite_filename in sprite_files:
        name = os.path.basename(os.path.normpath(sprite_filename))
        # copy to output folder
        shutil.copy(sprite_filename, os.path.join(output_dir, name))


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='generates the sprite sheet')
    parser.add_argument('--folder-path', required=True, type=str, help='path to folder')

    args = vars(parser.parse_args())
    main(args)
