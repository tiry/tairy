#!/usr/bin/env python3
"""
Benchmark Plotting Script
Generates comparative benchmark plots from benchmarks.csv
Creates separate plots for pp512 and tg128 tests
"""

import pandas as pd
import matplotlib.pyplot as plt
import os

# Read the CSV data
script_dir = os.path.dirname(os.path.abspath(__file__))
csv_path = os.path.join(script_dir, 'benchmarks.csv')
df = pd.read_csv(csv_path)

# Define backend colors and markers
backend_styles = {
    'rocm': {'color': 'red', 'marker': 'o', 'linestyle': '-', 'label': 'AMD/ROCm'},
    'amd/vulkan': {'color': 'orange', 'marker': 's', 'linestyle': '--', 'label': 'AMD/Vulkan'},
    'cuda': {'color': 'green', 'marker': '^', 'linestyle': '-', 'label': 'NVIDIA/CUDA'},
    'nvidia/vulkan': {'color': 'blue', 'marker': 'D', 'linestyle': '--', 'label': 'NVIDIA/Vulkan'}
}

# Create figure with 2 subplots
fig, axes = plt.subplots(1, 2, figsize=(16, 6))
fig.suptitle('LLM Benchmark Comparison', fontsize=16, fontweight='bold')

# Test types
tests = ['pp512', 'tg128']
test_titles = {
    'pp512': 'Prompt Processing (512 tokens)',
    'tg128': 'Text Generation (128 tokens)'
}

for idx, test in enumerate(tests):
    ax = axes[idx]
    
    # Filter data for this test
    test_data = df[df['test'] == test]
    
    # Plot each backend
    for backend, style in backend_styles.items():
        backend_data = test_data[test_data['backend'] == backend]
        
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
    ax.legend(loc='best', fontsize=10)
    
    # Set x-axis to show actual model sizes
    if not test_data.empty:
        ax.set_xlim(test_data['size_GiB'].min() - 1, test_data['size_GiB'].max() + 1)

# Adjust layout
plt.tight_layout()

# Save the plot
output_path = os.path.join(script_dir, 'benchmark_comparison.png')
plt.savefig(output_path, dpi=300, bbox_inches='tight')
print(f"Plot saved to: {output_path}")

# Show the plot
plt.show()
