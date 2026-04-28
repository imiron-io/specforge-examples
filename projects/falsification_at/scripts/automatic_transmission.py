#!/usr/bin/env python3

# Run as follows:
# uv run python scripts/automatic_transmission.py --system 'automatic_transmission' --spec 'AT6a' --options '{}' --params '{}' --project-dir '.'

import argparse
import json
import os

import io

import pandas as pd
import matlab
import matlab.engine
import numpy as np
import plotly.graph_objects as go
import plotly.subplots as sp

from staliro import Sample, SignalInput, TestOptions, staliro
from staliro.models import Model, Result
from staliro.optimizers import DualAnnealing
from staliro.specifications import rtamt

from specforge_sdk import (
    SpecForgeClient,
    nested_encoding,
    flat_encoding,
    EXPORT_LILO,
    EXPORT_JSON,
    EXPORT_RTAMT,
    converters,
)

parser = argparse.ArgumentParser(
    prog="Automatic Transmission Model Falsifier",
    description="Find a signal which falsifies a given (lilo) specification on the Automatic Transmission model.",
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


class AutotransModel(Model[list[float], None]):
    MODEL_NAME = "Autotrans_shift"

    def __init__(self) -> None:
        self.sampling_step = 0.2
        self.engine = matlab.engine.start_matlab()
        self.engine.addpath(
            str(specforgeClient.project_dir) + "/model/automatic_transmission/"
        )
        model_opts = self.engine.simget(AutotransModel.MODEL_NAME)
        self.model_opts = self.engine.simset(model_opts, "SaveFormat", "Array")

    def simulate(self, sample: Sample) -> Result[list[float], None]:
        assert sample.signals.tspan is not None

        tstart, tend = sample.signals.tspan
        duration = tend - tstart
        sim_t = matlab.double([0, tend])
        n_times = duration // self.sampling_step
        signal_times = np.linspace(tstart, tend, num=int(n_times))
        signal_values = np.array(
            [[signal.at_time(t) for t in signal_times] for signal in sample.signals]
        )

        model_input = matlab.double(
            np.row_stack((signal_times, signal_values)).T.tolist()
        )

        # Create a string buffer to capture and suppress output
        # We create a new one per simulation to avoid memory growing indefinitely
        out_buffer = io.StringIO()
        err_buffer = io.StringIO()

        timestamps, _, data = self.engine.sim(
            self.MODEL_NAME,
            sim_t,
            self.model_opts,
            model_input,
            nargout=3,
            stdout=out_buffer,  # Redirects MATLAB standard output here
            stderr=err_buffer,  # Redirects MATLAB error output here
        )

        times: list[float] = np.array(timestamps).flatten().tolist()
        states: list[list[float]] = list(data)

        return Result(times=times, states=states, extra=None)


model = AutotransModel()

rtamt_formula = specforgeClient.export(
    system=system_name,
    definition=spec_name,
    export_type=EXPORT_RTAMT,
    return_string=True,  # Get the exported string
)

spec = rtamt.parse_discrete(rtamt_formula, {"rpm": 0, "speed": 1, "gear": 2})

optimizer = DualAnnealing()

options = TestOptions(
    runs=1,
    iterations=25,
    tspan=(0, 30),
    signals={
        "throttle": SignalInput(control_points=[(0, 100)] * 7),
        "brake": SignalInput(control_points=[(0, 350)] * 3),
    },
)

runs = staliro(model, spec, optimizer, options)
run = runs[0]
min_cost_eval = min(run.evaluations, key=lambda e: e.cost)
min_cost_trace = min_cost_eval.extra.trace

dataframe = pd.DataFrame(
    {
        "throttle": [
            min_cost_eval.sample.signals["throttle"].at_time(t)
            for t in min_cost_trace.times
        ],
        "brake": [
            min_cost_eval.sample.signals["brake"].at_time(t)
            for t in min_cost_trace.times
        ],
        "time": [t for t in min_cost_trace.times],
        "rpm": [s[0] for s in min_cost_trace.states],
        "speed": [s[1] for s in min_cost_trace.states],
        "gear": [s[2] for s in min_cost_trace.states],
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
    output = json.dumps({"tag": "Err", "contents": "Couldn't Falsify"})
    print(output)
else:
    output = json.dumps(
        {
            "tag": "Ok",
            "contents": {"signal": converters.python_to_api_timeseries(dataframe)},
        }
    )
    print(output)
