# 작업 로그 — 수출입원가관리 대시보드

## 마지막 작업: 2026-05-09

---

## 진행 상황 요약

### 완료된 기능
- Supabase 연동 (인증, DB, Storage) + RLS 정책 설정
- 제품 관리 (이미지 업로드 → Supabase Storage)
- 발주 등록 — 상품명 검색 콤보박스 (IME 지원)
- 차수 자유입력 필드 ("16차", "컨7차", "1/3" 등 복합 패턴 대응)
- 분할 선적 기능 (일부 수량 → "보관중" 상태로 자동 분리)
- 기존 엑셀 데이터 가져오기 (M/D 날짜 → 연도 자동 추정)
- Shift+Click 범위 선택 + 벌크 삭제
- **원가 계산 로직 수정 (최신)**
  - 물건값 = 위안단가 × 환율 × **1.0396** (카드수수료)
  - 관부가세(관세+부가세)만 물건값 기준으로 안분
  - 통관수수료·내륙운송비·기타항목 → 물류비(CBM 기준 안분)

### 파일 구조
- `cost_dashboard/index.html` — 단일 파일 전체 (서버 불필요)
- 배포: https://blackgosu100-png.github.io/import-cost-management-dashboard/
- GitHub: https://github.com/blackgosu100-png/import-cost-management-dashboard.git

### Supabase 테이블
- `products` — 제품 목록 (이미지는 Storage `product-images` 버킷)
- `orders` — 발주 목록
- `ship_groups` — 선적 묶음 + 원가 정보
- `activity_log` — 활동 로그

---

## 다음에 할 일 (우선순위 순)

1. **원가 계산 검증** — 실제 데이터로 계산 결과가 맞는지 확인
2. **Shift+Click 재확인** — 이전 세션에서 수정했으나 실제 동작 미확인
3. **보관중 → 선적 처리 흐름** — 보관중 행을 나중에 선적 완료로 전환하는 UI
4. **원가 카드 기타항목 표시** — 저장된 기타 항목들이 보드 카드에 표시 안 됨

---

## 에이전트 재시작용 프롬프트

```
수출입원가관리 대시보드 작업 이어서 해줘.

파일: c:\Ai_jung\cost_dashboard\index.html
배포: https://blackgosu100-png.github.io/import-cost-management-dashboard/
GitHub: https://github.com/blackgosu100-png/import-cost-management-dashboard.git

기술스택: 순수 HTML/CSS/JS 단일파일, Supabase(DB+Storage+Auth), SheetJS

마지막 작업: 원가 계산 로직 수정
- 물건값 = 위안단가 × 환율 × 1.0396 (카드수수료)
- 관세+부가세만 물건값 기준 안분, 나머지는 물류비(CBM 기준)

다음 작업: [여기에 하고 싶은 작업 적기]
```
