#!/usr/bin/env python3

import json
import math
import random
import sys

# Flip a coin to decide between success and failure
if random.random() < 0.5:
    # Generate signal samples over 12 seconds with temperature and humidity
    samples = []
    for i in range(121):  # 0 to 12 seconds, every 0.1 seconds
        time = i * 0.1
        if time < 3.0:
            temperature = 22 + 8 * math.sin(time * 0.5)
        elif time < 6.0:
            temperature = 50 + 3 * math.sin(time)
        elif time < 9.0:
            progress = (time - 6.0) / 3.0
            temperature = 50 - progress * (50 - 25) + 3 * math.sin(time * 2)
        else:
            temperature = 25 + 5 * math.sin(time * 0.3)

        if 15.0 <= temperature <= 35.0:
            humidity = 50 + 20 * math.cos(time * 0.7)
        else:
            humidity = 85 + 10 * math.sin(time)

        samples.append(
            {"time": time, "value": {"temperature": temperature, "humidity": humidity}}
        )

    data = {
        "tag": "Ok",
        "contents": {
            "signal": {
                "encoding": {"tag": "Flat", "contents": {"separator": "_"}},
                "signal": {"tag": "SignalJson", "contents": {"samples": samples}},
            }
        },
    }
else:
    data = {
        "tag": "Err",
        "contents": {
            "message": "Temperature monitoring falsifier failed to generate signal"
        },
    }

json.dump(data, sys.stdout)
sys.stdout.write("\n")
