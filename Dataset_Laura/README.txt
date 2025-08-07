
Files where obtained in .xdf file format. In case of need, Two folders have been provided. One with .xdf files and another one with .fif files (both for the raw data). 

STRUCTURE OF THE DATA:

Names of the files where automatically created based on the Psychopy program + LSL protocol. 

On each folder you will find soubgroups of folders (they where automatically created when obtaining the data). 


Inside each folder you will have a sub-P001 (subject 1, myself) -> ses-S00X (number of session that this data was obtained from) -> eeg (automatically created by the program)

Inside that final folder some files can be found (THERE IS NOT THIS AMOUNT OF FILES FOR ALL THE CASES, BUT FOR MOST OF THEM): 

.XDF file -> raw data obtained in xdf file format
ica_filtered_raw.fif -> raw data only filtered with ICA (Independent Component Analysis)
eeg_raw.fif -> raw data obtained on .fif format 
event_data.JSON -> timestamps to control when the MI (LEFT / RIGHT) started, compared to resting state. 


Extra_Dataset -> dataset used for training and validation pursposes (if needed)