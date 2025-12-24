# Hugging Face Model Downloader

A command-line utility for downloading models from Hugging Face Hub with automatic authentication support.

## Features

- 🚀 Simple CLI interface for downloading Hugging Face models
- 🔐 Automatic HF_TOKEN authentication from `.env` file
- 📁 Smart directory naming based on model IDs
- 🎯 Support for specific model revisions
- 🛡️ Safe folder name generation (sanitized from special characters)
- ✅ Visual feedback with colored status messages

## Prerequisites

- Python 3.7+
- Hugging Face account (for private/gated models)

## Installation

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up your Hugging Face token:**

   a. Get your token from [Hugging Face Settings](https://huggingface.co/settings/tokens)
   
   b. Create a `.env` file in the `utils` directory:
   ```bash
   cp .env.example .env
   ```
   
   c. Edit `.env` and add your token:
   ```
   HF_TOKEN=hf_your_actual_token_here
   ```

   **⚠️ Important:** The `.env` file is gitignored to protect your token. Never commit it to version control.

## Usage

### Basic Syntax

```bash
python hf_download.py MODEL_ID [OPTIONS]
```

### Parameters

- `MODEL_ID` (required): The Hugging Face repository ID
  - Format: `organization/model-name`
  - Example: `mistralai/Ministral-3-8B-Reasoning-2512`

### Options

- `-d, --model-folder PATH`: Parent directory where the model will be downloaded
  - If not specified, downloads to current directory
  - The script creates a subfolder based on the model ID

- `--revision TEXT`: Specific model revision to download
  - Default: `main`
  - Can be a branch name, tag, or commit hash

### Examples

#### 1. Download to Current Directory

```bash
python hf_download.py mistralai/Ministral-3-8B-Reasoning-2512
```

This creates a folder `mistralai_Ministral-3-8B-Reasoning-2512` in the current directory.

#### 2. Download to Specific Directory

```bash
python hf_download.py mistralai/Ministral-3-8B-Reasoning-2512 -d /data/models
```

This creates `/data/models/mistralai_Ministral-3-8B-Reasoning-2512`.

#### 3. Download a Specific Revision

```bash
python hf_download.py meta-llama/Llama-2-7b-hf --revision v1.0
```

#### 4. Download with Full Options

```bash
python hf_download.py openai/whisper-large-v3 -d ~/models --revision main
```

## How It Works

### Authentication

1. On startup, the script automatically loads the `.env` file from the `utils` directory
2. If `HF_TOKEN` is found, it's loaded into the environment
3. The Hugging Face Hub library uses this token for authentication
4. Status messages indicate whether the token was loaded successfully

### Folder Naming

The script converts model IDs into safe folder names:
- Replaces `/` with `_`
- Removes special characters
- Keeps alphanumeric characters, underscores, hyphens, and periods

Example transformations:
- `mistralai/Ministral-3-8B` → `mistralai_Ministral-3-8B`
- `openai/whisper-large-v3` → `openai_whisper-large-v3`

### Download Process

The script uses `snapshot_download` from `huggingface_hub` which:
- Downloads all files from the model repository
- Preserves the directory structure
- Skips already downloaded files (resumable downloads)
- Uses direct file copies (no symlinks) for better compatibility

## Troubleshooting

### Token Not Found Warning

**Message:** `⚠ Warning: HF_TOKEN not found in .env file`

**Solution:**
1. Ensure `.env` file exists in the `utils` directory
2. Verify the token is formatted as: `HF_TOKEN=hf_...`
3. Check there are no extra spaces or quotes around the token

### Authentication Errors

**Error:** `401 Unauthorized` or `Access denied`

**Solutions:**
- Verify your HF_TOKEN is valid and hasn't expired
- For gated models, ensure you've accepted the model's terms on Hugging Face
- Check your token has the necessary permissions (read access)

### Download Failures

**Error:** `Error downloading model: ...`

**Common causes:**
1. **Invalid model ID:** Verify the model exists on Hugging Face
2. **Network issues:** Check your internet connection
3. **Insufficient disk space:** Ensure you have enough space for the model
4. **Permission errors:** Verify write permissions for the target directory

### Module Not Found

**Error:** `ModuleNotFoundError: No module named 'dotenv'`

**Solution:**
```bash
pip install -r requirements.txt
```

## File Structure

After setup, your `utils` directory should contain:

```
utils/
├── hf_download.py      # Main script
├── requirements.txt    # Python dependencies
├── .env                # Your HF_TOKEN (gitignored)
├── .env.example        # Template for .env
└── ReadMe.md          # This file
```

## Security Notes

- ✅ The `.env` file is automatically excluded from git via `.gitignore`
- ✅ Never commit your `HF_TOKEN` to version control
- ✅ Keep your token private and rotate it if exposed
- ✅ Use read-only tokens when possible

## Dependencies

- **huggingface_hub**: Core library for downloading models
- **click**: Command-line interface framework
- **python-dotenv**: Environment variable management

## Version History

- **v1.1**: Added automatic `.env` file support for HF_TOKEN
- **v1.0**: Initial release with basic download functionality

## Support

For issues related to:
- **This script**: Check the troubleshooting section above
- **Hugging Face models**: Visit [Hugging Face Documentation](https://huggingface.co/docs)
- **Specific models**: Check the model's repository page on Hugging Face

## License

This utility is part of the Tairy project. Refer to the main project license for details.
