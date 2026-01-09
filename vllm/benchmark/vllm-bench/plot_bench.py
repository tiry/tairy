#!/usr/bin/env python3
"""
Generate plots showing throughput vs concurrency for vLLM benchmarks.

Creates one plot per architecture showing how total_throughput varies
with concurrency for each model.
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from pathlib import Path
import argparse
from typing import Dict, List
import numpy as np


def generate_plots(csv_file: Path, output_dir: Path):
    """Generate throughput vs concurrency plots for each architecture."""
    
    # Read the CSV file
    try:
        df = pd.read_csv(csv_file)
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        return
    
    # Filter out rows without benchmark results
    df = df[df['total_throughput'] != 'N/A']
    
    # Convert numeric columns
    df['total_throughput'] = pd.to_numeric(df['total_throughput'], errors='coerce')
    df['concurrency'] = pd.to_numeric(df['concurrency'], errors='coerce')
    
    # Drop rows with NaN values
    df = df.dropna(subset=['total_throughput', 'concurrency', 'architecture', 'model_name'])
    
    if df.empty:
        print("No valid benchmark data found in CSV!")
        return
    
    # Get unique architectures
    architectures = df['architecture'].unique()
    
    print(f"Found architectures: {', '.join(architectures)}")
    
    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate a plot for each architecture
    for arch in architectures:
        if arch == 'Unknown':
            continue
            
        print(f"Generating plot for {arch}...")
        
        # Filter data for this architecture
        arch_data = df[df['architecture'] == arch].copy()
        
        if arch_data.empty:
            print(f"No data for {arch}, skipping...")
            continue
        
        # Create figure
        plt.figure(figsize=(12, 8))
        
        # Get unique models for this architecture
        models = arch_data['model_name'].unique()
        
        # Define colors for different models
        colors = plt.cm.tab10(np.linspace(0, 1, len(models)))
        
        # Plot data for each model
        for idx, model in enumerate(models):
            model_data = arch_data[arch_data['model_name'] == model].copy()
            
            # Sort by concurrency for proper line plotting
            model_data = model_data.sort_values('concurrency')
            
            # Extract model short name (last part after /)
            model_short = model.split('/')[-1] if '/' in model else model
            
            # Plot line with markers
            plt.plot(
                model_data['concurrency'], 
                model_data['total_throughput'],
                marker='o',
                markersize=8,
                linewidth=2,
                color=colors[idx],
                label=model_short,
                alpha=0.8
            )
            
            # Add value labels on points
            for _, row in model_data.iterrows():
                plt.annotate(
                    f"{row['total_throughput']:.1f}",
                    (row['concurrency'], row['total_throughput']),
                    textcoords="offset points",
                    xytext=(0, 10),
                    ha='center',
                    fontsize=8,
                    alpha=0.7
                )
        
        # Customize plot
        plt.xlabel('Concurrency', fontsize=12, fontweight='bold')
        plt.ylabel('Total Throughput (tok/s)', fontsize=12, fontweight='bold')
        plt.title(f'vLLM Benchmark: Total Throughput vs Concurrency\nArchitecture: {arch}', 
                  fontsize=14, fontweight='bold', pad=20)
        plt.grid(True, alpha=0.3, linestyle='--')
        plt.legend(loc='best', fontsize=10, framealpha=0.9)
        
        # Add some padding to y-axis
        ymin, ymax = plt.ylim()
        plt.ylim(ymin * 0.95, ymax * 1.1)
        
        # Set x-axis to show integer concurrency values
        plt.gca().xaxis.set_major_locator(plt.MaxNLocator(integer=True))
        
        # Tight layout
        plt.tight_layout()
        
        # Save plot
        output_file = output_dir / f'throughput_vs_concurrency_{arch.lower()}.png'
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        print(f"Saved plot: {output_file}")
        
        plt.close()
    
    print(f"\nAll plots saved to: {output_dir}")


def main():
    parser = argparse.ArgumentParser(
        description='Generate throughput vs concurrency plots from vLLM benchmark results'
    )
    parser.add_argument(
        '--csv',
        type=Path,
        default=Path(__file__).parent / 'benchmark_results.csv',
        help='Path to benchmark results CSV file (default: ./benchmark_results.csv)'
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path(__file__).parent / 'plots',
        help='Output directory for plots (default: ./plots)'
    )
    
    args = parser.parse_args()
    
    if not args.csv.exists():
        print(f"Error: CSV file not found: {args.csv}")
        print("Run generate_report.py first to create the CSV file.")
        return 1
    
    generate_plots(args.csv, args.output_dir)
    return 0


if __name__ == '__main__':
    exit(main())
