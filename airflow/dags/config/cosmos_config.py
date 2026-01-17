"""Cosmos configuration for dbt integration."""

from cosmos import ProfileConfig, ProjectConfig, ExecutionConfig
from cosmos.constants import ExecutionMode


def get_dbt_project_config() -> ProjectConfig:
    """
    Get dbt project configuration.

    Returns:
        ProjectConfig: Configuration for locating dbt project files
    """
    return ProjectConfig(
        dbt_project_path="/opt/airflow/transform",
        models_relative_path="models",
        seeds_relative_path="seeds",
        snapshots_relative_path="snapshots",
    )


def get_dbt_profile_config() -> ProfileConfig:
    """
    Get dbt profile configuration for DuckDB.

    Returns:
        ProfileConfig: Configuration for dbt profile connection
    """
    return ProfileConfig(
        profile_name="strava_transform",
        target_name="dev",
        profiles_yml_filepath="/opt/airflow/transform/profiles.yml",
    )


def get_dbt_execution_config() -> ExecutionConfig:
    """
    Get dbt execution configuration.

    Returns:
        ExecutionConfig: Configuration for how dbt commands are executed
    """
    return ExecutionConfig(
        dbt_executable_path="/usr/local/bin/dbt",
        execution_mode=ExecutionMode.LOCAL,  # Run dbt commands directly in Airflow container
    )
