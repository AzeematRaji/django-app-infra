#!/bin/bash

# Update system
yum update -y

# Install required packages
yum install -y python3 python3-pip git nginx amazon-cloudwatch-agent

# Install Python dependencies
pip3 install gunicorn psycopg2-binary boto3

# Create application user
useradd -m django

# Clone the application
cd /home/django
git clone https://github.com/cognetiks/Technical_DevOps_app.git
cd Technical_DevOps_app

# Install application dependencies
pip3 install -r requirements.txt

# Set environment variables
cat > /etc/environment << EOF
RDS_DB_NAME=${db_name}
RDS_USERNAME=${db_username}
RDS_PASSWORD=${db_password}
RDS_HOSTNAME=${rds_endpoint}
RDS_PORT=5432
S3_BUCKET_NAME=${s3_bucket_name}
EOF

# Source environment variables
source /etc/environment

# Run migrations
python3 manage.py migrate

# Collect static files
python3 manage.py collectstatic --noinput

# Set up Gunicorn service
cat > /etc/systemd/system/gunicorn.service << EOF
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=django
Group=django
WorkingDirectory=/home/django/Technical_DevOps_app
ExecStart=/usr/local/bin/gunicorn --access-logfile - --workers 3 --bind unix:/home/django/Technical_DevOps_app/gunicorn.sock myproject.wsgi:application
EnvironmentFile=/etc/environment

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
cat > /etc/nginx/conf.d/django.conf << EOF
server {
    listen 8000;
    server_name _;

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/django/Technical_DevOps_app/gunicorn.sock;
    }

    location /static/ {
        alias /home/django/Technical_DevOps_app/static/;
    }

    location /health/ {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Set permissions
chown -R django:django /home/django/Technical_DevOps_app

# Start and enable services
systemctl daemon-reload
systemctl start gunicorn
systemctl enable gunicorn
systemctl start nginx
systemctl enable nginx

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/aws/ec2/django-app/access",
                        "log_stream_name": "{instance_id}/nginx-access"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/aws/ec2/django-app",
                        "log_stream_name": "{instance_id}/nginx-error"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s