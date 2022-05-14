# Realms-contracts testing

## Commands

To run all tests:

`$ pytest -n auto` with `n` the number of parallel workers.

To run a specific test:

`$ pytest -s tests/settling_game/01_settling_test.py`
`$ pytest -s tests/settling_game/04_calculator_test.py`
`$ pytest -s tests/settling_game/06_combat_test.py`


### pytest Flags

```
-n num_workers          Number of parallel workers, can also use `auto`
-s                      Show output (like prints etc), prob won't work well with `-n`
-v                      Verbose
```

## Guidelines

### Template

```python
<<< imports >>>

<<< constants >>>

<<< custom util functions >>>
# put common utils in ./tests/utils.py

<<< custom fixtures >>>
# put common fixtures in ./tests/conftest.py

<<< tests >>>
```

### Naming convention

Dirs under `tests/` should reflect dir naming under `contracts/`.

File names: `name_test.py`

Module-related test files should have the module id in their name.

### Fixtures

Fixtures can be used as test inputs. If a fixture is required across more than one file, it can be put in `conftest.py`

#### Scopes

Use as e.g.: `@pytest.fixture(scope="session")`. From https://docs.pytest.org/en/6.2.x/fixture.html.

>`function`: the default scope, the fixture is destroyed at the end of the test.
>
>`class`: the fixture is destroyed during teardown of the last test in the class.
>
>`module`: the fixture is destroyed during teardown of the last test in the module.
>
>`package`: the fixture is destroyed during teardown of the last test in the package.
>
>`session`: the fixture is destroyed at the end of the test session.
