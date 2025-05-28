/*===============================================================================================================================*
Program Name        :  mean_multy_group
Path                :  
Program Language    :  SAS V9.4
_________________________________________________________________________________________________________________________________
Purpose             :  �����鶨����������ָ̬����𣬶�ָ̬����������ͳ��������ָ̬�����ģ�壩
Macro Calls         :  %mean_multy_group
Files
  Input             :  
  Output            :  
Program Flow:

==================================================================================================================================*/



%macro mean_multy_group(indata,var,group,outdata
        ,group_txt=%str(),group_delimiter=" ",group_misstxt=%str(ȱʧ),index=%str(    )
        ,testyn=1,testfmt=8.4,pfmt=pvalue6.4,Nfmt=8.0,label=%str(),bigcatyn=0,biglabel=%str()
        ,statlist=%str(n mean std median q1 q3 min max nmiss )
        ,S_template=%nrstr({N}({NMISS})|{MEAN}��{STD}|{MEDIAN}({Q1}, {Q3})|{MIN}, {MAX})
        ,S_temp_label=%nrstr(����(ȱʧ)|��������׼��|��λ��(Q1, Q3)|��Сֵ, ���ֵ)
        ,fmtyn=0,meanfmt=8.1,stdfmt=8.2,descfmt=8.0,type=1);
 
/*
        indata          : �������ݼ�
        group           : ���
        var             : �������
        outdata         : ������ݼ�
        group_txt       : �������ı����ɰ��ճ���˳������
        group_delimiter : �������ı��ָ�����Ĭ��Ϊ"�ո�"�����Ķ��Ž��鲻��Ϊ�ָ���,��ASCII�ַ��Ĵ������һЩ�������⣩
        group_misstxt   : ������ȱʧ��ı���Ĭ��Ϊ��ȱʧ��
        index           : ����

        testyn          : 1-���м��飬0-�����м��飨�������������Ƚ�ʱ��Ч��
        testfmt         : ͳ������ʽ
        pfmt            : Pֵ��ʽ
        Nfmt            : ������ʽ
        label           : ���������ǩ���硰����(��)����
        bigcatyn        : 1-���������༶��0-������
        biglabel        : �������ǩ

        statlist        : ����ͳ�����б�(�����ִ�Сд)
        S_template      ��ͳ�������ַ�ʽ���ɶ�ָ̬������У��á�|���ָ��У�����ָ̬��ͳ����("{}"��ѡstatlist�е��б����д)
        S_temp_label    ��ͳ������ǩ������S_template��ͳ����һһ��Ӧ

        fmtyn           : �Ƿ���Ϊָ�������ʽ��0-��ָ�����Զ���ȡС��λ����1-ָ��
        meanfmt         : ��ֵ��ʽ
        stdfmt          : ��׼���ʽ
        descfmt         : Q1,Q3����Сֵ�����ֵ��ʽ��ͬ���ݱ����ʽ��
        type            : ��ֵ��ű������������ݼ��ϲ�


*/


/* ��������ͳһ��д */
%let var=%sysfunc( upcase(&var) ) ;
%let statlist=%sysfunc( upcase(&statlist) ) ;


/* --------------------------------��������----------------------- */
/* �������ݣ�vvalue() ������ֵ����ʾ��ʽ תΪ�ı� ȱʧ�Ϊ&misstxt��%superq()ֱ�ӻ�ȡ�������ֵ���������κκ���� */
    data exdata;
        set &indata;
        _tem_var=strip(vvalue(&var));
        &group = coalescec(&group,"%superq(group_misstxt)" );
    run;
    /* �������� */
    data _null_;
        set exdata end=last;
            if last then call symput("totaln",_n_);
    run;


/*--------------��ȡ�������С��λ��-------------*/
%if &fmtyn=0  %then %do;
    /* ��ȡС��λ */
    proc sql noprint;
        /* С���� */
        select  max( case when index(_tem_var,".") = 0 then 0  else length(scan(_tem_var,2,"."))
                    end)  into : desc  from exdata(where=(^missing(&var)));
        /* ���� */
        select  max( case when index(_tem_var,".") = 0 then length(_tem_var) else length(scan(_tem_var,1,"."))
                    end)  into : _tem_int  from exdata(where=(^missing(&var)));
    quit;

    /* ��ֵС��λ��ʽ */
    proc sql noprint;
        select IFC( &desc<=4,CATS(%sysevalf(&_tem_int + &desc +1),".",&desc),CATS(&_tem_int + &desc +5,".4") ) INTO : descfmt from exdata;
        select IFC( &desc<=2,CATS(%sysevalf(&_tem_int + &desc +2),".",&desc+1),CATS(&_tem_int + &desc +6,".4") ) INTO : meanfmt from exdata;
        select IFC( &desc<=2,CATS(%sysevalf(&_tem_int + &desc +3),".",&desc+2),CATS(&_tem_int + &desc +7,".4") ) INTO : stdfmt from exdata;
    quit;

%end;
%else %if &fmtyn=1 %then %do;
    %let meanfmt = &meanfmt;
    %let stdfmt = &stdfmt;
    %let descfmt = &descfmt;
%end;
    %put meanfmt = &meanfmt;
    %put stdfmt = &stdfmt;
    %put descfmt = &descfmt;


/* ----------------����������-------------- */
/* ��var1/2txt�ı�û��ָ��,���Զ���ȡ */
%if %length(&group_txt)=0 %then %do;
    /* ��ȡ�з���-ȱʧ���Ϊ&misstxt */
    proc sql noprint;
        create table rowcat1 as
        select distinct( &group ) as rowcat
        from exdata; 
    quit;
    data _null_;
        set rowcat1 end=last;
        /* ������ */
        call symputx(cats("gtxt",_n_),rowcat );
        if last then call symput("gtxt_n",_n_);
    run;
    proc delete data=rowcat1;
    quit;
%end;
%else %do;
    data _null_;
        txt = symget('group_txt');delimiter = symget('group_delimiter'); n = countw(txt, delimiter) ;
      call symputx('gtxt_n', n);
    run;
    /* ����ָ�������ȡ������ */
    %do i=1 %to &gtxt_n;
        %let gtxt&i = %qtrim( %qscan( %superq(group_txt),&i,%unquote(%superq(group_delimiter)) ) ) ;
    %end;
%end;


/* ��ȡ �������� ͳ�������� */
data _null_;
    txt = symget('statlist');delimiter = symget('group_delimiter'); n = countw(txt, delimiter) ;
    call symputx('stat_n', n);
    /* ��ȡ �������� ģ������ */
    txt1 = symget('S_template'); n1 = countw(txt1, "|") ;call symputx('row_cate_n', n1);

run;
/* ��ȡͳ���������� */
%do i=1 %to &stat_n;
    %let stat&i = %qtrim( %qscan( %superq(statlist),&i,%unquote(%superq(group_delimiter)) ) ) ;
%end;



/* --------------------------��������-��ֵ��׼��-------------------------- */

/* ���� */
data _null_;
    if 0 then set exdata nobs=n;
    call symput("n_tol",n);
run;

/* ��ʼ���� */
/*options mprint;*/
proc means data=exdata noprint;
    var &var;
    class &group;
    output out=meanc    %do i=1 %to &stat_n; 
                            %str() %superq(stat&i) = %superq(stat&i)  %str()  
                        %end;
;
run;
/*options nomprint;*/

/* ------������------ */
/*options mprint;*/
data meanc1;
    set meanc;
    length seq 8. value $200.;

    if _TYPE_=0 then &group = "�ϼ�";

    dot_mean=input(kscan("&meanfmt",2,"."),8.) ;
    dot_std=input(kscan("&stdfmt",2,"."),8.) ;
    dot_desc=input(kscan("&descfmt",2,"."),8.) ;
    S_template= symget('S_template')  ;
    S_temp_label= symget('S_temp_label')  ;

    seq=0;value="  ";output;
    %do i=1 %to &row_cate_n;
        seq=&i ;
        formatted_result =  Kscan(S_template,&i,"|")  ;
        formatted_label =  Kscan(S_temp_label,&i,"|")  ;
        /* ���������ʽ����mean,median,q1,q3��ʵ��С��λ��1λ�����4λ
                    STD��mean��һλС���������λ
                    ����ͳ������min,max��ʵ��С��λ��ͬ
        */
        %do j=1 %to &stat_n;
            formatted_result =  tranwrd( formatted_result ,  
                                        "{%bquote(%superq(stat&j))}", 
                                        IFC( "%bquote(%superq(stat&j))" in("N" "NMISS")
                                            ,cats(put(&&stat&j,8.))
                                            ,IFC( "%bquote(%superq(stat&j))" in("MEAN" "MEDIAN" "Q1" "Q3")
                                                  ,cats(put( round(&&stat&j,(1/10)**dot_mean) ,&meanfmt.))
                                                  ,IFC( "%bquote(%superq(stat&j))"="STD"
                                                        ,cats(put( round(&&stat&j,(1/10)**dot_std) ,&stdfmt.))
                                                        ,cats(put( round(&&stat&j,(1/10)**dot_desc) ,&descfmt.))
                                                      )
                                                 )
                                            ) 
                                        ) ;
        %end;
        value=formatted_result;output;
    %end;
run;
/*options nomprint;*/



/* ������� ѭ�� ������ݼ� */
%let gtxt_tol_n = %eval(&gtxt_n+1) ;
%let gtxt&gtxt_tol_n = �ϼ� ;

data &outdata;
    length type 8. cate $200.;
    merge %do i=1 %to &gtxt_tol_n; 
        meanc1( where=( &group = "%superq(gtxt&i)" ) rename=( value = value&i )) 
            %str()
        %end; ;
    by seq;
    
    type=&type;

    if seq=0 then cate="&label";
    if seq>0 then cate="&index"||strip(formatted_label);

    ntotal=&n_tol ;

    label %do i=1 %to &gtxt_tol_n;  value&i = "%superq(gtxt&i)"  %str() %end;  ntotal="�������ݼ�����";
    
    keep type seq cate %do i=1 %to &gtxt_tol_n; value&i %str() %end; ntotal ;
run;




/* --------------------------------------------�������鶨�������Լ���---------------------------------------------- */
%if &testyn=1 and &gtxt_n^=2 %then %do;
    %put Note : ���������������Ϊ&gtxt_n �������飬δ���в����Լ��飡;
%end;
%if &testyn=1 and &gtxt_n=2 %then %do;
    /* ------����ֱ���̬�Լ���--------- */
    proc univariate data=exdata(where=( &group=strip(symget('gtxt1')) )) normal ;
        var &var;
        ods output testsfornormality=output_g1;
    quit;

   proc univariate data=exdata(where=( &group=strip(symget('gtxt2')) )) normal ;
        var &var;
        ods output testsfornormality=output_g2;
    quit;

    /* SAS�涨����N<=2000,���� Shapiro-Wilk �жϣ���N>2000,���� Kolmogorov -Smirnov ��� */
    %if &totaln<=2000 %then %do;

        proc sql noprint;
            select pValue into: p1_norm
            from output_g1(where=(Test="Shapiro-Wilk"));
            select pValue into: p2_norm
            from output_g2(where=(Test="Shapiro-Wilk"));
        quit;
    %end;
    %if &totaln>2000 %then %do;
        
        proc sql noprint;
            select pValue into: p1_norm
            from output_g1(where=(Test="Kolmogorov-Smirnov"));
            select pValue into: p2_norm
            from output_g2(where=(Test="Kolmogorov-Smirnov"));
        quit;
    %end;

    /* ָ�����format�����ڼ������ */
    proc format; 
        value $armfmt  "&gtxt1" = 1"&gtxt1"  "&gtxt2" = 2"&gtxt2" ; 
    run;

    /* ��������̬�����ó���T���� */
    %if &p1_norm>=0.05 and &p2_norm>=0.05 %then %do;
        
        /* T���� */
        proc ttest data=exdata(where=( &group=strip(symget('gtxt1')) or &group=strip(symget('gtxt2')) )) ;
            class &group;
            var &var;
            format &group  $armfmt. ;
            ods output ttests = _temp_out_ttest1 equality= _temp_out_ttest2;
        quit;


        /* �����룬��Ϊ�����ܡ�Tͳ����������Ϊ��Satterthwaite��Tͳ���� */
        /* �������ݼ� */
            data _temp_stat;
            length cate $200. value1 $200. value2 $200. spid0 8.  seq 8.;
                merge _temp_out_ttest1
                      _temp_out_ttest2(keep = Variable ProbF FValue)
                ;
                by Variable;
                seq= &row_cate_n+1 ;spid0=1;cate="&index"||"ͳ����";value1="t����";value2=strip(put(tValue,&testfmt.));output;
                seq= &row_cate_n+2 ;spid0=2;cate="&index"||"Pֵ";value1=strip(put(Probt,&pfmt.));value2=" ";output;

                keep Method cate value1 value2 spid0  seq ProbF;
            run; 
            data _temp_stat;
                set _temp_stat;
                if ( Method="����" and ProbF>=0.05 ) or ( Method="Satterthwaite" and ProbF<0.05 ) ;
            run;
        /* ɾ���������ݼ� */
        proc delete data= _temp_out_ttest1 _temp_out_ttest2;
        quit;

    %end;
/* ��������̬����wilcoxon */
    %if &p1_norm<0.05 or &p2_norm<0.05 %then %do; 
            
        proc npar1way data =exdata(where=( &group=strip(symget('gtxt1')) or &group=strip(symget('gtxt2')) )) 
                            wilcoxon noprint;
            class &group;
            var &var;
            format &group  $armfmt. ;
            output out=out_wil;
        quit;

        /* �������ݼ� */ 
        data _temp_stat;
            length cate $200. value1 $200. value2 $200. spid0 8. seq 8.;
            set out_wil;
            seq= &row_cate_n+1 ;spid0=1;cate="&index"||"ͳ����";value1="Wilcoxon�Ⱥͼ���";value2=strip(put(Z_WIL,&testfmt.));output;
            seq= &row_cate_n+2 ;spid0=2;cate="&index"||"Pֵ";value1=strip(put(P2_WIL,&pfmt.));value2=" ";output;
            keep cate value1 value2 spid0 seq;
        run;

        /* ɾ���������ݼ� */
        proc delete data=out_wil;
        quit;
    %end;

    /* -------------��������ݼ�----------- */
    data &outdata;
    length spid 8.;
        set &outdata _temp_stat;
        type=&type;
        spid=monotonic();
    run;

    
    /* ɾ���������ݼ� */
    proc delete data=output_g1 output_g2 _temp_stat;
    quit;

%end;


/* �Ƿ�--�����������ǩ */
%if &bigcatyn=1 %then %do;
    proc sql noprint;
        insert into &outdata(seq,cate,type) values(-1,"%superq(biglabel)",&type);
    quit;
    run;
    proc sort data=&outdata;
        by seq;
    quit;
    data &outdata;
        set &outdata;
        if cate^="%superq(biglabel)" then cate="&index"||cate;
        spid=monotonic();
    run;
    
%end;

/* ɾ���������ݼ� */
proc delete data=meanc meanc1 exdata;
run;

%mend;



