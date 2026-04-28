# Example Projects for SpecForge

[SpecForge](https://imiron.io/specforge/) is a tool for authoring and managing formal specifications in Lilo, a domain specific language designed for specifying temporal systems. Refer to the [SpecForge documentation](https://docs.imiron.io/) for more information.

This repository contains some example projects that showcase the different features of SpecForge.

## Example Projects

- [energy_romania](./projects/energy_romania/)
  - Exploration of Energy Statistics in Romania for hourly data over 6 years.
- [falsification_at](./projects/falsification_at/)
  - Automatic Transmission Falsification Example. Requires MATLAB/Simulink. Uses RTAMT.
- [falsification_f16](./projects/falsification_f16/)
  - F16 Fighter Jet Falsification Example. Does not require MATLAB/Simulink. Uses RTAMT.
- [temperature_sensor](./projects/temperature_sensor/)
  - A simple project involving a temperature sensor. Contains a trivial example of setting up falsification.

## Running the Examples

To run the examples, you will need SpecForge installed. Refer to the [docs](https://docs.imiron.io/v/0.5.11/en/setting-up.html) for installation instructions for your platform.

To use the Jupyter notebooks, you will need to download the python SDK, which is available from the [releases page](https://imiron.io/specforge/releases/). Make sure that the `specforge_sdk = { path = ... }` line is present in the `pyproject.toml` file, and is pointing to the correct location of the `.whl` file.
