/*===============================================================================================================================*
Program Name        :  mean_multy_group
Path                :  
Program Language    :  SAS V9.4
_________________________________________________________________________________________________________________________________
Purpose             :  不定组定量分析（动态指定组别，动态指定定量分析统计量，动态指定输出模板）
Macro Calls         :  %mean_multy_group
Files
  Input             :  
  Output            :  
Program Flow:

==================================================================================================================================*/



%macro mean_multy_group(indata,var,group,outdata
        ,group_txt=%str(),group_delimiter=" ",group_misstxt=%str(缺失),index=%str(    )
        ,testyn=1,testfmt=8.4,pfmt=pvalue6.4,Nfmt=8.0,label=%str(),bigcatyn=0,biglabel=%str()
        ,statlist=%str(n mean std median q1 q3 min max nmiss )
        ,S_template=%nrstr({N}({NMISS})|{MEAN}±{STD}|{MEDIAN}({Q1}, {Q3})|{MIN}, {MAX})
        ,S_temp_label=%nrstr(例数(缺失)|均数±标准差|中位数(Q1, Q3)|最小值, 最大值)
        ,fmtyn=0,meanfmt=8.1,stdfmt=8.2,descfmt=8.0,type=1);
 
/*
        indata          : 输入数据集
        group           : 组别
        var             : 分析结果
        outdata         : 输出数据集
        group_txt       : 组别分类文本（可按照出表顺序排序）
        group_delimiter : 组别分类文本分隔符，默认为"空格"（中文逗号建议不作为分隔符,非ASCII字符的处理存在一些特殊问题）
        group_misstxt   : 组别分类缺失填补文本，默认为“缺失”
        index           : 缩进

        testyn          : 1-进行检验，0-不进行检验（仅分析两组组间比较时生效）
        testfmt         : 统计量格式
        pfmt            : P值格式
        Nfmt            : 例数格式
        label           : 分析结果标签（如“年龄(岁)”）
        bigcatyn        : 1-衍生最大分类级别，0-不衍生
        biglabel        : 最大分类标签

        statlist        : 计算统计量列表(不区分大小写)
        S_template      ：统计量呈现方式，可动态指定输出行（用“|”分割行），动态指定统计量("{}"框选statlist中的列表，需大写)
        S_temp_label    ：统计量标签，需与S_template的统计量一一对应

        fmtyn           : 是否人为指定输出格式，0-不指定（自动读取小数位），1-指定
        meanfmt         : 均值格式
        stdfmt          : 标准差格式
        descfmt         : Q1,Q3，最小值，最大值格式（同数据本身格式）
        type            : 赋值序号便于与其他数据集合并


*/


/* 分析变量统一大写 */
%let var=%sysfunc( upcase(&var) ) ;
%let statlist=%sysfunc( upcase(&statlist) ) ;


/* --------------------------------读入数据----------------------- */
/* 读入数据：vvalue() 保留数值型显示格式 转为文本 缺失填补为&misstxt，%superq()直接获取宏变量的值而不触发任何宏解析 */
    data exdata;
        set &indata;
        _tem_var=strip(vvalue(&var));
        &group = coalescec(&group,"%superq(group_misstxt)" );
    run;
    /* 总样本数 */
    data _null_;
        set exdata end=last;
            if last then call symput("totaln",_n_);
    run;


/*--------------获取数据最大小数位数-------------*/
%if &fmtyn=0  %then %do;
    /* 获取小数位 */
    proc sql noprint;
        /* 小数点 */
        select  max( case when index(_tem_var,".") = 0 then 0  else length(scan(_tem_var,2,"."))
                    end)  into : desc  from exdata(where=(^missing(&var)));
        /* 整数 */
        select  max( case when index(_tem_var,".") = 0 then length(_tem_var) else length(scan(_tem_var,1,"."))
                    end)  into : _tem_int  from exdata(where=(^missing(&var)));
    quit;

    /* 赋值小数位格式 */
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


/* ----------------读入组别分类-------------- */
/* 若var1/2txt文本没有指定,则自动提取 */
%if %length(&group_txt)=0 %then %do;
    /* 提取行分类-缺失已填补为&misstxt */
    proc sql noprint;
        create table rowcat1 as
        select distinct( &group ) as rowcat
        from exdata; 
    quit;
    data _null_;
        set rowcat1 end=last;
        /* 分类数 */
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
    /* 根据指定分类读取分类数 */
    %do i=1 %to &gtxt_n;
        %let gtxt&i = %qtrim( %qscan( %superq(group_txt),&i,%unquote(%superq(group_delimiter)) ) ) ;
    %end;
%end;


/* 读取 定量分析 统计量个数 */
data _null_;
    txt = symget('statlist');delimiter = symget('group_delimiter'); n = countw(txt, delimiter) ;
    call symputx('stat_n', n);
    /* 读取 定量分析 模板行数 */
    txt1 = symget('S_template'); n1 = countw(txt1, "|") ;call symputx('row_cate_n', n1);

run;
/* 读取统计量分类数 */
%do i=1 %to &stat_n;
    %let stat&i = %qtrim( %qscan( %superq(statlist),&i,%unquote(%superq(group_delimiter)) ) ) ;
%end;



/* --------------------------定量分析-均值标准差-------------------------- */

/* 总数 */
data _null_;
    if 0 then set exdata nobs=n;
    call symput("n_tol",n);
run;

/* 开始分析 */
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

/* ------处理结果------ */
/*options mprint;*/
data meanc1;
    set meanc;
    length seq 8. value $200.;

    if _TYPE_=0 then &group = "合计";

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
        /* 以下输出格式规则：mean,median,q1,q3比实际小数位多1位，最多4位
                    STD比mean多一位小数，最多四位
                    其他统计量如min,max和实际小数位相同
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



/* 根据组别 循环 输出数据集 */
%let gtxt_tol_n = %eval(&gtxt_n+1) ;
%let gtxt&gtxt_tol_n = 合计 ;

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

    label %do i=1 %to &gtxt_tol_n;  value&i = "%superq(gtxt&i)"  %str() %end;  ntotal="读入数据集总数";
    
    keep type seq cate %do i=1 %to &gtxt_tol_n; value&i %str() %end; ntotal ;
run;




/* --------------------------------------------进行两组定量差异性检验---------------------------------------------- */
%if &testyn=1 and &gtxt_n^=2 %then %do;
    %put Note : 定量分析中组别数为&gtxt_n 不是两组，未进行差异性检验！;
%end;
%if &testyn=1 and &gtxt_n=2 %then %do;
    /* ------两组分别正态性检验--------- */
    proc univariate data=exdata(where=( &group=strip(symget('gtxt1')) )) normal ;
        var &var;
        ods output testsfornormality=output_g1;
    quit;

   proc univariate data=exdata(where=( &group=strip(symget('gtxt2')) )) normal ;
        var &var;
        ods output testsfornormality=output_g2;
    quit;

    /* SAS规定：若N<=2000,则用 Shapiro-Wilk 判断，若N>2000,则用 Kolmogorov -Smirnov 结果 */
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

    /* 指定组别format，便于检验出表 */
    proc format; 
        value $armfmt  "&gtxt1" = 1"&gtxt1"  "&gtxt2" = 2"&gtxt2" ; 
    run;

    /* 若满足正态，则用成组T检验 */
    %if &p1_norm>=0.05 and &p2_norm>=0.05 %then %do;
        
        /* T检验 */
        proc ttest data=exdata(where=( &group=strip(symget('gtxt1')) or &group=strip(symget('gtxt2')) )) ;
            class &group;
            var &var;
            format &group  $armfmt. ;
            ods output ttests = _temp_out_ttest1 equality= _temp_out_ttest2;
        quit;


        /* 方差齐，则为“汇总”T统计量，否则为“Satterthwaite”T统计量 */
        /* 出表数据集 */
            data _temp_stat;
            length cate $200. value1 $200. value2 $200. spid0 8.  seq 8.;
                merge _temp_out_ttest1
                      _temp_out_ttest2(keep = Variable ProbF FValue)
                ;
                by Variable;
                seq= &row_cate_n+1 ;spid0=1;cate="&index"||"统计量";value1="t检验";value2=strip(put(tValue,&testfmt.));output;
                seq= &row_cate_n+2 ;spid0=2;cate="&index"||"P值";value1=strip(put(Probt,&pfmt.));value2=" ";output;

                keep Method cate value1 value2 spid0  seq ProbF;
            run; 
            data _temp_stat;
                set _temp_stat;
                if ( Method="汇总" and ProbF>=0.05 ) or ( Method="Satterthwaite" and ProbF<0.05 ) ;
            run;
        /* 删除过程数据集 */
        proc delete data= _temp_out_ttest1 _temp_out_ttest2;
        quit;

    %end;
/* 不满足正态，用wilcoxon */
    %if &p1_norm<0.05 or &p2_norm<0.05 %then %do; 
            
        proc npar1way data =exdata(where=( &group=strip(symget('gtxt1')) or &group=strip(symget('gtxt2')) )) 
                            wilcoxon noprint;
            class &group;
            var &var;
            format &group  $armfmt. ;
            output out=out_wil;
        quit;

        /* 出表数据集 */ 
        data _temp_stat;
            length cate $200. value1 $200. value2 $200. spid0 8. seq 8.;
            set out_wil;
            seq= &row_cate_n+1 ;spid0=1;cate="&index"||"统计量";value1="Wilcoxon秩和检验";value2=strip(put(Z_WIL,&testfmt.));output;
            seq= &row_cate_n+2 ;spid0=2;cate="&index"||"P值";value1=strip(put(P2_WIL,&pfmt.));value2=" ";output;
            keep cate value1 value2 spid0 seq;
        run;

        /* 删除过程数据集 */
        proc delete data=out_wil;
        quit;
    %end;

    /* -------------总输出数据集----------- */
    data &outdata;
    length spid 8.;
        set &outdata _temp_stat;
        type=&type;
        spid=monotonic();
    run;

    
    /* 删除过程数据集 */
    proc delete data=output_g1 output_g2 _temp_stat;
    quit;

%end;


/* 是否--衍生最大分类标签 */
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

/* 删除过程数据集 */
proc delete data=meanc meanc1 exdata;
run;

%mend;



