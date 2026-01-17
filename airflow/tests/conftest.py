"""
Pytest configuration and shared fixtures
"""

import pytest
import os
import sys
from pathlib import Path

# Add the parent directory to the path so we can import modules
airflow_home = Path(__file__).parent.parent
sys.path.insert(0, str(airflow_home))
sys.path.insert(0, str(airflow_home / "plugins"))

# Set AIRFLOW_HOME environment variable
os.environ["AIRFLOW_HOME"] = str(airflow_home)
os.environ["AIRFLOW__CORE__DAGS_FOLDER"] = str(airflow_home / "dags")
os.environ["AIRFLOW__CORE__PLUGINS_FOLDER"] = str(airflow_home / "plugins")
os.environ["AIRFLOW__CORE__LOAD_EXAMPLES"] = "False"
os.environ["AIRFLOW__CORE__UNIT_TEST_MODE"] = "True"


@pytest.fixture(scope="session")
def airflow_home_path():
    """Return the Airflow home directory path"""
    return airflow_home


@pytest.fixture(scope="session")
def dags_folder():
    """Return the DAGs folder path"""
    return airflow_home / "dags"


@pytest.fixture(autouse=True)
def reset_airflow_db():
    """Reset Airflow database before each test (if needed)"""
    # This is a placeholder - implement if you need to reset DB between tests
    yield


@pytest.fixture
def sample_dag_run_conf():
    """Sample DAG run configuration for testing"""
    return {
        "start_date": "2022-01-01",
        "end_date": "2022-12-31"
    }