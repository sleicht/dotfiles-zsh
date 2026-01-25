# Testing Patterns

**Analysis Date:** 2026-01-25

## Overview

This repository uses Python's pytest framework for testing the Dotbot installation framework (found in the `dotbot/` submodule). Shell configuration files (`zsh.d/`) do not have automated tests; they are validated manually via shell execution. Testing is concentrated in `dotbot/tests/`.

## Test Framework

**Runner:**
- pytest (version not specified, assumed recent based on modern syntax)
- Config: No explicit pytest.ini or pyproject.toml configuration found in main repo
- Dotbot submodule has `pyproject.toml` with pytest configuration

**Assertion Library:**
- pytest's built-in `assert` statements with assertion rewriting
- Custom assertion helpers in test fixtures

**Run Commands:**
```bash
pytest dotbot/tests/              # Run all Dotbot tests
pytest dotbot/tests/ -v           # Run with verbose output
pytest dotbot/tests/ --collect-only  # Collect test info without running
```

**Test Discovery:**
- Files: `test_*.py` pattern (e.g., `test_link.py`, `test_config.py`, `test_create.py`)
- Classes/functions: Standard pytest convention (test_* prefix)
- Location: `dotbot/tests/` directory

## Test File Organization

**Location:**
- Pattern: Tests in separate directory from source code
- Path: `dotbot/tests/` alongside `dotbot/` source
- Separate from main dotfiles configuration (`zsh.d/`, `steps/`, `.config/`)

**Naming:**
- `test_link.py` - Tests for symlink/link functionality
- `test_config.py` - Configuration parsing tests
- `test_create.py` - Directory creation tests
- `test_noop.py` - No-operation tests
- `test_clean.py` - Cleanup operation tests
- `test_plugins.py` - Plugin system tests
- `test_bin_dotbot.py` - Main binary/CLI tests
- `conftest.py` - Shared fixtures and configuration

**Structure:**
```
dotbot/
├── tests/
│   ├── conftest.py           # Pytest configuration and fixtures
│   ├── test_link.py          # Symlink tests
│   ├── test_config.py        # Configuration tests
│   ├── test_create.py        # Creation tests
│   ├── test_clean.py         # Cleanup tests
│   ├── test_noop.py          # No-op tests
│   ├── test_plugins.py       # Plugin tests
│   └── test_bin_dotbot.py    # CLI tests
└── lib/                       # Source code being tested
```

## Test Structure

**Suite Organization:**

From `test_link.py`:

```python
def test_link_canonicalization(home: str, dotfiles: Dotfiles, run_dotbot: Callable[..., None]) -> None:
    """Verify links to symlinked targets are canonical."""

    dotfiles.write("f", "apple")
    dotfiles.write_config([{"link": {"~/.f": {"path": "f"}}}])

    dotfiles_symlink = os.path.join(home, "dotfiles-symlink")
    os.symlink(dotfiles.directory, dotfiles_symlink)

    expected = os.path.join(dotfiles.directory, "f")
    actual = os.readlink(os.path.abspath(os.path.expanduser("~/.f")))
    assert expected == actual
```

**Patterns:**

1. **Fixture Usage:** Functions take dependencies as parameters (pytest fixture injection)
   - `home: str` - Isolated home directory
   - `dotfiles: Dotfiles` - Dotfiles management object
   - `run_dotbot: Callable[..., None]` - Function to run dotbot

2. **Setup Pattern:** Test setup happens in test function body
   - Create test files via `dotfiles.write()`
   - Write configuration via `dotfiles.write_config()`
   - Configure symlinks or other state

3. **Execution:** Call function being tested via injected callable
   - `run_dotbot("-c", config_file)`
   - Uses mock.patch for sys.argv

4. **Assertion:** Direct assertions with descriptive messages
   - `assert expected == actual` - Simple equality checks
   - `assert path[: len(str(root))] == str(root), msg` - Slicing with message

## Fixtures and Test Data

**Fixture System:**

From `conftest.py`, key fixtures include:

```python
@pytest.fixture(autouse=True, scope="session")
def standardize_tmp() -> None:
    """Standardize the temporary directory path."""
    # Handles macOS /var symlink and Windows short paths
    # Session-scoped: runs once per test session
```

```python
@pytest.fixture(autouse=True)
def root(standardize_tmp: None) -> Generator[str, None, None]:
    """Create a temporary directory for the duration of each test."""
    # Function-scoped: runs before each test
    # Yields isolated temp directory
    # Cleans up in finally block
```

```python
@pytest.fixture
def home(monkeypatch: pytest.MonkeyPatch, root: str) -> str:
    """Create a home directory for the duration of the test."""
    # Mocks HOME (Unix) or USERPROFILE (Windows)
    # Returns path to isolated home dir
```

```python
@pytest.fixture
def dotfiles(root: str) -> Dotfiles:
    """Create a dotfiles directory."""
    return Dotfiles(root)
```

**Test Data Factory:**

`Dotfiles` class in `conftest.py`:

```python
class Dotfiles:
    """Create and manage a dotfiles directory for a test."""

    def __init__(self, root: str):
        self.root = root
        self.directory = os.path.join(root, "dotfiles")
        os.mkdir(self.directory)

    def write(self, path: str, content: str = "") -> None:
        """Write test file to dotfiles directory."""
        path = os.path.abspath(os.path.join(self.directory, path))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as file:
            file.write(content)

    def write_config(self, config: Any, serializer: str = "yaml", path: Optional[str] = None) -> str:
        """Write dotbot config and return filename."""
        serialize = yaml.dump if serializer == "yaml" else json.dumps
        with open(config_path, "w") as file:
            file.write(serialize(config))
        return config_path
```

**Location:**
- Fixtures defined in `dotbot/tests/conftest.py`
- Factories: `Dotfiles` class serves as factory for test data
- Reusable across all test modules via pytest auto-discovery

## Mocking

**Framework:**
- Python `unittest.mock` (from standard library)
- Mock-patching via decorator/context manager

**Patterns:**

1. **Filesystem Operation Mocking:**

From `conftest.py`:

```python
def wrap_function(function: Callable, function_path: str, arg_index: int, kwarg_key: str, root: str) -> Callable:
    """Wrap filesystem operations to enforce isolation."""

    def wrapper(*args: Any, **kwargs: Any) -> Any:
        value = kwargs[kwarg_key] if kwarg_key in kwargs else args[arg_index]

        # Check path is absolute
        assert value == os.path.abspath(value), f"Must be absolute path"

        # Check path is in test root
        assert value[: len(str(root))] == str(root), f"Must be rooted in {root}"

        return function(*args, **kwargs)

    return wrapper

# Applied via mock.patch:
patches = []
for module, function_name, arg_index, kwarg_key in functions_to_wrap:
    function_path = f"{module.__name__}.{function_name}"
    wrapped = wrap_function(function, function_path, arg_index, kwarg_key, current_root)
    patches.append(mock.patch(function_path, wrapped))
```

2. **CLI Mocking:**

```python
def runner(*argv: Any, **kwargs: Any) -> None:
    argv = ("dotbot", *argv)
    if kwargs.get("custom", False) is not True:
        argv = (*argv, "-c", dotfiles.config_filename)
    with mock.patch("sys.argv", list(argv)):
        dotbot.cli.main()
```

**What to Mock:**
- Filesystem operations (os.mkdir, os.symlink, shutil.rmtree, etc.)
- System calls that could affect the test machine
- Command-line argument parsing (sys.argv)
- Environment variables (via pytest's monkeypatch)

**What NOT to Mock:**
- Core logic being tested
- File I/O operations needed for test validation
- Actual directory creation for isolated test spaces

## Cleanup and Isolation

**Pattern:**
- Fixtures use yield statements with cleanup in finally blocks
- Temporary directories created per test, deleted after

```python
@pytest.fixture(autouse=True)
def root(standardize_tmp: None) -> Generator[str, None, None]:
    current_root = tempfile.mkdtemp()

    # Setup patches and mocks
    [patch.start() for patch in patches]

    try:
        yield current_root
    finally:
        # Cleanup in reverse order
        for patch in reversed(patches):
            patch.stop()
        os.chdir(current_working_directory)
        rmtree(current_root, onexc=rmtree_error_handler)
```

**Isolation Strategy:**
- Monkeypatch: Used for environment variables (HOME, USERPROFILE)
- Temporary directories: Each test gets isolated temp directory
- Mock patches: Start before test, stop in reverse order after
- Current directory: Saved and restored per test

## Type Hints and Documentation

**Usage:**
- All function signatures include type hints
- Return types specified: `-> None`, `-> str`, `-> Callable[..., None]`
- Complex types: `Callable[[int, str], bool]`, `Optional[str]`, `List[str]`
- Generator types: `Generator[str, None, None]`

**Example:**

```python
def test_link_default_target(
    dst: str,
    include_force: bool,
    home: str,
    dotfiles: Dotfiles,
    run_dotbot: Callable[..., None],
) -> None:
```

**Docstrings:**
- Triple-quoted docstrings for fixtures and utilities
- Format: Brief one-liner followed by blank line and details
- Examples from conftest.py

## Test Types

**Unit Tests:**
- Scope: Individual Dotbot directives (link, create, clean, etc.)
- Approach: Mock filesystem, test configuration parsing and execution
- Coverage: Each directive type has dedicated test file
- Examples: `test_link.py` (20+ test functions), `test_create.py`

**Integration Tests:**
- Scope: Multiple directives working together
- Approach: Full isolated filesystem with config files
- Current state: Some parameterized tests combine scenarios
- Example: `test_link_default_target()` with parameter combinations

**Parametrized Tests:**

From `test_link.py`:

```python
@pytest.mark.parametrize("dst", ["~/.f", "~/f"])
@pytest.mark.parametrize("include_force", [True, False])
def test_link_default_target(
    dst: str,
    include_force: bool,
    home: str,
    dotfiles: Dotfiles,
    run_dotbot: Callable[..., None],
) -> None:
```

Creates 4 combinations (2×2) of parameters automatically.

**E2E Tests:**
- Framework: Not explicitly present; would be higher-level testing
- Integration tests with full config files serve as e2e validation

## Cross-Platform Testing

**Patterns:**
- Platform detection via `sys.platform` checks
- Windows-specific code paths tested separately
- Path normalization for cross-platform compatibility
- Examples:
  - `if sys.platform == "win32"`: Handle short paths
  - `if sys.platform == "darwin"`: Handle /var symlink

```python
if sys.platform != "win32":
    return path

# Windows-specific logic for long path conversion
buffer_size = 1000
buffer = ctypes.create_unicode_buffer(buffer_size)
get_long_path_name = ctypes.windll.kernel32.GetLongPathNameW
get_long_path_name(path, buffer, buffer_size)
return buffer.value
```

## Coverage

**Requirements:**
- No explicit coverage requirement or threshold detected
- No coverage configuration in main repo

**View Coverage (if configured):**
```bash
pytest --cov=dotbot dotbot/tests/
pytest --cov=dotbot --cov-report=html dotbot/tests/  # HTML report
```

---

*Testing analysis: 2026-01-25*
