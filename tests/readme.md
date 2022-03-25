# Realms-contracts testing

## Commands

To run all tests:

`$ pytest -n auto` with `n` the number of parallel workers.

To run a specific test:

`$ pytest tests/settling_game/00_realms_contract_test.py`

### pytest Flags

```
-n num_workers          Number of parallel workers, can also use `auto`
-s                      Show output (like prints etc), prob won't work well with `-n`
-v                      Verbose
```

## Guidelines

### Naming convention

Dirs under `tests/` should reflect dir naming under `contracts/`.

File names: `name_test.py`

Module-related test files should have the module id in their name.

### Fixtures

Fixtures can be used as test inputs. If a fixture is required across more than one file, it can be put in `conftest.py`
