-- Seed data for MCP server tests.
-- Creates reporting schema tables matching the production reporting models.

CREATE SCHEMA IF NOT EXISTS reporting;

-- ============================================================
-- rpt_kpis__all
-- ============================================================
CREATE TABLE reporting.rpt_kpis__all
(
    grain          VARCHAR,
    sport_type     VARCHAR,
    sport_slug     VARCHAR,
    activity_year  INTEGER,
    activity_date  DATE,
    month_start    DATE,
    month_number   INTEGER,
    month_label    VARCHAR,
    month_name     VARCHAR,
    activity_count INTEGER,
    total_distance_km DOUBLE,
    total_distance_miles DOUBLE,
    total_moving_time_hours DOUBLE,
    time_display   VARCHAR,
    total_elevation_gain_feet DOUBLE,
    avg_speed_mph DOUBLE,
    avg_speed_kmh DOUBLE,
    avg_pace_min_per_km DOUBLE,
    avg_heartrate_bpm DOUBLE,
    longest_distance_miles DOUBLE,
    hardest_elevation_gain_feet DOUBLE
);

INSERT INTO reporting.rpt_kpis__all
VALUES ('all', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 120, 1500.0, 932.1, 250.0, '250:00:00', 45000.0, 6.2,
        10.0, 6.0, 145.0, 26.2, 3500.0),
       ('year', NULL, NULL, 2025, NULL, NULL, NULL, NULL, NULL, 80, 1000.0, 621.4, 170.0, '170:00:00', 30000.0, 6.1,
        9.8, 6.1, 146.0, 26.2, 3500.0),
       ('year', NULL, NULL, 2024, NULL, NULL, NULL, NULL, NULL, 40, 500.0, 310.7, 80.0, '80:00:00', 15000.0, 6.3, 10.1,
        5.9, 144.0, 13.1, 2000.0),
       ('sport_type', 'Run', 'run', NULL, NULL, NULL, NULL, NULL, NULL, 90, 1200.0, 745.6, 200.0, '200:00:00', 35000.0,
        5.8, 9.3, 6.5, 150.0, 26.2, 3500.0),
       ('sport_type', 'Ride', 'ride', NULL, NULL, NULL, NULL, NULL, NULL, 30, 300.0, 186.5, 50.0, '50:00:00', 10000.0,
        7.5, 12.1, 5.0, 135.0, 50.0, 2000.0),
       ('sport_type_year', 'Run', 'run', 2025, NULL, NULL, NULL, NULL, NULL, 60, 800.0, 497.1, 140.0, '140:00:00',
        25000.0, 5.7, 9.2, 6.5, 151.0, 26.2, 3500.0),
       ('sport_type_year', 'Run', 'run', 2024, NULL, NULL, NULL, NULL, NULL, 30, 400.0, 248.5, 60.0, '60:00:00',
        10000.0, 6.0, 9.7, 6.2, 149.0, 13.1, 2000.0),
       ('sport_type_year', 'Ride', 'ride', 2025, NULL, NULL, NULL, NULL, NULL, 20, 200.0, 124.3, 30.0, '30:00:00',
        5000.0, 7.6, 12.2, 4.9, 136.0, 50.0, 2000.0),
       ('year_month', NULL, NULL, NULL, NULL, '2025-01-01', 1, '2025-01', 'Jan', 12, 150.0, 93.2, 25.0, '25:00:00',
        4500.0, 6.0, 9.7, 6.2, 147.0, 13.1, 1500.0),
       ('year_month', NULL, NULL, NULL, NULL, '2025-02-01', 2, '2025-02', 'Feb', 10, 120.0, 74.6, 20.0, '20:00:00',
        3500.0, 6.1, 9.8, 6.1, 148.0, 10.0, 1200.0),
       ('year_month', NULL, NULL, NULL, NULL, '2024-12-01', 12, '2024-12', 'Dec', 8, 100.0, 62.1, 15.0, '15:00:00',
        2500.0, 6.2, 10.0, 6.0, 145.0, 8.5, 1000.0),
       ('day', NULL, NULL, NULL, '2025-01-15', NULL, NULL, NULL, NULL, 1, 10.0, 6.2, 1.0, '01:00:00', 500.0, 6.2, 10.0,
        6.0, 145.0, 6.2, 500.0),
       ('day', NULL, NULL, NULL, '2025-01-16', NULL, NULL, NULL, NULL, 2, 15.0, 9.3, 1.5, '01:30:00', 800.0, 6.3, 10.1,
        5.9, 146.0, 6.5, 600.0),
       ('sport_type_year_month', 'Run', 'run', NULL, NULL, '2025-01-01', 1, '2025-01', 'Jan', 10, 130.0, 80.8, 22.0,
        '22:00:00', 4000.0, 5.8, 9.3, 6.5, 150.0, 13.1, 1500.0),
       ('sport_type_year_month', 'Run', 'run', NULL, NULL, '2024-12-01', 12, '2024-12', 'Dec', 7, 90.0, 55.9, 13.0,
        '13:00:00', 2200.0, 5.9, 9.5, 6.3, 149.0, 8.5, 1000.0);

-- ============================================================
-- rpt_activity_detail__activity
-- ============================================================
CREATE TABLE reporting.rpt_activity_detail__activity
(
    activity_id             BIGINT,
    activity_name           VARCHAR,
    sport_type              VARCHAR,
    sport_slug              VARCHAR,
    workout_type            VARCHAR,
    started_at_local        TIMESTAMP,
    timezone                VARCHAR,
    activity_date           DATE,
    activity_year           INTEGER,
    activity_month          INTEGER,
    activity_week           INTEGER,
    activity_day_of_week    INTEGER,
    location_city           VARCHAR,
    location_state          VARCHAR,
    location_country        VARCHAR,
    distance_meters DOUBLE,
    distance_km DOUBLE,
    distance_miles DOUBLE,
    moving_time_seconds     INTEGER,
    elapsed_time_seconds    INTEGER,
    moving_time_display     VARCHAR,
    elapsed_time_display    VARCHAR,
    time_display            VARCHAR,
    moving_time_minutes DOUBLE,
    elapsed_time_minutes DOUBLE,
    elevation_gain_meters DOUBLE,
    elevation_gain_feet DOUBLE,
    average_speed_mps DOUBLE,
    average_speed_kph DOUBLE,
    average_speed_mph DOUBLE,
    max_speed_mps DOUBLE,
    max_speed_kph DOUBLE,
    max_speed_mph DOUBLE,
    pace_min_per_km DOUBLE,
    pace_min_per_mile DOUBLE,
    has_heartrate           BOOLEAN,
    average_heartrate_bpm DOUBLE,
    max_heartrate_bpm DOUBLE,
    has_power_meter         BOOLEAN,
    average_watts DOUBLE,
    kilojoules DOUBLE,
    calories_burned DOUBLE,
    polyline                VARCHAR,
    start_latitude DOUBLE,
    start_longitude DOUBLE,
    end_latitude DOUBLE,
    end_longitude DOUBLE,
    kudos_count             INTEGER,
    comment_count           INTEGER,
    achievement_count       INTEGER,
    pr_count                INTEGER,
    suffer_score DOUBLE,
    is_trainer              BOOLEAN,
    is_commute              BOOLEAN,
    is_manual               BOOLEAN,
    device_name             VARCHAR,
    activity_link           VARCHAR,
    is_private              BOOLEAN,
    visibility              VARCHAR,
    has_time_stream         BOOLEAN,
    has_distance_stream     BOOLEAN,
    has_altitude_stream     BOOLEAN,
    has_velocity_stream     BOOLEAN,
    has_heartrate_stream    BOOLEAN,
    has_latlng_stream       BOOLEAN,
    stream_data_point_count INTEGER
);

INSERT INTO reporting.rpt_activity_detail__activity
VALUES (1001, 'Morning Run', 'Run', 'run', 'default', '2025-01-15 07:00:00', 'America/New_York', '2025-01-15', 2025, 1,
        3, 3, 'Brooklyn', 'NY', 'US', 10000.0, 10.0, 6.2, 3600, 3700, '01:00:00', '01:01:40', '01:00:00', 60.0, 61.7,
        50.0, 164.0, 2.78, 10.0, 6.2, 3.5, 12.6, 7.8, 6.0, 9.7, true, 145.0, 170.0, false, NULL, NULL, NULL,
        'encoded_polyline_data', 40.68, -73.97, 40.69, -73.96, 12, 2, 3, 1, 78.0, false, false, false,
        'Garmin Forerunner 265', '/activity/run/1001', false, 'everyone', true, true, true, true, true, true, 3600),
       (1002, 'Lunch Ride', 'Ride', 'ride', 'default', '2025-01-15 12:00:00', 'America/New_York', '2025-01-15', 2025, 1,
        3, 3, 'Brooklyn', 'NY', 'US', 30000.0, 30.0, 18.6, 5400, 5600, '01:30:00', '01:33:20', '01:30:00', 90.0, 93.3,
        100.0, 328.0, 5.56, 20.0, 12.4, 8.33, 30.0, 18.6, 3.0, 4.8, true, 135.0, 160.0, true, 200.0, 800.0, 191.0,
        'encoded_polyline_data_2', 40.68, -73.97, 40.70, -73.95, 8, 0, 5, 2, 65.0, false, false, false, 'Wahoo ELEMNT',
        '/activity/ride/1002', false, 'everyone', true, true, true, true, true, true, 5400),
       (1003, 'Easy Recovery Run', 'Run', 'run', 'default', '2025-01-16 07:30:00', 'America/New_York', '2025-01-16',
        2025, 1, 3, 4, 'Brooklyn', 'NY', 'US', 5000.0, 5.0, 3.1, 1800, 1900, '00:30:00', '00:31:40', '00:30:00', 30.0,
        31.7, 20.0, 65.6, 2.78, 10.0, 6.2, 3.0, 10.8, 6.7, 6.0, 9.7, true, 130.0, 150.0, false, NULL, NULL, NULL,
        'encoded_polyline_data_3', 40.68, -73.97, 40.69, -73.96, 5, 0, 0, 0, 45.0, false, false, false,
        'Garmin Forerunner 265', '/activity/run/1003', false, 'everyone', true, true, true, true, true, true, 1800),
       (1004, 'Long Run', 'Run', 'run', 'long_run', '2025-01-18 08:00:00', 'America/New_York', '2025-01-18', 2025, 1, 3,
        6, 'Brooklyn', 'NY', 'US', 21100.0, 21.1, 13.1, 6300, 6500, '01:45:00', '01:48:20', '01:45:00', 105.0, 108.3,
        150.0, 492.0, 3.35, 12.1, 7.5, 4.17, 15.0, 9.3, 5.0, 8.0, true, 155.0, 180.0, false, NULL, NULL, NULL,
        'encoded_polyline_data_4', 40.68, -73.97, 40.70, -73.95, 25, 5, 8, 3, 120.0, false, false, false,
        'Garmin Forerunner 265', '/activity/run/1004', false, 'everyone', true, true, true, true, true, true, 6300),
       (1005, 'Indoor Trainer', 'Ride', 'ride', 'default', '2024-12-20 18:00:00', 'America/New_York', '2024-12-20',
        2024, 12, 51, 5, NULL, NULL, NULL, 25000.0, 25.0, 15.5, 3600, 3600, '01:00:00', '01:00:00', '01:00:00', 60.0,
        60.0, 0.0, 0.0, 6.94, 25.0, 15.5, 8.33, 30.0, 18.6, 3.0, 4.8, true, 140.0, 165.0, true, 220.0, 792.0, 189.0,
        NULL, NULL, NULL, NULL, NULL, 3, 0, 0, 0, 70.0, true, false, false, 'Wahoo KICKR', '/activity/ride/1005', false,
        'everyone', true, true, false, true, true, false, 3600);


-- ============================================================
-- rpt_streaks__all
-- ============================================================
CREATE TABLE reporting.rpt_streaks__all
(
    grain                     VARCHAR,
    sport_type                VARCHAR,
    sport_slug                VARCHAR,
    activity_year             INTEGER,
    max_activity_date         DATE,
    current_streak            INTEGER,
    current_streak_start_date DATE,
    current_streak_end_date   DATE,
    longest_streak            INTEGER,
    active_days_last_30       INTEGER,
    active_days_year          INTEGER
);

INSERT INTO reporting.rpt_streaks__all
VALUES ('all', NULL, NULL, NULL, '2025-01-18', 2, '2025-01-17', '2025-01-18', 5, 12, NULL),
       ('year', NULL, NULL, 2025, '2025-01-18', 2, '2025-01-17', '2025-01-18', 3, 10, 15),
       ('year', NULL, NULL, 2024, '2024-12-20', 0, NULL, NULL, 5, 8, 40),
       ('sport_type', 'Run', 'run', NULL, '2025-01-18', 1, '2025-01-18', '2025-01-18', 4, 10, NULL),
       ('sport_type', 'Ride', 'ride', NULL, '2025-01-15', 0, NULL, NULL, 3, 5, NULL),
       ('sport_type_year', 'Run', 'run', 2025, '2025-01-18', 1, '2025-01-18', '2025-01-18', 3, 8, 12),
       ('sport_type_year', 'Ride', 'ride', 2025, '2025-01-15', 0, NULL, NULL, 2, 3, 5);


-- ============================================================
-- rpt_activity_zones__activity_zone
-- ============================================================
CREATE TABLE reporting.rpt_activity_zones__activity_zone
(
    activity_id  BIGINT,
    zone_type    VARCHAR,
    zone_id      INTEGER,
    zone_name    VARCHAR,
    zone_min_value DOUBLE,
    zone_max_value DOUBLE,
    time_seconds DOUBLE,
    time_display VARCHAR,
    time_minutes DOUBLE,
    pct_in_zone DOUBLE
);

INSERT INTO reporting.rpt_activity_zones__activity_zone
VALUES (1001, 'heartrate', 1, 'Zone 1', 90.0, 120.0, 600.0, '00:10:00', 10.0, 0.167),
       (1001, 'heartrate', 2, 'Zone 2', 120.0, 140.0, 1200.0, '00:20:00', 20.0, 0.333),
       (1001, 'heartrate', 3, 'Zone 3', 140.0, 155.0, 1200.0, '00:20:00', 20.0, 0.333),
       (1001, 'heartrate', 4, 'Zone 4', 155.0, 170.0, 480.0, '00:08:00', 8.0, 0.133),
       (1001, 'heartrate', 5, 'Zone 5', 170.0, 200.0, 120.0, '00:02:00', 2.0, 0.033),
       (1001, 'pace', 1, 'Active Recovery', NULL, NULL, 300.0, '00:05:00', 5.0, 0.083),
       (1001, 'pace', 2, 'Endurance', NULL, NULL, 2400.0, '00:40:00', 40.0, 0.667),
       (1001, 'pace', 3, 'Tempo', NULL, NULL, 600.0, '00:10:00', 10.0, 0.167),
       (1001, 'pace', 4, 'Threshold', NULL, NULL, 300.0, '00:05:00', 5.0, 0.083),
       (1002, 'heartrate', 1, 'Zone 1', 90.0, 120.0, 1800.0, '00:30:00', 30.0, 0.333),
       (1002, 'heartrate', 2, 'Zone 2', 120.0, 140.0, 2700.0, '00:45:00', 45.0, 0.500),
       (1002, 'heartrate', 3, 'Zone 3', 140.0, 155.0, 900.0, '00:15:00', 15.0, 0.167),
       (1002, 'power', 1, 'Active Recovery', 0.0, 120.0, 1080.0, '00:18:00', 18.0, 0.200),
       (1002, 'power', 2, 'Endurance', 120.0, 180.0, 2700.0, '00:45:00', 45.0, 0.500),
       (1002, 'power', 3, 'Tempo', 180.0, 240.0, 1080.0, '00:18:00', 18.0, 0.200),
       (1002, 'power', 4, 'Threshold', 240.0, 300.0, 540.0, '00:09:00', 9.0, 0.100);


-- ============================================================
-- rpt_activity_segment_efforts__activity
-- ============================================================
CREATE TABLE reporting.rpt_activity_segment_efforts__activity
(
    effort_id            BIGINT,
    activity_id          BIGINT,
    segment_id           BIGINT,
    segment_name         VARCHAR,
    distance_km DOUBLE,
    distance_miles DOUBLE,
    elapsed_time_seconds INTEGER,
    time_display         VARCHAR,
    elapsed_time_display VARCHAR,
    average_speed_kph DOUBLE,
    average_speed_mph DOUBLE,
    pace_min_per_km DOUBLE,
    pace_min_per_mile DOUBLE,
    average_grade DOUBLE,
    climb_category       INTEGER,
    climb_category_label VARCHAR,
    pr_rank              INTEGER,
    is_pr                BOOLEAN,
    kom_rank             INTEGER,
    has_kom_rank         BOOLEAN,
    average_heartrate_bpm DOUBLE,
    max_heartrate_bpm DOUBLE,
    start_index          INTEGER
);

INSERT INTO reporting.rpt_activity_segment_efforts__activity
VALUES (5001, 1004, 201, 'Prospect Park Loop', 5.0, 3.1, 1500, '00:25:00', '00:25:00', 12.0, 7.5, 5.0, 8.0, 1.2, 0,
        'NC', 1, true, NULL, false, 155.0, 170.0, 100),
       (5002, 1004, 202, 'Brooklyn Bridge Climb', 1.0, 0.6, 420, '00:07:00', '00:07:00', 8.6, 5.3, 7.0, 11.3, 5.5, 2,
        'Cat 3', 2, false, NULL, false, 165.0, 178.0, 2500),
       (5003, 1004, 203, 'East River Sprint', 0.5, 0.3, 120, '00:02:00', '00:02:00', 15.0, 9.3, 4.0, 6.4, -0.5, 0, 'NC',
        3, false, NULL, false, 170.0, 180.0, 4000),
       (5004, 1002, 301, 'Ocean Parkway Straight', 3.0, 1.9, 540, '00:09:00', '00:09:00', 20.0, 12.4, 3.0, 4.8, 0.0, 0,
        'NC', 1, true, 5, true, 138.0, 155.0, 200);
