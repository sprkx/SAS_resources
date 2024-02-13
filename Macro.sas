%MACRO DeleteDataset (lib=, data_name=, n_stt=, n_end=);
%do i=&n_stt. %to &n_end.;
proc delete lib=&lib. data=&data_name._&i.; run;
%end;
%MEND;
%MACRO IMPORT_N (file_n_stt=, file_n_end=, lib_name=, data_name=, folder_name=, data_name_infile=, var_name_list=, var_format_list=);
%do i=&file_n_stt. %to &file_n_end.;
%let file_num_infile=%sysfunc(putn(&i.,&file_num_form.));

data &lib_name..&data_name._&i.;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
%if &folder_name.= %then %do;
infile "&path_in.\&file_name_form..txt"
%end;
%else %do;
infile "&path_in.\&folder_name.\&file_name_form..txt"
%end;
delimiter='09'x MISSOVER DSD lrecl=32767 firstobs=2 ;

%let input_list=;

%do var_n=1 %to %sysfunc(countw(&var_name_list., %str( ),q));
	%let var_name=%scan(&var_name_list., &var_n., %str( ),q);
	%let var_format=%scan(&var_format_list., &var_n., %str( ),q);
	informat &var_name. &var_format.;
	format &var_name. &var_format.;
	%if %substr(&var_format.,1,1)=$ %then %let input_list=&input_list. &var_name. $;
	%else %let input_list=&input_list. &var_name.;
%end;

input &input_list.;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;
%end;
%MEND;
%MACRO IMPORT_TXT (path=, filename=, lib=, data_name=, var_name_list=, var_format_list=, delimiter=);
data &lib..&data_name.;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile "&path.\&filename..txt"
delimiter=&delimiter. MISSOVER DSD lrecl=32767 firstobs=2 ;

%let input_list=;
%do var_n=1 %to %sysfunc(countw(&var_name_list., %str( ),q));
	%let var_name=%scan(&var_name_list., &var_n., %str( ),q);
	%let var_format=%scan(&var_format_list., &var_n., %str( ),q);
	informat &var_name. &var_format.;
	format &var_name. &var_format.;
	%if %substr(&var_format.,1,1)=$ %then %let input_list=&input_list. &var_name. $;
	%else %let input_list=&input_list. &var_name.;
%end;
input &input_list.;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;
%MEND;
%MACRO IMPORT_XLSX (path=, filename=, lib=, data_name=, sheet=);
proc import
out=&lib..&data_name.
datafile= "&path.\&filename..xlsx"
dbms=xlsx replace;
sheet="&sheet.";
run;
%MEND;
%MACRO SPLIT (indata=, outdata=, symbol=, col_name=, keep_var_list=);
proc sql noprint;
select max(count(&col_name.,&symbol.))+1 into :max_cnt
from &indata.;
quit;
data temp_1;
set &indata.;
length &col_name.1 $100;
array name (&max_cnt) $100;
do i=1 to &max_cnt;
name(i)=scan(&col_name.,i,&symbol.);
&col_name.1=name(i);
if &col_name.1^="" then output;
end;
keep &keep_var_list. &col_name. &col_name.1;
run;
data &outdata;
set temp_1;
drop &col_name.;
rename &col_name.1=&col_name.;
run;
proc delete data=temp_1; run;
%MEND;
%MACRO EXTRACT (data_in=, data_out=, data_list=, remove_migrators=);
proc sql;
create table &data_out. as
select *
from &data_in. 
where patid in (select patid from &data_list.)
%IF &remove_migrators.=Y %then %do;
	and (substr(patid, length(patid)-4, 5)) not in (select gold_pracid from b.prac_migrt)
%end;
%else;
;quit;
%MEND;
