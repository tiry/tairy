# vconvert.sh - Video Conversion Script

Batch video conversion tool using ffmpeg with support for GPU/CPU encoding, multiple codecs, and background processing.

## Features

- **Batch Processing**: Convert all videos in a folder automatically
- **GPU/CPU Support**: Use hardware acceleration (VAAPI) or CPU encoding
- **Multiple Codecs**: AV1 and H.265 (HEVC) support
- **Background Mode**: Run long conversions detached from your terminal
- **Progress Tracking**: Check status of running conversions anytime
- **Smart File Management**: Preserves originals with `_src` suffix
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

### Monitor Live Output
```bash
tail -f ~/Videos/ToConvert/vconvert_output.log
```

### Stop Background Process
```bash
kill <PID>
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

The script processes files in the target folder:

**Before conversion:**
```
video1.mp4
video2.mkv
```

**After conversion:**
```
video1.mkv          # New converted file
video1_src.mp4      # Original renamed
video2.mkv          # New converted file
video2_src.mkv      # Original renamed
```

**Note**: Files with `_src` or `_av1` in the name are automatically skipped.

## Output Files

The script creates several files in the target folder:

- `conversion.log` - Detailed log of all conversions
- `vconvert_output.log` - Full output when running in background
- `.vconvert.pid` - Process ID file (hidden)
- `.vconvert.status` - Current status file (hidden)

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

### "Enter command" prompt appears
This was a bug in earlier versions. Update to the latest version where the `-y` flag is correctly positioned.

### No GPU acceleration
Ensure VAAPI drivers are installed and your GPU supports hardware encoding.

### Process shows as "not running"
The PID file may be stale. Try running the conversion again.

### Want to resume interrupted conversion
The script automatically skips already converted files (those with `_src` suffix). Just run the command again.

## Requirements

- `ffmpeg` with required codec support
- For GPU mode: VAAPI-compatible hardware and drivers
- Bash shell

## Help

View all options:
```bash
./scripts/vconvert.sh --help
```

## Tips

1. **Test first**: Use `--dry-run` to preview what will happen
2. **Start small**: Test on a few files before batch converting
3. **Use background mode**: For large batches, use `--background` so you can log out
4. **Monitor progress**: Check `--status` periodically for background jobs
5. **Adjust quality**: Start with default QP/CRF, adjust if files are too large/low quality
