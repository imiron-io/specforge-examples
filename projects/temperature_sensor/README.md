# Temperature Sensor - SpecForge Sample Project

This is a complete example demonstrating the SpecForge Python SDK capabilities.

## Files

- `temperature_monitoring.lilo` - Sample specification for temperature monitoring
- `sensor_data.csv` - Sample sensor data (31 data points with temperature and humidity)
- `demo.ipynb` - Jupyter notebook demonstrating all SDK features
- `temperature_config.json` - Configuration file (parameters) for the temperature monitoring example
- `util.lilo` - Utility functions for the example

## Setup

> **Note:** Hereafter, we recommend users to open `temperature_sensor` folder with VSCode.

### 1. Create and Activate a Virtual Environment

It is generally recommended (but not mandatory) to do this in a virtual environment. To do so, follow these instructions:

```bash
# Navigate to the sample project directory
cd temperature_sensor

# Create a virtual environment
python -m venv .venv

# Activate the virtual environment
# On Windows:
.venv\Scripts\activate
# On macOS/Linux:
source .venv/bin/activate
```

### 2. Install Dependencies

```bash
# Install the SpecForge SDK Wheel
pip install ../specforge_sdk-xxx.whl

# Install additional dependencies for the sample project
pip install jupyter pandas matplotlib numpy
```

### 3. Verify Installation

```bash
# Check that the SDK is installed correctly
python -c "from specforge_sdk import SpecForgeClient; print('✓ SDK installed successfully')"
```

## Running the Examples

### Prerequisites

1. Ensure SpecForge API server is running on `http://localhost:8080/health`
2. Activate your virtual environment (if not already active):
   ```bash
   # On Windows:
   venv\Scripts\activate
   # On macOS/Linux:
   source venv/bin/activate
   ```

### Run the Examples

To check that the extension is working, execute the cells in `demo.ipynb`. The output of the monitoring commands should have a visualization.

You may need to make sure your notebook is connected to the correct Pyhton kernel. Often, it is `.venv (Python3.X.X)` or `ipykernel`. It can be configured from the VSCode notebook interface.

## Sample Data Overview

The included `sensor_data.csv` contains:

- 31 time points (0.0 to 30.0)
- Temperature readings (20.8°C to 25.0°C)
- Humidity readings (40.9% to 51.5%)

This data is designed to test various specifications including temperature bounds, stability, and humidity correlation.

## Deactivating the Environment

When you're done working with the sample project:

```bash
deactivate
```

## Troubleshooting

### Common Issues

1. **"Module not found" errors**: Ensure the virtual environment is activated and the SDK is installed with `pip install ../specforge_sdk-xxx.whl`
2. **Connection refused**: Make sure the SpecForge API server is running on `http://localhost:8080/health`
3. **Jupyter not found**: Install it with `pip install jupyter` in your activated virtual environment
4. **Missing sample files**: Ensure you're in the `temperature_sensor` directory

### Verify Setup

```bash
# Check Python environment
which python
pip list | grep specforge

# Test API connection
python -c "from specforge_sdk import SpecForgeClient; specforge = SpecForgeClient(); print('Health check:', specforge.health_check())"
```
