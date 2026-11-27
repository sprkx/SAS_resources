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

data events;
input patid $ eventdate :date9. code $;
format eventdate date9.;
datalines;
1001 05JAN2020 A1
1002 11FEB2020 B2
1003 20MAR2020 A1
1004 02APR2020 C3
1001 19MAY2020 B2
;
run;

data cohort;
input patid $;
datalines;
1001
1003
;
run;

%EXTRACT (data_in=events, data_out=events_cohort, data_list=cohort, remove_migrators=N);

proc print data=events_cohort; run;
