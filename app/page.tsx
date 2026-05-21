import Link from "next/link";
import styles from "./page.module.css";

/**
 * 디스커버리 홈 (D01)
 * 사용자 명시 사양 그대로:
 * - 필터: 지역·인기·회원수
 * - 내 모임 카루셀
 * - 모임 카드 A안: 좌측 로고 + 우측 최근글 2 + 인기글 2 (위아래)
 * R1에서는 *목업 데이터*로 화면만 그림. R2에서 Supabase 연결.
 */

const MOCK_CAFES = [
  {
    id: "1",
    name: "강서구 7세 엄마 모임",
    slug: "gangseo-7yr-moms",
    emoji: "👶",
    accent: "#3D5A47",
    heartbeat: 32,
    memberCount: 87,
    region: "강서구",
    isGenesis: true,
    recent: [
      "아이 처음 어린이집 보내는 분",
      "강서구 정형외과 추천 부탁드려요"
    ],
    popular: [
      "7세 한글 떼기 어떻게 했나요",
      "학원 다니다 너무 힘들어요"
    ]
  },
  {
    id: "2",
    name: "강서구 비건 엄마 모임",
    slug: "gangseo-vegan-moms",
    emoji: "🌱",
    accent: "#0D9488",
    heartbeat: 19,
    memberCount: 34,
    region: "강서구",
    recent: ["비건 이유식 조리법 공유", "강서구 비건 카페 추천"],
    popular: ["남편이 비건 반대해요", "아이도 비건으로 키우시나요?"]
  },
  {
    id: "3",
    name: "30대 디자이너 출신 엄마",
    slug: "designer-moms",
    emoji: "✏️",
    accent: "#7C3AED",
    heartbeat: 47,
    memberCount: 142,
    region: "서울",
    recent: ["프리랜서 복귀 고민", "아이 그림책 추천"],
    popular: ["10년 만에 다시 디자인 시작", "포트폴리오 어떻게 정리하셨나요"]
  }
];

export default function HomePage() {
  return (
    <main className={styles.main}>
      {/* 상단 바 */}
      <header className={styles.header}>
        <div className="container">
          <div className={styles.headerRow}>
            <h1 className={styles.logo}>심박</h1>
            <div className={styles.headerActions}>
              <Link href="/login" className={styles.iconBtn} aria-label="로그인">
                로그인
              </Link>
            </div>
          </div>
        </div>
      </header>

      <div className="container">
        {/* 오늘의 모임 결정 — 19시 가동 (Q1 b) */}
        <section className={styles.dailyDecision}>
          <div className={styles.dailyBadge}>오늘의 모임 결정 · 매일 19시</div>
          <h2 className={styles.dailyTitle}>
            오늘 강서구 7세 엄마 모임은 어떻게 결정했을까요?
          </h2>
          <p className={styles.dailySub}>
            응답 전엔 다른 분들 결과를 볼 수 없어요. <span className="muted">시간 외엔 비활성</span>
          </p>
          <Link href="/decision" className="btn btn-accent btn-block">
            지금 참여하기
          </Link>
        </section>

        {/* 내 모임 카루셀 */}
        <section className={styles.mySection}>
          <h3 className={styles.sectionTitle}>내 모임</h3>
          <div className={styles.myList}>
            <Link href="/cafe/new" className={styles.myCardAdd}>
              <span className={styles.addIcon}>+</span>
              <span>새 모임 만들기</span>
            </Link>
            <div className={styles.myCardEmpty}>아직 가입한 모임이 없어요</div>
          </div>
        </section>

        {/* 필터 칩 */}
        <section className={styles.filters} aria-label="필터">
          <button className={styles.filterChip}>
            지역 <strong>강서구</strong> ▾
          </button>
          <button className={styles.filterChip}>
            인기 <strong>활발한 순</strong> ▾
          </button>
          <button className={styles.filterChip}>
            회원수 <strong>전체</strong> ▾
          </button>
        </section>

        {/* 모임 카드 리스트 — 사용자 명시 A안 */}
        <section className={styles.cafeList}>
          {MOCK_CAFES.map((cafe) => (
            <Link
              key={cafe.id}
              href={`/cafe/${cafe.slug}`}
              className={styles.cafeCard}
              style={{ "--card-accent": cafe.accent } as React.CSSProperties}
            >
              <div className={styles.cafeLogo} aria-hidden>
                <span>{cafe.emoji}</span>
              </div>
              <div className={styles.cafeBody}>
                <ul className={styles.previewList}>
                  <li className={styles.previewItem}>
                    <span className={styles.previewIcon}>📰</span>
                    <span className={styles.previewText}>{cafe.recent[0]}</span>
                  </li>
                  <li className={styles.previewItem}>
                    <span className={styles.previewIcon}>📰</span>
                    <span className={styles.previewText}>{cafe.recent[1]}</span>
                  </li>
                  <li className={styles.previewItem}>
                    <span className={styles.previewIcon}>🔥</span>
                    <span className={styles.previewText}>{cafe.popular[0]}</span>
                  </li>
                  <li className={styles.previewItem}>
                    <span className={styles.previewIcon}>🔥</span>
                    <span className={styles.previewText}>{cafe.popular[1]}</span>
                  </li>
                </ul>
                <div className={styles.cafeMeta}>
                  <span className={styles.cafeName}>
                    {cafe.isGenesis && <span className={styles.genesisBadge}>Genesis</span>}
                    {cafe.name}
                  </span>
                  <span className={styles.heartbeat}>
                    ♥ <strong>{cafe.heartbeat}</strong>
                  </span>
                </div>
              </div>
            </Link>
          ))}
        </section>

        {/* 결핍 카드 — 아뱅 Q2 안 1 */}
        <section className={styles.gapCard}>
          <div className={styles.gapIcon}>⚠</div>
          <div>
            <p className={styles.gapTitle}>
              이 동네에 [3-7세 한부모 엄마] 모임이 없어요.
            </p>
            <p className={styles.gapBody}>
              지난 7일간 53명이 검색했어요. 첫 운영자가 되시겠어요?
            </p>
            <Link href="/cafe/new" className="btn btn-secondary">
              모임 만들기
            </Link>
          </div>
        </section>

        <footer className={styles.foot}>
          <p>심박 (Heartbeat) — 모임의 생사를 책임지는 곳</p>
          <p className="caption">
            R1 · 디스커버리 골격. 화면 데이터는 목업.
          </p>
        </footer>
      </div>
    </main>
  );
}
