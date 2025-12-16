*&---------------------------------------------------------------------*
*& Include  ZWORK19_001_PAI
*&---------------------------------------------------------------------*

MODULE user_command_0100 INPUT.
  gv_save_ok = ok_code.
  CLEAR ok_code.

  CASE gv_save_ok.
    WHEN 'SAVE'.                          " <-- Application Toolbar: 환율등록
      PERFORM save_to_db.

    WHEN 'BACK' OR 'CANCEL' OR 'EXIT'.
      LEAVE TO SCREEN 0.

    WHEN OTHERS.
      " ALV 툴바 커맨드는 on_user_command에서 처리 (필요 시)
  ENDCASE.
ENDMODULE.
