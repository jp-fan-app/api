#!/bin/bash

service cron start

/app/Run serve -e prod -b 0.0.0.0