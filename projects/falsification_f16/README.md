# Falsification Example - F16 Aircraft Model

In this example project, we demonstrate how SpecForge can be used as a part of a falsification workflow. **Falsification**, usually intended as a part of specification-driven development, is the discovery of inputs to a system which violates the given specifications.

Generally, the problem can be understood in terms of the following components.

- Context: System Model (i.e, a relation between input signals and output signals)
- Input: A Specification on the input and output signals of the system
- Output: An Input Signal that causes the system to violate the specification

We will use the Lilo language to express our specifications in temporal logic. In all our examples, the models will be externally fixed and not be a part of the input. We use [Ψ-Taliro](https://psy-taliro.readthedocs.io/) [3], as our falsification engine. Ψ-Taliro treats the models as a blackbox, meaning that the internal implementation details of the model are unavailable to the falsifier.

We use a model in this example, which is frequently cited as an example in the literature, and is listed as part of the benchmarks in [ARCH-COMP](https://easychair.org/publications/volume/ARCH-COMP24).

- **F16 Aircraft Model**: This is a model of the [F16 aircraft](https://en.wikipedia.org/wiki/General_Dynamics_F-16_Fighting_Falcon) modelled using 16 continuous variables with piecewise nonlinear differential equations, whose core component is a ground collision avoidance system. It is taken from [1].

## Dependencies

To run this example project, some dependencies are required.

Ensure that you have access to the SpecForge server, either on a remote machine or from a locally running SpecForge executable. Also, ensure that VSCode extension for SpecForge is installed so that the interactive visualization and the easy analysis features can be used.

This project is intended to be used within a Python Ecosystem. Using a virtualization environment (directly with `venv`, or using `poetry` or `uv`) is recommended. We have included a `pyproject.toml` file that could be used to set up the dependencies.

- The Specforge SDK is needed to interface with the SpecForge server
- The F16 model requires installation through an [external source](https://github.com/cpslab-asu/aerobenchvvpython)

### Setting up a Python Virtual Environment

In this subsection, we give some instructions on how one could set up a virtual environment for working with Python projects using `uv`. If you prefer to use a different tool, or are already familiar with this, this subsection can be skipped.

1. Install `uv`. See the official instructions in [the `uv` documentation](https://docs.astral.sh/uv/getting-started/installation/).
2. Navigate to the project directory, i.e, the directory in which the `pyproject.toml` file is located.
3. You may need to update the path for the `specforge-sdk` in `pyproject.toml`, especially if using a wheel file. If so, change the appropriate line to

```
specforge-sdk = { path = "path/to/specforge_sdk-x.y.z-py3-none-any.whl" }
```

4. If you do not wish to use the MATLAB, remove the `matlab` and `matlabengine` dependencies from `pyproject.toml`.
5. Run `uv sync`. This should create a `.venv` directory which would have the appropriate dependencies (including the correct version of python) installed.
6. Run `source .venv/bin/activate` to use the Shell Hook with access to `python`. You can confirm that this has been configured correctly as follows.

```bash
$ source .venv/bin/activate
(falsification-examples) $ which python
/Users/agnishom/code/specforge/api/examples/projects/falsification/.venv/bin/python
```

7. Now, you can browse the example notebooks. Make sure that your notebook is connected to the kernel in the `.venv`. This is usually configured automatically, but can also be done manually. To do so, run `jupyter server` and copy and paste the server URL in the kernel settings in the VSCode notebook viewer.

## Running the Examples

The exploratory notebooks are included in the `notebooks` folder. They demonstrate how to work with Lilo Specifications and use them in falsification workflows.

In addition, the falsification workflow can be invoked using the _easy analysis_ option of the VSCode extension. Doing so will invoke the python scripts included in the `scripts` folder. Note that these python scripts require the same dependencies. The scripts are invoked with command line arguments by the VSCode extension, in a manner similar to this:

```bash
python scripts/automatic_transmission.py --system 'automatic_transmission' --spec 'AT6a' --options '{}' --params '{}' --project-dir './spec/'
```

The specs are included in the `spec` folder as `.lilo` files.

---

1. Peter Heidlauf, Alexander Collins, Michael Bolender, and Stanley Bak. Verification challenges in F-16 ground collision avoidance and other automated maneuvers. In ARCH18. International Workshop on Applied Verification of Continuous and Hybrid Systems, EPiC Series in Computing, pages 208–217. EasyChair, 2018.
2. Bardh Hoxha, Houssam Abbas, and Georgios Fainekos. Benchmarks for temporal logic requirements for automotive systems. In ARCH14-15. International Workshop on Applied veRification for Continuous and Hybrid Systems, EPiC Series in Computing, pages 25–30. EasyChair, 2015.
3. Quinn Thibeault, Jacob Anderson, Aniruddh Chandratre, Giulia Pedrielli, and Georgios Fainekos. PSY-TaLiRo: A Python Toolbox for Search-Based Test Generation for Cyber-Physical Systems. In Formal Methods for Industrial Critical Systems, pages 223–231. Springer, 2021.
