import os
import shutil
import argparse
from pathlib import Path

# Parse command-line arguments
parser = argparse.ArgumentParser(
    description='Copy PNG files from source folder to overwrite matching files in target folder.'
)
parser.add_argument('target_folder', type=str, 
                    help='Target folder containing PNG files to be overwritten')
parser.add_argument('source_folder', type=str, 
                    help='Source folder containing PNG files to copy from')
parser.add_argument('--dry-run', action='store_true',
                    help='Show what would be copied without actually copying')
args = parser.parse_args()

# Validate directories
if not os.path.exists(args.target_folder):
    print(f"❌ Error: Target folder '{args.target_folder}' does not exist")
    exit(1)

if not os.path.exists(args.source_folder):
    print(f"❌ Error: Source folder '{args.source_folder}' does not exist")
    exit(1)

print(f"Target folder: {args.target_folder}")
print(f"Source folder: {args.source_folder}")
if args.dry_run:
    print("🔍 DRY RUN MODE - No files will be modified\n")
print("-" * 50)

# Get all PNG files in target folder
target_files = [f for f in os.listdir(args.target_folder) if f.lower().endswith('.png')]
target_files.sort()

if not target_files:
    print(f"⚠️  No PNG files found in target folder '{args.target_folder}'")
    exit(0)

print(f"Found {len(target_files)} PNG file(s) in target folder\n")

copied_count = 0
skipped_count = 0
error_count = 0

for filename in target_files:
    source_path = os.path.join(args.source_folder, filename)
    target_path = os.path.join(args.target_folder, filename)
    
    # Check if source file exists
    if not os.path.exists(source_path):
        print(f"⚠️  Skipped: {filename} (not found in source folder)")
        skipped_count += 1
        continue
    
    try:
        if args.dry_run:
            print(f"🔍 Would copy: {filename}")
            copied_count += 1
        else:
            # Copy and overwrite
            shutil.copy2(source_path, target_path)
            print(f"✅ Copied: {filename}")
            copied_count += 1
            
    except Exception as e:
        print(f"❌ Error copying {filename}: {e}")
        error_count += 1

print("\n" + "=" * 50)
print(f"📊 Summary:")
print(f"   Copied: {copied_count}")
print(f"   Skipped: {skipped_count}")
print(f"   Errors: {error_count}")
print("=" * 50)

if args.dry_run:
    print("\n💡 This was a dry run. Use without --dry-run to actually copy files.")
