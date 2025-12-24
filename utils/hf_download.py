import click
import re
import os
from pathlib import Path
from dotenv import load_dotenv
from huggingface_hub import snapshot_download

# Load environment variables from .env file in the same directory as this script
env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

# Set HF_TOKEN environment variable if it exists in .env
if 'HF_TOKEN' in os.environ:
    click.echo(click.style("✓ HF_TOKEN loaded from .env file", fg='green'))
else:
    click.echo(click.style("⚠ Warning: HF_TOKEN not found in .env file. Private models may not be accessible.", fg='yellow'))

def get_safe_folder_name(model_id):
    """
    Derives a safe directory name from the model_id.
    """
    # Replace the repo separator with an underscore
    safe_name = model_id.replace("/", "_")
    # Remove any character that isn't alphanumeric, underscore, hyphen, or period
    safe_name = re.sub(r'[^\w\-.]', '', safe_name)
    return safe_name

@click.command()
@click.argument('model_id')
@click.option('--model-folder', '-d', default=None, help='Parent directory where the model folder will be created.')
@click.option('--revision', default='main', help='The specific model revision to download.')
def download_cli(model_id, model_folder, revision):
    """
    Downloads a model from Hugging Face to a local directory.
    
    MODEL_ID: The Hugging Face repo ID (e.g. mistralai/Ministral-3-8B-Reasoning-2512)
    """
    # Derive the specific folder name for this model (e.g. mistralai_Ministral...)
    derived_name = get_safe_folder_name(model_id)
    
    # Determine the final full path
    if model_folder:
        # If a parent folder is specified, join it with the derived name
        # e.g. /data/models/mistralai_Ministral...
        local_dir = os.path.join(model_folder, derived_name)
    else:
        # Otherwise just use the derived name in the current directory
        local_dir = derived_name

    click.echo(f"Preparing to download: {model_id}")
    click.echo(f"Download location: {local_dir}")

    try:
        snapshot_download(
            repo_id=model_id,
            local_dir=local_dir,
            local_dir_use_symlinks=False,
            revision=revision
        )
        click.echo(click.style(f"\nSuccessfully downloaded to {local_dir}", fg='green'))
    except Exception as e:
        click.echo(click.style(f"\nError downloading model: {e}", fg='red'))

if __name__ == '__main__':
    download_cli()
