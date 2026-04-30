FROM public.ecr.aws/lambda/python:3.9@sha256:ed423f4168b793088d341d8bc1c5ae0ca26a56d04adfd2f3254aca8445aa34c4 

# Install utilities 
RUN pip install --upgrade pip 
RUN pip install --no-cache-dir boto3 opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp 

# Download the OpenTelemetry Layer with Application Signals Support 
RUN yum install -y unzip wget 
RUN wget https://github.com/aws-observability/aws-otel-python-instrumentation/releases/latest/download/layer.zip -O /tmp/layer.zip 

# Extract and include Lambda layer contents 
RUN mkdir -p /opt && \ 
unzip /tmp/layer.zip -d /opt/ && \ 
chmod -R 755 /opt/ && \ 
rm /tmp/layer.zip 

# Copy function code 
COPY app.py ${LAMBDA_TASK_ROOT}/ 
COPY requirements.txt ${LAMBDA_TASK_ROOT}/ 

# Install dependencies 
RUN pip install -r requirements.txt 

# Set the CMD to your handler 
CMD [ "app.lambda_handler" ] 