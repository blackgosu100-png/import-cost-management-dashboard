-- 제품 DB 확장 (상품db2.xlsx 반영) — Supabase SQL Editor에서 1회 실행
-- 실행 방법: supabase.com 로그인 → 프로젝트 → SQL Editor → 붙여넣기 → Run
alter table products
  add column if not exists brand text,          -- 브랜드 (친절한마이쮸/주방고수/제로브)
  add column if not exists barcode text,        -- 바코드
  add column if not exists box_size text,       -- 박스사이즈 (예: 15*11*4.2)
  add column if not exists dim_sum numeric,     -- 3면합(cm)
  add column if not exists parcel_fee numeric,  -- (인터지스)택배+작업
  add column if not exists parcel_fee2 numeric, -- (심비)택배비
  add column if not exists cost_krw numeric,    -- 원가(원화)
  add column if not exists sale_price numeric;  -- 사이트판매가
