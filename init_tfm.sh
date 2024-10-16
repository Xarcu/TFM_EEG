#!/usr/bin/env bash
conda init bash
if ! conda list --name TFM; then
    echo 'Creating Environment'
    conda config --add channels conda-forge
    conda env create --file=./environment.yml
fi
conda activate tdcs_predict
conda env update -n tdcs_predict --file environment.yml --prune

python -m pip install --upgrade pip

export PYTHONPATH=${PWD}


