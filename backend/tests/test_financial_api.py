from fastapi.testclient import TestClient

from main import app, financial_service


def test_financial_summary_contract_shape() -> None:
    original = financial_service.get_summary

    def fake_summary(user_id: str, horizon_months: int = 12):
        assert user_id == "user-1"
        assert horizon_months == 12
        return {
            "readiness": {
                "score": 72,
                "tier": "Near Ready",
                "qualifying_threshold": 80,
                "points_to_threshold": 8,
                "missing_requirements": [],
            },
            "matched_grants": [],
        }

    financial_service.get_summary = fake_summary
    try:
        client = TestClient(app)
        response = client.post("/financial/summary", json={"user_id": "user-1"})
        assert response.status_code == 200
        payload = response.json()
        assert payload["readiness"]["score"] == 72
        assert isinstance(payload["matched_grants"], list)
    finally:
        financial_service.get_summary = original


def test_financial_summary_validation_ranges() -> None:
    client = TestClient(app)
    response = client.post(
        "/financial/summary",
        json={
            "user_id": "user-1",
            "horizon_months": 99,
        },
    )
    assert response.status_code == 422
