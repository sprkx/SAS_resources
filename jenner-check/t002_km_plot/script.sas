%MACRO Plot (type=, in_data=, out_surv_data=, rst_test=
, outcome_var=, group_var=, weight=
, fu_var=, fu_max=, fu_inc=, y_max=
, line_thickness= , file_name=, format=, note=);

data temp_1;
set &in_data.;
dummy_weight=1;
run;

%if &type.=ci %then %do;
%let y_axis=_1_SURVIVAL_;
%let y_label=Cumulative Incidence;
proc lifetest data=temp_1 plots=survival(f)
outsurv=survival_data timelist=(0 to &fu_max. by &fu_inc.) reduceout;
strata &group_var.;
time &fu_var.*&outcome_var.(0);
weight &weight.;
ods output failureplot=temp_2 HomTests=temp_test;
run;
%end;

%else %if &type.=km %then %do;
%let y_axis=SURVIVAL;
%let y_label=Survival Probability;
proc lifetest data=temp_1 plots=survival
outsurv=survival_data timelist=(0 to &fu_max. by &fu_inc.) reduceout;
strata &group_var.;
time &fu_var.*&outcome_var.(0);
weight &weight.;
ods output survivalplot=temp_2 HomTests=temp_test;
run;
%end;

ods graphics / reset imagename="&file_name." imagefmt=&format.;
proc sgplot data=temp_2;
step x=time y=&y_axis./group=stratum lineattrs=(pattern=1 thickness=&line_thickness.);
xaxis values=(0 to &fu_max. by &fu_inc.) valueshint label="Time to event";
yaxis offsetmin=0.02 min=0 offsetmax=0.1 max=&y_max. label="&y_label.";
run;
/*ods graphics off;*/

data &out_surv_data.;
set temp_2;
note="&note.";
run;
data &rst_test.;
set temp_test; 
note="&note.";
run;
proc delete data=temp_1 temp_2 temp_test; run;
%MEND;

data fu;
input id exposure t1 out1 iptw;
datalines;
1 0 100 1 1.1
2 0 400 0 0.9
3 0 250 1 1.0
4 0 900 0 1.2
5 0 600 1 0.8
6 0 1000 0 1.0
7 1 150 1 1.3
8 1 300 1 0.7
9 1 700 0 1.0
10 1 1000 0 1.1
11 1 450 1 0.9
12 1 850 0 1.0
;
run;

%Plot (type=km, in_data=fu, out_surv_data=surv_1, rst_test=test_out1
, outcome_var=out1, group_var=exposure, weight=iptw
, fu_var=t1, fu_max=1095.75, fu_inc=30.5, y_max=1.0, line_thickness=1
, file_name=CI_itt_out1, format=png, note=ITT_out1);

proc print data=surv_1(obs=10); run;
proc print data=test_out1; run;
