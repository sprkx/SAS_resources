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


/*ods graphics on;*/
/*ods listing gpath='E:\DataAnalysis\DiscSod\Output';*/
/*%MACRO XXX;*/
/*%do i=1 %to 6;*/
/*%Plot (*/
/*type=ci, in_data=y.fu_itt_trunc, out_surv_data=surv_&i., rst_test=test_out&i.*/
/*, outcome_var=out&i., group_var=exposure, weight=iptw*/
/*, fu_var=t&i., fu_max=1095.75, fu_inc=30.5, y_max=1.0, line_thickness=1*/
/*, file_name=CI_itt_out&i., format=png, note=ITT_out&i.*/
/*);*/
/*%end;*/
/*%MEND; %XXX;*/
/*data z.surv_itt; set surv_1 - surv_6; run;*/
/*data z.test_itt; set test_out1 - test_out6; run;*/
/*ods _all_ close;*/
