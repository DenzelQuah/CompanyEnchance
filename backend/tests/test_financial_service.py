from app.financial_service import FinancialService


def _service() -> FinancialService:
    return FinancialService()


def test_readiness_score_capped_and_threshold_gap() -> None:
    service = _service()
    survey = {
        "business_registration_no": "UBIN-123",
        "sales_tracking": "app",
        "digital_presence": ["Shopee", "Grab", "TikTok Shop"],
        "digital_statement_months": 8,
        "has_audited_statements": True,
    }
    milestones = [{"status": "done"}, {"status": "done"}, {"status": "current"}]
    readiness = service._build_readiness(survey=survey, milestones=milestones)
    assert readiness.score <= 100
    assert readiness.score >= 80
    assert readiness.points_to_threshold == 0


def test_missing_requirements_generated() -> None:
    service = _service()
    survey = {
        "business_registration_no": "",
        "sales_tracking": "paper",
        "digital_presence": [],
        "digital_statement_months": 1,
        "has_audited_statements": False,
    }
    readiness = service._build_readiness(survey=survey, milestones=[])
    assert readiness.score < 80
    assert readiness.points_to_threshold > 0
    assert readiness.missing_requirements
    assert any(req.code == "digital_statements" for req in readiness.missing_requirements)


def test_grant_matching_filters_by_sector_location_and_readiness() -> None:
    service = _service()
    service._fetch_grants = lambda: [
        {
            "id": "g1",
            "name": "TEKUN Sarawak Biz",
            "agency": "TEKUN",
            "country": "Malaysia",
            "state": "sarawak",
            "sector_tags": ["retail & e-commerce"],
            "min_readiness_score": 60,
            "max_funding_rm": 100000,
            "deadline": "2026-12-31",
            "requirements": [],
            "application_url": "https://example.com/tekun",
            "is_active": True,
        },
        {
            "id": "g2",
            "name": "Mismatch",
            "agency": "X",
            "country": "Malaysia",
            "state": "selangor",
            "sector_tags": ["technology"],
            "min_readiness_score": 90,
            "max_funding_rm": 100000,
            "deadline": "2026-12-31",
            "requirements": [],
            "application_url": "https://example.com/x",
            "is_active": True,
        },
    ]
    survey = {"location": "Kuching, Sarawak, Malaysia", "sector": "Retail & E-commerce"}
    readiness = service._build_readiness(
        survey={
            "business_registration_no": "A",
            "sales_tracking": "app",
            "digital_presence": ["Shopee", "TikTok Shop"],
            "digital_statement_months": 6,
            "has_audited_statements": True,
        },
        milestones=[{"status": "done"}],
    )
    matches = service._match_grants(survey=survey, readiness=readiness)
    assert len(matches) == 1
    assert matches[0].id == "g1"
