# Energy Production and Consumption in the Romanian Electricity Grid

A SpecForge project specifying temporal properties over hourly electricity production and consumption, and a guided tour of the **Lilo** language and tooling.

The data is from [this Kaggle dataset](https://www.kaggle.com/datasets/stefancomanita/hourly-electricity-consumption-and-production/data), which has hourly grid statistics over six consecutive years.

## Project files

- [`Energy.lilo`](./Energy.lilo) — the `main` system: signals, parameters, assumptions and temporal specs.
- [`Utils.lilo`](./Utils.lilo) — a module with the shared units (`MW`, `MWh`, `h`), the `energy` helper and the `Thresholds` record; `Energy.lilo` imports it four ways (plain, aliased, `use { … }`, unit imports).
- [`explore.ipynb`](./explore.ipynb) — a notebook driving the server: satisfiability, monitoring, exemplification and RTAMT export.
- [`specforge.toml`](./specforge.toml) — project config: label colours and a validation rule.
- `sampled.csv`, `first60.csv`, `last60.csv` — the data; columns match the signals in `Energy.lilo`.

## Searching, validating and labelling specs

The `specforge` CLI exposes the same spec-search engine as the VS Code extension. Run these from the project directory:

```sh
# Find all safety-critical specs.
specforge search --query 'label:safety'

# Search by custom field — specs a reviewer has signed off.
specforge search --query 'reviewed:true AND owner:"grid-ops"'

# Validate the rules declared in specforge.toml (every reviewed spec must name an owner).
specforge validate

# Validate an ad-hoc containment rule: is every renewable spec also a production spec?
specforge validate --antecedent 'label:renewable' --consequent 'label:production'

# Bulk-apply a label to every spec matching a query.
specforge bulk-label --query 'label:renewable' --label 'green-energy'
```

## Setup

See the [official documentation](https://docs.imiron.io) for setting up the SpecForge server, the VS Code extension and the Python SDK.
