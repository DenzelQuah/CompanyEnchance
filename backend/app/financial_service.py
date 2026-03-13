from __future__ import annotations

import calendar
from dataclasses import dataclass
from datetime import date, datetime
import math
from typing import Any

from supabase import Client, create_client

from .config import settings
from .models import (
    BankReadiness,
    DailyFinancialLog,
    DailyFinancialLogListResponse,
    FinancialGrowthGraphResponse,
    FinancialTargetResponse,
    FinancialSummaryResponse,
    GrantMatch,
    MissingRequirement,
)


@dataclass(frozen=True)
class _CriterionScore:
    code: str
    label: str
    current: float
    max_points: float
    action_tip: str

    @property
    def missing(self) -> float:
        return max(0.0, self.max_points - self.current)


class FinancialService:
    def __init__(self) -> None:
        self.supabase: Client = create_client(
            settings.supabase_url, settings.supabase_service_role_key
        )

    def get_summary(self, user_id: str, horizon_months: int = 12) -> FinancialSummaryResponse:
        survey = self._fetch_survey_context(user_id=user_id)
        milestones = self._fetch_user_milestones(user_id=user_id)
        readiness = self._build_readiness(survey=survey, milestones=milestones)
        grants = self._match_grants(survey=survey, readiness=readiness)
        return FinancialSummaryResponse(
            readiness=readiness,
            matched_grants=grants,
        )

    def upsert_target(
        self,
        user_id: str,
        month: str,
        monthly_budget_rm: float,
        target_growth_pct: float,
    ) -> FinancialTargetResponse:
        normalized_month = self._normalize_month(month)
        payload = {
            "user_id": user_id,
            "month": normalized_month,
            "monthly_budget_rm": float(monthly_budget_rm),
            "target_growth_pct": float(target_growth_pct),
        }
        result = (
            self.supabase.table("business_financial_targets")
            .upsert(payload, on_conflict="user_id,month")
            .execute()
        )
        row = (result.data or [payload])[0]
        return FinancialTargetResponse(
            user_id=str(row.get("user_id", user_id)),
            month=str(row.get("month", normalized_month)),
            monthly_budget_rm=float(row.get("monthly_budget_rm", monthly_budget_rm)),
            target_growth_pct=float(row.get("target_growth_pct", target_growth_pct)),
        )

    def get_target(self, user_id: str, month: str) -> FinancialTargetResponse:
        normalized_month = self._normalize_month(month)
        try:
            result = (
                self.supabase.table("business_financial_targets")
                .select("user_id,month,monthly_budget_rm,target_growth_pct")
                .eq("user_id", user_id)
                .eq("month", normalized_month)
                .maybe_single()
                .execute()
            )
            row = dict((getattr(result, "data", None)) or {})
        except Exception:
            row = {}
        return FinancialTargetResponse(
            user_id=user_id,
            month=normalized_month,
            monthly_budget_rm=float(row.get("monthly_budget_rm", 0.0)),
            target_growth_pct=float(row.get("target_growth_pct", 0.0)),
        )

    def upsert_daily_log(
        self,
        user_id: str,
        log_date: str,
        revenue_rm: float,
        expense_rm: float,
        note: str | None = None,
    ) -> DailyFinancialLog:
        normalized_date = self._normalize_date(log_date)
        payload = {
            "user_id": user_id,
            "log_date": normalized_date,
            "revenue_rm": float(revenue_rm),
            "expense_rm": float(expense_rm),
            "note": (note or "").strip() or None,
        }
        result = (
            self.supabase.table("daily_financial_logs")
            .upsert(payload, on_conflict="user_id,log_date")
            .execute()
        )
        row = (result.data or [payload])[0]
        return DailyFinancialLog(
            id=str(row.get("id", "")),
            user_id=str(row.get("user_id", user_id)),
            log_date=str(row.get("log_date", normalized_date)),
            revenue_rm=float(row.get("revenue_rm", revenue_rm)),
            expense_rm=float(row.get("expense_rm", expense_rm)),
            note=row.get("note"),
        )

    def get_daily_logs(self, user_id: str, month: str) -> DailyFinancialLogListResponse:
        normalized_month = self._normalize_month(month)
        start_date, end_date = self._month_date_range(normalized_month)
        try:
            result = (
                self.supabase.table("daily_financial_logs")
                .select("id,user_id,log_date,revenue_rm,expense_rm,note")
                .eq("user_id", user_id)
                .gte("log_date", start_date)
                .lte("log_date", end_date)
                .order("log_date", desc=False)
                .execute()
            )
            rows = list((getattr(result, "data", None)) or [])
        except Exception:
            rows = []
        items = [
            DailyFinancialLog(
                id=str(row.get("id", "")),
                user_id=str(row.get("user_id", user_id)),
                log_date=str(row.get("log_date", "")),
                revenue_rm=float(row.get("revenue_rm", 0.0)),
                expense_rm=float(row.get("expense_rm", 0.0)),
                note=row.get("note"),
            )
            for row in rows
        ]
        return DailyFinancialLogListResponse(items=items)

    def get_growth_graph(self, user_id: str, month: str) -> FinancialGrowthGraphResponse:
        target = self.get_target(user_id=user_id, month=month)
        logs = self.get_daily_logs(user_id=user_id, month=month).items
        normalized_month = target.month
        year, month_num = self._split_month(normalized_month)
        days_in_month = calendar.monthrange(year, month_num)[1]

        budget = max(0.0, float(target.monthly_budget_rm))
        baseline_daily = (budget / days_in_month) if days_in_month > 0 else 0.0
        target_growth = float(target.target_growth_pct)

        revenue_by_day: dict[int, float] = {}
        for item in logs:
            day = self._day_of_month(item.log_date)
            if day <= 0:
                continue
            revenue_by_day[day] = revenue_by_day.get(day, 0.0) + float(item.revenue_rm)

        dates: list[str] = []
        projection_growth_pct: list[float] = []
        actual_growth_pct: list[float] = []
        cumulative_revenue = 0.0

        for day in range(1, days_in_month + 1):
            dates.append(f"{normalized_month}-{day:02d}")
            cumulative_revenue += revenue_by_day.get(day, 0.0)
            baseline_cumulative = baseline_daily * day
            progress = day / days_in_month if days_in_month > 0 else 0.0
            projected_growth = target_growth * progress
            if baseline_cumulative <= 0:
                actual_growth = 0.0
            else:
                actual_growth = ((cumulative_revenue - baseline_cumulative) / baseline_cumulative) * 100.0
            projection_growth_pct.append(round(projected_growth, 2))
            actual_growth_pct.append(round(actual_growth, 2))

        return FinancialGrowthGraphResponse(
            month=normalized_month,
            monthly_budget_rm=round(budget, 2),
            target_growth_pct=round(target_growth, 2),
            dates=dates,
            projection_growth_pct=projection_growth_pct,
            actual_growth_pct=actual_growth_pct,
        )

    def _fetch_survey_context(self, user_id: str) -> dict[str, Any]:
        result = (
            self.supabase.table("survey_responses")
            .select(
                "id,sector,location,sales_tracking,has_audited_statements,digital_presence,"
                "business_registration_no,registration_type,digital_statement_months"
            )
            .eq("id", user_id)
            .maybe_single()
            .execute()
        )
        return dict(result.data or {})

    def _fetch_user_milestones(self, user_id: str) -> list[dict[str, Any]]:
        result = (
            self.supabase.table("user_milestones")
            .select("id,title,description,week_label,status,created_at")
            .eq("user_id", user_id)
            .order("created_at", desc=False)
            .execute()
        )
        return list(result.data or [])

    def _build_readiness(
        self, survey: dict[str, Any], milestones: list[dict[str, Any]]
    ) -> BankReadiness:
        registration_no = str(survey.get("business_registration_no") or "").strip()
        sales_tracking = str(survey.get("sales_tracking") or "").strip().lower()
        digital_presence = self._as_string_list(survey.get("digital_presence"))
        digital_months = int(survey.get("digital_statement_months") or 0)
        has_audit = bool(survey.get("has_audited_statements"))

        completed = len([m for m in milestones if str(m.get("status")) == "done"])
        completion_ratio = 0.0 if not milestones else completed / len(milestones)

        sales_tracking_points = 0.0
        if sales_tracking == "app":
            sales_tracking_points = 15.0
        elif sales_tracking == "excel":
            sales_tracking_points = 8.0
        elif sales_tracking == "paper":
            sales_tracking_points = 3.0

        digital_sales_channels = {"shopee", "grab", "tiktok shop", "tiktok", "lazada"}
        channels_present = {
            p.lower().strip() for p in digital_presence if p.lower().strip() in digital_sales_channels
        }
        digital_channel_points = min(20.0, float(len(channels_present)) * 10.0)
        statement_points = min(20.0, (min(max(digital_months, 0), 6) / 6.0) * 20.0)
        milestone_points = completion_ratio * 5.0

        criteria = [
            _CriterionScore(
                code="registration",
                label="Business registration",
                current=25.0 if registration_no else 0.0,
                max_points=25.0,
                action_tip="Register your business (UBIN/SSM) to unlock lender trust.",
            ),
            _CriterionScore(
                code="sales_tracking",
                label="Sales tracking maturity",
                current=sales_tracking_points,
                max_points=15.0,
                action_tip="Move sales records to a POS/accounting app for stronger verification.",
            ),
            _CriterionScore(
                code="digital_channels",
                label="Digital sales channels",
                current=digital_channel_points,
                max_points=20.0,
                action_tip="Add Shopee/Grab/TikTok Shop channels to strengthen digital proof.",
            ),
            _CriterionScore(
                code="digital_statements",
                label="Digital statement history",
                current=statement_points,
                max_points=20.0,
                action_tip=f"Need {max(0, 6 - digital_months)} more months of digital statements to maximize scoring.",
            ),
            _CriterionScore(
                code="audited",
                label="Audited statements",
                current=15.0 if has_audit else 0.0,
                max_points=15.0,
                action_tip="Prepare audited statements to reduce underwriting risk.",
            ),
            _CriterionScore(
                code="milestone_progress",
                label="Roadmap execution",
                current=milestone_points,
                max_points=5.0,
                action_tip="Complete roadmap milestones to improve execution credibility.",
            ),
        ]

        raw_score = sum(c.current for c in criteria)
        score = int(round(max(0.0, min(100.0, raw_score))))
        threshold = 80
        tier = self._readiness_tier(score)
        points_to_threshold = max(0, threshold - score)

        missing_requirements = [
            MissingRequirement(
                code=c.code,
                label=c.label,
                current=round(c.current, 2),
                max=round(c.max_points, 2),
                missing_points=round(c.missing, 2),
                action_tip=c.action_tip,
            )
            for c in sorted(criteria, key=lambda item: item.missing, reverse=True)
            if c.missing > 0
        ]

        return BankReadiness(
            score=score,
            tier=tier,
            qualifying_threshold=threshold,
            points_to_threshold=points_to_threshold,
            missing_requirements=missing_requirements,
        )

    def _match_grants(self, survey: dict[str, Any], readiness: BankReadiness) -> list[GrantMatch]:
        rows = self._fetch_grants()
        location = str(survey.get("location") or "").lower()
        sector = str(survey.get("sector") or "").lower()
        today = date.today()
        matches: list[GrantMatch] = []
        for row in rows:
            if not bool(row.get("is_active", True)):
                continue
            deadline = self._parse_deadline(row.get("deadline"))
            if deadline and deadline < today:
                continue

            min_readiness = int(row.get("min_readiness_score") or 0)
            if readiness.score < min_readiness:
                continue

            row_country = str(row.get("country") or "").lower()
            row_state = str(row.get("state") or "").lower()
            if row_country and "malaysia" not in row_country:
                continue
            if row_state and row_state not in {"any", "all"} and row_state not in location:
                continue

            tags = [str(tag).lower() for tag in (row.get("sector_tags") or [])]
            sector_match = (not tags) or ("all" in tags) or (sector in tags)
            if not sector_match:
                continue

            requirements = [str(r) for r in (row.get("requirements") or [])]
            unmet = self._grant_unmet_requirements(requirements=requirements, survey=survey)
            fit_score = self._grant_fit_score(
                readiness_score=readiness.score,
                min_readiness=min_readiness,
                location=location,
                grant_state=row_state,
                sector_match=sector_match,
            )
            matches.append(
                GrantMatch(
                    id=str(row.get("id") or ""),
                    name=str(row.get("name") or "Grant"),
                    agency=str(row.get("agency") or "Agency"),
                    country=str(row.get("country") or "Malaysia"),
                    state=str(row.get("state") or "Any"),
                    max_funding_rm=round(self._to_float(row.get("max_funding_rm"), 0.0), 2),
                    deadline=str(row.get("deadline") or ""),
                    fit_score=round(fit_score, 2),
                    application_url=str(row.get("application_url") or ""),
                    requirements=requirements,
                    unmet_requirements=unmet,
                )
            )

        matches.sort(key=lambda item: (-item.fit_score, item.deadline))
        return matches

    def _fetch_grants(self) -> list[dict[str, Any]]:
        try:
            result = self.supabase.table("grants_asean_2026").select("*").execute()
            return list(result.data or [])
        except Exception:
            return []

    def _grant_unmet_requirements(
        self, requirements: list[str], survey: dict[str, Any]
    ) -> list[str]:
        registration_no = str(survey.get("business_registration_no") or "").strip()
        digital_months = int(survey.get("digital_statement_months") or 0)
        audited = bool(survey.get("has_audited_statements"))
        unmet: list[str] = []
        for req in requirements:
            lowered = req.lower()
            if "registration" in lowered and not registration_no:
                unmet.append(req)
            elif "digital statement" in lowered and digital_months < 3:
                unmet.append(req)
            elif "audited" in lowered and not audited:
                unmet.append(req)
        return unmet

    def _grant_fit_score(
        self,
        readiness_score: int,
        min_readiness: int,
        location: str,
        grant_state: str,
        sector_match: bool,
    ) -> float:
        readiness_component = 0.0
        if readiness_score >= min_readiness:
            readiness_component = min(50.0, 30.0 + (readiness_score - min_readiness) * 1.5)
        location_component = 20.0
        if grant_state and grant_state not in {"any", "all"} and grant_state not in location:
            location_component = 0.0
        sector_component = 30.0 if sector_match else 0.0
        return min(100.0, readiness_component + location_component + sector_component)

    def _readiness_tier(self, score: int) -> str:
        if score >= 80:
            return "Loan Ready"
        if score >= 60:
            return "Near Ready"
        if score >= 40:
            return "Developing"
        return "Early Stage"

    def _as_string_list(self, value: Any) -> list[str]:
        if isinstance(value, list):
            return [str(item) for item in value]
        return []

    def _to_float(self, value: Any, fallback: float) -> float:
        try:
            parsed = float(value)
            if math.isnan(parsed) or math.isinf(parsed):
                return fallback
            return parsed
        except (TypeError, ValueError):
            return fallback

    def _parse_deadline(self, raw: Any) -> date | None:
        if raw is None:
            return None
        if isinstance(raw, date):
            return raw
        text = str(raw).strip()
        if not text:
            return None
        try:
            return date.fromisoformat(text)
        except ValueError:
            return None

    def _normalize_month(self, value: str) -> str:
        text = str(value or "").strip()
        try:
            parsed = datetime.strptime(text, "%Y-%m")
            return parsed.strftime("%Y-%m")
        except ValueError as exc:
            raise ValueError("month must be in YYYY-MM format.") from exc

    def _normalize_date(self, value: str) -> str:
        text = str(value or "").strip()
        try:
            parsed = datetime.strptime(text, "%Y-%m-%d")
            return parsed.strftime("%Y-%m-%d")
        except ValueError as exc:
            raise ValueError("log_date must be in YYYY-MM-DD format.") from exc

    def _split_month(self, value: str) -> tuple[int, int]:
        parts = value.split("-")
        return (int(parts[0]), int(parts[1]))

    def _month_date_range(self, value: str) -> tuple[str, str]:
        year, month_num = self._split_month(value)
        last_day = calendar.monthrange(year, month_num)[1]
        return (f"{year:04d}-{month_num:02d}-01", f"{year:04d}-{month_num:02d}-{last_day:02d}")

    def _day_of_month(self, value: str) -> int:
        try:
            return datetime.strptime(value, "%Y-%m-%d").day
        except ValueError:
            return 0
