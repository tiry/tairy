#!/usr/bin/env python3
"""
Generate CSV report from vLLM benchmark logs.

This script parses the logs directory and creates a CSV file with benchmark results.
"""

import os
import re
import csv
import json
import yaml
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime


def detect_architecture(log_file: Path) -> str:
    """Detect if ROCm or CUDA architecture from server log."""
    try:
        with open(log_file, 'r') as f:
            content = f.read()
            # Case-insensitive search for rocm
            if re.search(r'rocm', content, re.IGNORECASE):
                return 'ROCm'
            elif re.search(r'cuda', content, re.IGNORECASE):
                return 'CUDA'
            return 'Unknown'
    except Exception as e:
        return 'Unknown'


def extract_model_size(memory_file: Path) -> Optional[str]:
    """Extract model size from model_memory_info.txt."""
    try:
        with open(memory_file, 'r') as f:
            content = f.read()
            # Look for "Model loading took X.XX GiB memory"
            match = re.search(r'Model loading took ([\d.]+) GiB memory', content)
            if match:
                return f"{match.group(1)} GiB"
    except Exception:
        pass
    return None


def parse_run_params(params_file: Path) -> Dict:
    """Parse run_params.txt key-value file."""
    params = {}
    try:
        with open(params_file, 'r') as f:
            for line in f:
                line = line.strip()
                if '=' in line and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    params[key.strip()] = value.strip()
    except Exception as e:
        pass
    return params


def parse_benchmark_results(log_dir: Path) -> Dict:
    """Parse benchmark results from benchmark.log file."""
    results = {}
    
    # Try to read from benchmark.log first
    benchmark_log = log_dir / 'benchmark.log'
    if benchmark_log.exists():
        try:
            with open(benchmark_log, 'r') as f:
                content = f.read()
                
                # Extract metrics using regex
                # Output token throughput (tok/s): 159.95
                match = re.search(r'Output token throughput \(tok/s\):\s+([\d.]+)', content)
                if match:
                    results['output_throughput'] = float(match.group(1))
                
                # Peak output token throughput (tok/s): 208.00
                match = re.search(r'Peak output token throughput \(tok/s\):\s+([\d.]+)', content)
                if match:
                    results['peak_output_throughput'] = float(match.group(1))
                
                # Peak concurrent requests: 22.00
                match = re.search(r'Peak concurrent requests:\s+([\d.]+)', content)
                if match:
                    results['peak_concurrent_requests'] = float(match.group(1))
                
                # Total Token throughput (tok/s): 175.03
                match = re.search(r'Total Token throughput \(tok/s\):\s+([\d.]+)', content)
                if match:
                    results['total_throughput'] = float(match.group(1))
                    
        except Exception as e:
            pass
    
    # Fall back to JSON files if benchmark.log doesn't exist
    if not results:
        for result_file in log_dir.glob('*_results.json'):
            try:
                with open(result_file, 'r') as f:
                    data = json.load(f)
                    
                    # Extract metrics
                    if 'summary' in data:
                        summary = data['summary']
                        results['output_throughput'] = summary.get('output_throughput', 'N/A')
                        results['peak_output_throughput'] = summary.get('peak_output_throughput', 'N/A')
                        results['peak_concurrent_requests'] = summary.get('peak_concurrent_requests', 'N/A')
                        results['total_throughput'] = summary.get('total_throughput', 'N/A')
                        
            except Exception as e:
                continue
    
    return results


def extract_model_name_from_config(config_file: Path) -> Optional[str]:
    """Extract model name from the server log or config."""
    # Try to get from parent directory's server log
    log_dir = config_file.parent
    server_log = log_dir / 'vllm_server.log'
    
    if server_log.exists():
        try:
            with open(server_log, 'r') as f:
                content = f.read()
                # Look for model name in various formats
                # "model='google/gemma-3-4b-it'"
                match = re.search(r"model='([^']+)'", content)
                if match:
                    return match.group(1)
                # "model": "google/gemma-3-4b-it"
                match = re.search(r'"model":\s*"([^"]+)"', content)
                if match:
                    return match.group(1)
        except Exception:
            pass
    
    return None


def process_log_directory(logs_dir: Path) -> List[Dict]:
    """Process all benchmark runs in the logs directory."""
    results = []
    
    # Iterate through timestamp directories
    for run_dir in sorted(logs_dir.iterdir()):
        if not run_dir.is_dir():
            continue
        
        # Initialize row data
        row = {
            'timestamp': run_dir.name,
            'model_name': 'N/A',
            'model_size': 'N/A',
            'architecture': 'N/A',
            'concurrency': 'N/A',
            'num_prompts': 'N/A',
            'output_throughput': 'N/A',
            'peak_output_throughput': 'N/A',
            'peak_concurrent_requests': 'N/A',
            'total_throughput': 'N/A',
        }
        
        # Try to read run_params.txt first (contains actual parameters used)
        params_file = run_dir / 'run_params.txt'
        if params_file.exists():
            params = parse_run_params(params_file)
            row['model_name'] = params.get('model_name', 'N/A')
            row['concurrency'] = params.get('max_concurrency', 'N/A')
            row['num_prompts'] = params.get('num_prompts', 'N/A')
        
        # Extract architecture from server log
        server_log = run_dir / 'vllm_server.log'
        if server_log.exists():
            row['architecture'] = detect_architecture(server_log)
            
            # If we didn't get model name from params, try server log
            if row['model_name'] == 'N/A':
                model_name = extract_model_name_from_config(run_dir / 'config_*.yaml')
                if model_name:
                    row['model_name'] = model_name
        
        # Extract model size
        memory_file = run_dir / 'model_memory_info.txt'
        if memory_file.exists():
            model_size = extract_model_size(memory_file)
            if model_size:
                row['model_size'] = model_size
        
        # Parse benchmark results
        bench_results = parse_benchmark_results(run_dir)
        row.update(bench_results)
        
        # Check if last 4 columns have valid (non-empty) values
        last_four_columns = ['output_throughput', 'peak_output_throughput', 
                            'peak_concurrent_requests', 'total_throughput']
        has_valid_metrics = all(
            row.get(col) not in ['N/A', None, '', 'nan'] 
            for col in last_four_columns
        )
        
        # Only add row if we have valid data for all last 4 columns
        if has_valid_metrics:
            results.append(row)
    
    return results


def generate_csv_report(logs_dir: Path, output_file: Path):
    """Generate CSV report from benchmark logs."""
    
    print(f"Scanning logs directory: {logs_dir}")
    results = process_log_directory(logs_dir)
    
    if not results:
        print("No benchmark results found!")
        return
    
    # Define CSV columns
    columns = [
        'timestamp',
        'model_name',
        'model_size',
        'architecture',
        'concurrency',
        'num_prompts',
        'output_throughput',
        'peak_output_throughput',
        'peak_concurrent_requests',
        'total_throughput',
    ]
    
    # Write CSV
    with open(output_file, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=columns)
        writer.writeheader()
        writer.writerows(results)
    
    print(f"CSV report generated: {output_file}")
    print(f"Total benchmark runs: {len(results)}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate CSV report from vLLM benchmark logs')
    parser.add_argument(
        '--logs-dir',
        type=Path,
        default=Path(__file__).parent / 'logs',
        help='Path to logs directory (default: ./logs)'
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=Path(__file__).parent / 'benchmark_results.csv',
        help='Output CSV file (default: ./benchmark_results.csv)'
    )
    
    args = parser.parse_args()
    
    if not args.logs_dir.exists():
        print(f"Error: Logs directory not found: {args.logs_dir}")
        return 1
    
    generate_csv_report(args.logs_dir, args.output)
    return 0


if __name__ == '__main__':
    exit(main())
