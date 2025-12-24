import os
from PIL import Image, ImageOps

# --- Configuration ---
INPUT_DIR = "tiry_pics"           
OUTPUT_DIR = "tiry_pics_processed" 
TARGET_SIZE = (512, 512)
FILE_PREFIX = "tiry"                

# Create output directory if it doesn't exist
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

print(f"Processing images from '{INPUT_DIR}'...")

# Get a sorted list of files so the order is consistent
valid_extensions = ('.png', '.jpg', '.jpeg', '.webp')
files = [f for f in os.listdir(INPUT_DIR) if f.lower().endswith(valid_extensions)]
files.sort()

count = 0

for i, filename in enumerate(files, start=1):
    img_path = os.path.join(INPUT_DIR, filename)
    
    try:
        with Image.open(img_path) as img:
            # 1. Convert to RGB (fixes PNG transparency or CMYK issues)
            img = img.convert("RGB")
            
            # 2. Smart Resize & Crop to fill 512x512
            # This scales the image to fill the box, then crops the excess from the center
            processed_img = ImageOps.fit(img, TARGET_SIZE, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
            
            # 3. Create new Sequential Filename
            new_filename = f"{FILE_PREFIX}{i}.png"
            save_path = os.path.join(OUTPUT_DIR, new_filename)
            
            # 4. Save
            processed_img.save(save_path, quality=100)
            print(f"✅ Processed: {filename} -> {new_filename}")
            count += 1
            
    except Exception as e:
        print(f"❌ Error processing {filename}: {e}")

print("\n" + "-"*30)
print(f"🎉 Done! {count} images ready in '{OUTPUT_DIR}'")
print("-" * 30)