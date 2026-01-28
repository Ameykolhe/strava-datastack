FROM apache/airflow:3.1.5

# Switch to root to install system dependencies if needed
USER root

# Create data directory for DuckDB database
RUN mkdir -p /opt/airflow/data && chown -R airflow:root /opt/airflow/data

# Copy custom entrypoint script
COPY scripts/entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh

# Switch back to airflow user
USER airflow

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Set custom entrypoint that installs extract package at runtime
ENTRYPOINT ["/custom-entrypoint.sh"]
CMD ["airflow"]
