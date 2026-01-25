"""Explicit schema contract for Strava raw tables."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping


@dataclass(frozen=True)
class ColumnContract:
    name: str
    data_type: str
    nullable: bool
    default: Any = None
    timezone: bool | None = None
    is_system: bool = False

    def to_dlt_column(self) -> dict[str, Any]:
        column: dict[str, Any] = {
            "name": self.name,
            "data_type": self.data_type,
            "nullable": self.nullable,
        }
        if self.timezone is not None:
            column["timezone"] = self.timezone
        return column


@dataclass(frozen=True)
class TableContract:
    name: str
    columns: tuple[ColumnContract, ...]

    def to_dlt_columns(self) -> list[dict[str, Any]]:
        return [column.to_dlt_column() for column in self.columns]

    @property
    def column_names(self) -> set[str]:
        return {column.name for column in self.columns}


SCHEMA_CONTRACTS: dict[str, TableContract] = {
    "activities": TableContract(
        name="activities",
        columns=(
            ColumnContract(name="location_city", data_type="text", nullable=True),
            ColumnContract(name="location_state", data_type="text", nullable=True),
            ColumnContract(name="location_country", data_type="text", nullable=True),
            ColumnContract(name="resource_state", data_type="bigint", nullable=True),
            ColumnContract(name="athlete", data_type="json", nullable=True),
            ColumnContract(name="name", data_type="text", nullable=True),
            ColumnContract(name="distance", data_type="double", nullable=True),
            ColumnContract(name="moving_time", data_type="bigint", nullable=True),
            ColumnContract(name="elapsed_time", data_type="bigint", nullable=True),
            ColumnContract(name="total_elevation_gain", data_type="double", nullable=True),
            ColumnContract(name="type", data_type="text", nullable=True),
            ColumnContract(name="sport_type", data_type="text", nullable=True),
            ColumnContract(name="id", data_type="bigint", nullable=False),
            ColumnContract(
                name="start_date",
                data_type="timestamp",
                nullable=True,
            ),
            ColumnContract(
                name="start_date_local",
                data_type="timestamp",
                nullable=True,
            ),
            ColumnContract(name="timezone", data_type="text", nullable=True),
            ColumnContract(name="utc_offset", data_type="double", nullable=True),
            ColumnContract(name="achievement_count", data_type="bigint", nullable=True),
            ColumnContract(name="kudos_count", data_type="bigint", nullable=True),
            ColumnContract(name="comment_count", data_type="bigint", nullable=True),
            ColumnContract(name="athlete_count", data_type="bigint", nullable=True),
            ColumnContract(name="photo_count", data_type="bigint", nullable=True),
            ColumnContract(name="map", data_type="json", nullable=True),
            ColumnContract(name="trainer", data_type="bool", nullable=True),
            ColumnContract(name="commute", data_type="bool", nullable=True),
            ColumnContract(name="manual", data_type="bool", nullable=True),
            ColumnContract(name="private", data_type="bool", nullable=True),
            ColumnContract(name="visibility", data_type="text", nullable=True),
            ColumnContract(name="flagged", data_type="bool", nullable=True),
            ColumnContract(name="gear_id", data_type="text", nullable=True),
            ColumnContract(name="start_latlng", data_type="json", nullable=True),
            ColumnContract(name="end_latlng", data_type="json", nullable=True),
            ColumnContract(name="average_speed", data_type="double", nullable=True),
            ColumnContract(name="max_speed", data_type="double", nullable=True),
            ColumnContract(name="has_heartrate", data_type="bool", nullable=True),
            ColumnContract(name="heartrate_opt_out", data_type="bool", nullable=True),
            ColumnContract(
                name="display_hide_heartrate_option",
                data_type="bool",
                nullable=True,
            ),
            ColumnContract(name="elev_high", data_type="double", nullable=True),
            ColumnContract(name="elev_low", data_type="double", nullable=True),
            ColumnContract(name="upload_id", data_type="bigint", nullable=True),
            ColumnContract(name="upload_id_str", data_type="text", nullable=True),
            ColumnContract(name="external_id", data_type="text", nullable=True),
            ColumnContract(name="from_accepted_tag", data_type="bool", nullable=True),
            ColumnContract(name="pr_count", data_type="bigint", nullable=True),
            ColumnContract(name="total_photo_count", data_type="bigint", nullable=True),
            ColumnContract(name="has_kudoed", data_type="bool", nullable=True),
            ColumnContract(name="suffer_score", data_type="double", nullable=True),
            ColumnContract(
                name="_dlt_load_id",
                data_type="text",
                nullable=False,
                is_system=True,
            ),
            ColumnContract(
                name="_dlt_id",
                data_type="text",
                nullable=False,
                is_system=True,
            ),
            ColumnContract(name="workout_type", data_type="bigint", nullable=True),
            ColumnContract(name="device_name", data_type="text", nullable=True),
            ColumnContract(name="average_watts", data_type="double", nullable=True),
            ColumnContract(name="device_watts", data_type="bool", nullable=True),
            ColumnContract(name="kilojoules", data_type="double", nullable=True),
            ColumnContract(name="average_heartrate", data_type="double", nullable=True),
            ColumnContract(name="max_heartrate", data_type="double", nullable=True),
        ),
    ),
    "activity_segment_efforts": TableContract(
        name="activity_segment_efforts",
        columns=(
            ColumnContract(name="kom_rank", data_type="bigint", nullable=True),
            ColumnContract(name="id", data_type="bigint", nullable=False),
            ColumnContract(name="resource_state", data_type="bigint", nullable=True),
            ColumnContract(name="name", data_type="text", nullable=True),
            ColumnContract(name="activity", data_type="json", nullable=True),
            ColumnContract(name="athlete", data_type="json", nullable=True),
            ColumnContract(name="elapsed_time", data_type="bigint", nullable=True),
            ColumnContract(name="moving_time", data_type="bigint", nullable=True),
            ColumnContract(
                name="start_date",
                data_type="timestamp",
                nullable=True,
            ),
            ColumnContract(
                name="start_date_local",
                data_type="timestamp",
                nullable=True,
            ),
            ColumnContract(name="distance", data_type="double", nullable=True),
            ColumnContract(name="start_index", data_type="bigint", nullable=True),
            ColumnContract(name="end_index", data_type="bigint", nullable=True),
            ColumnContract(name="device_watts", data_type="bool", nullable=True),
            ColumnContract(name="segment", data_type="json", nullable=True),
            ColumnContract(name="pr_rank", data_type="bigint", nullable=True),
            ColumnContract(name="achievements", data_type="json", nullable=True),
            ColumnContract(name="visibility", data_type="text", nullable=True),
            ColumnContract(name="hidden", data_type="bool", nullable=True),
            ColumnContract(name="_activities_id", data_type="bigint", nullable=True),
            ColumnContract(
                name="_dlt_load_id",
                data_type="text",
                nullable=False,
                is_system=True,
            ),
            ColumnContract(
                name="_dlt_id",
                data_type="text",
                nullable=False,
                is_system=True,
            ),
            ColumnContract(name="average_heartrate", data_type="double", nullable=True),
            ColumnContract(name="max_heartrate", data_type="double", nullable=True),
        ),
    ),
    "activity_streams": TableContract(
        name="activity_streams",
        columns=(
            ColumnContract(name="type", data_type="text", nullable=False),
            ColumnContract(name="data", data_type="json", nullable=True),
            ColumnContract(name="series_type", data_type="text", nullable=True),
            ColumnContract(name="original_size", data_type="bigint", nullable=True),
            ColumnContract(name="resolution", data_type="text", nullable=True),
            ColumnContract(name="_activities_id", data_type="bigint", nullable=False),
            ColumnContract(
                name="_dlt_load_id",
                data_type="text",
                nullable=False,
                is_system=True,
            ),
            ColumnContract(
                name="_dlt_id",
                data_type="text",
                nullable=False,
                is_system=True,
            ),
        ),
    ),
    "activity_zones": TableContract(
        name="activity_zones",
        columns=(
            ColumnContract(name="score", data_type="double", nullable=True),
            ColumnContract(name="distribution_buckets", data_type="json", nullable=True),
            ColumnContract(name="type", data_type="text", nullable=False),
            ColumnContract(name="resource_state", data_type="bigint", nullable=True),
            ColumnContract(name="sensor_based", data_type="bool", nullable=True),
            ColumnContract(name="_activities_id", data_type="bigint", nullable=False),
            ColumnContract(
                name="_dlt_load_id",
                data_type="text",
                nullable=False,
                is_system=True,
            ),
            ColumnContract(
                name="_dlt_id",
                data_type="text",
                nullable=False,
                is_system=True,
            ),
            ColumnContract(name="points", data_type="bigint", nullable=True),
            ColumnContract(name="custom_zones", data_type="bool", nullable=True),
        ),
    ),
}


def get_table_contract(table_name: str) -> TableContract | None:
    return SCHEMA_CONTRACTS.get(table_name)


def normalize_record(record: Any, contract: TableContract) -> Any:
    if not isinstance(record, Mapping):
        return record

    normalized: dict[str, Any] = {}
    # Unknown fields are ignored by only copying contract-defined columns.
    for column in contract.columns:
        if column.is_system:
            continue
        if column.name in record:
            normalized[column.name] = record[column.name]
        else:
            # Inject explicit defaults (None when no default exists) for missing fields.
            normalized[column.name] = column.default

    return normalized
