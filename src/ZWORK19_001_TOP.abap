*&---------------------------------------------------------------------*
*& Include  ZWORK19_001_TOP
*&---------------------------------------------------------------------*
TABLES: ZTCURR19, sscrfields.

"=== Selection-Screen 파라미터 바인딩용 타입 ===
TYPES: BEGIN OF ty_xl_raw,
         row    TYPE i,
         col    TYPE i,
         value  TYPE string,
       END OF ty_xl_raw.

"=== 엑셀 구조(템플릿) : 원시/대상통화, 환율 ===
TYPES: BEGIN OF ty_xl_rate,
         fcurr   TYPE c LENGTH 3,   "원시통화(From Currency)
         tcurr   TYPE c LENGTH 3,   "대상통화(To Currency)
         ukurs   TYPE p LENGTH 8 DECIMALS 5, "환율
       END OF ty_xl_rate.

"=== ALV 출력/저장 구조: 환율유형, 효력시작일 추가 ===
TYPES: BEGIN OF ty_rate,
         kurst   TYPE c LENGTH 1,         "환율유형 (M 고정)
         gdatu   TYPE dats,               "효력시작(조회조건의 처리일자)
         fcurr   TYPE c LENGTH 3,
         tcurr   TYPE c LENGTH 3,
         ukurs   TYPE p LENGTH 8 DECIMALS 5,
         changed TYPE abap_bool,          "편집 여부 표시
        ffact TYPE p LENGTH 9 DECIMALS 0,
         tfact TYPE p LENGTH 9 DECIMALS 0,
         crname LIKE ZTCURR19-crname,
         crdate LIKE ZTCURR19-crdate,
       END OF ty_rate.

DATA: gt_xl_raw   TYPE STANDARD TABLE OF ty_xl_raw,
      gs_xl_rate  TYPE TY_rate,
      gt_xl_rate  TYPE STANDARD TABLE OF ty_rate,
      gt_rate     TYPE STANDARD TABLE OF ty_rate,
      gs_rate     TYPE ty_rate.

"=== ALV 컨테이너/그리드 ===
DATA: go_dock     TYPE REF TO cl_gui_docking_container,
      go_grid     TYPE REF TO cl_gui_alv_grid.

"필드카탈로그/레이아웃
DATA: gt_fcat     TYPE lvc_t_fcat,
      gs_fcat     TYPE lvc_s_fcat,
      gs_layout   TYPE lvc_s_layo.

"데이터 변경 이벤트 캐치
DATA: gs_stbl     TYPE lvc_s_stbl.

"STATUS용 OK_CODE
DATA: ok_code     TYPE syucomm,
      gv_save_ok  TYPE syucomm.

"기타 상수
CONSTANTS: c_kurst  TYPE c VALUE 'M',           "M 고정
           c_fun_sav TYPE syucomm VALUE 'ZSV',  "ALV Toolbar 저장
           c_fun_bak TYPE syucomm VALUE 'ZBK'.  "ALV Toolbar 뒤로


DATA: t_raw_excel TYPE STANDARD TABLE OF alsmex_tabline,
      s_raw_excel TYPE alsmex_tabline.

DATA : gv_path TYPE string,
       gv_fullpath TYPE string.
DATA : gv_dest TYPE rlgrap-filename VALUE 'C:\'.
