FROM python:3.6.8

# copy source and install dependencies
ENV dir /opt/app
RUN mkdir -p $dir/weather_app
COPY . $dir/weather_app/
COPY requirements.txt $dir
WORKDIR $dir
RUN pip3 install --upgrade pip && pip3 install -r requirements.txt

# run server
CMD [ "python3", "/opt/app/weather_app/manage.py", "runserver", "0.0.0.0:8000"]
