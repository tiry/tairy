#!/usr/bin/env python3
"""
Benchmark Plotting Script
Generates comparative benchmark plots from benchmarks.csv
Creates separate plots for pp512 and tg128 tests (llama.cpp only)
Plus a comparison plot for tg128 between llama.cpp and pytorch
"""

import pandas as pd
import matplotlib.pyplot as plt
import os

# Read the CSV data
script_dir = os.path.dirname(os.path.abspath(__file__))
csv_path = os.path.join(script_dir, 'benchmarks.csv')
df = pd.read_csv(csv_path)

# ============================================================================
# PLOT 1: llama.cpp benchmarks (pp512 and tg128)
# ============================================================================

# Filter only llama.cpp data
llamacpp_df = df[df['inference'] == 'llama.cpp'].copy()

# Create combined backend/GPU label
llamacpp_df['backend_gpu'] = llamacpp_df['GPU'] + '/' + llamacpp_df['backend']

# Get unique backend/GPU combinations and assign colors/markers
unique_backends = llamacpp_df['backend_gpu'].unique()
colors = ['red', 'orange', 'green', 'blue', 'purple', 'brown', 'pink', 'gray', 'cyan', 'magenta']
markers = ['o', 's', '^', 'D', 'v', '<', '>', 'p', '*', 'h']

backend_styles = {}
for i, backend in enumerate(unique_backends):
    backend_styles[backend] = {
        'color': colors[i % len(colors)],
        'marker': markers[i % len(markers)],
        'linestyle': '-',
        'label': backend
    }

# Create figure with 2 subplots
fig, axes = plt.subplots(1, 2, figsize=(16, 6))
fig.suptitle('LLM Benchmark Comparison (llama.cpp)', fontsize=16, fontweight='bold')

# Test types
tests = ['pp512', 'tg128']
test_titles = {
    'pp512': 'Prompt Processing (512 tokens)',
    'tg128': 'Text Generation (128 tokens)'
}

for idx, test in enumerate(tests):
    ax = axes[idx]
    
    # Filter data for this test
    test_data = llamacpp_df[llamacpp_df['test'] == test]
    
    # Plot each backend
    for backend, style in backend_styles.items():
        backend_data = test_data[test_data['backend_gpu'] == backend]
        
        if not backend_data.empty:
            # Sort by model size for proper line plotting
            backend_data = backend_data.sort_values('size_GiB')
            
            ax.plot(backend_data['size_GiB'], 
                   backend_data['speed_t_s'],
                   color=style['color'],
                   marker=style['marker'],
                   linestyle=style['linestyle'],
                   linewidth=2,
                   markersize=8,
                   label=style['label'])
            
            # Add value labels on points
            for _, row in backend_data.iterrows():
                ax.annotate(f"{row['speed_t_s']:.1f}",
                           (row['size_GiB'], row['speed_t_s']),
                           textcoords="offset points",
                           xytext=(0, 10),
                           ha='center',
                           fontsize=8,
                           alpha=0.7)
    
    # Configure axes
    ax.set_xlabel('Model Size (GiB)', fontsize=12, fontweight='bold')
    ax.set_ylabel('Speed (tokens/second)', fontsize=12, fontweight='bold')
    ax.set_title(test_titles[test], fontsize=14, fontweight='bold')
    ax.grid(True, alpha=0.3, linestyle='--')
    ax.legend(loc='best', fontsize=9)
    
    # Set x-axis to show actual model sizes
    if not test_data.empty:
        ax.set_xlim(test_data['size_GiB'].min() - 1, test_data['size_GiB'].max() + 1)

# Adjust layout
plt.tight_layout()

# Save the plot
output_path = os.path.join(script_dir, 'benchmark_comparison.png')
plt.savefig(output_path, dpi=300, bbox_inches='tight')
print(f"Plot 1 saved to: {output_path}")

# ============================================================================
# PLOT 2: llama.cpp vs pytorch comparison for tg128
# ============================================================================

# Filter only tg128 data with RTX GPU and cuda backend
tg128_df = df[(df['test'] == 'tg128') & 
              (df['GPU'].str.contains('RTX', na=False)) & 
              (df['backend'] == 'cuda')].copy()

# Find models that have data for both llama.cpp and pytorch
# Group by model to see which ones have both inference types
model_inference_counts = tg128_df.groupby('model')['inference'].apply(lambda x: set(x))

# Get models that have both llama.cpp and pytorch
models_with_both = [model for model, inferences in model_inference_counts.items() 
                    if 'llama.cpp' in inferences and 'pytoch' in inferences]

if models_with_both:
    # Filter data for models with both inference types (already filtered for RTX/cuda)
    comparison_df = tg128_df[tg128_df['model'].isin(models_with_both)].copy()
    
    # Create a new figure for comparison
    fig2, ax2 = plt.subplots(figsize=(12, 8))
    fig2.suptitle('Text Generation (128 tokens): llama.cpp vs PyTorch Comparison', 
                  fontsize=16, fontweight='bold')
    
    # Get unique model/GPU/backend combinations for llama.cpp and pytorch
    llamacpp_comp = comparison_df[comparison_df['inference'] == 'llama.cpp'].copy()
    pytorch_comp = comparison_df[comparison_df['inference'] == 'pytoch'].copy()
    
    # Create labels combining model, GPU, and backend
    llamacpp_comp['label'] = llamacpp_comp['model'] + '\n' + llamacpp_comp['GPU'] + '/' + llamacpp_comp['backend']
    pytorch_comp['label'] = pytorch_comp['model'] + '\n' + pytorch_comp['GPU'] + '/' + pytorch_comp['backend']
    
    # For each model, find matching GPU/backend combinations
    x_pos = 0
    x_positions = []
    x_labels = []
    
    for model in models_with_both:
        model_llama = llamacpp_comp[llamacpp_comp['model'] == model]
        model_pytorch = pytorch_comp[pytorch_comp['model'] == model]
        
        # Get common GPU/backend combinations
        llama_configs = set(zip(model_llama['GPU'], model_llama['backend']))
        pytorch_configs = set(zip(model_pytorch['GPU'], model_pytorch['backend']))
        
        # For simplicity, we'll plot all combinations and group by model
        # Plot llama.cpp bars
        for _, row in model_llama.iterrows():
            ax2.bar(x_pos, row['speed_t_s'], width=0.35, 
                   color='steelblue', label='llama.cpp' if x_pos == 0 else '')
            ax2.text(x_pos, row['speed_t_s'] + 1, f"{row['speed_t_s']:.1f}", 
                    ha='center', va='bottom', fontsize=8)
            x_positions.append(x_pos)
            x_labels.append(f"{row['model']}\n{row['GPU']}/{row['backend']}")
            x_pos += 1
        
        # Plot pytorch bars
        for _, row in model_pytorch.iterrows():
            ax2.bar(x_pos, row['speed_t_s'], width=0.35, 
                   color='coral', label='PyTorch' if len(x_positions) == 1 else '')
            ax2.text(x_pos, row['speed_t_s'] + 1, f"{row['speed_t_s']:.1f}", 
                    ha='center', va='bottom', fontsize=8)
            x_positions.append(x_pos)
            x_labels.append(f"{row['model']}\n{row['GPU']}/{row['backend']}")
            x_pos += 1
        
        x_pos += 1  # Add spacing between models
    
    ax2.set_ylabel('Speed (tokens/second)', fontsize=12, fontweight='bold')
    ax2.set_xlabel('Model and Configuration', fontsize=12, fontweight='bold')
    ax2.set_xticks(x_positions)
    ax2.set_xticklabels(x_labels, rotation=45, ha='right', fontsize=8)
    ax2.grid(True, alpha=0.3, linestyle='--', axis='y')
    ax2.legend(loc='best', fontsize=10)
    
    # Adjust layout
    plt.tight_layout()
    
    # Save the comparison plot
    output_path2 = os.path.join(script_dir, 'benchmark_inference_comparison.png')
    plt.savefig(output_path2, dpi=300, bbox_inches='tight')
    print(f"Plot 2 saved to: {output_path2}")
    
    plt.show()
else:
    print("No models found with data for both llama.cpp and pytorch")

print("\nDone!")
