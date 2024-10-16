conda init
$exists = conda list --name tdcs_predict
if (-Not $exists )
{
    Write-Output 'Creating Environment'
    conda config --add channels conda-forge
    conda env create --file=./environment.yml
}
conda activate tdcs_predict
conda env update -n tdcs_predict --file environment.yml --prune
python -m pip install --upgrade pip
$env:PYTHONPATH = $pwd





