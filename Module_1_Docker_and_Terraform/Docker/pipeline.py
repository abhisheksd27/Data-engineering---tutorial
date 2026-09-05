import sys
import pandas as pd

print("Pipeline started!")
print(f"Arguments received: {sys.argv}")

# Simulate a data pipeline step
day = sys.argv[1]
print(f"Processing data for day: {day}")
print("Pipeline completed!")