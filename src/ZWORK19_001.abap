*&---------------------------------------------------------------------*
*& Report ZWORK19_001
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZWORK19_001 MESSAGE-ID ZMED19.

INCLUDE ZWORK19_001_TOP. "전역 상수/타입/데이터
INCLUDE ZWORK19_001_SCR. "조회조건(Selection Screen)
INCLUDE ZWORK19_001_F01. "FORM 정의
INCLUDE ZWORK19_001_PBO. "화면 PBO
INCLUDE ZWORK19_001_PAI. "화면 PAI

INITIALIZATION. "기본값 세팅
  PERFORM INIT_DEFAULTS.

AT SELECTION-SCREEN OUTPUT. "화면 동적 제어 (환율유형 = M 고정)
  PERFORM SET_SCREEN.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.              "Application Toolbar: 템플릿 다운로드
      PERFORM download_template.
      CLEAR sscrfields-ucomm.

    WHEN 'ONLI'.              "F8 실행
      IF p_file IS INITIAL.
        MESSAGE e000(zmed19) WITH '엑셀 파일을 선택하세요.'.
      ENDIF.
  ENDCASE.


"--- 실행부(F8에서만 도달)
START-OF-SELECTION.
  PERFORM read_excel_to_itab.
  PERFORM build_fieldcat.
  CALL SCREEN 100.
