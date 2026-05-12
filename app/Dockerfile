FROM debian:bookworm-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:0.11.3 /uv /uvx /bin/

ENV UV_PYTHON_INSTALL_DIR=/opt/python

RUN uv venv /opt/venv --python 3.11

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN uv pip install --no-cache -r requirements.txt

FROM debian:bookworm-slim

RUN useradd --create-home appuser

COPY --from=builder /opt/python /opt/python
COPY --from=builder /opt/venv /opt/venv

USER appuser
WORKDIR /home/appuser/code
COPY . .

ENV PYTHONUNBUFFERED=1
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

EXPOSE 5000

CMD ["/opt/venv/bin/gunicorn", "-b", "0.0.0.0:5000", "-w", "2", "app:app"]
