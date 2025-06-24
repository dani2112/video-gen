import sys
import os
from PIL import Image

def transform_transparency(input_path):
    # Open the image with alpha channel
    img = Image.open(input_path).convert("RGBA")
    pixels = img.load()

    # Create an RGB result image (no alpha)
    result = Image.new("RGB", img.size)
    result_pixels = result.load()

    for y in range(img.height):
        for x in range(img.width):
            _, _, _, a = pixels[x, y]
            if a == 0:
                result_pixels[x, y] = (0, 0, 0)  # Transparent -> black
            else:
                result_pixels[x, y] = (255, 255, 255)  # Others -> white

    # Generate output path
    base, ext = os.path.splitext(input_path)
    output_path = f"{base}_mask{ext}"
    result.save(output_path)
    print(f"Saved mask image to: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python mask_transparency.py <input_image.png>")
        sys.exit(1)

    input_image_path = sys.argv[1]
    transform_transparency(input_image_path)
