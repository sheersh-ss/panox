FROM pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /opt/app

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libglib2.0-0 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /opt/app/requirements.txt

RUN python -m pip install --upgrade pip setuptools wheel
RUN python -m pip install -r /opt/app/requirements.txt

COPY packages/nnunetv2 /opt/app/packages/nnunetv2

RUN python -m pip uninstall -y nnunetv2 || true
RUN python -m pip install -e /opt/app/packages/nnunetv2

COPY packages/report-guided-annotation /opt/app/packages/report-guided-annotation
RUN pip install -e /opt/app/packages/report-guided-annotation

COPY main.py /opt/app/main.py
COPY gc_wrapper.py /opt/app/gc_wrapper.py
COPY workspace/nnUNet_results /opt/app/workspace/nnUNet_results

ENV nnUNet_raw=/opt/app/workspace/nnUNet_raw
ENV nnUNet_preprocessed=/opt/app/workspace/nnUNet_preprocessed
ENV nnUNet_results=/opt/app/workspace/nnUNet_results
ENV RESULTS_FOLDER=/opt/app/workspace/nnUNet_results

RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --create-home --home-dir /home/appuser appuser && \
    mkdir -p /opt/app/workspace/nnUNet_raw \
             /opt/app/workspace/nnUNet_preprocessed \
             /tmp/pandx_input \
             /tmp/pandx_output && \
    chown -R appuser:appgroup /opt/app /home/appuser /tmp/pandx_input /tmp/pandx_output

USER appuser

ENTRYPOINT ["python", "/opt/app/gc_wrapper.py"]