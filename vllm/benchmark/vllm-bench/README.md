# vLLM Benchmark Automation

This directory contains an automated benchmarking script for vLLM models. The script handles the complete workflow of starting a vLLM server, monitoring its startup, capturing model information, and running benchmarks.

## Features

- ✅ Automated vLLM server startup and shutdown
- ✅ Model-specific configuration support
- ✅ Automatic log capture and organization
- ✅ Model information extraction (weights size, parameter count)
- ✅ Server startup monitoring with timeout
- ✅ Configuration file backup for each run
- ✅ Colored console output for better readability
- ✅ Flexible benchmark parameter configuration

## Quick Start

### Basic Usage

Run a benchmark with default settings:

```bash
./run.sh google/gemma-3-4b-it
```

### With Custom Parameters

```bash
./run.sh --max-concurrency 2 --num-prompts 10 meta-llama/Llama-3.2-3B-Instruct
```

### Using a Custom Configuration File

```bash
./run.sh -c my-config.yaml Qwen/Qwen3-4B-Instruct-2507
```

### Dry Run Mode

Before executing a benchmark, you can verify all parameters using dry run mode:

```bash
./run.sh --dry-run google/gemma-3-4b-it
```

This will:
- Load and parse the configuration
- Validate all parameters
- Show exactly what commands would be executed
- Exit without running the server or benchmark

Perfect for verifying your setup before committing to a full benchmark run.

## Configuration

### Configuration File Structure

The script uses a YAML configuration file (`config.yaml` by default) to define benchmark settings and model-specific parameters.

#### Example Configuration

```yaml
# vllm-bench configuration file

# Benchmark settings
benchmark:
  max_concurrency: 1
  num_prompts: 3
  temperature: 0.3
  top_p: 0.75
  request_rate: inf
  dataset_path: prompts.jsonl

# Model configurations
models:
  # Example: Ministral base model is in BF16 format
  "mistralai/Ministral-3-3B-Base-2512":
    vllm_args:
      - "--tokenizer_mode"
      - "mistral"
      - "--config_format"
      - "mistral"
      - "--load_format"
      - "mistral"
  
  # Standard models that work without additional parameters
  "google/gemma-3-4b-it":
    vllm_args: []
  
  "meta-llama/Llama-3.2-3B-Instruct":
    vllm_args: []
  
  "Qwen/Qwen3-4B-Instruct-2507":
    vllm_args: []
```

### Adding New Models

To add configuration for a new model, add an entry under the `models` section:

```yaml
models:
  "your-org/your-model":
    vllm_args:
      - "--parameter-name"
      - "parameter-value"
      - "--another-parameter"
      - "another-value"
```

## Command Line Options

```
Usage: ./run.sh [OPTIONS] <model_name>

Options:
    -c, --config FILE       Configuration file (default: config.yaml)
    -h, --help              Show this help message
    --dry-run               Show what would be executed without running it
    --max-concurrency NUM   Maximum concurrency (default: 1)
    --num-prompts NUM       Number of prompts (default: 3)
    --temperature NUM       Temperature (default: 0.3)
    --top-p NUM             Top-p value (default: 0.75)
    --request-rate NUM      Request rate (default: inf)

Arguments:
    model_name              HuggingFace model name (required)
```

### Examples

#### Standard Gemma Model Benchmark

```bash
./run.sh google/gemma-3-4b-it
```

This will:
- Load model-specific parameters from `config.yaml`
- Start the vLLM server
- Wait for server startup
- Run the benchmark with default settings
- Save all results to `logs/<timestamp>/`

#### High Concurrency Test

```bash
./run.sh --max-concurrency 10 --num-prompts 100 meta-llama/Llama-3.2-3B-Instruct
```

#### Custom Temperature and Top-p

```bash
./run.sh --temperature 0.7 --top-p 0.9 Qwen/Qwen3-4B-Instruct-2507
```

#### Ministral Model with Special Configuration

```bash
./run.sh mistralai/Ministral-3-3B-Base-2512
```

This model uses BF16 format and requires special Mistral tokenizer settings (automatically loaded from config.yaml).

## Output and Logs

### Directory Structure

All outputs are saved in timestamped directories under `logs/`:

```
logs/
└── 20260108_172130/
    ├── config_20260108_172130.yaml  # Backup of configuration used
    ├── vllm_server.log               # Complete server logs
    ├── benchmark.log                 # Benchmark execution logs
    ├── model_weights.txt             # Extracted model weight information
    ├── model_config.txt              # Extracted model configuration
    └── [benchmark result files]      # vLLM benchmark output files
```

### Log Files

- **config_*.yaml**: Snapshot of the configuration file used for this run
- **vllm_server.log**: Complete output from the vLLM server, including startup messages and model loading information
- **benchmark.log**: Output from the benchmark execution
- **model_weights.txt**: Extracted information about model weights and VRAM usage
- **model_config.txt**: Model configuration including parameter count

## How It Works

### Execution Flow

1. **Configuration Loading**
   - Parse command line arguments
   - Load benchmark settings from config file
   - Extract model-specific vLLM parameters

2. **Log Directory Setup**
   - Create timestamped log directory
   - Backup configuration file to log directory

3. **vLLM Server Startup**
   - Start vLLM server with model-specific parameters
   - Redirect all output to server log file
   - Monitor startup progress

4. **Server Monitoring**
   - Wait for "Application startup complete" message
   - Track model loading progress
   - Enforce 5-minute startup timeout
   - Extract model information (weights, config)

5. **Benchmark Execution**
   - Run vLLM benchmark with configured parameters
   - Stream output to both console and log file
   - Save detailed results to log directory

6. **Cleanup**
   - Automatically stop vLLM server on exit
   - Display result summary
   - List all generated files

### Server Startup Detection

The script monitors the vLLM server log for specific patterns:

- **"Loading model weights"**: Indicates model loading has started
- **"ModelConfig"**: Contains parameter count and model configuration
- **"Application startup complete"**: Server is ready to accept requests

### Automatic Cleanup

The script registers cleanup handlers for:
- Normal exit
- Ctrl+C (SIGINT)
- Script termination (SIGTERM)

This ensures the vLLM server is always properly shut down.

## Prerequisites

- vLLM installed and available in PATH
- Model files downloaded or accessible via HuggingFace
- `prompts.jsonl` file in the script directory (or custom path in config)

### Installing vLLM

```bash
pip install vllm
```

## Dataset Format

The script expects a dataset file in JSONL format. The default is `prompts.jsonl`.

Example `prompts.jsonl`:

```jsonl
{"prompt": "What is the capital of France?"}
{"prompt": "Explain quantum computing in simple terms."}
{"prompt": "Write a short poem about the ocean."}
```

## Advanced Usage

### Running Multiple Benchmarks with run_all.sh

The `run_all.sh` script automates benchmarking multiple models listed in a file:

```bash
# Create or edit models2benchmark file (one model per line)
# Example:
# google/gemma-3-4b-it
# meta-llama/Llama-3.2-3B-Instruct
# Qwen/Qwen3-4B-Instruct-2507
# mistralai/Ministral-3-3B-Base-2512

# Run all models with default settings
./run_all.sh

# Dry run all models to verify setup
./run_all.sh --dry-run

# Run all models with custom parameters
./run_all.sh --num-prompts 10 --max-concurrency 2

# Continue even if some models fail
./run_all.sh --continue-on-error

# Use a different models file
./run_all.sh -f my-models.txt
```

The script will:
- Read model names from `models2benchmark` (one per line)
- Run benchmarks sequentially for each model
- Track success/failure for each model
- Display a summary at the end
- Optionally continue on errors with `--continue-on-error`

**models2benchmark format:**
```
# Format: model_name [concurrency] [num_prompts]
# If concurrency and num_prompts are not specified, defaults from config.yaml will be used

# Basic format (uses defaults from config.yaml)
google/gemma-3-4b-it

# With concurrency only (uses default num_prompts from config.yaml)
mistralai/Ministral-3-3B-Base-2512 16

# With both concurrency and num_prompts
meta-llama/Llama-3.2-3B-Instruct 32 64
Qwen/Qwen3-4B-Instruct-2507 16 48
```

This flexible format allows you to:
- Use defaults for all models
- Specify different concurrency/prompt counts per model
- Mix models with different configurations in one file
- Easily test how each model scales with different parameters

### Custom Configuration Per Run

```bash
./run.sh -c configs/high-concurrency.yaml google/gemma-3-4b-it
./run.sh -c configs/low-concurrency.yaml google/gemma-3-4b-it
```

### Analyzing Results

After running benchmarks, you can compare results:

```bash
# View all benchmark runs
ls -lt logs/

# Compare model configurations
diff logs/20260108_172130/model_config.txt logs/20260108_173045/model_config.txt

# Extract specific metrics
grep "throughput" logs/*/benchmark.log
```

### Generating CSV Report

Use the `generate_report.py` script to create a CSV summary of all benchmark runs:

```bash
# Generate report with default settings
./generate_report.py

# Specify custom paths
./generate_report.py --logs-dir ./logs --output results.csv
```

The script will:
- Scan all directories in `logs/`
- Extract benchmark metrics from JSON result files
- Parse model information (name, size, architecture)
- Detect ROCm vs CUDA from server logs
- Generate a CSV file with columns:
  - timestamp
  - model_name
  - model_size (VRAM in GiB)
  - architecture (ROCm/CUDA)
  - concurrency
  - num_prompts
  - output_throughput (tok/s)
  - peak_output_throughput (tok/s)
  - peak_concurrent_requests
  - total_throughput (tok/s)

**Example workflow:**
```bash
# Run benchmarks for multiple models
./run_all.sh

# Generate CSV report
./generate_report.py

# View the results
cat benchmark_results.csv
```

The CSV file can be opened in Excel, LibreOffice, or processed further with data analysis tools.

### Generating Plots

Use the `plot_bench.py` script to visualize throughput vs concurrency:

```bash
# Generate plots with default settings
./plot_bench.py

# Specify custom paths
./plot_bench.py --csv benchmark_results.csv --output-dir ./my_plots
```

The script will:
- Read the CSV file generated by `generate_report.py`
- Group data by architecture (ROCm/CUDA)
- Create one plot per architecture showing:
  - Total throughput (tok/s) on Y-axis
  - Concurrency level on X-axis
  - One line per model with data points and value labels
- Save high-resolution PNG files to `./plots/` directory

**Output files:**
- `throughput_vs_concurrency_rocm.png`
- `throughput_vs_concurrency_cuda.png`

**Prerequisites:**
```bash
pip install -r requirements.txt
```

**Complete workflow:**
```bash
# Run benchmarks
./run_all.sh

# Generate CSV report
./generate_report.py

# Generate plots
./plot_bench.py

# View the plots
ls -lh plots/
```
