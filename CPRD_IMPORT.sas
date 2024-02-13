option compress=yes;
/*options symbolgen mlogic mprint;*/
/*options nosymbolgen nomlogic nomprint;*/

libname cprd "E:\Data\CPRD_GOLD_202307";
libname a "E:\Data\CPRD_Pregnancy";
libname b "E:\Data\Resources"; *Dictionary, Sources;

/*********/
/* Macro */
/*********/
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
/********************************/
/* Import: GOLD, Aurum, linkage */
/********************************/

/*Gold*/
%IMPORT_TXT (path=E:\Data\Pregnancy\Gold_MBlink
, filename=21_000464_PregReg
, lib=a
, data_name=gold_preg
, var_name_list=patid pregid babypatid pregnumber pregstart startsource pregend outcome
, var_format_list=$20. $20. $20. $2. ddmmyy10. $1. ddmmyy10. $2. 
, delimiter='09'x);
%IMPORT_TXT (path=E:\Data\Pregnancy\Gold_MBlink
, filename=21_000464_MBL
, lib=a
, data_name=gold_mblink
, var_name_list=pracid	mumpatid	babypatid
, var_format_list=$20. $20. $20. 
, delimiter='09'x);


%let path_in=E:\Data\Pregnancy\Gold_mother;
%let file_num_form=Z3.; *Format of Number in File (e.g., Zw. or w.);
%let file_name_form=Test02_Extract_&data_name_infile._&file_num_infile.; *Format of Filename, using &file_num_infile. and &data_name_infile.;

*Patient;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Patient
, folder_name=Patient, data_name_infile=Patient
, var_name_list=patid vmid gender yob mob marital famnum chsreg chsdate prescr capsup frd crd regstat reggap internal tod toreason deathdate accept
, var_format_list=$20. $20. best1. best4. best2. best3. best20. best1. ddmmyy10. best3. best3. ddmmyy10. ddmmyy10. best2. best5. best2. ddmmyy10. best3. ddmmyy10. $1.
);
data a.gold_patient; set patient_1; run; 
%DeleteDataset(lib=work, data_name=patient, n_stt=1, n_end=1);
*Practice;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Practice
, folder_name=Practice, data_name_infile=Practice
, var_name_list=pracid region lcd uts
, var_format_list=$5. best3. ddmmyy10. ddmmyy10.
);
proc sql;
create table a.gold_practice as
select *
from practice_1
where pracid not in (select gold_pracid from b.prac_migrt)
;quit;
%DeleteDataset(lib=work, data_name=practice, n_stt=1, n_end=1);
*Clinical;
%IMPORT_N (file_n_stt=1, file_n_end=16, lib_name=work, data_name=Clinical
, folder_name=Clinical, data_name_infile=Clinical
, var_name_list=patid	eventdate	sysdate	constype	consid	medcode	sctid	sctdescid	sctexpression	sctmaptype	sctmapversion	sctisindicative	sctisassured	staffid	episode	enttype	adid
, var_format_list=$20. ddmmyy10. ddmmyy10. 3. $20. $20. $20. $20. $20. 1. 10. $1. $1. $20. 3. 5. $20.
);
data a.gold_clinical; set clinical_1 - clinical_16; run; 
%DeleteDataset(lib=work, data_name=clinical, n_stt=1, n_end=16);
*Additional;
%IMPORT_N (file_n_stt=1, file_n_end=3, lib_name=work, data_name=Additional
, folder_name=Additional, data_name_infile=Additional
, var_name_list=patid enttype adid data1 data2 data3 data4 data5 data6 data7 data8 data9 data10 data11 data12
, var_format_list=$20. best5. $20. $20. $20. $20. $20. $20. $20. $20. $20. $20. $20. $20. $20. 
);
data a.gold_additional; set additional_1 - additional_3; run;
%DeleteDataset(lib=work, data_name=additional, n_stt=1, n_end=3);
*Therapy;
%IMPORT_N (file_n_stt=1, file_n_end=16, lib_name=work, data_name=Therapy
, folder_name=Therapy, data_name_infile=Therapy
, var_name_list=patid	eventdate	sysdate	consid	prodcode	drugdmd	staffid	dosageid	bnfcode	qty	numdays	numpacks	packtype	issueseq	prn
, var_format_list=$20. ddmmyy10. ddmmyy10. $20. $20. $20. $20. $64. $5. 20. 20. 8. 10. 20. $1. $20. $7. $100.
);
data a.gold_therapy; set therapy_1 - therapy_16; run; 
%DeleteDataset(lib=work, data_name=therapy, n_stt=1, n_end=16);
*Test;
%IMPORT_N (file_n_stt=1, file_n_end=14, lib_name=work, data_name=Test
, folder_name=Test, data_name_infile=Test
, var_name_list=patid	eventdate	sysdate	constype	consid	medcode	sctid	sctdescid	sctexpression	sctmaptype	sctmapversion	sctisindicative	sctisassured	staffid	enttype	data1	data2	data3	data4	data5	data6	data7	data8
, var_format_list=$20. ddmmyy10. ddmmyy10. 3. $20. $20. $20. $20. $20. 1. $10. $1. $1. $20. 5. $3. $20. $20. $20. $20. $20. $20. $20. 
);
data a.gold_test; set test_1 - test_14; run; 
%DeleteDataset(lib=work, data_name=test, n_stt=1, n_end=14);
*Staff;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Staff
, folder_name=Staff, data_name_infile=Staff
, var_name_list=staffid	gender	role
, var_format_list=$20. 1. 3.
);
data a.gold_Staff; set Staff_1; run; 
%DeleteDataset(lib=work, data_name=Staff, n_stt=1, n_end=1);
*Referral;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Referral
, folder_name=Referral, data_name_infile=Referral
, var_name_list=patid	eventdate	sysdate	constype	consid	medcode	sctid	sctdescid	sctexpression	sctmaptype	sctmapversion	sctisindicative	sctisassured	staffid	source	nhsspec	fhsaspec	inpatient	attendance	urgency
, var_format_list=$20. ddmmyy10. ddmmyy10. 3. $20. $20. $20. $20. $20. 1. 10. $1. $1. $20. 2. 3. 3. 2. 2. 2.
);
data a.gold_Referral; set Referral_1; run; 
%DeleteDataset(lib=work, data_name=Referral, n_stt=1, n_end=1);
*Immunisation;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Immunisation
, folder_name=Immunisation, data_name_infile=Immunisation
, var_name_list=patid	eventdate	sysdate	constype	consid	medcode	sctid	sctdescid	sctexpression	sctmaptype	sctmapversion	sctisindicative	sctisassured	staffid	immstype	stage	status	compound	source	reason	method	batch
, var_format_list=$20. ddmmyy10. ddmmyy10. 3. $20. $20. $20. $20. $20. 1. 10. $1. $1. $20. 4. 2. 3. 4. 3. 3. 3. 20.  
);
data a.gold_Immunisation; set Immunisation_1; run; 
%DeleteDataset(lib=work, data_name=Immunisation, n_stt=1, n_end=1);
*Consultation;
%IMPORT_N (file_n_stt=1, file_n_end=13, lib_name=work, data_name=Consultation
, folder_name=Consultation, data_name_infile=Consultation
, var_name_list=patid	eventdate	sysdate	constype	consid	staffid	duration
, var_format_list=$20. ddmmyy10. ddmmyy10. 3. $20. $20. 10.
);
data a.gold_Consultation; set Consultation_1 - Consultation_13; run; 
%DeleteDataset(lib=work, data_name=Consultation, n_stt=1, n_end=13);


%let path_in=E:\Data\Pregnancy\Gold_child;
%let file_num_form=Z3.; *Format of Number in File (e.g., Zw. or w.);
%let file_name_form=DiaA_kid_Extract_&data_name_infile._&file_num_infile.; *Format of Filename, using &file_num_infile. and &data_name_infile.;

*Patient;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Patient
, folder_name=Patient, data_name_infile=Patient
, var_name_list=patid vmid gender yob mob marital famnum chsreg chsdate prescr capsup frd crd regstat reggap internal tod toreason deathdate accept
, var_format_list=$20. $20. best1. best4. best2. best3. best20. best1. ddmmyy10. best3. best3. ddmmyy10. ddmmyy10. best2. best5. best2. ddmmyy10. best3. ddmmyy10. $1.
);
data a.gold_patient_b; set patient_1; run; 
%DeleteDataset(lib=work, data_name=patient, n_stt=1, n_end=1);
*Practice;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Practice
, folder_name=Practice, data_name_infile=Practice
, var_name_list=pracid region lcd uts
, var_format_list=$5. best3. ddmmyy10. ddmmyy10.
);
proc sql;
create table a.gold_practice_b as
select *
from practice_1
where pracid not in (select gold_pracid from b.prac_migrt)
;quit;
%DeleteDataset(lib=work, data_name=practice, n_stt=1, n_end=1);
*Clinical;
%IMPORT_N (file_n_stt=1, file_n_end=9, lib_name=work, data_name=Clinical
, folder_name=Clinical, data_name_infile=Clinical
, var_name_list=patid	eventdate	sysdate	constype	consid	medcode	sctid	sctdescid	sctexpression	sctmaptype	sctmapversion	sctisindicative	sctisassured	staffid	episode	enttype	adid
, var_format_list=$20. ddmmyy10. ddmmyy10. 3. $20. $20. $20. $20. $20. 1. 10. $1. $1. $20. 3. 5. $20.
);
data a.gold_clinical_b; set clinical_1 - clinical_9; run; 
%DeleteDataset(lib=work, data_name=clinical, n_stt=1, n_end=9);
*Additional;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Additional
, folder_name=Additional, data_name_infile=Additional
, var_name_list=patid enttype adid data1 data2 data3 data4 data5 data6 data7 data8 data9 data10 data11 data12
, var_format_list=$20. best5. $20. $20. $20. $20. $20. $20. $20. $20. $20. $20. $20. $20. $20. 
);
data a.gold_additional_b; set additional_1 - additional_1; run;
%DeleteDataset(lib=work, data_name=additional, n_stt=1, n_end=1);
*Therapy;
%IMPORT_N (file_n_stt=1, file_n_end=8, lib_name=work, data_name=Therapy
, folder_name=Therapy, data_name_infile=Therapy
, var_name_list=patid	eventdate	sysdate	consid	prodcode	drugdmd	staffid	dosageid	bnfcode	qty	numdays	numpacks	packtype	issueseq	prn
, var_format_list=$20. ddmmyy10. ddmmyy10. $20. $20. $20. $20. $64. $5. 20. 20. 8. 10. 20. $1. $20. $7. $100.
);
data a.gold_therapy_b; set therapy_1 - therapy_8; run; 
%DeleteDataset(lib=work, data_name=therapy, n_stt=1, n_end=8);
*Test;
%IMPORT_N (file_n_stt=1, file_n_end=3, lib_name=work, data_name=Test
, folder_name=Test, data_name_infile=Test
, var_name_list=patid	eventdate	sysdate	constype	consid	medcode	sctid	sctdescid	sctexpression	sctmaptype	sctmapversion	sctisindicative	sctisassured	staffid	enttype	data1	data2	data3	data4	data5	data6	data7	data8
, var_format_list=$20. ddmmyy10. ddmmyy10. 3. $20. $20. $20. $20. $20. 1. $10. $1. $1. $20. 5. $3. $20. $20. $20. $20. $20. $20. $20. 
);
data a.gold_test_b; set test_1 - test_3; run; 
%DeleteDataset(lib=work, data_name=test, n_stt=1, n_end=3);
*Staff;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Staff
, folder_name=Staff, data_name_infile=Staff
, var_name_list=staffid	gender	role
, var_format_list=$20. 1. 3.
);
data a.gold_Staff_b; set Staff_1; run; 
%DeleteDataset(lib=work, data_name=Staff, n_stt=1, n_end=1);
*Referral;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Referral
, folder_name=Referral, data_name_infile=Referral
, var_name_list=patid	eventdate	sysdate	constype	consid	medcode	sctid	sctdescid	sctexpression	sctmaptype	sctmapversion	sctisindicative	sctisassured	staffid	source	nhsspec	fhsaspec	inpatient	attendance	urgency
, var_format_list=$20. ddmmyy10. ddmmyy10. 3. $20. $20. $20. $20. $20. 1. 10. $1. $1. $20. 2. 3. 3. 2. 2. 2.
);
data a.gold_Referral_b; set Referral_1; run; 
%DeleteDataset(lib=work, data_name=Referral, n_stt=1, n_end=1);
*Immunisation;
%IMPORT_N (file_n_stt=1, file_n_end=4, lib_name=work, data_name=Immunisation
, folder_name=Immunisation, data_name_infile=Immunisation
, var_name_list=patid	eventdate	sysdate	constype	consid	medcode	sctid	sctdescid	sctexpression	sctmaptype	sctmapversion	sctisindicative	sctisassured	staffid	immstype	stage	status	compound	source	reason	method	batch
, var_format_list=$20. ddmmyy10. ddmmyy10. 3. $20. $20. $20. $20. $20. 1. 10. $1. $1. $20. 4. 2. 3. 4. 3. 3. 3. 20.  
);
data a.gold_Immunisation_b; set Immunisation_1 - immunisation_4; run; 
%DeleteDataset(lib=work, data_name=Immunisation, n_stt=1, n_end=4);
*Consultation;
%IMPORT_N (file_n_stt=1, file_n_end=7, lib_name=work, data_name=Consultation
, folder_name=Consultation, data_name_infile=Consultation
, var_name_list=patid	eventdate	sysdate	constype	consid	staffid	duration
, var_format_list=$20. ddmmyy10. ddmmyy10. 3. $20. $20. 10.
);
data a.gold_Consultation_b; set Consultation_1 - Consultation_7; run; 
%DeleteDataset(lib=work, data_name=Consultation, n_stt=1, n_end=7);



/*Aurum*/
*PregRegister;
%IMPORT_TXT (
path=E:\Data\Pregnancy\Aurum_MBlink\23_002937_Type1_data, 
filename=aurum_pregnancy_register_2022_05
, lib=a, data_name=aurum_preg
, var_name_list=patid	pregstart	pregend
, var_format_list=$20. ddmmyy10. ddmmyy10.
, delimiter='09'x
);
%IMPORT_TXT (
path=E:\Data\Pregnancy\Aurum_MBlink\23_002937_Type1_data, 
filename=aurum_mbl_2022_05
, lib=a, data_name=aurum_mblink
, var_name_list=mumpatid	babypatid	deldate
, var_format_list=$20. $20. ddmmyy10.
, delimiter='09'x
);

%let path_in=E:\Data\Pregnancy\Aurum_mother;
%let file_num_form=Z3.; *Format of Number in File (e.g., Zw. or w.);
%let file_name_form=aurum_mother_Extract_&data_name_infile._&file_num_infile.; *Format of Filename, using &file_num_infile. and &data_name_infile.;
*Patient;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Patient
, folder_name=Patient, data_name_infile=Patient
, var_name_list=patid	pracid	usualgpstaffid	gender	yob	mob	emis_ddate	regstartdate	patienttypeid	regenddate	acceptable	cprd_ddate
, var_format_list=$20. $5. $10. 3. 4. 2. ddmmyy10. ddmmyy10. $5. ddmmyy10. 1. ddmmyy10.
);
data a.aurum_patient; set patient_1; run; 
%DeleteDataset(lib=work, data_name=patient, n_stt=1, n_end=1);
*Practice;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Practice
, folder_name=Practice, data_name_infile=Practice
, var_name_list=pracid	lcd	uts	region
, var_format_list=$5. ddmmyy10. ddmmyy10. 5.
);
data a.aurum_practice; set practice_1; run;
%DeleteDataset(lib=work, data_name=practice, n_stt=1, n_end=1);
*Observation;
%IMPORT_N (file_n_stt=1, file_n_end=89, lib_name=work, data_name=observation
, folder_name=Observation, data_name_infile=Observation
, var_name_list=patid	consid	pracid	obsid	obsdate	enterdate	staffid	parentobsid	medcodeid	value	numunitid	obstypeid	numrangelow	numrangehigh	probobsid
, var_format_list=$20. $20. $5. $20. ddmmyy10. ddmmyy10. $20. $20. $20. 19.3 $10. $5. 19.3 19.3 $20.
);
data a.aurum_observation; set observation_1 - observation_89; run;
%DeleteDataset(lib=work, data_name=observation, n_stt=1, n_end=89);
*DrugIssue;
%IMPORT_N (file_n_stt=1, file_n_end=29, lib_name=work, data_name=drug
, folder_name=Drug, data_name_infile=DrugIssue
, var_name_list=patid	issueid	pracid	probobsid	drugrecid	issuedate	enterdate	staffid	prodcodeid	dosageid	quantity	quantunitid	duration	estnhscost
, var_format_list=$20. $20. $5. $20. $20. ddmmyy10. ddmmyy10. $10. $20. $64. 9.3 $2. 10. 10.4
);
data a.aurum_drug; set drug_1 - drug_29; run;
%DeleteDataset(lib=work, data_name=drug, n_stt=1, n_end=29);
*Problem;
%IMPORT_N (file_n_stt=1, file_n_end=3, lib_name=work, data_name=Problem
, folder_name=Problem, data_name_infile=Problem
, var_name_list=patid	obsid	pracid	parentprobobsid	probenddate	expduration	lastrevdate	lastrevstaffid	parentprobrelid	probstatusid	signid
, var_format_list=$20. $20. $5. $20. ddmmyy10. 5. ddmmyy10. $10. $5. $5. $5.
);
data a.aurum_Problem; set Problem_1 - Problem_3; run; 
%DeleteDataset(lib=work, data_name=Problem, n_stt=1, n_end=3);
*Referral;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Referral
, folder_name=Referral, data_name_infile=Referral
, var_name_list=patid	obsid	pracid	refsourceorgid	reftargetorgid	refurgencyid	refservicetypeid	refmodeid
, var_format_list=$20. $20. $5. $10. $10. $1. $2. $1. 
);
data a.aurum_Referral; set Referral_1; run; 
%DeleteDataset(lib=work, data_name=Referral, n_stt=1, n_end=1);
*Staff;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Staff
, folder_name=Staff, data_name_infile=Staff
, var_name_list=staffid	pracid	jobcatid
, var_format_list=$10. $5. $5.
);
data a.aurum_Staff; set Staff_1; run; 
%DeleteDataset(lib=work, data_name=Staff, n_stt=1, n_end=1);
*Consultation;
%IMPORT_N (file_n_stt=1, file_n_end=24, lib_name=work, data_name=Consultation
, folder_name=Consultation, data_name_infile=Consultation
, var_name_list=patid	consid	pracid	consdate	enterdate	staffid	conssourceid	cprdconstype	consmedcodeid
, var_format_list=$20. $20. $5. ddmmyy10. ddmmyy10. $10. $10. 3. $20.
);
data a.aurum_Consultation; set Consultation_1 - Consultation_24; run; 
%DeleteDataset(lib=work, data_name=Consultation, n_stt=1, n_end=24);

%let path_in=E:\Data\Pregnancy\Aurum_child;
%let file_num_form=Z3.; *Format of Number in File (e.g., Zw. or w.);
%let file_name_form=aurum_child_Extract_&data_name_infile._&file_num_infile.; *Format of Filename, using &file_num_infile. and &data_name_infile.;
*Patient;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Patient
, folder_name=Patient, data_name_infile=Patient
, var_name_list=patid	pracid	usualgpstaffid	gender	yob	mob	emis_ddate	regstartdate	patienttypeid	regenddate	acceptable	cprd_ddate
, var_format_list=$20. $5. $10. 3. 4. 2. ddmmyy10. ddmmyy10. $5. ddmmyy10. 1. ddmmyy10.
);
data a.aurum_patient_b; set patient_1; run; 
%DeleteDataset(lib=work, data_name=patient, n_stt=1, n_end=1);
*Practice;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Practice
, folder_name=Practice, data_name_infile=Practice
, var_name_list=pracid	lcd	uts	region
, var_format_list=$5. ddmmyy10. ddmmyy10. 5.
);
data a.aurum_practice_b; set practice_1; run;
%DeleteDataset(lib=work, data_name=practice, n_stt=1, n_end=1);
*Observation;
%IMPORT_N (file_n_stt=1, file_n_end=34, lib_name=work, data_name=observation
, folder_name=Observation, data_name_infile=Observation
, var_name_list=patid	consid	pracid	obsid	obsdate	enterdate	staffid	parentobsid	medcodeid	value	numunitid	obstypeid	numrangelow	numrangehigh	probobsid
, var_format_list=$20. $20. $5. $20. ddmmyy10. ddmmyy10. $20. $20. $20. 19.3 $10. $5. 19.3 19.3 $20.
);
data a.aurum_observation_b; set observation_1 - observation_34; run;
%DeleteDataset(lib=work, data_name=observation, n_stt=1, n_end=34);
*DrugIssue;
%IMPORT_N (file_n_stt=1, file_n_end=13, lib_name=work, data_name=drug
, folder_name=Drug, data_name_infile=DrugIssue
, var_name_list=patid	issueid	pracid	probobsid	drugrecid	issuedate	enterdate	staffid	prodcodeid	dosageid	quantity	quantunitid	duration	estnhscost
, var_format_list=$20. $20. $5. $20. $20. ddmmyy10. ddmmyy10. $10. $20. $64. 9.3 $2. 10. 10.4
);
data a.aurum_drug_b; set drug_1 - drug_13; run;
%DeleteDataset(lib=work, data_name=drug, n_stt=1, n_end=13);
*Problem;
%IMPORT_N (file_n_stt=1, file_n_end=2, lib_name=work, data_name=Problem
, folder_name=Problem, data_name_infile=Problem
, var_name_list=patid	obsid	pracid	parentprobobsid	probenddate	expduration	lastrevdate	lastrevstaffid	parentprobrelid	probstatusid	signid
, var_format_list=$20. $20. $5. $20. ddmmyy10. 5. ddmmyy10. $10. $5. $5. $5.
);
data a.aurum_Problem_b; set Problem_1 - Problem_2; run; 
%DeleteDataset(lib=work, data_name=Problem, n_stt=1, n_end=2);
*Referral;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Referral
, folder_name=Referral, data_name_infile=Referral
, var_name_list=patid	obsid	pracid	refsourceorgid	reftargetorgid	refurgencyid	refservicetypeid	refmodeid
, var_format_list=$20. $20. $5. $10. $10. $1. $2. $1. 
);
data a.aurum_Referral_b; set Referral_1; run; 
%DeleteDataset(lib=work, data_name=Referral, n_stt=1, n_end=1);
*Staff;
%IMPORT_N (file_n_stt=1, file_n_end=1, lib_name=work, data_name=Staff
, folder_name=Staff, data_name_infile=Staff
, var_name_list=staffid	pracid	jobcatid
, var_format_list=$10. $5. $5.
);
data a.aurum_Staff_b; set Staff_1; run; 
%DeleteDataset(lib=work, data_name=Staff, n_stt=1, n_end=1);
*Consultation;
%IMPORT_N (file_n_stt=1, file_n_end=13, lib_name=work, data_name=Consultation
, folder_name=Consultation, data_name_infile=Consultation
, var_name_list=patid	consid	pracid	consdate	enterdate	staffid	conssourceid	cprdconstype	consmedcodeid
, var_format_list=$20. $20. $5. ddmmyy10. ddmmyy10. $10. $10. 3. $20.
);
data a.aurum_Consultation_b; set Consultation_1 - Consultation_13; run; 
%DeleteDataset(lib=work, data_name=Consultation, n_stt=1, n_end=13);





*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
