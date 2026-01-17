"""
Tests for StravaExtractOperator
Tests the custom Strava extraction operator
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from airflow.exceptions import AirflowException
from airflow.models import Variable

# Import the operator
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../plugins/operators'))
from strava_extract_operator import StravaExtractOperator


class TestStravaExtractOperator:
    """Test suite for StravaExtractOperator"""

    @pytest.fixture
    def mock_variables(self):
        """Mock Airflow Variables"""
        with patch.object(Variable, 'get') as mock_get:
            mock_get.side_effect = lambda key: {
                'STRAVA_CLIENT_ID': 'test_client_id',
                'STRAVA_CLIENT_SECRET': 'test_client_secret',
                'STRAVA_REFRESH_TOKEN': 'test_refresh_token'
            }.get(key)
            yield mock_get

    @pytest.fixture
    def operator(self):
        """Create a StravaExtractOperator instance"""
        return StravaExtractOperator(
            task_id='test_extract',
            extract_start_date='2022-01-01',
            extract_end_date='2022-12-31'
        )

    def test_operator_initialization(self, operator):
        """Test that operator initializes correctly"""
        assert operator.task_id == 'test_extract'
        assert operator.extract_start_date == '2022-01-01'
        assert operator.extract_end_date == '2022-12-31'
        assert operator.ui_color == "#ff5a00"  # Strava brand color

    def test_operator_template_fields(self, operator):
        """Test that template fields are correctly defined"""
        expected_fields = ['extract_start_date', 'extract_end_date']
        assert operator.template_fields == expected_fields

    def test_missing_credentials_raises_error(self, operator):
        """Test that missing credentials raise an error"""
        with patch.object(Variable, 'get', side_effect=KeyError('STRAVA_CLIENT_ID')):
            with pytest.raises(ValueError, match="Missing required Airflow Variable"):
                operator.execute(context={})

    @patch('strava_extract_operator.run_pipeline')
    def test_successful_execution(self, mock_run_pipeline, operator, mock_variables):
        """Test successful pipeline execution"""
        # Mock the run_pipeline function
        mock_load_info = MagicMock()
        mock_load_info.__str__ = lambda self: "Pipeline completed"
        mock_run_pipeline.return_value = mock_load_info

        # Execute
        result = operator.execute(context={})

        # Verify
        mock_run_pipeline.assert_called_once_with(
            start_date='2022-01-01',
            end_date='2022-12-31'
        )
        assert result['start_date'] == '2022-01-01'
        assert result['end_date'] == '2022-12-31'
        assert 'load_info' in result

    @patch('strava_extract_operator.run_pipeline')
    def test_handles_none_dates(self, mock_run_pipeline, operator, mock_variables):
        """Test that None dates are handled correctly"""
        operator.extract_start_date = None
        operator.extract_end_date = None

        mock_load_info = MagicMock()
        mock_run_pipeline.return_value = mock_load_info

        result = operator.execute(context={})

        # Should pass None to run_pipeline
        mock_run_pipeline.assert_called_once_with(
            start_date=None,
            end_date=None
        )

    @patch('strava_extract_operator.run_pipeline')
    def test_handles_string_none_dates(self, mock_run_pipeline, operator, mock_variables):
        """Test that string 'None' is converted to actual None"""
        operator.extract_start_date = "None"
        operator.extract_end_date = ""

        mock_load_info = MagicMock()
        mock_run_pipeline.return_value = mock_load_info

        result = operator.execute(context={})

        # Should convert "None" and "" to None
        mock_run_pipeline.assert_called_once_with(
            start_date=None,
            end_date=None
        )

    @patch('strava_extract_operator.run_pipeline')
    def test_pipeline_failure_raises_error(self, mock_run_pipeline, operator, mock_variables):
        """Test that pipeline failures raise appropriate errors"""
        mock_run_pipeline.side_effect = Exception("Pipeline failed")

        with pytest.raises(Exception, match="Pipeline failed"):
            operator.execute(context={})

    @patch('strava_extract_operator.os.environ')
    @patch('strava_extract_operator.run_pipeline')
    def test_environment_variables_cleanup(self, mock_run_pipeline, mock_environ, operator, mock_variables):
        """Test that environment variables are cleaned up after execution"""
        mock_load_info = MagicMock()
        mock_run_pipeline.return_value = mock_load_info

        # Mock the environ pop method
        mock_environ.pop = Mock()

        try:
            operator.execute(context={})
        except:
            pass

        # Verify cleanup was attempted for all credential keys
        expected_keys = [
            'CREDENTIALS__CLIENT_ID',
            'CREDENTIALS__CLIENT_SECRET',
            'CREDENTIALS__REFRESH_TOKEN'
        ]
        for key in expected_keys:
            mock_environ.pop.assert_any_call(key, None)

    def test_operator_with_jinja_templating(self):
        """Test that operator works with Jinja2 templating"""
        operator = StravaExtractOperator(
            task_id='test_extract',
            extract_start_date='{{ dag_run.conf.get("start_date") }}',
            extract_end_date='{{ dag_run.conf.get("end_date") }}'
        )

        # Template fields should accept Jinja expressions
        assert '{{' in operator.extract_start_date
        assert '{{' in operator.extract_end_date