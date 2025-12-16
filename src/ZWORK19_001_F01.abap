*&---------------------------------------------------------------------*
*&  Include           ZWORK19_001_F01
*&---------------------------------------------------------------------*
FORM init_defaults.
  "필요시 추가 초기화
ENDFORM.

*& 화면 동적 제어 (환율유형 고정 보이되 입력불가 옵션도 가능)
FORM set_screen.
  LOOP AT SCREEN.
    IF screen-name = 'P_KURST'.
      screen-input = 0.   "변경 불가
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDFORM.


FORM download_template.

  CONSTANTS: c_objid TYPE wwwdata-objid VALUE 'ZFX_TEMPLATE'. " SMW0 OBJID

  DATA: lv_rc       TYPE sy-subrc,
        ls_key      TYPE wwwdatatab,        " SMW0 키 구조

        lv_defname  TYPE string,
        lv_filename TYPE string,
        lv_path     TYPE string,
        lv_fullpath TYPE string,            " FILE_SAVE_DIALOG 결과 (string)
        lv_dest     TYPE rlgrap-filename.   " ★ DOWNLOAD_WEB_OBJECT 용

  " 기본 파일명: ZFX_TEMPLATE_YYYYMMDD.xlsx
  CONCATENATE 'ZFX_TEMPLATE_' sy-datum '.xlsx' INTO lv_defname.

  " 1) 저장 경로 선택 (친구 코드 스타일)
  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      window_title      = '엑셀 템플릿 저장'
      default_extension = 'XLSX'
      default_file_name = lv_defname
    CHANGING
      filename          = lv_filename
      path              = lv_path
      fullpath          = lv_fullpath
    EXCEPTIONS
      OTHERS            = 1.

  IF sy-subrc <> 0 OR lv_fullpath IS INITIAL.
    MESSAGE '파일 저장이 취소되었습니다.' TYPE 'I'.
    RETURN.
  ENDIF.

  " 확장자 보정 (사용자 확장자 안 넣었을 때 대비)
  IF lv_fullpath CP '*.xlsx'.
  ELSE.
    CONCATENATE lv_fullpath '.xlsx' INTO lv_fullpath.
  ENDIF.

  " ★ DESTINATION은 rlgrap-filename 타입이어야 함
  lv_dest = lv_fullpath.

  " 2) SMW0에서 오브젝트 키 읽기
  CLEAR ls_key.

  SELECT SINGLE *
    FROM wwwdata
    INTO CORRESPONDING FIELDS OF ls_key
    WHERE relid = 'MI'             " Binary storage
      AND objid = c_objid.         " ZFX_TEMPLATE

  IF sy-subrc <> 0.
    MESSAGE 'SMW0에서 템플릿 오브젝트를 찾을 수 없습니다.' TYPE 'E'.
    RETURN.
  ENDIF.

  " 3) SAP 표준 함수로 그대로 다운로드 (엑셀 안 깨지는 방식)
  CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
    EXPORTING
      key         = ls_key
      destination = lv_dest      " ★ string 말고 rlgrap-filename 변수
    IMPORTING
      rc          = lv_rc.

  IF lv_rc = 0.
    MESSAGE |엑셀 템플릿을 저장했습니다: { lv_fullpath }| TYPE 'S'.
  ELSE.
    MESSAGE '템플릿 다운로드 중 오류가 발생했습니다.' TYPE 'E'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  READ_EXCEL_TO_ITAB    "XLSX 전용 + 7열 매핑 → gt_rate
*&---------------------------------------------------------------------*
FORM read_excel_to_itab.

  DATA: lv_file_str TYPE string,
        lv_file     TYPE rlgrap-filename,
        lv_upper    TYPE string,
        lv_len      TYPE i,
        lv_pos      TYPE i,
        lv_ext      TYPE string,
        lv_exist    TYPE abap_bool,
        lt_excel    TYPE STANDARD TABLE OF alsmex_tabline,
        ls_excel    TYPE alsmex_tabline,
        lv_currrow  TYPE i VALUE 0,
        lv_num      TYPE string,
        lv_tmp      TYPE string,
        lv_date     TYPE dats.

  CLEAR: gt_rate, gs_rate.

  lv_file_str = p_file.
  lv_file = lv_file_str.
  SHIFT lv_file_str RIGHT DELETING TRAILING SPACE.
  SHIFT lv_file_str LEFT  DELETING LEADING SPACE.
  REPLACE ALL OCCURRENCES OF '"' IN lv_file_str WITH ''.

  "--- 파일 존재 여부(STRING으로 체크)
  lv_exist = abap_false.
  cl_gui_frontend_services=>file_exist(
    EXPORTING  file   = lv_file_str
    RECEIVING  result = lv_exist
    EXCEPTIONS OTHERS = 1 ).
  IF lv_exist = abap_false.
    MESSAGE '지정한 파일이 존재하지 않습니다. 경로를 확인하세요.' TYPE 'E'.
    RETURN.
  ENDIF.

  "--- XLSX 읽기: 1행=헤더, 2행부터, 1~7열 전체
  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename    = lv_file
      i_begin_col = 2 "열
      i_begin_row = 2 "행
      i_end_col   = 8
      i_end_row   = 10
    TABLES
      intern      = lt_excel
    EXCEPTIONS
      INCONSISTENT_PARAMETERS       = 1
      upload_ole  = 2
      OTHERS      = 3.
  IF sy-subrc <> 0 OR lt_excel IS INITIAL.
    MESSAGE '엑셀을 읽지 못했습니다. (Excel 설치/권한/SAP GUI 실행 확인)' TYPE 'E'.
    RETURN.
  ENDIF.

  "=== ALSM 결과를 행 단위로 ty_rate(=gs_rate)에 매핑 ===
  CLEAR gs_rate.
  lv_currrow = 0.

  LOOP AT lt_excel INTO ls_excel.
    CASE ls_excel-col.
      IF ls_excel-row = 1.
    CONTINUE.
  ENDIF.


      WHEN 1. gs_rate-kurst = ls_excel-value.
      WHEN 2. gs_rate-fcurr = ls_excel-value.
      WHEN 3. gs_rate-tcurr = ls_excel-value.
      WHEN 4. gs_rate-gdatu = ls_excel-value.
      WHEN 5. gs_rate-ukurs = ls_excel-value.
      WHEN 6. gs_rate-ffact = ls_excel-value.
      WHEN 7. gs_rate-tfact = ls_excel-value.
    ENDCASE.

    AT END OF row.
      gs_rate-crname = sy-uname.
      gs_rate-crdate = sy-datum.
    APPEND gs_rate TO gt_rate.
    CLEAR gs_rate.
   ENDAT.
  ENDLOOP.

ENDFORM.



*& ALV 필드카탈로그
FORM build_fieldcat.
  CLEAR : gs_fcat, gt_fcat.
  gs_fcat-col_pos = 1.
  gs_fcat-coltext = '환율유형'.
  gs_fcat-fieldname = 'KURST'.
  APPEND gs_fcat TO gt_fcat.

 CLEAR : gs_fcat.
 gs_fcat-col_pos = 2.
 gs_fcat-coltext = '소스통화'.
 gs_fcat-fieldname = 'FCURR'.
 APPEND gs_fcat TO gt_fcat.

 CLEAR : gs_fcat.
 gs_fcat-col_pos = 3.
 gs_fcat-coltext = '대상통화'.
 gs_fcat-fieldname = 'TCURR'.
  APPEND gs_fcat TO gt_fcat.

 CLEAR : gs_fcat.
 gs_fcat-col_pos = 4.
 gs_fcat-coltext = '효력시작'.
 gs_fcat-fieldname = 'GDATU'.
 APPEND gs_fcat TO gt_fcat.

 CLEAR : gs_fcat.
 gs_fcat-col_pos = 5.
 gs_fcat-coltext = '환율'.
 gs_fcat-fieldname = 'UKURS'.
 gs_fcat-edit = 'X'.
 gs_fcat-decimals = 5.
 APPEND gs_fcat TO gt_fcat.

 CLEAR : gs_fcat.
 gs_fcat-col_pos = 6.
 gs_fcat-coltext = '원시통화단위비율'.
 gs_fcat-fieldname = 'FFACT'.
 APPEND gs_fcat TO gt_fcat.

 CLEAR : gs_fcat.
 gs_fcat-col_pos = 7.
 gs_fcat-coltext = '대상통화단위비율'.
 gs_fcat-fieldname = 'TFACT'.
 APPEND gs_fcat TO gt_fcat.

 CLEAR : gs_fcat.
 gs_fcat-col_pos = 8.
 gs_fcat-coltext = '입력자'.
 gs_fcat-fieldname = 'CRNAME'.
 APPEND gs_fcat TO gt_fcat.

 CLEAR : gs_fcat.
 gs_fcat-col_pos = 9.
 gs_fcat-coltext = '입력일'.
 gs_fcat-fieldname = 'CRDATE'.
 APPEND gs_fcat TO gt_fcat.
ENDFORM.

FORM add_fcat USING iv_field iv_text iv_edit iv_key iv_noout iv_ref_table iv_ref_field iv_hotspot iv_curr iv_qfield.
  CLEAR gs_fcat.
  gs_fcat-fieldname  = iv_field.
  gs_fcat-coltext    = iv_text.
  IF iv_edit = 'X'. gs_fcat-edit = abap_true. ENDIF.
  IF iv_key  = 'X'. gs_fcat-key  = abap_true. ENDIF.
  IF iv_noout = 'X'. gs_fcat-no_out = abap_true. ENDIF.
  IF iv_curr = 'X'. gs_fcat-outputlen = 15. ENDIF.
  APPEND gs_fcat TO gt_fcat.
ENDFORM.

*& 데이터 저장 (팝업 확인 후)
FORM save_to_db.
  DATA: lv_answer TYPE c LENGTH 1.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar       = '환율등록'
      text_question  = '환율정보를 등록하시겠습니까?'
      text_button_1  = 'Yes'
      text_button_2  = 'No'
      default_button = '2'
    IMPORTING
      answer         = lv_answer.

  IF lv_answer <> '1'.
    MESSAGE '취소되었습니다.' TYPE 'I'.
    RETURN.
  ENDIF.

  LOOP AT gt_rate INTO gs_rate.
    PERFORM upsert_ztcurr19 USING gs_rate.
  ENDLOOP.

  MESSAGE 'ZTCURR19 저장 완료' TYPE 'I'.
ENDFORM.

FORM upsert_ztcurr19 USING is_rate TYPE ty_rate.
  DATA: ls_db TYPE ztcurr19.

  " 매핑
  ls_db-mandt = sy-mandt.
  ls_db-kurst = is_rate-kurst.
  ls_db-fcurr = is_rate-fcurr.
  ls_db-tcurr = is_rate-tcurr.
  ls_db-gdatu = is_rate-gdatu.
  ls_db-ukurs = is_rate-ukurs.
  ls_db-ffact = is_rate-ffact.
  ls_db-tfact = is_rate-tfact.

  "------------------------------------------
  " FCURR 기준으로만 UPDATE, 없으면 INSERT
  "------------------------------------------
  UPDATE ztcurr19
    SET ukurs = ls_db-ukurs
        ffact = ls_db-ffact
        tfact = ls_db-tfact
        kurst = ls_db-kurst      "필요하면 같이 맞춰줌
        tcurr = ls_db-tcurr
        gdatu = ls_db-gdatu
        crname = SY-UNAME
        crdate = SY-DATUM
  WHERE fcurr = ls_db-fcurr.

  IF sy-subrc <> 0.
    "해당 FCURR가 하나도 없으면 새로 추가
    INSERT ztcurr19 FROM ls_db.
  ENDIF.
ENDFORM.


*& ALV 데이터 변경 반영 (즉시 UI 반영)
FORM handle_data_changed USING ir_changed TYPE REF TO cl_alv_changed_data_protocol.
  DATA: lt_mod TYPE lvc_t_modi,
        ls_mod TYPE lvc_s_modi,
        lv_val TYPE p LENGTH 8 DECIMALS 5.

  "메서드 호출 대신 속성 사용
  lt_mod = ir_changed->mt_mod_cells.

  LOOP AT lt_mod INTO ls_mod.
    IF ls_mod-fieldname = 'UKURS'.
      READ TABLE gt_rate ASSIGNING FIELD-SYMBOL(<r>) INDEX ls_mod-row_id.
      IF sy-subrc = 0.
        lv_val = ls_mod-value.
        <r>-ukurs   = lv_val.
        <r>-changed = abap_true.
      ENDIF.
    ENDIF.
  ENDLOOP.

  gs_stbl-row = 'X'. gs_stbl-col = 'X'.
  IF go_grid IS BOUND.
    CALL METHOD go_grid->refresh_table_display
      EXPORTING is_stable = gs_stbl.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  F4_FILE_OPEN
*&---------------------------------------------------------------------*
FORM f4_file_open CHANGING p_file TYPE string.
  DATA lv_fullpath TYPE string.

  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      mode     = 'O'
      mask     = 'Excel (*.xlsx)|*.xlsx|All files (*.*)|*.*'
    IMPORTING
      filename = lv_fullpath
    EXCEPTIONS
      OTHERS   = 1.

  IF sy-subrc = 0 AND lv_fullpath IS NOT INITIAL.
    p_file = lv_fullpath.
  ENDIF.
ENDFORM.
