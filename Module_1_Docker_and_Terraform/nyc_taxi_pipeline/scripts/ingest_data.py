#!/usr/bin/env python3
"""
NYC Taxi Data Ingestion Script
Downloads a CSV or Parquet file and loads it into PostgreSQL
"""


import argparse
import os
import pandas as pd
from sqlalchemy import create_engine
from time import time

