# vconvert.sh - Video Conversion Script

Batch video conversion tool using ffmpeg with support for GPU/CPU encoding, multiple codecs, and background processing.

## Features

- **Batch Processing**: Convert all videos in a folder automatically
- **GPU/CPU Support**: Use hardware acceleration (VAAPI) or CPU encoding
- **Multiple Codecs**: AV1 and H.265 (HEVC) support
- **Background Mode**: Run long conversions detached from your terminal
- **Progress Tracking**: Check status of running conversions anytime
- **Smart File Management**: Preserves originals with `_src` suffix
- **Auto-Organization**: Moves completed conversions to `done/` subdirectory
- **Size Validation**: Only replaces original if encoded file is smaller
- **Intelligent Skipping**: Automatically handles problematic audio streams
- **Summary Reports**: Generates detailed conversion summaries with statistics
- **Detailed Logging**: Track conversion times and size savings

## Quick Start

### Basic Usage

Convert all videos in a folder using default settings (GPU, AV1, QP 30):
```bash
./scripts/vconvert.sh ~/Videos/ToConvert/
```

### Preset Modes

Use convenient presets for common scenarios:

```bash
# Fast mode (GPU, AV1, QP 30) - quickest conversion
./scripts/vconvert.sh --fast ~/Videos/

# Medium mode (CPU, AV1, CRF 28, preset 8) - balanced quality/speed
./scripts/vconvert.sh --medium ~/Videos/

# Best mode (CPU, H.265, CRF 28, slow preset) - highest quality
./scripts/vconvert.sh --best ~/Videos/
```

## Background Processing

For long-running conversions, use background mode to detach the process:

### Start in Background
```bash
./scripts/vconvert.sh --background --medium ~/Videos/ToConvert/
```

The script will display:
- Process ID (PID)
- Status check command
- Log file location
- Stop command

### Check Progress
```bash
./scripts/vconvert.sh --status ~/Videos/ToConvert/
```

This shows:
- Current progress (files processed/total)
- Success/failure counts
- Currently processing file
- Recent output (last 20 lines)
- Commands to stop or view full log

### Stop Background Process
```bash
./scripts/vconvert.sh --stop ~/Videos/ToConvert/
```

### Monitor Live Output
```bash
tail -f ~/Videos/ToConvert/vconvert_output.log
```

## Advanced Options

### Manual Configuration

Customize encoding parameters:

```bash
# GPU encoding with custom quality
./scripts/vconvert.sh --mode gpu --codec av1 --qp 25 ~/Videos/

# CPU encoding with custom CRF and preset
./scripts/vconvert.sh --mode cpu --codec h265 --crf 22 --preset medium ~/Videos/
```

### Encoding Modes

**GPU Mode** (using VAAPI):
- Faster encoding
- Lower CPU usage
- Requires compatible hardware
- Quality controlled by `--qp` (lower = better quality)

**CPU Mode**:
- Slower encoding
- Higher quality potential
- Works on any system
- Quality controlled by `--crf` (lower = better quality)
- Speed controlled by `--preset`

### Codec Options

**AV1** (`--codec av1`):
- Better compression (smaller files)
- Newer codec
- CPU preset range: 0-13 (higher = faster)

**H.265/HEVC** (`--codec h265`):
- Good compression
- Wide compatibility
- CPU presets: ultrafast, superfast, fast, medium, slow, slower, veryslow

### Dry Run

Test what the script would do without actually converting:
```bash
./scripts/vconvert.sh --dry-run --medium ~/Videos/
```

## Examples

### Example 1: Quick GPU Conversion
```bash
./scripts/vconvert.sh --fast ~/Downloads/videos/
```

### Example 2: High-Quality Background Conversion
```bash
# Start conversion
./scripts/vconvert.sh --background --best ~/Movies/Originals/

# Check progress later
./scripts/vconvert.sh --status ~/Movies/Originals/

# Stop if needed
./scripts/vconvert.sh --stop ~/Movies/Originals/

# View live output
tail -f ~/Movies/Originals/vconvert_output.log
```

### Example 3: Custom CPU Encoding
```bash
./scripts/vconvert.sh --mode cpu --codec av1 --crf 30 --preset 10 ~/Videos/
```

### Example 4: Test Before Converting
```bash
# See what would happen without actually converting
./scripts/vconvert.sh --dry-run --medium ~/Videos/

# If happy with the plan, run for real
./scripts/vconvert.sh --medium ~/Videos/
```

## File Management

The script automatically organizes your files:

### Directory Structure

**Before conversion:**
```
~/Videos/ToConvert/
├── video1.mp4
├── video2.mkv
└── video3.avi
```

**After successful conversion:**
```
~/Videos/ToConvert/
├── done/
│   ├── video1.mkv              # Converted file
│   ├── video1_src.mp4          # Original backup
│   ├── video2.mkv              # Converted file
│   ├── video2_src.mkv          # Original backup
│   └── conversion_summary.log  # Cumulative history
├── video3.avi                  # Not converted (failed or no size reduction)
├── conversion.log              # Detailed log
└── conversion_summary.log      # Current run summary
```

### File Handling Logic

- **SUCCESS**: Both converted file and original (`_src`) moved to `done/`
- **SKIPPED**: Original kept in place if encoded file is not smaller
- **FAILED**: Original kept in place, partial conversion removed
- **Already Processed**: Files with `_src` or `_av1` suffix are automatically skipped

## Output Files

The script creates several files:

### In Main Folder
- `conversion.log` - Detailed log of all conversions with timestamps
- `conversion_summary.log` - Table format summary of current run
- `vconvert_output.log` - Full output when running in background
- `.vconvert.pid` - Process ID file (hidden)
- `.vconvert.status` - Current status file (hidden)

### In done/ Folder
- `conversion_summary.log` - Cumulative conversion history (appended on each run)
- Successfully converted files and their `_src` originals

## Summary Reports

The script generates a detailed summary table for each run:

```
=== Video Conversion Summary ===
Run started: Fri Nov 15 07:00:00 PM UTC 2025
Config: Mode: cpu | Codec: av1 | Quality (CRF): 28 | Preset: 8

File                                               | Status     |   Duration | Size Before     -> Size After      | Delta %
----------------------------------------------------------------------------------------------------------------------------------
video1.mp4                                         | SUCCESS    |      245s  |        1.2GiB -> 456MiB           |   62.50%
video2.mkv                                         | SUCCESS    |      180s  |        850MiB -> 320MiB           |   62.35%
video3.avi                                         | SKIPPED    |      120s  |        200MiB -> 210MiB           |   -5.00%
corrupted.mp4                                      | FAILED     |         -  |        500MiB -> -                |       -

=== Final Summary ===
Total files processed: 4
Successful conversions: 2
Failed conversions: 1
```

### Status Types
- **SUCCESS**: File converted and smaller than original
- **SKIPPED**: Encoded file was larger than original (kept original)
- **FAILED**: Conversion failed (ffmpeg error)

## Smart Features

### Size Validation
The script automatically checks if the encoded file is actually smaller:
- **Smaller**: Replaces original and moves both to `done/`
- **Larger or Equal**: Keeps original, removes encoded version, logs as SKIPPED

### Audio Stream Handling
If audio copying fails (e.g., corrupted AAC), the script automatically:
1. Detects the failure
2. Retries with audio re-encoding (AAC 192k)
3. Displays notification about audio re-encoding

### Re-run Safety
When running the script multiple times:
- Skips files already processed (checks for `_src` files)
- Appends summary to existing `done/conversion_summary.log`
- Perfect for incremental conversions

## Quality Settings Guide

### QP/CRF Values (lower = better quality, larger files)

- **18-22**: Very high quality, large files
- **23-28**: High quality, balanced (recommended)
- **29-32**: Good quality, smaller files
- **33+**: Lower quality, very small files

### CPU Preset Guide (AV1)

- **0-4**: Slowest, best compression
- **5-8**: Balanced (8 recommended for most users)
- **9-13**: Fastest, larger files

### CPU Preset Guide (H.265)

- **veryslow/slower**: Best compression, very slow
- **slow/medium**: Good compression, acceptable speed
- **fast/superfast**: Lower compression, fast encoding

## Troubleshooting

### Common Issues

**"Enter command" prompt appears**
- Fixed in current version with `-nostdin` flag
- Update to latest version if you see this

**Audio errors (AAC extradata)**
- Script automatically handles this by re-encoding audio
- Look for "Audio was re-encoded" messages in output

**No size reduction**
- Some videos are already well-compressed
- Check summary for SKIPPED files
- Try adjusting quality settings (lower QP/CRF for better compression)

**Process shows as "not running"**
- The PID file may be stale
- Use `--stop` command to clean up

**Want to resume interrupted conversion**
- Simply run the command again
- Script automatically skips already converted files

### No GPU acceleration
- Ensure VAAPI drivers are installed
- Check GPU supports hardware encoding
- Use CPU mode as fallback

## Workflow Tips

### Typical Workflow
```bash
# 1. Start background conversion
./scripts/vconvert.sh --background --medium ~/Videos/Archive/

# 2. Check progress periodically
./scripts/vconvert.sh --status ~/Videos/Archive/

# 3. When complete, review summary
cat ~/Videos/Archive/conversion_summary.log

# 4. Check done directory
ls ~/Videos/Archive/done/

# 5. Review cumulative history
cat ~/Videos/Archive/done/conversion_summary.log
```

### Best Practices

1. **Test first**: Use `--dry-run` to preview operations
2. **Start small**: Test on a few files before batch converting
3. **Use background mode**: For large batches, use `--background`
4. **Monitor progress**: Check `--status` periodically
5. **Review summaries**: Check SKIPPED files to adjust quality settings
6. **Archive strategy**: Keep `done/` folder as your archive
7. **Verify results**: Spot-check converted files before deleting originals

## Requirements

- `ffmpeg` with required codec support
- For GPU mode: VAAPI-compatible hardware and drivers
- Bash shell
- Standard Unix utilities: `find`, `stat`, `awk`, `numfmt`

## Command Reference

### All Options
```
--best              High quality H.265 CPU encoding
--medium            Balanced AV1 CPU encoding
--fast              Quick AV1 GPU encoding
--mode <gpu|cpu>    Encoder mode
--codec <av1|h265>  Video codec
--qp <value>        GPU quality (lower = better)
--crf <value>       CPU quality (lower = better)
--preset <value>    CPU encoding speed
--dry-run           Preview without converting
--background        Run in background
--status            Check progress
--stop              Stop background process
--help              Show help message
```

### Quick Reference
```bash
# View help
./scripts/vconvert.sh --help

# Basic conversion
./scripts/vconvert.sh ~/Videos/

# Background with status checks
./scripts/vconvert.sh --background --medium ~/Videos/
./scripts/vconvert.sh --status ~/Videos/
./scripts/vconvert.sh --stop ~/Videos/

# Custom settings
./scripts/vconvert.sh --mode cpu --codec av1 --crf 25 --preset 6 ~/Videos/
```

## Version History

### Latest Version
- Added `--stop` parameter for graceful shutdown
- Size validation prevents larger encoded files
- Auto-organization with `done/` subdirectory  
- Summary table generation with statistics
- Cumulative history in `done/conversion_summary.log`
- Audio re-encoding fallback for problematic streams
- Single source of truth for file extensions
- Fixed all ffmpeg interactive prompts with `-nostdin`

### Previous Features
- Background processing with PID tracking
- Progress monitoring with `--status`
- Dry-run mode
- Preset shortcuts (--fast, --medium, --best)
- GPU and CPU encoding modes
- Multiple codec support

## License

This script is provided as-is for video conversion tasks. Use at your own risk. Always keep backups of original files until you verify the conversions.
