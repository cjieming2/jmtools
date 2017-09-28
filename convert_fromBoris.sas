LIBNAME TEST V9 "/folders/myfolders/sasuser.v94" inencoding=asciiany;
%MACRO convert(table_name);
	proc export data=test.&table_name
	outfile="'/folders/myfolders/sasuser.v94/&table_name\.csv'"
    dbms=csv
	replace;
	run;
%MEND convert;
data list;
	INFORMAT file_name $20. ;
	input file_name $;
datalines;
cand_kipa
cand_liin
cand_thor
control
donor_deceased
donor_disposition
donor_live
don_liv_fol
fol_immuno
immuno
institution
malig
mpexcept
mpexcept_orig_tumors
mpexcept_tumors
pra_hist
rec_histo
rec_histo_xmat
stathist_kipa
stathist_liin
stathist_thor
statjust_hr1a
statjust_hr1b
statjust_li1
statjust_li2a
statjust_li2b
treatment
txf_hl
txf_hr
txf_in
txf_ki
txf_kp
txf_li
txf_lu
txf_pa
tx_hl
tx_hr
tx_in
tx_ki
tx_kp
tx_li
tx_lu
tx_pa
;
data _null_;
	set list;
	call execute('%convert(table_name='||file_name||')');
run;
