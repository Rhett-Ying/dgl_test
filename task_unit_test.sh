#!/bin/bash

python3 -m pip install pytest
python3 -m pytest -v --junitxml=pytest_basics.xml --durations=10 test_basics.py
python3 -c "print('test')"
