--
-- PostgreSQL database dump
--

\restrict 7SknGSI7L4d1VLXhrxI9nABvk6TVkjH368IosjfoH3ImWW3wtbxv1p2R6FLwjb2

-- Dumped from database version 17.10
-- Dumped by pg_dump version 17.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_mst (
    act_idx integer NOT NULL,
    store_idx integer NOT NULL,
    act_type character varying(20) NOT NULL,
    act_dt date,
    create_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    act_notes text,
    sv_id character varying(50),
    appr_status character varying(20) DEFAULT 'DRAFT'::character varying,
    appr_dt timestamp with time zone,
    suggestions text,
    sv_notes text,
    chk_yn character(1) DEFAULT 'N'::bpchar,
    memo_txt text,
    appr_id text,
    appr_notes text
);


--
-- Name: TABLE active_mst; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.active_mst IS '활동관리 마스터 테이블';


--
-- Name: COLUMN active_mst.act_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.act_idx IS '활동 고유 번호(PK)';


--
-- Name: COLUMN active_mst.store_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.store_idx IS '가맹점 IDX (FK 연관용)';


--
-- Name: COLUMN active_mst.act_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.act_type IS '활동구분 (상담/방문/점검/전화)';


--
-- Name: COLUMN active_mst.act_dt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.act_dt IS '활동 실제 수행 일자';


--
-- Name: COLUMN active_mst.create_dt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.create_dt IS '시스템 등록 일시';


--
-- Name: COLUMN active_mst.act_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.act_notes IS '주요상담내용';


--
-- Name: COLUMN active_mst.sv_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.sv_id IS '담당 슈퍼바이저 ID';


--
-- Name: COLUMN active_mst.appr_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.appr_status IS '결재상태 (APPROVED:결재완료, PENDING:결재대기, DRAFT:임시저장)';


--
-- Name: COLUMN active_mst.appr_dt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.appr_dt IS '최종 결재 완료 일시';


--
-- Name: COLUMN active_mst.suggestions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.suggestions IS '가맹점 건의 사항';


--
-- Name: COLUMN active_mst.sv_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.sv_notes IS '담당 슈퍼바이저 의견 및 노트';


--
-- Name: COLUMN active_mst.chk_yn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.chk_yn IS '체크리스트 작성 여부 (Y/N)';


--
-- Name: COLUMN active_mst.memo_txt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.memo_txt IS '특이사항';


--
-- Name: COLUMN active_mst.appr_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.appr_id IS '결재자';


--
-- Name: COLUMN active_mst.appr_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.active_mst.appr_notes IS '지시사항(결재특이사항)';


--
-- Name: active_mst_act_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_mst_act_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_mst_act_idx_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_mst_act_idx_seq OWNED BY public.active_mst.act_idx;


--
-- Name: chk_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chk_mst (
    chk_idx integer NOT NULL,
    chk_type character varying(50) NOT NULL,
    chk_content text NOT NULL,
    base_score integer DEFAULT 0,
    use_yn character(1) DEFAULT 'Y'::bpchar,
    display_order integer,
    create_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    brand_cd character varying(20)
);


--
-- Name: TABLE chk_mst; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.chk_mst IS '체크리스트 항목 마스터 테이블';


--
-- Name: COLUMN chk_mst.chk_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chk_mst.chk_idx IS '체크리스트 IDX';


--
-- Name: COLUMN chk_mst.chk_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chk_mst.chk_type IS '항목 구분 (외관 시설/ 홀 시설/ 주방 시설 등 grp_cd 50)';


--
-- Name: COLUMN chk_mst.chk_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chk_mst.chk_content IS '상세 체크항목 내용';


--
-- Name: COLUMN chk_mst.base_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chk_mst.base_score IS '항목별 기본 배점';


--
-- Name: COLUMN chk_mst.brand_cd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chk_mst.brand_cd IS '브랜드 코드';


--
-- Name: chk_mst_chk_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chk_mst_chk_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chk_mst_chk_idx_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chk_mst_chk_idx_seq OWNED BY public.chk_mst.chk_idx;


--
-- Name: chk_result_dtl; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chk_result_dtl (
    res_idx integer NOT NULL,
    act_idx integer NOT NULL,
    chk_idx integer NOT NULL,
    answer_val character varying(20),
    answer_score integer DEFAULT 0
);


--
-- Name: TABLE chk_result_dtl; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.chk_result_dtl IS '활동별 체크리스트 상세 결과 테이블';


--
-- Name: COLUMN chk_result_dtl.res_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chk_result_dtl.res_idx IS '결과 상세 PK';


--
-- Name: COLUMN chk_result_dtl.act_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chk_result_dtl.act_idx IS '활동관리 테이블 연관 키';


--
-- Name: COLUMN chk_result_dtl.chk_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chk_result_dtl.chk_idx IS '체크리스트 문항 마스터 연관 키';


--
-- Name: COLUMN chk_result_dtl.answer_val; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chk_result_dtl.answer_val IS '체크 결과값 (Y/N 등)';


--
-- Name: COLUMN chk_result_dtl.answer_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chk_result_dtl.answer_score IS '해당 항목에서 획득한 점수';


--
-- Name: chk_result_dtl_res_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chk_result_dtl_res_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chk_result_dtl_res_idx_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chk_result_dtl_res_idx_seq OWNED BY public.chk_result_dtl.res_idx;


--
-- Name: code_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.code_mst (
    grp_cd character varying(20) NOT NULL,
    code_cd character varying(20) NOT NULL,
    code_nm character varying(100) NOT NULL,
    sort_order integer,
    use_yn character(1) DEFAULT 'Y'::bpchar
);


--
-- Name: TABLE code_mst; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.code_mst IS '코드 마스터';


--
-- Name: COLUMN code_mst.grp_cd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.code_mst.grp_cd IS '그룹코드';


--
-- Name: COLUMN code_mst.code_cd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.code_mst.code_cd IS '코드';


--
-- Name: COLUMN code_mst.code_nm; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.code_mst.code_nm IS '코드이름';


--
-- Name: COLUMN code_mst.use_yn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.code_mst.use_yn IS '사용여부(Y / N)';


--
-- Name: dept_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dept_mst (
    dept_idx integer NOT NULL,
    dept_nm character varying(255) NOT NULL,
    upper_dept_idx integer,
    dept_level integer,
    sort_order integer
);


--
-- Name: TABLE dept_mst; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.dept_mst IS '조직/부서 정보 마스터';


--
-- Name: COLUMN dept_mst.upper_dept_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dept_mst.upper_dept_idx IS '상위 부서 PK (자기참조)';


--
-- Name: dept_mst_dept_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dept_mst_dept_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dept_mst_dept_idx_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dept_mst_dept_idx_seq OWNED BY public.dept_mst.dept_idx;


--
-- Name: menu_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_mst (
    menu_cd character varying(20) NOT NULL,
    menu_nm character varying(100) NOT NULL,
    parent_menu_cd character varying(20),
    route_path character varying(200),
    menu_type character(1) DEFAULT 'L'::bpchar NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    use_yn character(1) DEFAULT 'Y'::bpchar NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_menu_mst_type CHECK ((menu_type = ANY (ARRAY['G'::bpchar, 'L'::bpchar]))),
    CONSTRAINT ck_menu_mst_use_yn CHECK ((use_yn = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);


--
-- Name: TABLE menu_mst; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.menu_mst IS 'ERP 메뉴 마스터';


--
-- Name: COLUMN menu_mst.menu_cd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.menu_mst.menu_cd IS '메뉴 코드 (예: dsh001, str001)';


--
-- Name: COLUMN menu_mst.route_path; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.menu_mst.route_path IS 'GoRouter 경로 (그룹은 NULL 가능)';


--
-- Name: COLUMN menu_mst.menu_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.menu_mst.menu_type IS 'G=그룹(폴더), L=화면(리프)';


--
-- Name: notif_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notif_mst (
    notif_idx integer NOT NULL,
    user_id character varying(50) NOT NULL,
    msg_txt character varying(500) NOT NULL,
    notif_typ character varying(40),
    read_yn character(1) DEFAULT 'N'::bpchar NOT NULL,
    create_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    appr_yn character varying(2) DEFAULT 'N'::character varying NOT NULL,
    act_idx integer
);


--
-- Name: COLUMN notif_mst.appr_yn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notif_mst.appr_yn IS '결재여부';


--
-- Name: COLUMN notif_mst.act_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notif_mst.act_idx IS '활동 idx';


--
-- Name: notif_mst_notif_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notif_mst_notif_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notif_mst_notif_idx_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notif_mst_notif_idx_seq OWNED BY public.notif_mst.notif_idx;


--
-- Name: partner_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partner_mst (
    partner_idx integer NOT NULL,
    partner_nm character varying(50) NOT NULL,
    partner_status character varying(20),
    partner_tel character varying(20) NOT NULL,
    partner_email character varying(100),
    gender character(1),
    create_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    partner_birth date,
    p_zip_cd character varying(10),
    p_address character varying(255),
    p_address_detail character varying(255),
    p_region character varying(50)
);


--
-- Name: TABLE partner_mst; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.partner_mst IS '예비창업자 마스터 정보';


--
-- Name: COLUMN partner_mst.partner_nm; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.partner_mst.partner_nm IS '예비창업자 성함';


--
-- Name: COLUMN partner_mst.partner_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.partner_mst.partner_status IS '상태 (예비창업자 / 가맹점사업자)';


--
-- Name: COLUMN partner_mst.partner_tel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.partner_mst.partner_tel IS '휴대전화번호';


--
-- Name: COLUMN partner_mst.partner_email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.partner_mst.partner_email IS '이메일 주소';


--
-- Name: COLUMN partner_mst.gender; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.partner_mst.gender IS '성별';


--
-- Name: COLUMN partner_mst.partner_birth; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.partner_mst.partner_birth IS '생년월일';


--
-- Name: COLUMN partner_mst.p_zip_cd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.partner_mst.p_zip_cd IS '우편번호';


--
-- Name: COLUMN partner_mst.p_address; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.partner_mst.p_address IS '주소';


--
-- Name: COLUMN partner_mst.p_address_detail; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.partner_mst.p_address_detail IS '상세주소';


--
-- Name: COLUMN partner_mst.p_region; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.partner_mst.p_region IS '지역';


--
-- Name: partner_mst_partner_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.partner_mst_partner_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: partner_mst_partner_idx_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.partner_mst_partner_idx_seq OWNED BY public.partner_mst.partner_idx;


--
-- Name: property_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.property_mst (
    prop_idx integer NOT NULL,
    prop_nm character varying(100) NOT NULL,
    zip_cd character varying(10),
    address character varying(255),
    address_detail character varying(255),
    region character varying(50),
    prop_status character varying(20),
    prop_type character varying(20),
    floor integer,
    cont_area numeric(12,2),
    real_area numeric(12,2),
    rent_deposit bigint DEFAULT 0,
    monthly_rent bigint DEFAULT 0,
    premium_fee bigint DEFAULT 0,
    prop_notes text,
    create_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    survey_dt date,
    latitude numeric(10,7),
    longitude numeric(10,7),
    surveyor character varying(20),
    maint_fee bigint DEFAULT 0
);


--
-- Name: TABLE property_mst; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.property_mst IS '물건(입지/부동산) 정보 마스터 테이블';


--
-- Name: COLUMN property_mst.prop_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.prop_idx IS '물건 고유 번호(PK)';


--
-- Name: COLUMN property_mst.prop_nm; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.prop_nm IS '물건명';


--
-- Name: COLUMN property_mst.prop_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.prop_status IS '구분 (CONTRACTED, PENDING, UNSUITABLE)';


--
-- Name: COLUMN property_mst.prop_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.prop_type IS '종류 (LEASE, OWNED)';


--
-- Name: COLUMN property_mst.cont_area; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.cont_area IS '계약 면적';


--
-- Name: COLUMN property_mst.real_area; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.real_area IS '전용(실) 면적';


--
-- Name: COLUMN property_mst.rent_deposit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.rent_deposit IS '임대 보증금';


--
-- Name: COLUMN property_mst.monthly_rent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.monthly_rent IS '월 임차료';


--
-- Name: COLUMN property_mst.premium_fee; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.premium_fee IS '권리금';


--
-- Name: COLUMN property_mst.prop_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.prop_notes IS '물건별 특이사항';


--
-- Name: COLUMN property_mst.survey_dt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.survey_dt IS '물건 조사일자';


--
-- Name: COLUMN property_mst.latitude; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.latitude IS '위도 (주소 입력 시 자동 추출 기능 대상)';


--
-- Name: COLUMN property_mst.longitude; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.longitude IS '경도 (주소 입력 시 자동 추출 기능 대상)';


--
-- Name: COLUMN property_mst.surveyor; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.surveyor IS '조사자ID';


--
-- Name: COLUMN property_mst.maint_fee; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.property_mst.maint_fee IS '월 평균 관리비';


--
-- Name: property_mst_prop_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.property_mst_prop_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: property_mst_prop_idx_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.property_mst_prop_idx_seq OWNED BY public.property_mst.prop_idx;


--
-- Name: sale_zone_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_zone_mst (
    zone_idx integer NOT NULL,
    zone_nm character varying(100) NOT NULL,
    brand_cd character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE sale_zone_mst; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sale_zone_mst IS '영업지역 마스터 정보';


--
-- Name: COLUMN sale_zone_mst.zone_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sale_zone_mst.zone_idx IS '영업지역 IDX';


--
-- Name: COLUMN sale_zone_mst.zone_nm; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sale_zone_mst.zone_nm IS '영업지역명';


--
-- Name: sale_zone_mst_zone_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sale_zone_mst_zone_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sale_zone_mst_zone_idx_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sale_zone_mst_zone_idx_seq OWNED BY public.sale_zone_mst.zone_idx;


--
-- Name: store_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_history (
    his_idx integer NOT NULL,
    store_idx integer NOT NULL,
    chg_type character varying(10) NOT NULL,
    chg_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    chg_user_id character varying(50),
    store_nm character varying(100),
    chg_content jsonb
);


--
-- Name: TABLE store_history; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.store_history IS '가맹점 정보 변경 이력 상세 테이블';


--
-- Name: COLUMN store_history.his_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_history.his_idx IS '이력 고유 번호(PK)';


--
-- Name: COLUMN store_history.store_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_history.store_idx IS '대상 가맹점 IDX';


--
-- Name: COLUMN store_history.chg_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_history.chg_type IS '변경 작업 타입';


--
-- Name: COLUMN store_history.chg_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_history.chg_content IS '상세 변경 내용 (컬럼명, 변경 전/후 데이터 포함)';


--
-- Name: store_history_his_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.store_history_his_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: store_history_his_idx_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.store_history_his_idx_seq OWNED BY public.store_history.his_idx;


--
-- Name: store_mst_store_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.store_mst_store_idx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: store_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_mst (
    store_idx integer DEFAULT nextval('public.store_mst_store_idx_seq'::regclass) NOT NULL,
    store_cd character varying(20),
    store_nm character varying(100) NOT NULL,
    owner_nm character varying(50),
    region_cd character varying(10),
    store_tel character varying(20),
    address text,
    latitude numeric(10,7),
    longitude numeric(10,7),
    store_status character varying(20) DEFAULT 'new'::character varying,
    cont_end_dt date,
    auto_renewal_yn boolean DEFAULT true,
    store_type character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    adress_detail text,
    zip_cd character varying(10),
    brand_cd text,
    cont_start_dt date,
    business_number character varying(20),
    fr_fee integer DEFAULT 0,
    edu_fee integer DEFAULT 0,
    insu_deposit integer DEFAULT 0,
    cont_deposit integer DEFAULT 0,
    cont_manager character varying(50),
    edu_manager character varying(50),
    sv_id character varying(50),
    first_cont_dt date,
    cont_area numeric(10,2),
    real_area numeric(10,2),
    floor integer,
    parking_count integer,
    premium_fee integer DEFAULT 0,
    monthly_rent integer DEFAULT 0,
    rent_deposit integer DEFAULT 0,
    notes character varying(500),
    prop_idx integer,
    partner_idx integer,
    zone_idx integer
);


--
-- Name: TABLE store_mst; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.store_mst IS '가맹점 마스터 정보 테이블';


--
-- Name: COLUMN store_mst.store_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.store_idx IS '가맹점idx';


--
-- Name: COLUMN store_mst.store_cd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.store_cd IS '가맹점코드';


--
-- Name: COLUMN store_mst.store_nm; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.store_nm IS '가맹점명';


--
-- Name: COLUMN store_mst.owner_nm; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.owner_nm IS '가맹점 사업자(대표자명)';


--
-- Name: COLUMN store_mst.region_cd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.region_cd IS '영업지역코드(grp_cd = 20)';


--
-- Name: COLUMN store_mst.store_tel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.store_tel IS '가맹점 연락처';


--
-- Name: COLUMN store_mst.address; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.address IS '가맹점 주소';


--
-- Name: COLUMN store_mst.latitude; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.latitude IS '위도 (주소 입력 시 자동 추출 기능 대상)';


--
-- Name: COLUMN store_mst.longitude; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.longitude IS '경도 (주소 입력 시 자동 추출 기능 대상)';


--
-- Name: COLUMN store_mst.store_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.store_status IS '가맹 상태 (신규계약: NEW, 재계약: RENEWAL, 양수도: TRANSFER 등) grp_cd = 10';


--
-- Name: COLUMN store_mst.cont_end_dt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.cont_end_dt IS '가맹계약 만료일자';


--
-- Name: COLUMN store_mst.auto_renewal_yn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.auto_renewal_yn IS '자동갱신 여부 (TRUE/FALSE)';


--
-- Name: COLUMN store_mst.store_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.store_type IS '가맹구분 (가맹점: FR, 직영점: DI) grp_cd = 30';


--
-- Name: COLUMN store_mst.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.created_at IS '데이터 생성 일시';


--
-- Name: COLUMN store_mst.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.updated_at IS '데이터 수정 일시';


--
-- Name: COLUMN store_mst.adress_detail; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.adress_detail IS '상세주소';


--
-- Name: COLUMN store_mst.zip_cd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.zip_cd IS '우편번호';


--
-- Name: COLUMN store_mst.brand_cd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.brand_cd IS '브랜드코드(역전할머니맥주 YJ)';


--
-- Name: COLUMN store_mst.cont_start_dt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.cont_start_dt IS '가맹계약시작일자';


--
-- Name: COLUMN store_mst.business_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.business_number IS '사업자번호';


--
-- Name: COLUMN store_mst.fr_fee; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.fr_fee IS '가맹비';


--
-- Name: COLUMN store_mst.edu_fee; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.edu_fee IS '교육비';


--
-- Name: COLUMN store_mst.insu_deposit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.insu_deposit IS '보증보험금';


--
-- Name: COLUMN store_mst.cont_deposit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.cont_deposit IS '계약보증금';


--
-- Name: COLUMN store_mst.cont_manager; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.cont_manager IS '가맹담당자';


--
-- Name: COLUMN store_mst.edu_manager; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.edu_manager IS '기본교육담당자';


--
-- Name: COLUMN store_mst.sv_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.sv_id IS '담당슈퍼바이저';


--
-- Name: COLUMN store_mst.first_cont_dt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.first_cont_dt IS '최초가맹계약일자';


--
-- Name: COLUMN store_mst.cont_area; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.cont_area IS '계약면적';


--
-- Name: COLUMN store_mst.real_area; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.real_area IS '실면적';


--
-- Name: COLUMN store_mst.floor; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.floor IS '층수';


--
-- Name: COLUMN store_mst.parking_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.parking_count IS '주차가능대수';


--
-- Name: COLUMN store_mst.premium_fee; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.premium_fee IS '권리금';


--
-- Name: COLUMN store_mst.monthly_rent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.monthly_rent IS '임차료';


--
-- Name: COLUMN store_mst.rent_deposit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.rent_deposit IS '임대차보증금';


--
-- Name: COLUMN store_mst.notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.notes IS '특이사항';


--
-- Name: COLUMN store_mst.prop_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.prop_idx IS '물건Idx';


--
-- Name: COLUMN store_mst.partner_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.partner_idx IS '예비창업자idx';


--
-- Name: COLUMN store_mst.zone_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.store_mst.zone_idx IS '영업지역Idx';


--
-- Name: user_menu_auth; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_menu_auth (
    user_idx integer NOT NULL,
    menu_cd character varying(20) NOT NULL,
    can_view character(1) DEFAULT 'N'::bpchar NOT NULL,
    can_create character(1) DEFAULT 'N'::bpchar NOT NULL,
    can_update character(1) DEFAULT 'N'::bpchar NOT NULL,
    can_delete character(1) DEFAULT 'N'::bpchar NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_user_menu_auth_create CHECK ((can_create = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT ck_user_menu_auth_delete CHECK ((can_delete = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT ck_user_menu_auth_update CHECK ((can_update = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT ck_user_menu_auth_view CHECK ((can_view = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);


--
-- Name: TABLE user_menu_auth; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_menu_auth IS '사용자별 메뉴 권한';


--
-- Name: COLUMN user_menu_auth.can_view; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_menu_auth.can_view IS '메뉴 접근(사이드바·라우트)';


--
-- Name: user_mst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_mst (
    user_idx integer NOT NULL,
    user_name character varying(50) NOT NULL,
    user_id character varying(50),
    user_password character varying(255) NOT NULL,
    dept_idx integer,
    user_phone character varying(20),
    user_email character varying(100),
    sv_yn character(1),
    position_cd character varying(10),
    tag_yn character(1),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    join_dt date
);


--
-- Name: TABLE user_mst; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_mst IS '사용자 마스터 정보 테이블';


--
-- Name: COLUMN user_mst.user_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.user_idx IS '사용자 고유 번호(PK)';


--
-- Name: COLUMN user_mst.user_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.user_name IS '사용자 성명';


--
-- Name: COLUMN user_mst.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.user_id IS '로그인 아이디';


--
-- Name: COLUMN user_mst.user_password; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.user_password IS '암호화된 비밀번호';


--
-- Name: COLUMN user_mst.dept_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.dept_idx IS '부서 코드';


--
-- Name: COLUMN user_mst.user_phone; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.user_phone IS '연락처';


--
-- Name: COLUMN user_mst.user_email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.user_email IS '이메일 주소';


--
-- Name: COLUMN user_mst.sv_yn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.sv_yn IS '슈퍼바이저 권한 여부 (Y: 대상, N: 미대상)';


--
-- Name: COLUMN user_mst.position_cd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.position_cd IS '직급 코드(grp_cd = 60)';


--
-- Name: COLUMN user_mst.tag_yn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.tag_yn IS '태그사용여부';


--
-- Name: COLUMN user_mst.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.created_at IS '등록일시';


--
-- Name: COLUMN user_mst.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.updated_at IS '수정일시';


--
-- Name: COLUMN user_mst.join_dt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_mst.join_dt IS '입사년월일';


--
-- Name: user_mst_user_idx_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_mst_user_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_mst_user_idx_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_mst_user_idx_seq OWNED BY public.user_mst.user_idx;


--
-- Name: active_mst act_idx; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_mst ALTER COLUMN act_idx SET DEFAULT nextval('public.active_mst_act_idx_seq'::regclass);


--
-- Name: chk_mst chk_idx; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chk_mst ALTER COLUMN chk_idx SET DEFAULT nextval('public.chk_mst_chk_idx_seq'::regclass);


--
-- Name: chk_result_dtl res_idx; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chk_result_dtl ALTER COLUMN res_idx SET DEFAULT nextval('public.chk_result_dtl_res_idx_seq'::regclass);


--
-- Name: dept_mst dept_idx; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dept_mst ALTER COLUMN dept_idx SET DEFAULT nextval('public.dept_mst_dept_idx_seq'::regclass);


--
-- Name: notif_mst notif_idx; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notif_mst ALTER COLUMN notif_idx SET DEFAULT nextval('public.notif_mst_notif_idx_seq'::regclass);


--
-- Name: partner_mst partner_idx; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_mst ALTER COLUMN partner_idx SET DEFAULT nextval('public.partner_mst_partner_idx_seq'::regclass);


--
-- Name: property_mst prop_idx; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.property_mst ALTER COLUMN prop_idx SET DEFAULT nextval('public.property_mst_prop_idx_seq'::regclass);


--
-- Name: sale_zone_mst zone_idx; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_zone_mst ALTER COLUMN zone_idx SET DEFAULT nextval('public.sale_zone_mst_zone_idx_seq'::regclass);


--
-- Name: store_history his_idx; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store_history ALTER COLUMN his_idx SET DEFAULT nextval('public.store_history_his_idx_seq'::regclass);


--
-- Name: user_mst user_idx; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mst ALTER COLUMN user_idx SET DEFAULT nextval('public.user_mst_user_idx_seq'::regclass);


--
-- Name: active_mst active_mst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_mst
    ADD CONSTRAINT active_mst_pkey PRIMARY KEY (act_idx);


--
-- Name: chk_mst chk_mst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chk_mst
    ADD CONSTRAINT chk_mst_pkey PRIMARY KEY (chk_idx);


--
-- Name: chk_result_dtl chk_result_dtl_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chk_result_dtl
    ADD CONSTRAINT chk_result_dtl_pkey PRIMARY KEY (res_idx);


--
-- Name: code_mst code_mst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_mst
    ADD CONSTRAINT code_mst_pkey PRIMARY KEY (grp_cd, code_cd);


--
-- Name: dept_mst dept_mst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dept_mst
    ADD CONSTRAINT dept_mst_pkey PRIMARY KEY (dept_idx);


--
-- Name: notif_mst notif_mst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notif_mst
    ADD CONSTRAINT notif_mst_pkey PRIMARY KEY (notif_idx);


--
-- Name: partner_mst partner_mst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_mst
    ADD CONSTRAINT partner_mst_pkey PRIMARY KEY (partner_idx);


--
-- Name: menu_mst pk_menu_mst; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_mst
    ADD CONSTRAINT pk_menu_mst PRIMARY KEY (menu_cd);


--
-- Name: user_menu_auth pk_user_menu_auth; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_menu_auth
    ADD CONSTRAINT pk_user_menu_auth PRIMARY KEY (user_idx, menu_cd);


--
-- Name: property_mst property_mst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.property_mst
    ADD CONSTRAINT property_mst_pkey PRIMARY KEY (prop_idx);


--
-- Name: sale_zone_mst sale_zone_mst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_zone_mst
    ADD CONSTRAINT sale_zone_mst_pkey PRIMARY KEY (zone_idx);


--
-- Name: store_history store_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store_history
    ADD CONSTRAINT store_history_pkey PRIMARY KEY (his_idx);


--
-- Name: store_mst store_mst_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store_mst
    ADD CONSTRAINT store_mst_pk UNIQUE (store_idx);


--
-- Name: user_mst user_mst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mst
    ADD CONSTRAINT user_mst_pkey PRIMARY KEY (user_idx);


--
-- Name: user_mst user_mst_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mst
    ADD CONSTRAINT user_mst_user_id_key UNIQUE (user_id);


--
-- Name: idx_user_mst_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_mst_id ON public.user_mst USING btree (user_id);


--
-- Name: ix_menu_mst_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_menu_mst_parent ON public.menu_mst USING btree (parent_menu_cd);


--
-- Name: ix_menu_mst_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_menu_mst_sort ON public.menu_mst USING btree (parent_menu_cd, sort_order, menu_cd);


--
-- Name: ix_notif_mst_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notif_mst_user_id ON public.notif_mst USING btree (user_id);


--
-- Name: ix_notif_mst_user_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notif_mst_user_read ON public.notif_mst USING btree (user_id, read_yn);


--
-- Name: ix_user_menu_auth_menu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_menu_auth_menu ON public.user_menu_auth USING btree (menu_cd);


--
-- Name: menu_mst fk_menu_mst_parent; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_mst
    ADD CONSTRAINT fk_menu_mst_parent FOREIGN KEY (parent_menu_cd) REFERENCES public.menu_mst(menu_cd) ON DELETE SET NULL;


--
-- Name: chk_result_dtl fk_res_chk_idx; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chk_result_dtl
    ADD CONSTRAINT fk_res_chk_idx FOREIGN KEY (chk_idx) REFERENCES public.chk_mst(chk_idx);


--
-- Name: user_menu_auth fk_user_menu_auth_menu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_menu_auth
    ADD CONSTRAINT fk_user_menu_auth_menu FOREIGN KEY (menu_cd) REFERENCES public.menu_mst(menu_cd) ON DELETE CASCADE;


--
-- Name: user_menu_auth fk_user_menu_auth_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_menu_auth
    ADD CONSTRAINT fk_user_menu_auth_user FOREIGN KEY (user_idx) REFERENCES public.user_mst(user_idx) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 7SknGSI7L4d1VLXhrxI9nABvk6TVkjH368IosjfoH3ImWW3wtbxv1p2R6FLwjb2

