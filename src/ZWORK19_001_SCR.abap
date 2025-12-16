*&---------------------------------------------------------------------*
*&  Include  ZWORK19_001_SCR
*&---------------------------------------------------------------------*

" 검색조건 블록 (이제 제목은 다른 걸로)
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS: p_date  TYPE sy-datum OBLIGATORY DEFAULT sy-datum. "처리일자(효력시작)
PARAMETERS: p_file  TYPE string LOWER CASE.
PARAMETERS : p_kurst TYPE kurst DEFAULT 'M' MODIF ID m1 VISIBLE LENGTH 1.
SELECTION-SCREEN END OF BLOCK b1.

"=== Application Toolbar용 Function Key 선언 ===
SELECTION-SCREEN FUNCTION KEY 1.

"F4 - 파일 선택
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM f4_file_open CHANGING p_file.

INITIALIZATION.
  sscrfields-functxt_01 = '템플릿 다운로드'.  "⬅️ Application Toolbar 버튼 텍스트
