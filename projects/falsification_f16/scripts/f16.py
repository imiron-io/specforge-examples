#!/usr/bin/env python3

from sys import monitoring
import sys
import logging
import math
import argparse
from typing import Final

import numpy as np
import plotly.graph_objects as go

# This is installed via git+https://github.com/cpslab-asu/aerobenchvvpython.git
from aerobench.examples.gcas.gcas_autopilot import GcasAutopilot
from aerobench.run_f16_sim import run_f16_sim

from staliro import TestOptions, Trace, staliro
from staliro.models import Blackbox, blackbox
from staliro.optimizers import DualAnnealing
from staliro.specifications import rtamt

TSPAN: Final[tuple[float, float]] = (0, 15)

from specforge_sdk import (
    SpecForgeClient,
    nested_encoding,
    flat_encoding,
    EXPORT_LILO,
    EXPORT_JSON,
    EXPORT_RTAMT,
    converters,
)
import pandas as pd
import json
import numpy as np
import os

parser = argparse.ArgumentParser(
    prog="F16Falsifier",
    description="Find a signal which falsifies a given (lilo) specification on the F16 model.",
)
parser.add_argument(
    "--project-dir",
    type=str,
    help="Path to the SpecForge project directory.",
    required=True,
)
parser.add_argument(
    "--system", type=str, help="Name of the Lilo system.", required=True
)
parser.add_argument(
    "--spec", type=str, help="Name of the Lilo specification.", required=True
)
parser.add_argument(
    "--params",
    type=json.loads,
    default={},
    help="Additional parameters for the model.",
    required=False,
)
parser.add_argument(
    "--options",
    type=json.loads,
    default={},
    help="Additional options for the falsification process.",
    required=False,
)

args = parser.parse_args()
project_dir = args.project_dir
system_name = args.system
spec_name = args.spec
# params = args.params
# options = args.options

port = os.environ.get("SPECFORGE_PORT", "8080")
specforgeClient = SpecForgeClient(
    base_url="http://localhost:" + port, project_dir=project_dir
)

if not specforgeClient.health_check():
    raise ConnectionError("Could not connect to SpecForge server.")


@blackbox()
def f16_model(inputs: Blackbox.Inputs) -> Trace[list[float]]:
    power = 9
    alpha = np.deg2rad(2.1215)
    beta = 0
    alt = 2330
    vel = 540
    phi = inputs.static["phi"]
    theta = inputs.static["theta"]
    psi = inputs.static["psi"]

    initial_state = [vel, alpha, beta, phi, theta, psi, 0, 0, 0, 0, 0, 0, alt, power]
    step = 1.0 / 30.0
    autopilot = GcasAutopilot(init_mode="roll", stdout=False)
    result = run_f16_sim(initial_state, TSPAN[1], autopilot, step, extended_states=True)
    states = np.vstack(
        (
            np.array([0 if x == "standby" else 1 for x in result["modes"]]),
            result["states"][:, 4],  # roll
            result["states"][:, 5],  # pitch
            result["states"][:, 6],  # yaw
            result["states"][:, 12],  # altitude
        )
    )

    return Trace(times=result["times"], states=np.transpose(states).tolist())


rtamt_formula = specforgeClient.export(
    system=system_name,
    definition=spec_name,
    export_type=EXPORT_RTAMT,
    return_string=True,  # Get the exported string
)
# print("Exported RTAMT formula:", rtamt_formula)

spec = rtamt.parse_dense(rtamt_formula, {"alt": 4})
optimizer = DualAnnealing()
options = TestOptions(
    runs=1,
    iterations=10,
    tspan=TSPAN,
    static_inputs={
        "phi": math.pi / 4 + np.array([-math.pi / 20, math.pi / 30]),
        "theta": -math.pi / 2 * 0.8 + np.array([0, math.pi / 20]),
        "psi": -math.pi / 4 + np.array([-math.pi / 8, math.pi / 8]),
    },
)

# print("Running Falsification...")

# logging.basicConfig(level=logging.DEBUG)

runs = staliro(f16_model, spec, optimizer, options)
run = runs[0]
min_cost_eval = min(run.evaluations, key=lambda e: e.cost)
min_cost_trace = min_cost_eval.extra.trace

dataframe = pd.DataFrame(
    {
        "time": [t for t in min_cost_trace.times],
        "mode": [bool(s[0]) for s in min_cost_trace.states],
        "roll": [s[1] for s in min_cost_trace.states],
        "pitch": [s[2] for s in min_cost_trace.states],
        "yaw": [s[3] for s in min_cost_trace.states],
        "alt": [s[4] for s in min_cost_trace.states],
    }
)

monitoring_result = specforgeClient.monitor(
    system=system_name,
    definition=spec_name,
    data=dataframe,
    verdicts=False,
    return_timeseries=True,
)

if monitoring_result.loc[0, "value"] == True:
    output = json.dumps({"tag": "Err", "contents": None})
    print(output)
else:
    output = json.dumps(
        {
            "tag": "Ok",
            "contents": {"signal": converters.python_to_api_timeseries(dataframe)},
        }
    )
    print(output)
