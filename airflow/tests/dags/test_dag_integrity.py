"""
DAG Integrity Tests
Tests that verify DAG structure, configuration, and basic properties
"""

import pytest
from airflow.models import DagBag


class TestDagIntegrity:
    """Test suite for DAG integrity and structure"""

    EXPECTED_NUMBER_OF_DAGS = 1
    DAG_ID = "strava_data_pipeline"

    @pytest.fixture(scope="class")
    def dagbag(self):
        """Load all DAGs"""
        return DagBag(dag_folder="dags/", include_examples=False)

    def test_dagbag_import_errors(self, dagbag):
        """Test that there are no import errors in DAGs"""
        assert len(dagbag.import_errors) == 0, f"DAG import errors: {dagbag.import_errors}"

    def test_expected_number_of_dags(self, dagbag):
        """Test that the expected number of DAGs are present"""
        assert (
            len(dagbag.dags) == self.EXPECTED_NUMBER_OF_DAGS
        ), f"Expected {self.EXPECTED_NUMBER_OF_DAGS} DAGs, found {len(dagbag.dags)}"

    def test_dag_exists(self, dagbag):
        """Test that the Strava pipeline DAG exists"""
        assert self.DAG_ID in dagbag.dags, f"DAG {self.DAG_ID} not found"

    def test_dag_has_tags(self, dagbag):
        """Test that DAG has appropriate tags"""
        dag = dagbag.dags[self.DAG_ID]
        assert dag.tags, "DAG should have tags"
        expected_tags = {"strava", "data_pipeline"}
        assert expected_tags.issubset(
            set(dag.tags)
        ), f"Expected tags {expected_tags} in {dag.tags}"

    def test_dag_not_paused(self, dagbag):
        """Test that DAG is not paused by default"""
        dag = dagbag.dags[self.DAG_ID]
        assert not dag.is_paused_upon_creation, "DAG should not be paused upon creation"

    def test_dag_has_retries(self, dagbag):
        """Test that DAG has retry configuration"""
        dag = dagbag.dags[self.DAG_ID]
        assert (
            dag.default_args.get("retries") is not None
        ), "DAG should have retry configuration"

    def test_dag_has_required_tasks(self, dagbag):
        """Test that DAG has all required tasks"""
        dag = dagbag.dags[self.DAG_ID]
        required_task_ids = [
            "extract_strava_data",
            "validate_pipeline",
        ]

        for task_id in required_task_ids:
            assert task_id in dag.task_ids, f"Required task {task_id} not found in DAG"

    def test_dag_has_dbt_transform_group(self, dagbag):
        """Test that DAG has dbt transformation task group"""
        dag = dagbag.dags[self.DAG_ID]
        dbt_tasks = [task_id for task_id in dag.task_ids if "dbt_transform" in task_id]
        assert len(dbt_tasks) > 0, "DAG should have dbt transformation tasks"

    def test_task_dependencies(self, dagbag):
        """Test that task dependencies are correctly set"""
        dag = dagbag.dags[self.DAG_ID]

        # Extract should run first
        extract_task = dag.get_task("extract_strava_data")
        assert len(extract_task.upstream_list) == 0, "Extract task should have no upstream dependencies"

        # dbt transform tasks should depend on extract
        dbt_tasks = [task for task in dag.tasks if "dbt_transform" in task.task_id]
        for task in dbt_tasks:
            # Check if extract is in the upstream (directly or through task group)
            all_upstream = task.upstream_task_ids
            assert any(
                "extract" in str(upstream).lower() for upstream in all_upstream
            ) or len(
                all_upstream
            ) > 0, f"dbt task {task.task_id} should depend on extract or other dbt tasks"

    def test_task_pool_configuration(self, dagbag):
        """Test that dbt tasks use the correct pool for sequential execution"""
        dag = dagbag.dags[self.DAG_ID]
        dbt_run_tasks = [
            task for task in dag.tasks if "dbt_transform" in task.task_id and ".run" in task.task_id
        ]

        for task in dbt_run_tasks:
            assert (
                task.pool == "dbt_duckdb_pool"
            ), f"dbt task {task.task_id} should use dbt_duckdb_pool"

    def test_dag_max_active_runs(self, dagbag):
        """Test that DAG has proper max_active_runs to prevent concurrent runs"""
        dag = dagbag.dags[self.DAG_ID]
        assert dag.max_active_runs == 1, "DAG should have max_active_runs=1 for DuckDB compatibility"

    def test_task_retries_configuration(self, dagbag):
        """Test that tasks have reasonable retry configuration"""
        dag = dagbag.dags[self.DAG_ID]

        for task in dag.tasks:
            # All tasks should inherit retries from DAG defaults or have their own
            retries = task.retries if hasattr(task, "retries") else dag.default_args.get("retries", 0)
            assert retries >= 0, f"Task {task.task_id} should have non-negative retries"
            assert retries <= 3, f"Task {task.task_id} should not have excessive retries"