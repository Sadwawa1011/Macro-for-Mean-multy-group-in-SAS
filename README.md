# Macro-for-Mean-multy-group-in-SAS
  不定组别（分类）下，定量分析的SAS宏程序  
  动态指定`组别（分类）`，动态指定SAS`定量分析统计量`，动态指定`简单的输出模板（呈现样式）`；  
  可用于`两组`中定量分析和差异性假设检验（`T检验`/`Wilcoxon秩和检验`）

# 必填参数目录content
- [indata](#indata)  
- [outdata](#outdata)  
- [var](#var)  
- [group](#group)

# 可选参数目录content
- [group_txt](#group_txt)  
- [group_delimiter](#group_delimiter)  
- [group_misstxt](#group_misstxt)  
- [statlist](#statlist)  
- [S_template](#S_template)  
- [S_temp_label](#S_temp_label)  
- [label](#label)  
- [bigcatyn](#bigcatyn)  
- [biglabel](#biglabel)  
- [index](#index)  
- [testyn](#testyn)  
- [testfmt](#testfmt)  
- [pfmt](#pfmt)  
- [Nfmt](#Nfmt)  
- [fmtyn](#fmtyn)  
- [meanfmt](#meanfmt)  
- [stdfmt](#stdfmt)  
- [descfmt](#descfmt)  
- [type](#type)  

# 宏程序使用语法
```sas
%mean_multy_group( in_data_test, var_test , group_test , out_data_test  );
%mean_multy_group( indata = in_data_test, var = var_test , group = group_test , outdata = out_data_test  );
```

# 参数使用语法
## indata
  输入用于分析的数据集名称  
  分析数据集要求：至少有一列定量数据，一列分类变量数据。  
  
## outdata
  输出用于呈现分析结果的数据集名称。    
  输出数据集结构如下：  
  
<div align="center">

| cate_标签   | group_分类1 | group_分类2 | group_分类j  |   合计   |
| :----------  | -----------| ----------  | -----------|-----------|
| "&label"    |            |             |            |           |
| "&index"例数(缺失)      | XX(XX)        | XX(XX)         | XX(XX)        | XX(XX)     |
| "&index"均数±标准差     | XX±XX         | XX±XX          | XX±XX         | XX±XX      |
| "&index"中位数(Q1, Q3)  | XX(XX, XX)    | XX(XX, XX)     | XX(XX, XX)    | XX(XX, XX) |
| "&index"最小值, 最大值  | XX, XX        | XX, XX         | XX, XX        | XX, XX     |

</div>
备注：仅调用必填参数情况下的数据集结构。  

## var
  定量分析变量，如年龄（age）。
  调用：
  ```sas
  var = age ;
  ```

## group
  组别或分类变量，如（arm:试验组VS对照组）
  ```sas
  group = arm ;
  ```

## group_txt
  组别（分类）变量的`分类文本`。  
  主要用于`没有但需呈现的分类`，如`安慰剂组`。
  default：不调用，分类呈现按照数据实际存在的分类呈现（排序：按照文本升序排序）
  ```sas
  group_txt = %str();
  ```

  调用语法：  
  ```sas
  group_txt = %str(试验组 对照组 安慰剂组);
  group_txt = %str(试验组@对照组@安慰剂组) , group_delimiter = %str(@)  ;
  ```
  备注：排序：按照调用时填写的文本分类顺序呈现。可与[group_delimiter](#group_delimiter)联合使用。

## group_delimiter
    组别（分类）变量，调用[group_txt](#group_txt)时，指定特定的分类文本分隔符。
    default  
    ``` 
    group_delimiter = %str();  
    ```
    备注：中文逗号建议不作为分隔符，非ASCⅡ字符的处理目前存在一些特殊问题。

## group_misstxt
  组别（分类）分类变量的`缺失值填补文本`。
  default
  ```sas
  group_misstxt = %str(缺失) ;
  ```

## statlist
  用于指定定量统计量列表，与SAS`PROC MEANS`过程关键字一致，例如：
<div align="center">

| 统计量关键字   | 含义 | 
| :----------  | ----------- |
|  N          |    例数     |
|  NMISS      |    缺失例数 |
| MEAN        |    均数     |
| STD (STDDEV)         |    标准差  |
| MEDIAN (P50)         |    中位数  |
| Q1 (P25) / Q3 (P75)  |    第25 / 75百分数数  |
| MIN / MAX            |    最小值 / 最大值    |
|   RANGE              |    极差               |
|      ...             |    ...               |

</div>

  default
  ```sas
  statlist=%str(n mean std median q1 q3 min max nmiss );
  ```
  备注：调用时，不区分大小写，可与[group_delimiter](#group_delimiter)联合使用。
  例如：
  ```sas
    statlist=%str(n@mean@std@median@q1@q3@min@max@nmiss) , group_delimiter = %str(@) ;
  ```

## S_template
  用于动态指定输出样式。
  default
  ```sas
  S_template=%nrstr({N}({NMISS})|{MEAN}±{STD}|{MEDIAN}({Q1}, {Q3})|{MIN}, {MAX}) ;
  ```
  默认参数下，输出结果同[outdata](#outdata)中表格。  
  备注：1.输出样式中的`统计量关键字`需在[statlist](#statlist)中调用 。  
  2.此部分`统计量关键字`需大写，用`{}`定义为一个`统计量关键字`。  
  3.用`|`定义换行，即当遇到`|`开始换行到下一行输出。  
  例如：
  ```sas
  S_template=%nrstr({N}|{NMISS}|{MEAN}|{STD});
  ```
  结果如下：
  
<div align="center">

| cate_标签   | group_分类1 | group_分类2 | group_分类j  |   合计   |
| :----------  | -----------| ----------  | -----------|-----------|
| "&label"    |            |             |            |           |
| "&index"例数      | XX         | XX         | XX        | XX    |
| "&index"缺失例数  | XX         | XX         | XX        | XX    |
| "&index"均数      | XX         | XX         | XX        | XX    |
| "&index"标准差    | XX         | XX         | XX        | XX    |

</div>  

## S_temp_label 
  用于动态指定输出样式的标签。即指定输出样式[S_template](#S_template)的标签。  
  default
  ```
  S_temp_label=%nrstr(例数(缺失)|均数±标准差|中位数(Q1, Q3)|最小值, 最大值);
  ```
  备注：用`|`定义换行，即当遇到`|`开始换行到下一行输出标签，建议与输出样式保持一致。  
  例如：
  ```sas
  S_template=%nrstr({N}|{NMISS}|{MEAN}|{STD}) , S_temp_label=%nrstr(例数|缺失|均数|标准差) ;
  ```

## label
  出表标签，主要用于明确分析的变量标签。
  default
  ```
  label = %str() ;
  ```
  例如：
  ```
  label = %str(年龄（岁）) ;
  ```
<div align="center">

| cate_标签   | group_分类1 | group_分类2 | group_分类j  |   合计   |
| :----------  | -----------| ----------  | -----------|-----------|
| 年龄（岁）  |            |             |            |           |
| ...         | ...        | ...         | ...        | ...       |

</div>

## bigcatyn
  是否衍生大分类标签，位于[label](#label)的上一级大分类（上一行）。
<div align="center">

| 可选项（数值型）  |   含义      |
|  ---------        | -------     |
| 0                 | 不衍生  |
| 1                 |  衍生   |

</div>    

  default  
  ```sas  
  bigcatyn = 0 ;  
  ```  

## biglabel 
  大分类标签的文本（仅[bigcatyn](#bigcatyn) = 1时生效）。
  default
  ```sas
  biglabel = %str() ;
  ```
 
## index
  `cate_标签`中，各行[S_temp_label](#S_temp_label) 或 [label](#label)(仅在bigcatyn = 1时)的标签前置缩进符号。
  default：默认为前置缩进`四个空格`。  
  ```sas
  index = %str(    );
  ```

## testyn
  是否进行两组差异性检验（`T检验`/`Wilcoxon秩和检验`）（仅在[group](#group)分类为二分类时生效）。
<div align="center">
  
| 可选项（数值型）  |   含义      |
|  ---------        | -------     |
| 0                 | 不衍生  |
| 1                 |  衍生   |

</div> 

  default  
  ```sas  
  testyn = 0 ;  
  ```  

## testfmt
  检验统计量值的输出格式。
  default
  ```sas
  testfmt = 8.4 ；
  ```
  备注：仅在[group](#group)分类为二分类且[testyn](#testyn) = 1 时生效。  

## pfmt
  检验统计量对应P值的输出格式。
  default
  ```sas
  pfmt = pvalue6.4 ；
  ```
  备注：仅在[group](#group)分类为二分类且[testyn](#testyn) = 1 时生效。   

## Nfmt
  定量统计量关键字例数（N）的输出格式。  
  default
  ```sas
  Nfmt = 8.0 ；
  ```

## fmtyn
  是否手动指定统计量输出格式。  
<div align="center">
  
| 可选项（数值型）  |   含义      |
|  ---------        | -------     |
| 0                 | 自动读取-按照既定规则衍生  |
| 1                 |  手动指定格式   |

</div>  

  default  
  ```sas  
  fmtyn = 0 ;  
  ```

  自动读取-既定规则（宏程序默认自动读取 `定量变量`的最高小数位进行衍生）。   
  
<div align="center">
  
| 自动读取-衍生的参数  |   含义      |  衍生规则  |
|  ---------           | -------      |-------     |
|  [meanfmt](#meanfmt)     | 均数、中位数、Q1、Q3的输出格式                                 | mean,median,q1,q3比实际小数位多1位，最多4位 |
| [stdfmt](#stdfmt)        | 标准差的输出格式                                               | STD比mean多一位小数，最多四位               |
| [descfmt](#descfmt)      | 除`例数` `缺失例数` `均数` `标准差`以外，其他统计量的输出格式   | 其他统计量如min,max和实际小数位相同         |

</div>   

## meanfmt
  均数、中位数、Q1、Q3的输出格式。仅当[fmtyn](#fmtyn) = 1时生效。  
  宏程序默认自动读取 `定量变量`的最高小数位进行衍生。  

## stdfmt
  标准差的输出格式。仅当[fmtyn](#fmtyn) = 1时生效。  
  宏程序默认自动读取 `定量变量`的最高小数位进行衍生。  

## descfmt
  除`例数` `缺失例数` `均数` `标准差`以外，其他统计量的输出格式。仅当[fmtyn](#fmtyn) = 1时生效。  
  宏程序默认自动读取 `定量变量`的最高小数位进行衍生。  

##  type 
  指定输出数据集的唯一序号，便于（可能）与其他数据集的合并。  
  default
  ```
  type = 1 ;
  ```

## END




  




