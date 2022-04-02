FROM fedora:latest
RUN dnf -y install pip
RUN pip install -q hvac
COPY ./app /app
WORKDIR /app
EXPOSE 8200
ENTRYPOINT ["python3"]
CMD ["my-hvac-app.py" ]
