from fastapi.testclient import TestClient

from main import app, financial_service


def test_upsert_target_contract_shape() -> None:
    original = financial_service.upsert_target

    def fake_upsert_target(
        user_id: str, month: str, monthly_budget_rm: float, target_growth_pct: float
    ):
        assert user_id == "user-1"
        assert month == "2026-03"
        assert monthly_budget_rm == 25000
        assert target_growth_pct == 12
        return {
            "user_id": user_id,
            "month": month,
            "monthly_budget_rm": monthly_budget_rm,
            "target_growth_pct": target_growth_pct,
        }

    financial_service.upsert_target = fake_upsert_target
    try:
        client = TestClient(app)
        response = client.post(
            "/financial/targets",
            json={
                "user_id": "user-1",
                "month": "2026-03",
                "monthly_budget_rm": 25000,
                "target_growth_pct": 12,
            },
        )
        assert response.status_code == 200
        payload = response.json()
        assert payload["month"] == "2026-03"
    finally:
        financial_service.upsert_target = original


def test_upsert_daily_log_contract_shape() -> None:
    original = financial_service.upsert_daily_log

    def fake_upsert_daily_log(
        user_id: str,
        log_date: str,
        revenue_rm: float,
        expense_rm: float,
        note: str | None = None,
    ):
        return {
            "id": "log-1",
            "user_id": user_id,
            "log_date": log_date,
            "revenue_rm": revenue_rm,
            "expense_rm": expense_rm,
            "note": note,
        }

    financial_service.upsert_daily_log = fake_upsert_daily_log
    try:
        client = TestClient(app)
        response = client.post(
            "/financial/logs",
            json={
                "user_id": "user-1",
                "log_date": "2026-03-07",
                "revenue_rm": 1200,
                "expense_rm": 500,
            },
        )
        assert response.status_code == 200
        payload = response.json()
        assert payload["id"] == "log-1"
    finally:
        financial_service.upsert_daily_log = original


def test_growth_graph_contract_shape() -> None:
    original = financial_service.get_growth_graph

    def fake_growth_graph(user_id: str, month: str):
        return {
            "month": month,
            "monthly_budget_rm": 25000,
            "target_growth_pct": 12,
            "dates": ["2026-03-01", "2026-03-02"],
            "projection_growth_pct": [0.4, 0.8],
            "actual_growth_pct": [0.2, 1.1],
        }

    financial_service.get_growth_graph = fake_growth_graph
    try:
        client = TestClient(app)
        response = client.post(
            "/financial/growth-graph",
            json={"user_id": "user-1", "month": "2026-03"},
        )
        assert response.status_code == 200
        payload = response.json()
        assert len(payload["dates"]) == 2
    finally:
        financial_service.get_growth_graph = original


def test_targets_validation_rejects_bad_month_format() -> None:
    client = TestClient(app)
    response = client.post(
        "/financial/targets",
        json={
            "user_id": "user-1",
            "month": "03-2026",
            "monthly_budget_rm": 25000,
            "target_growth_pct": 12,
        },
    )
    # Request model format passes as string; service enforces month format.
    assert response.status_code in (400, 422)


def test_logs_validation_rejects_bad_date_format() -> None:
    client = TestClient(app)
    response = client.post(
        "/financial/logs",
        json={
            "user_id": "user-1",
            "log_date": "2026/03/07",
            "revenue_rm": 1000,
            "expense_rm": 500,
        },
    )
    assert response.status_code in (400, 422)
