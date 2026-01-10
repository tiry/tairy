#!/usr/bin/env python3
"""
Compare inference speed between llamacpp and vllm for various models.
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import re

# Model mapping from llamacpp to vllm naming
MODEL_MAPPING = {
    'gemma3 4B F16': 'google/gemma-3-4b-it',
    'qwen3 4B F16': 'Qwen/Qwen3-4B-Instruct-2507',
    'mistral3 3B F16': 'mistralai/Ministral-3-3B-Base-2512',
    'llama 3B F16': 'meta-llama/Llama-3.2-3B-Instruct'
}

# Display names for models
MODEL_DISPLAY_NAMES = {
    'gemma3 4B F16': 'Gemma3 4B',
    'qwen3 4B F16': 'Qwen3 4B',
    'mistral3 3B F16': 'Ministral3 3B',
    'llama 3B F16': 'llama 3.2 3B'
}

def extract_numeric_value(value_str):
    """Extract numeric value from string like '26.22 ± 0.02'"""
    if isinstance(value_str, str):
        match = re.match(r'([\d.]+)', value_str)
        if match:
            return float(match.group(1))
    return float(value_str)

def load_llamacpp_data(filepath='llamacpp.csv'):
    """Load and filter llamacpp benchmark data."""
    df = pd.read_csv(filepath)
    # Filter for tg128 test only
    df_filtered = df[df['test'] == 'tg128'].copy()
    
    # Extract numeric value from t/s column
    df_filtered['throughput'] = df_filtered['t/s'].apply(extract_numeric_value)
    
    return df_filtered[['model', 'backend', 'throughput']]

def load_vllm_data(filepath='../vllm/benchmark/vllm-bench/benchmark_results.csv'):
    """Load and filter vllm benchmark data."""
    df = pd.read_csv(filepath)
    # Filter for concurrency=1 only
    df_filtered = df[df['concurrency'] == 1].copy()
    
    return df_filtered[['model_name', 'architecture', 'output_throughput']]

def create_comparison_plot(llamacpp_df, vllm_df):
    """Create a comparison plot of inference speeds."""
    # Prepare data for plotting
    models = []
    backends = ['ROCm', 'CUDA']
    llamacpp_data = {backend: [] for backend in backends}
    vllm_data = {backend: [] for backend in backends}
    
    # Iterate through model mapping
    for llama_model, vllm_model in MODEL_MAPPING.items():
        models.append(MODEL_DISPLAY_NAMES[llama_model])
        
        for backend in backends:
            # Get llamacpp throughput
            llama_row = llamacpp_df[
                (llamacpp_df['model'] == llama_model) & 
                (llamacpp_df['backend'] == backend)
            ]
            llama_throughput = llama_row['throughput'].values[0] if len(llama_row) > 0 else 0
            llamacpp_data[backend].append(llama_throughput)
            
            # Get vllm throughput
            vllm_row = vllm_df[
                (vllm_df['model_name'] == vllm_model) & 
                (vllm_df['architecture'] == backend)
            ]
            vllm_throughput = vllm_row['output_throughput'].values[0] if len(vllm_row) > 0 else 0
            vllm_data[backend].append(vllm_throughput)
    
    # Create subplots for each backend
    fig, axes = plt.subplots(1, 2, figsize=(16, 6))
    
    for idx, backend in enumerate(backends):
        ax = axes[idx]
        
        x = np.arange(len(models))
        width = 0.35
        
        bars1 = ax.bar(x - width/2, llamacpp_data[backend], width, 
                       label='llama.cpp', alpha=0.8, color='steelblue')
        bars2 = ax.bar(x + width/2, vllm_data[backend], width, 
                       label='vLLM', alpha=0.8, color='coral')
        
        ax.set_xlabel('Model', fontsize=12)
        ax.set_ylabel('Throughput (tokens/s)', fontsize=12)
        ax.set_title(f'Inference Speed Comparison - {backend}', fontsize=14, fontweight='bold')
        ax.set_xticks(x)
        ax.set_xticklabels(models, rotation=45, ha='right')
        ax.legend(fontsize=10)
        ax.grid(axis='y', alpha=0.3, linestyle='--')
        
        # Add value labels on top of bars
        for bars in [bars1, bars2]:
            for bar in bars:
                height = bar.get_height()
                if height > 0:
                    ax.text(bar.get_x() + bar.get_width()/2., height,
                           f'{height:.1f}',
                           ha='center', va='bottom', fontsize=9)
    
    plt.tight_layout()
    plt.savefig('benchmark_comparison.png', dpi=300, bbox_inches='tight')
    print("Plot saved as 'benchmark_comparison.png'")
    plt.show()

def print_summary(llamacpp_df, vllm_df):
    """Print summary statistics."""
    print("\n" + "="*80)
    print("INFERENCE SPEED COMPARISON SUMMARY")
    print("="*80)
    
    for llama_model, vllm_model in MODEL_MAPPING.items():
        print(f"\n{llama_model} <-> {vllm_model}")
        print("-" * 80)
        
        for backend in ['ROCm', 'CUDA']:
            llama_row = llamacpp_df[
                (llamacpp_df['model'] == llama_model) & 
                (llamacpp_df['backend'] == backend)
            ]
            vllm_row = vllm_df[
                (vllm_df['model_name'] == vllm_model) & 
                (vllm_df['architecture'] == backend)
            ]
            
            if len(llama_row) > 0 and len(vllm_row) > 0:
                llama_throughput = llama_row['throughput'].values[0]
                vllm_throughput = vllm_row['output_throughput'].values[0]
                speedup = vllm_throughput / llama_throughput if llama_throughput > 0 else 0
                
                print(f"  {backend:6s}: llama.cpp = {llama_throughput:6.2f} tok/s, "
                      f"vLLM = {vllm_throughput:6.2f} tok/s, "
                      f"Speedup = {speedup:.2f}x")
            elif len(llama_row) > 0:
                llama_throughput = llama_row['throughput'].values[0]
                print(f"  {backend:6s}: llama.cpp = {llama_throughput:6.2f} tok/s, "
                      f"vLLM = N/A")
            elif len(vllm_row) > 0:
                vllm_throughput = vllm_row['output_throughput'].values[0]
                print(f"  {backend:6s}: llama.cpp = N/A, "
                      f"vLLM = {vllm_throughput:6.2f} tok/s")

def main():
    """Main function."""
    print("Loading benchmark data...")
    
    # Load data
    llamacpp_df = load_llamacpp_data()
    vllm_df = load_vllm_data()
    
    print(f"Loaded {len(llamacpp_df)} llamacpp records (tg128 only)")
    print(f"Loaded {len(vllm_df)} vLLM records (concurrency=1 only)")
    
    # Print summary
    print_summary(llamacpp_df, vllm_df)
    
    # Create comparison plot
    print("\nGenerating comparison plot...")
    create_comparison_plot(llamacpp_df, vllm_df)

if __name__ == '__main__':
    main()
