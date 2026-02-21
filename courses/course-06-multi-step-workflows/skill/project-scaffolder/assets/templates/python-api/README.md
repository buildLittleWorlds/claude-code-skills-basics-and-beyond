# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

## Testing

```bash
pytest
```

## Development

```bash
ruff check .
ruff format .
```
