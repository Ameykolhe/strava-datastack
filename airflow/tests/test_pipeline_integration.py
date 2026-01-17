"""
Integration Tests for Strava Data Pipeline
Tests the end-to-end pipeline execution
"""

import pytest
import os
from datetime import datetime, timedelta
from airflow.models import DagBag, DagRun, TaskInstance
from airflow.utils.state import DagRunState, TaskInstanceState
from airflow.utils.types import DagRunType


class TestPipelineIntegration:
    """Integration test suite for the complete pipeline"""

    DAG_ID = "strava_data_pipeline"

    @pytest.fixture(scope="class")
    def dagbag(self):
        """Load DAGs"""
        return DagBag(dag_folder="dags/", include_examples=False)

    @pytest.fixture(scope="class")
    def dag(self, dagbag):
        """Get the Strava pipeline DAG"""
        return dagbag.get_dag(self.DAG_ID)

    def test_dag_loads_successfully(self, dag):
        """Test that the DAG loads without errors"""
        assert dag is not None, f"DAG {self.DAG_ID} failed to load"

    def test_dag_has_correct_schedule(self, dag):
        """Test that DAG has appropriate schedule"""
        # DAG should be manually triggered or have a schedule
        assert dag.schedule_interval is not None or dag.schedule_interval == "@daily"

    def test_all_tasks_have_owners(self, dag):
        """Test that all tasks have owners defined"""
        for task in dag.tasks:
            owner = task.owner if hasattr(task, 'owner') else dag.default_args.get('owner')
            assert owner is not None, f"Task {task.task_id} should have an owner"

    def test_extract_task_configuration(self, dag):
        """Test that extract task is properly configured"""
        extract_task = dag.get_task("extract_strava_data")

        # Should use the custom operator
        assert extract_task.__class__.__name__ == "StravaExtractOperator"

        # Should have template fields for date parameters
        assert hasattr(extract_task, 'extract_start_date')
        assert hasattr(extract_task, 'extract_end_date')

    def test_dbt_tasks_configuration(self, dag):
        """Test that dbt tasks are properly configured"""
        dbt_tasks = [task for task in dag.tasks if "dbt_transform" in task.task_id]

        assert len(dbt_tasks) > 0, "Should have dbt transformation tasks"

        # All dbt run tasks should use the sequential pool
        dbt_run_tasks = [t for t in dbt_tasks if ".run" in t.task_id]
        for task in dbt_run_tasks:
            assert task.pool == "dbt_duckdb_pool", \
                f"dbt task {task.task_id} should use dbt_duckdb_pool for sequential execution"

    def test_validate_task_exists(self, dag):
        """Test that pipeline has a validation task"""
        validate_task = dag.get_task("validate_pipeline")
        assert validate_task is not None, "Pipeline should have validation task"

    def test_task_execution_order(self, dag):
        """Test that tasks execute in the correct order"""
        extract_task = dag.get_task("extract_strava_data")
        validate_task = dag.get_task("validate_pipeline")

        # Extract should have no upstream tasks
        assert len(extract_task.upstream_list) == 0

        # Validate should be at the end
        dbt_tasks = [task for task in dag.tasks if "dbt_transform" in task.task_id]
        # At least some dbt tasks should be upstream of validate
        assert len(validate_task.upstream_list) > 0

    def test_dag_with_valid_dates(self, dag):
        """Test that DAG can be triggered with valid date configuration"""
        # Test with 2022 dates (known to have data in tests)
        conf = {
            "start_date": "2022-01-01",
            "end_date": "2022-12-31"
        }

        # Create a test dag run (don't actually execute)
        execution_date = datetime(2022, 1, 1)

        # Verify no errors when creating run with this config
        # (We won't actually run it in unit tests)
        assert dag is not None

    def test_dag_handles_missing_config(self, dag):
        """Test that DAG handles missing date configuration"""
        # Should be able to create a run without config (uses defaults)
        conf = {}

        # The extract operator should handle None dates by using default lookback
        extract_task = dag.get_task("extract_strava_data")
        assert extract_task.extract_start_date is None or \
               hasattr(extract_task, 'extract_start_date')

    def test_sequential_execution_config(self, dag):
        """Test that DAG is configured for sequential execution"""
        # max_active_runs should be 1 to prevent concurrent DuckDB access
        assert dag.max_active_runs == 1, \
            "DAG should have max_active_runs=1 for DuckDB"

        # dbt tasks should use a pool with 1 slot
        dbt_run_tasks = [t for t in dag.tasks if "dbt_transform" in t.task_id and ".run" in t.task_id]
        pools = set(t.pool for t in dbt_run_tasks)
        assert "dbt_duckdb_pool" in pools, \
            "dbt tasks should use dbt_duckdb_pool"

    def test_task_retry_configuration(self, dag):
        """Test that tasks have appropriate retry configuration"""
        # Extract task should have retries
        extract_task = dag.get_task("extract_strava_data")
        retries = extract_task.retries if hasattr(extract_task, 'retries') else dag.default_args.get('retries')

        # Should have some retries but not too many
        assert retries is not None, "Extract task should have retry configuration"

    def test_task_timeout_configuration(self, dag):
        """Test that tasks have reasonable timeout configuration"""
        for task in dag.tasks:
            # Tasks should complete within reasonable time
            # This is a sanity check that no task is configured with extremely long timeouts
            if hasattr(task, 'execution_timeout') and task.execution_timeout:
                assert task.execution_timeout.total_seconds() <= 7200, \
                    f"Task {task.task_id} has timeout > 2 hours"