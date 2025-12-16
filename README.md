# ZWORK19_001 – 환율 엑셀 업로드 및 관리 프로그램

## 📘 프로그램 개요
본 프로그램은 SAP ABAP 기반의 환율 관리 프로그램으로,  
엑셀(xlsx) 파일을 업로드하여 환율 데이터를 읽고 ALV Grid 화면에서
확인 및 수정 후 DB 테이블에 저장하는 기능을 제공한다.

SMW0에 등록된 엑셀 템플릿을 다운로드하여 표준 형식으로 데이터를 입력할 수 있으며,  
업로드된 데이터는 실시간으로 ALV에 반영된다.

## 🎯 개발 목적
- 엑셀 업로드 기능 구현 (XLSX)
- ALV Grid 기반 데이터 관리
- 사용자 입력 기반 환율 데이터 등록/수정
- Custom Table(ZTCURR19) 연계 실습

## 🛠 개발 환경
- SAP NetWeaver AS ABAP
- ABAP Report
- ALV Grid (CL_GUI_ALV_GRID)
- Excel Upload (ALSM_EXCEL_TO_INTERNAL_TABLE)
- Frontend Service (CL_GUI_FRONTEND_SERVICES)

## 📂 프로그램 구조
```text
ZWORK19_001
├─ ZWORK19_001_TOP   # 전역 타입, 상수, 데이터 선언
├─ ZWORK19_001_SCR   # Selection Screen
├─ ZWORK19_001_F01   # FORM 로직
├─ ZWORK19_001_PBO   # 화면 PBO
└─ ZWORK19_001_PAI   # 화면 PAI
